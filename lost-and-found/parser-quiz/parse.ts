import * as XLSX from './xlsx';
import * as fs from 'fs';
import * as cptable from './cpexcel.full.mjs';
XLSX.set_cptable(cptable);
XLSX.set_fs(fs);

const wb = XLSX.readFile('./input.xlsx');

interface Block { id: string; description: string; db_id: number }

type XlsType = 'SN' | 'SC' | 'AC' | 'SNT' | 'MC';
type DbQuizConfigType = 'yesnomaybe' | 'skillset' | 'text' | 'onlychoice' |
    'yesno' | 'botao_fim' | 'cep_address_lookup' | 'auto_change_questionnaire' |
    'displaytext' | 'yesnogroup' | 'autocontinue' | 'botao_tela_modo_camuflado' |
    'next_mf_questionnaire' | 'multiplechoice';

const yesnoRegex = new RegExp(/(S|N|T)\s*[:,]\s*(.+)\s*/);
const mcRegexp = new RegExp(/\"([^\"]+)"\s*[:,]\s*(.+)\s*/);

const DeParaType: Record<XlsType, DbQuizConfigType> = {
    'AC': 'autocontinue',
    'SNT': 'yesnomaybe',
    'SN': 'yesno',
    'SC': 'onlychoice',
    'MC': 'multiplechoice'
};

interface XLSXParsedOption {
    proxima_pergunta: string
    opcao: string
    cod_respostas: string[]
}

interface QuizConfigTarefa {
    codigo: string
}

interface ParsedQuestionType {
    orig_type: XlsType
    db_type: DbQuizConfigType
    change_to_questionnaire_id: number | null
    options: XLSXParsedOption[]
    tarefas: QuizConfigTarefa[]
}

interface Question {
    blockId: string;
    questionId: string;
    description: string;
    type: string;
    optionsPath: string
    parsedType: ParsedQuestionType
    obs: string;
    tasks: string;
    questionario: string;
    intros: string[];
}

interface Reply {
    blockId: string;
    questionId: string;
    replyId: string;
    description: string;
}

interface Task {
    blockId: string;
    replyId: string;
    taskId: string;
    description: string;
    belongsToBlock: string;
    observation: string;
}

const parseSheet = <T>(worksheet: XLSX.WorkSheet): T[] => {
    const json = XLSX.utils.sheet_to_json(worksheet, { header: 1 });
    const headers = json.shift() as string[];
    return json.map((row: any) => {
        const formatted: any = {};
        headers.forEach((header, index) => {
            const value = row[index];

            formatted[header] = typeof value === 'string' ?
                value.replace(/\u2028/g, `\n`) // Unicode Line Separator (U+2028)
                    .replace(/\r\n/g, `\n`) // sai windows!
                    .replace(/[“”]/g, `"`) // windows hate us
                    .replace(/ {2,9}/g, ` `) // espaços duplicados
                    .trim()
                : value;
        });
        return formatted;
    }) as T[];
};

const transformBlock = (data: any): Block => ({
    id: data["ID Bloco"],
    description: data["Descrição Bloco"],
    db_id: +data["ID Questionario"],
});

const transformQuestion = (data: any): Question => {
    const parsed: ParsedQuestionType = {
        change_to_questionnaire_id: null,
        db_type: DeParaType[data["Tipo"]],
        orig_type: data["Tipo"],
        options: [],
        tarefas: [],
        cod_respostas: [],
    };

    let returning = {
        blockId: data["ID Bloco"],
        questionId: data["ID Pergunta"],
        description: data["Descrição Pergunta"],
        type: data["Tipo"],
        optionsPath: data["Opcoes / caminho subsequente"],
        obs: data["Obs"],
        tasks: data["tarefas"],
        questionario: data["questionario"],
        intros: data["intros"] ? data["intros"].split('\n\n') : [],
        parsedType: parsed,
    };

    if (returning.tasks) {
        parsed.tarefas.push(returning.tasks.split(',').map(n => n.trim()));
        console.log(parsed)
    }

    if (returning.blockId) {
        if (typeof parsed.db_type === 'undefined')
            throw `faltando de-para para o tipo ${data["Tipo"]} em ${JSON.stringify(returning)}`;


        if (parsed.db_type === 'autocontinue') {
            parsed.change_to_questionnaire_id = +returning.questionario;

            if (isNaN(parsed.change_to_questionnaire_id))
                throw `faltando change_to_questionnaire_id para o tipo autocontinue em ${JSON.stringify(returning)}`;
        } else if ([
            'onlychoice',
            'multiplechoice',
            'yesno',
            'yesnomaybe'
        ].includes(parsed.db_type)) {
            for (const line of returning.optionsPath.split('\n')) {
                const ret = (['yesno', 'yesnomaybe'].includes(parsed.db_type) ? yesnoRegex : mcRegexp).exec(line);

                if (!ret || !ret[1] || !ret[2]) throw `falha ao parsear linha ${line} em ${JSON.stringify(returning)}`;

                const paths = ret[2].split(',').map(n => n.trim());

                const cod_respostas: string[] = [];
                let pergunta = '';
                for (const path of paths) {
                    if (path.toLowerCase().startsWith('p')) {
                        if (pergunta) throw `só pode seguir pra uma pergunta por vez, ${line} em ${JSON.stringify(returning)}`
                        pergunta = path;
                    } else {
                        cod_respostas.push(path)
                    }
                }
                if (!pergunta) throw `faltando pergunta, ${line} em ${JSON.stringify(returning)}`

                parsed.options.push({
                    opcao: ret[1],
                    proxima_pergunta: pergunta,
                    cod_respostas
                });
            }

            console.log(parsed)
        }

    }

    return returning;
};

const transformReply = (data: any): Reply => ({
    blockId: data["ID\nBloco"],
    questionId: data["ID\nPergunta"],
    replyId: data["ID\nResposta"],
    description: data["Descrição Resposta"],
});

const transformTask = (data: any): Task => ({
    blockId: data["ID Bloco"],
    replyId: data["ID Resposta"],
    taskId: data["ID Tarefa"],
    description: data["Descrição Tarefa"],
    belongsToBlock: data["Pertence ao bloco"],
    observation: data["Observação"],
});

const blocks: Block[] = parseSheet(wb.Sheets[wb.SheetNames[0]]).map(transformBlock).filter(n => n.id);
const questions: Question[] = parseSheet(wb.Sheets[wb.SheetNames[1]]).map(transformQuestion).filter(n => n.blockId);
const replies: Reply[] = parseSheet(wb.Sheets[wb.SheetNames[2]]).map(transformReply).filter(n => n.blockId);
const tasks: Task[] = parseSheet(wb.Sheets[wb.SheetNames[3]]).map(transformTask).filter(n => n.blockId);

//console.log("Blocks:", blocks);
//console.log("Questions:", questions);
//console.log("Replies:", replies);
//console.log("Tasks:", tasks);

