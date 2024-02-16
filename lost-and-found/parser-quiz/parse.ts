import * as XLSX from './xlsx';
import * as fs from 'fs';
import * as cptable from './cpexcel.full.mjs';
XLSX.set_cptable(cptable);
XLSX.set_fs(fs);

interface Block {
    id: string;
    description: string;
    db_id: number;
}

const fixTarefasSQL = `
update mf_tarefa set eh_customizada=true where tipo != 'checkbox';
`;

type XlsType = 'SN' | 'SC' | 'AC' | 'SNT' | 'MC' | 'BF' | 'PS' | 'ET' | 'PQ' | 'RF';

type DbQuizConfigType =
    | 'yesnomaybe'
    | 'skillset'
    | 'text'
    | 'onlychoice'
    | 'yesno'
    | 'botao_fim'
    | 'cep_address_lookup'
    | 'displaytext'
    | 'yesnogroup'
    | 'auto_change_questionnaire'
    | 'botao_tela_modo_camuflado'
    | 'next_mf_questionnaire'
    | 'multiplechoices'
    | 'next_mf_questionnaire_outstanding'
    | 'tag_user';

const yesnoRegex = new RegExp(/(S|N|T)\s*[:,]\s*(.+)\s*/);
const mcRegexp = new RegExp(/\"([^\"]+)"\s*[:,]\s*(.+)\s*/);
const escapeString = (str: string) => (str ? str.replace(/\\/g, '\\\\').replace(/'/g, "\\'") : '');

const bf_label = 'Concluir';

function linkify(text: string | undefined): string {
    if (!text) return text || '';

    // if there isn't http, but find www, then replace it by https
    return text.replace(/(https?:\/\/(?:www\.|(?!www))[^\s.]+\.[^\s]{2,}|www\.[^\s]+\.[^\s]{2,})/g, (match) => {
        let href = match;
        if (!/^http/.test(href)) {
            href = `https://${href}`;
        }
        return `<a href=\"${href}\">${href}<\/a>`;
    });
}

const DeParaType: Record<XlsType, DbQuizConfigType> = {
    AC: 'auto_change_questionnaire',
    PS: 'next_mf_questionnaire_outstanding',
    SNT: 'yesnomaybe',
    SN: 'yesno',
    SC: 'onlychoice',
    MC: 'multiplechoices',
    BF: 'botao_fim',
    ET: 'displaytext',
    PQ: 'next_mf_questionnaire',
    RF: 'yesno',
};

interface QuizConfigTarefa {
    codigo: string;
}

interface QuizConfigTag {
    codigo: string;
}

interface QuizConfig {
    status: 'published';
    sort: number;
    type: DbQuizConfigType;
    code: string;
    question: string; //length max 800
    questionnaire_id: number; //foreign key, not nullable
    intro: string[]; //default []
    relevance: string; //default is '1', length max 2000
    button_label: string | null; //default 'null', length max 200
    options: any[] | null;
    tarefas: QuizConfigTarefa[]; //default []
    change_to_questionnaire_id: number | null;
    tag: QuizConfigTag[];
}

interface XLSXParsedOption {
    proxima_pergunta: string;
    opcao: string;
    opcao_clean: string;
    cod_respostas: string[];
    tags: string[];
}

interface ParsedQuestionType {
    orig_type: XlsType;
    db_type: DbQuizConfigType;
    change_to_questionnaire_id: number | null;
    options: XLSXParsedOption[];
    tarefas: QuizConfigTarefa[];
    button_label: string | null;
}

interface Question {
    blockId: string;
    questionId: string;
    description: string;
    type: string;
    optionsPath: string;
    relevance: string;
    tags: QuizConfigTag[];
    parsedType: ParsedQuestionType;
    obs: string;
    tasks: string;
    questionario: string;
    intros: string[];
}

interface ReplyXls {
    blockId: string;
    questionsId: string;
    replyId: string;
    description: string;
}

interface Reply {
    blockId: string;
    questionId: string;
    replyId: string;
    description: string;
    tarefas: string[];
}

interface Task {
    blockId: string;
    repliesIds: string[];
    taskId: string;
    description: string;
    belongsToBlock: string;
    observation: string;
}

interface Tag {
    tagCode: string;
    description: string;
}

const parseSheet = <T>(worksheet: XLSX.WorkSheet): T[] => {
    const json = XLSX.utils.sheet_to_json(worksheet, { header: 1 });
    const headers = json.shift() as string[];
    return json.map((row: any) => {
        const formatted: any = {};
        headers.forEach((header, index) => {
            const value = row[index];

            formatted[header] =
                typeof value === 'string'
                    ? value
                          .replace(/\u2028/g, `\n`) // Unicode Line Separator (U+2028)
                          .replace(/\r\n/g, `\n`) // sai windows!
                          .replace(/[“”]/g, `"`) // windows hate us
                          .replace(/\u00A0/g, ' ')
                          .replace(/ {2,9}/g, ` `) // espaços duplicados
                          .trim()
                    : value;
        });
        return formatted;
    }) as T[];
};

const transformBlock = (data: any): Block => ({
    id: data['ID Bloco'],
    description: data['Descrição Bloco'],
    db_id: +data['ID Questionario'],
});

const transformTag = (data: any): Tag => ({
    tagCode: data['ID TAG'],
    description: data['DESCRICAO'],
});

const transformQuestion = (data: any): Question => {
    const parsed: ParsedQuestionType = {
        change_to_questionnaire_id: null,
        db_type: DeParaType[data['Tipo']],
        orig_type: data['Tipo'],
        options: [],
        tarefas: [],
        button_label: null,
    };

    let returning: Question = {
        blockId: data['ID Bloco'],
        questionId: data['ID Pergunta'],
        description: data['Descrição Pergunta'],
        type: data['Tipo'],
        optionsPath: data['Opcoes / caminho subsequente'],
        obs: data['Obs'],
        tasks: data['tarefas'],
        questionario: data['questionario'],
        intros: data['intros'] ? data['intros'].split('\n\n') : [],
        parsedType: parsed,
        relevance: '',
        tags: [],
    };

    if (returning.tasks) {
        const tasks = returning.tasks.split(',');
        for (const codigo of tasks) {
            parsed.tarefas.push({
                codigo: codigo.trim(),
            });
        }
    }

    if (returning.blockId) {
        if (typeof parsed.db_type === 'undefined')
            throw `faltando de-para para o tipo ${data['Tipo']} em ${JSON.stringify(returning)}`;

        if (parsed.orig_type === 'RF') {
            try {
                const params = JSON.parse(returning.optionsPath);
                returning.relevance = params.relevance || '';

                if (params.type) {
                    parsed.db_type = params.type;
                }

                if (params.button_label) {
                    parsed.button_label = params.button_label;
                }

                if (params.tags && Array.isArray(params.tags)) {
                    for (const tag of params.tags) {
                        returning.tags.push({ codigo: tag });
                    }
                }

                returning.optionsPath = 'skip';
            } catch (error) {
                throw `falha ao ler JSON do campo RF ${error}`;
            }
        }

        if (parsed.db_type === 'auto_change_questionnaire') {
            parsed.change_to_questionnaire_id = +returning.questionario;

            if (isNaN(parsed.change_to_questionnaire_id))
                throw `faltando change_to_questionnaire_id para o tipo auto_change_questionnaire em ${JSON.stringify(
                    returning
                )}`;
        } else if (parsed.db_type == 'botao_fim') {
            parsed.button_label = bf_label;
        } else if (
            ['onlychoice', 'multiplechoices', 'yesno', 'yesnomaybe'].includes(parsed.db_type) &&
            returning.optionsPath !== 'skip'
        ) {
            for (const line of returning.optionsPath.split('\n')) {
                const ret = (['yesno', 'yesnomaybe'].includes(parsed.db_type) ? yesnoRegex : mcRegexp).exec(line);

                if (!ret || !ret[1] || !ret[2]) throw `falha ao parsear linha ${line} em ${JSON.stringify(returning)}`;

                const paths = ret[2].split(',').map((n) => n.trim());

                const cod_respostas: string[] = [];
                const tags: string[] = [];
                let pergunta = '';
                for (const path of paths) {
                    if (path.toLowerCase().startsWith('p')) {
                        if (pergunta)
                            throw `só pode seguir pra uma pergunta por vez, ${line} em ${JSON.stringify(returning)}`;
                        pergunta = path;
                    } else if (path.toLowerCase().startsWith('t')) {
                        tags.push(path);
                    } else {
                        cod_respostas.push(path);
                    }
                }
                if (!pergunta) throw `faltando pergunta, ${line} em ${JSON.stringify(returning)}`;

                let opcao = ret[1];
                let opcao_clean: string;

                if (['yesno', 'yesnomaybe'].includes(parsed.db_type)) {
                    opcao = opcao.toUpperCase().replace('S', 'Y').replace('T', 'M'); // n => N
                    opcao_clean = opcao;
                } else {
                    opcao_clean = opcao
                        .toLowerCase()
                        .normalize('NFD')
                        .replace(/[\u0300-\u036f]/g, '')
                        .replace(/e\/ou/g, 'e_ou')
                        .replace(/\//g, '-ou-')
                        .replace(/\s/g, '-')
                        .replace(/\u00A0/g, ' ')
                        .replace(/[^a-z0-9\-\_]/g, '');
                }

                parsed.options.push({
                    opcao: opcao,
                    opcao_clean: opcao_clean,
                    proxima_pergunta: pergunta,
                    cod_respostas,
                    tags,
                });
            }

            if (returning.questionId == 'P10') {
                console.log(returning);
            }
            if (parsed.db_type === 'yesnomaybe') {
                if (parsed.options.length !== 3) {
                    console.log(parsed);
                    throw 'faltou opcao no yesnomaybe';
                }
            } else if (parsed.db_type === 'yesno') {
                if (parsed.options.length !== 2) {
                    console.log(parsed);
                    throw 'faltou opcao no yesno';
                }
            }
        }
    }

    return returning;
};

const transformReply = (data: any): ReplyXls => ({
    blockId: data['ID\nBloco'],
    questionsId: data['ID\nPergunta'],
    replyId: data['ID\nResposta'],
    description: data['Descrição Resposta'],
});

const transformTask = (data: any): Task => {
    const str = data['ID Resposta'] ? (data['ID Resposta'] as string).replace(/\s*ou\s*/, ',') : '';
    const repliesIds = str.split(',').map((s) => s.trim());

    return {
        blockId: data['ID Bloco'],
        repliesIds: repliesIds,
        taskId: data['ID Tarefa'],
        description: linkify(data['Descrição Tarefa']),
        belongsToBlock: data['Pertence ao bloco'],
        observation: data['Observação'],
    };
};

const dbTarefa = (tarefasIds: string[]): QuizConfigTarefa[] => {
    return tarefasIds.map((t) => ({ codigo: t }));
};

const expandReply = (replyXls: ReplyXls[]): Reply[] => {
    const out: Reply[] = [];

    for (const reply of replyXls) {
        const str = reply.questionsId.replace(/\s*ou\s*/, ',');
        const questions = str.split(',').map((s) => s.trim());

        for (const questionId of questions) {
            out.push({
                blockId: reply.blockId,
                description: reply.description,
                replyId: reply.replyId,
                questionId: questionId,
                tarefas: [],
            });
        }
    }

    return out;
};

const generateTagSql = (tags: Tag[]) => {
    let sqlStr = '';

    for (let tag of tags) {
        let escapedTagCode = escapeString(tag.tagCode);
        let escapedDescription = escapeString(tag.description);
        sqlStr += `INSERT INTO tag(code, description) VALUES (E'${escapedTagCode}', E'${escapedDescription}')
                   ON CONFLICT (code) DO UPDATE
                   SET description = EXCLUDED.description;\n`;
    }

    return sqlStr;
};

const generateTarefasSql = (tasks: Task[], blocks: Block[]) => {
    let sqlStr = '';

    for (let task of tasks) {
        const { taskId: codigo, description: descricao, belongsToBlock: agrupador } = task;

        // tudo vazio por enquanto
        const titulo = '';
        let tipo = 'checkbox';

        if (/Salve esses contatos/.test(descricao)) {
            tipo = 'checkbox_contato';
        }

        const blocoAgrupador = blocks.find((r) => r.id === agrupador)?.description || agrupador;

        sqlStr += `INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'${escapeString(codigo)}',
                      E'${escapeString(titulo)}',
                      E'${escapeString(descricao)}',
                      E'${escapeString(tipo)}',
                      E'${escapeString(blocoAgrupador)}'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;\n`;
    }

    return sqlStr;
};

function getBlockByid(blocks: Block[]) {
    const blockId: Record<string, number> = {};
    for (const block of blocks) {
        blockId[block.id] = +block.db_id;
    }
    return blockId;
}

const generateSql = (blocks: Block[], quiz: QuizConfig[]) => {
    let sqlStr = '';

    for (let block of blocks) {
        sqlStr += `DELETE FROM quiz_config WHERE questionnaire_id = ${block.db_id};\n`;

        for (let qc of quiz) {
            if (qc.questionnaire_id == block.db_id) {
                let escapedQuestion = escapeString(qc.question);
                let escapedIntro = escapeString(
                    JSON.stringify(
                        qc.intro.map((intro) => {
                            return { text: intro };
                        })
                    )
                );
                let escapedRelevance = escapeString(qc.relevance);
                let escapedOptions = qc.options !== null ? escapeString(JSON.stringify(qc.options)) : null;

                sqlStr += `INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('${qc.status}', ${qc.sort}, '${qc.type}', '${qc.code}', E'${escapedQuestion}',
                        ${qc.questionnaire_id}, E'${escapedIntro}', E'${escapedRelevance}', ${
                    qc.button_label === null ? 'null' : `'${qc.button_label}'`
                },
                        ${escapedOptions === null ? 'null' : `E'${escapedOptions}'`}, '${JSON.stringify(
                    qc.tarefas
                )}', ${qc.change_to_questionnaire_id}, '${JSON.stringify(qc.tag)}');\n`;
            }
        }
    }

    return sqlStr;
};

function boostrap() {
    const wb = XLSX.readFile('./input.xlsx');

    const blocks: Block[] = parseSheet(wb.Sheets[wb.SheetNames[0]])
        .map(transformBlock)
        .filter((n) => n.id);
    const questions: Question[] = parseSheet(wb.Sheets[wb.SheetNames[1]])
        .map(transformQuestion)
        .filter((n) => n.blockId);
    const replies: Reply[] = expandReply(
        parseSheet(wb.Sheets[wb.SheetNames[2]])
            .map(transformReply)
            .filter((n) => n.blockId)
    );
    const tasks: Task[] = parseSheet(wb.Sheets[wb.SheetNames[3]])
        .map(transformTask)
        .filter((n) => n.blockId);
    const tags: Tag[] = parseSheet(wb.Sheets[wb.SheetNames[4]])
        .map(transformTag)
        .filter((n) => n.tagCode);
    const blockById = getBlockByid(blocks);

    for (const task of tasks) {
        for (const reply of replies) {
            if (task.repliesIds.includes(reply.replyId)) {
                reply.tarefas.push(task.taskId);
            }
        }
    }

    fs.writeFileSync('out/tags.sql', generateTagSql(tags));
    fs.writeFileSync('out/tarefas.sql', generateTarefasSql(tasks, blocks) + fixTarefasSQL);

    //console.log(replies)

    let sort_order: number = 10000000 - 1000;
    const quiz: QuizConfig[] = [];

    for (const q of questions) {
        const code = `${q.blockId}_${q.questionId}`;

        const row: QuizConfig = {
            button_label: null,
            change_to_questionnaire_id: q.parsedType.change_to_questionnaire_id,
            code: code,
            intro: q.intros,
            options: null,
            question: linkify(q.description),
            questionnaire_id: blockById[q.blockId],
            relevance: q.relevance || '1', // se tinha alguma relevância que veio pelo excel, fica ela, se nao é default 1, mas se tiver pergunta, vai passar na frente anyway
            sort: sort_order,
            status: 'published',
            tarefas: q.parsedType.tarefas,
            type: q.parsedType.db_type,
            tag: q.tags,
        };

        if (!row.questionnaire_id) throw `Faltando ID para o bloco ${q.blockId} -- pergunta ${q.questionId}`;

        if (row.type === 'botao_fim') {
            row.button_label = bf_label;
        } else if (row.type === 'onlychoice' || row.type === 'multiplechoices') {
            row.options = [];
            for (const option of q.parsedType.options) {
                row.options.push({
                    label: option.opcao,
                    value: option.opcao_clean,
                });
            }
        }

        let relevances: string[] = [];

        for (const q2 of questions) {
            for (const option of q2.parsedType.options) {
                if (option.proxima_pergunta == q.questionId) {
                    if (q2.parsedType.db_type === 'multiplechoices') {
                        relevances.push(`is_json_member('${option.opcao_clean}', ${q2.blockId}_${q2.questionId}_json)`);
                    } else {
                        relevances.push(`${q2.blockId}_${q2.questionId} == '${option.opcao_clean}'`);
                    }
                }
            }
        }

        if (relevances.length > 0) {
            row.relevance = relevances.join(' || ');
        }

        quiz.push(row);

        const queued_responses: QuizConfig[] = [];

        for (const option of q.parsedType.options) {
            let relevance = '';

            if (q.parsedType.db_type === 'multiplechoices') {
                relevance = `is_json_member('${option.opcao_clean}', ${code}_json)`;
            } else {
                relevance = `${code} == '${option.opcao_clean}' `;
            }

            for (const resp of option.cod_respostas) {
                sort_order += 10;

                const replyObj = replies.filter((r) => r.replyId === resp);

                if (replyObj.length == 0) throw `reply ${resp} not found`; // pode ter N perguntas pra mesma resposta, por isso q pode dar > 1

                const resp_code = `${code}_${resp}`;

                const resp_row: QuizConfig = {
                    question: linkify(replyObj[0].description),
                    questionnaire_id: blockById[q.blockId],
                    relevance: relevance,
                    sort: sort_order,
                    tarefas: dbTarefa(replyObj[0].tarefas),
                    button_label: null,
                    change_to_questionnaire_id: null,
                    code: resp_code,
                    intro: [],
                    options: null,
                    status: 'published',
                    type: 'displaytext',
                    tag: [],
                };

                queued_responses.push(resp_row);
            }

            if (option.proxima_pergunta === 'PQ') {
                const next_mf: QuizConfig = {
                    question: ' ',
                    questionnaire_id: blockById[q.blockId],
                    relevance: relevance,
                    sort: sort_order + 1,
                    tarefas: [],
                    button_label: null,
                    change_to_questionnaire_id: null,
                    code: `${code}_PQ_${option.opcao_clean.replace(/-/g, '_').toUpperCase()}`,
                    intro: [],
                    options: null,
                    status: 'published',
                    type: 'next_mf_questionnaire',
                    tag: [],
                };

                queued_responses.push(next_mf);
            }

            if (option.tags.length > 0) {
                let relevance = '';

                if (q.parsedType.db_type === 'multiplechoices') {
                    relevance = `is_json_member('${option.opcao_clean}', ${code}_json)`;
                } else {
                    relevance = `${code} == '${option.opcao_clean}' `;
                }

                const resp_code = `${code}_tags`;

                const tag_row: QuizConfig = {
                    question: '',
                    questionnaire_id: blockById[q.blockId],
                    relevance: relevance,
                    sort: sort_order + 5,
                    tarefas: [],
                    button_label: null,
                    change_to_questionnaire_id: null,
                    code: resp_code,
                    intro: [],
                    options: null,
                    status: 'published',
                    type: 'tag_user',
                    tag: option.tags.map((t) => ({ codigo: t })),
                };

                queued_responses.push(tag_row);
            }
        }

        // quando é MC, precisa tratar o caso onde há varias respostas que contem a mesma resposta
        // vou usar como chave o codigo da resposta (R123 por exemplo)
        const regexp = new RegExp(/^B\d+_P\d+_/g);
        if (q.parsedType.db_type === 'multiplechoices') {
            const alreadyAdded = new Set();

            for (const response of queued_responses) {
                if (response.type !== 'displaytext') {
                    quiz.push(response);
                    continue;
                }

                const response_code = response.code.replace(regexp, '');

                if (alreadyAdded.has(response_code)) continue;
                alreadyAdded.add(response_code);

                const relevances: string[] = [];
                for (const otherR of queued_responses) {
                    if (otherR.type === response.type && otherR.code.replace(regexp, '') === response_code)
                        relevances.push(otherR.relevance);
                }

                console.log({ relevances, question: response.question, response_code });

                quiz.push({
                    ...response,
                    relevance: relevances.join(' || '),
                });
            }
        } else {
            quiz.push(...queued_responses);
        }

        //console.log(row)
        //if (sort_order >= 10000000 + 1000)
        //process.exit();

        sort_order += 1000;
    }

    //console.log("Blocks:", blocks);
    //console.log("Questions:", questions);
    //console.log("Replies:", replies);
    //console.log("Tasks:", tasks);
    //console.log("Tags:", tags);

    fs.writeFileSync('out/quiz_config.sql', generateSql(blocks, quiz));
}

boostrap();
