DELETE FROM quiz_config WHERE questionnaire_id = 12;
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 9999000, 'yesno', 'B0_P0a', E'Você quer limpar sua lista de tarefas atual? Lembre-se que esta lista foi feita especialmente para você, com base nas suas respostas anteriores. Se você limpar, todas as informações serão perdidas. Se não, novas tarefas serão somadas às atuais.',
                        12, E'[]', E'cliente.ja_completou_mf==\'1\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10000000, 'yesno', 'B0_P0b', E'Atenção: essa ação não pode ser desfeita. Para criar uma nova lista de tarefas será necessário responder todas as perguntas novamente. Tem certeza disso?',
                        12, E'[]', E'cliente.ja_completou_mf==\'1\' && B0_P0a ==\'Y\'', null,
                        null, '[]', null, '[{"codigo":"SIM_LIMPA_MF"}]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10001000, 'yesno', 'B0_P0c', E'Atenção: essa ação não pode ser desfeita. Novas tarefas, baseadas em suas próximas respostas, serão adicionadas à sua lista atual. Tem certeza de que não quer limpar sua lista de tarefas?',
                        12, E'[]', E'cliente.ja_completou_mf==\'1\' && B0_P0a ==\'N\' ', null,
                        null, '[]', null, '[{"codigo":"NAO_LIMPA_MF"}]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10002000, 'onlychoice', 'B0_P0', E'Separamos o conteúdo em quatro blocos. Por qual você quer começar?',
                        12, E'[{"text":"Olá, bem-vinda ao Manual de Fuga do PenhaS. A finalidade deste manual é construir junto contigo as melhores estratégias de segurança pessoal e informar sobre os direitos que você possui, caso precise fugir de casa para se proteger. "},{"text":"São necessários aproximadamente 20 minutos para responder e ter acesso a uma lista personalizada de ações imprescindíveis para o planejamento da sua fuga. Caso seja necessário, você pode interromper e voltar exatamente de onde parou."},{"text":"Tenha em mente que cada situação é diferente e somente você pode avaliar o risco que corre."}]', E'1', null,
                        E'[{"label":"Passos para fuga","value":"passos-para-fuga"},{"label":"Crianças, adolescentes e dependentes","value":"criancas-adolescentes-e-dependentes"},{"label":"Bens, trabalho e renda","value":"bens-trabalho-e-renda"},{"label":"Segurança pessoal","value":"seguranca-pessoal"}]', '[{"codigo":"T1"},{"codigo":"T2"},{"codigo":"T3"},{"codigo":"T4"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10003000, 'auto_change_questionnaire', 'B0_p0a', E'',
                        12, E'[]', E'B0_P0 == \'passos-para-fuga\'', null,
                        null, '[]', 13, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10004000, 'auto_change_questionnaire', 'B0_p0b', E'',
                        12, E'[]', E'B0_P0 == \'criancas-adolescentes-e-dependentes\'', null,
                        null, '[]', 14, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10005000, 'auto_change_questionnaire', 'B0_p0c', E'',
                        12, E'[]', E'B0_P0 == \'bens-trabalho-e-renda\'', null,
                        null, '[]', 15, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10006000, 'auto_change_questionnaire', 'B0_p0d', E'',
                        12, E'[]', E'B0_P0 == \'seguranca-pessoal\'', null,
                        null, '[]', 16, '[]');
DELETE FROM quiz_config WHERE questionnaire_id = 13;
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10007000, 'displaytext', 'B1_P1intro', E'Este bloco é essencial para por o seu plano de fuga em prática. As perguntas a seguir vão te ajudar a pensar em um local para se proteger e nas estratégias de deslocamento, priorizando sua proteção e bem-estar.',
                        13, E'[]', E'1', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10008000, 'yesnomaybe', 'B1_P1', E'Você tem para onde ir?',
                        13, E'[]', E'1', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10008010, 'displaytext', 'B1_P1_R9', E'Que bom que você não está sozinha! É muito importante que você consiga acesso a um lugar seguro onde possa ser acolhida e se proteger após a fuga.',
                        13, E'[]', E'B1_P1 == \'Y\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10008020, 'displaytext', 'B1_P1_R1', E'Fique calma! Há outras possibilidades. Existem casas de acolhimento e casas-abrigo para mulheres em situação de violência em alguns municípios. Também há a alternativa do recebimento do auxílio-aluguel.',
                        13, E'[]', E'B1_P1 == \'N\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10008030, 'displaytext', 'B1_P1_R10', E'Que bom que você talvez tenha algum lugar seguro para ir após a fuga, mas é importante estar certa dessa alternativa.',
                        13, E'[]', E'B1_P1 == \'M\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10009030, 'yesno', 'B1_P2', E'Deseja saber como esses serviços funcionam?',
                        13, E'[]', E'B1_P1 == \'N\'', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10009040, 'displaytext', 'B1_P2_R8', E'Tudo bem! Mas ter um lugar seguro onde você possa ser acolhida após a fuga, além de uma rede de apoio fortalecida, é muito importante. Vamos seguir construindo o seu plano!',
                        13, E'[]', E'B1_P2 == \'N\' ', null,
                        null, '[{"codigo":"T5"},{"codigo":"T6"},{"codigo":"T7"},{"codigo":"T8"},{"codigo":"T9"},{"codigo":"T10"},{"codigo":"T11"},{"codigo":"T12"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10010040, 'multiplechoices', 'B1_P3', E'Qual deles você quer conhecer?',
                        13, E'[]', E'B1_P2 == \'Y\'', null,
                        E'[{"label":"Auxílio-aluguel","value":"auxilio-aluguel"},{"label":"Casa abrigo","value":"casa-abrigo"},{"label":"Casa de acolhimento","value":"casa-de-acolhimento"}]', '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10010050, 'displaytext', 'B1_P3_R2', E'O auxílio-aluguel para mulheres em situação de violência só existe em alguns estados brasileiros. Para solicitá-lo, você precisa ter uma medida protetiva expedida e comprovar situação de vulnerabilidade econômica. Esse benefício garante às vítimas a chance de retomar a vida longe de seu agressor.',
                        13, E'[]', E'is_json_member(\'auxilio-aluguel\', B1_P3_json)', null,
                        null, '[{"codigo":"T5"},{"codigo":"T6"},{"codigo":"T7"},{"codigo":"T8"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10010060, 'displaytext', 'B1_P3_R3', E'A Casa abrigo fornece alojamento temporário e sigiloso de até 90 dias, com proteção e atendimento integral às mulheres em situação de violência com risco iminente de morte, acompanhadas ou não de seus filhos com menos de 18 anos. O objetivo é garantir a integridade física e psicológica da vítima, além de oferecer apoio para ela reestruturar sua vida. Apenas Centros de Referência de Assistência Social (CRAS) fazem o encaminhamento para esse serviço.',
                        13, E'[]', E'is_json_member(\'casa-abrigo\', B1_P3_json)', null,
                        null, '[{"codigo":"T5"},{"codigo":"T6"},{"codigo":"T7"},{"codigo":"T8"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10010070, 'displaytext', 'B1_P3_R4', E'A Casa de acolhimento é um serviço de abrigamento temporário de curta duração (até 15 dias), não-sigiloso, para mulheres em situação de violência que não correm risco iminente de morte, acompanhadas ou não de seus filhos. O abrigamento provisório deve garantir a integridade física e emocional da vítima, bem como realizar os encaminhamentos necessários.',
                        13, E'[]', E'is_json_member(\'casa-de-acolhimento\', B1_P3_json)', null,
                        null, '[{"codigo":"T5"},{"codigo":"T6"},{"codigo":"T7"},{"codigo":"T8"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10011070, 'yesno', 'B1_P4', E'Quer saber se em seu estado/cidade há alguns desses serviços?',
                        13, E'[]', E'is_json_member(\'auxilio-aluguel\', B1_P3_json) || is_json_member(\'casa-abrigo\', B1_P3_json) || is_json_member(\'casa-de-acolhimento\', B1_P3_json)', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10011080, 'displaytext', 'B1_P4_R5', E'Após finalizar o preenchimento dos blocos de perguntas, acesse o mapa de pontos de apoio ou fale com nossa equipe através do Suporte PenhaS para ter informações sobre os serviços mais próximos a você.',
                        13, E'[]', E'B1_P4 == \'Y\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10011090, 'displaytext', 'B1_P4_R6', E'Sabemos que é um momento extremamente delicado e que envolve muita coisa, mas lembre-se: estamos nessa luta juntas para que você tenha o direito de viver livre de violência! Continue firme!',
                        13, E'[]', E'B1_P4 == \'Y\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10011100, 'displaytext', 'B1_P4_R7', E'Estamos chegando ao final do bloco "Passos para a fuga". Obrigada por responder até aqui. O PenhaS quer te ajudar a sair de casa e a romper com o ciclo de violência, organizando os itens mais importantes para uma saída mais segura. Recomendamos que você refaça esse bloco quando decidir para onde vai fugir.',
                        13, E'[]', E'B1_P4 == \'Y\' ', null,
                        null, '[{"codigo":"T9"},{"codigo":"T10"},{"codigo":"T11"},{"codigo":"T12"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10011105, 'tag_user', 'B1_P4_tags', E'',
                        13, E'[]', E'B1_P4 == \'Y\' ', null,
                        null, '[]', null, '[{"codigo":"T1"}]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10011110, 'displaytext', 'B1_P4_R6', E'Sabemos que é um momento extremamente delicado e que envolve muita coisa, mas lembre-se: estamos nessa luta juntas para que você tenha o direito de viver livre de violência! Continue firme!',
                        13, E'[]', E'B1_P4 == \'N\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10011120, 'displaytext', 'B1_P4_R7', E'Estamos chegando ao final do bloco "Passos para a fuga". Obrigada por responder até aqui. O PenhaS quer te ajudar a sair de casa e a romper com o ciclo de violência, organizando os itens mais importantes para uma saída mais segura. Recomendamos que você refaça esse bloco quando decidir para onde vai fugir.',
                        13, E'[]', E'B1_P4 == \'N\' ', null,
                        null, '[{"codigo":"T9"},{"codigo":"T10"},{"codigo":"T11"},{"codigo":"T12"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10012120, 'next_mf_questionnaire_outstanding', 'B1_P4ac', E'',
                        13, E'[]', E'B1_P2 == \'N\' || B1_P4 == \'Y\' || B1_P4 == \'N\'', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10013120, 'onlychoice', 'B1_P5', E'Que lugar é esse?',
                        13, E'[]', E'B1_P1 == \'Y\'', null,
                        E'[{"label":"Casa de uma amiga ou vizinha","value":"casa-de-uma-amiga-ou-vizinha"},{"label":"Casa de um familiar","value":"casa-de-um-familiar"},{"label":"Casa-abrigo ou casa de Acolhimento","value":"casa-abrigo-ou-casa-de-acolhimento"},{"label":"Uma nova casa Alugada","value":"uma-nova-casa-alugada"}]', '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10013130, 'displaytext', 'B1_P5_R11', E'Que bom que você tem com quem contar. Isso ajuda muito! Lembre-se que é importante evitar lugares muito óbvios e cumprir as medidas de segurança necessárias, para que nem você, nem a pessoa que te acolheu fiquem em risco.',
                        13, E'[]', E'B1_P5 == \'casa-de-uma-amiga-ou-vizinha\' ', null,
                        null, '[{"codigo":"T9"},{"codigo":"T10"},{"codigo":"T11"},{"codigo":"T12"},{"codigo":"T13"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10013140, 'displaytext', 'B1_P5_R11', E'Que bom que você tem com quem contar. Isso ajuda muito! Lembre-se que é importante evitar lugares muito óbvios e cumprir as medidas de segurança necessárias, para que nem você, nem a pessoa que te acolheu fiquem em risco.',
                        13, E'[]', E'B1_P5 == \'casa-de-um-familiar\' ', null,
                        null, '[{"codigo":"T9"},{"codigo":"T10"},{"codigo":"T11"},{"codigo":"T12"},{"codigo":"T13"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10013150, 'displaytext', 'B1_P5_R12', E'Se você imagina que esses serviços podem te acolher, precisa saber a diferença entre os dois. A casa de acolhimento é um serviço temporário de curta duração (até 15 dias), de caráter não-sigiloso, que visa proteger a integridade física e emocional da mulher. Já a casa-abrigo é um local sigiloso, voltado para proteger a mulher que está em risco de morte iminente e que pode permanecer no local por até 90 dias.',
                        13, E'[]', E'B1_P5 == \'casa-abrigo-ou-casa-de-acolhimento\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10013160, 'displaytext', 'B1_P5_R13', E'O encaminhamento para os dois precisa ser feito pelo Centro de Referência de Assistência Social (CRAS). Tanto a casa de acolhimento quanto a casa-abrigo recebem crianças, mas cada um segue condições específicas.',
                        13, E'[]', E'B1_P5 == \'casa-abrigo-ou-casa-de-acolhimento\' ', null,
                        null, '[{"codigo":"T5"},{"codigo":"T6"},{"codigo":"T7"},{"codigo":"T8"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10013170, 'displaytext', 'B1_P5_R16', E'Lembre-se: Não vá para lugares onde o agressor possa te encontrar facilmente. Só comente onde estará com pessoas de extrema confiança para preservar a sua segurança. Assim que estiver segura, vá à delegacia, ao CRAS ou outro serviço especializado de atendimento mulheres vítimas de violência. Em nosso mapa, aqui no app, você pode acessar os equipamentos da rede mais próximos a você.',
                        13, E'[]', E'B1_P5 == \'casa-abrigo-ou-casa-de-acolhimento\' ', null,
                        null, '[{"codigo":"T9"},{"codigo":"T10"},{"codigo":"T11"},{"codigo":"T12"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10013180, 'displaytext', 'B1_P5_R14', E'Acredito que se você pensa nessa possibilidade, tem se organizado financeiramente para esse passo. Caso você precise, em alguns estados brasileiros mulheres em situação de violência tem direito a um auxílio-aluguel.',
                        13, E'[]', E'B1_P5 == \'uma-nova-casa-alugada\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10013190, 'displaytext', 'B1_P5_R15', E'Para solicitá-lo, você deve ter uma medida protetiva expedida e comprovar situação de vulnerabilidade econômica. Vamos adicionar alguns itens à sua lista, caso você queira checar se essa é uma possibilidade para você. Tudo bem?',
                        13, E'[]', E'B1_P5 == \'uma-nova-casa-alugada\' ', null,
                        null, '[{"codigo":"T5"},{"codigo":"T6"},{"codigo":"T7"},{"codigo":"T8"},{"codigo":"T14"},{"codigo":"T15"},{"codigo":"T16"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10013200, 'displaytext', 'B1_P5_R16', E'Lembre-se: Não vá para lugares onde o agressor possa te encontrar facilmente. Só comente onde estará com pessoas de extrema confiança para preservar a sua segurança. Assim que estiver segura, vá à delegacia, ao CRAS ou outro serviço especializado de atendimento mulheres vítimas de violência. Em nosso mapa, aqui no app, você pode acessar os equipamentos da rede mais próximos a você.',
                        13, E'[]', E'B1_P5 == \'uma-nova-casa-alugada\' ', null,
                        null, '[{"codigo":"T9"},{"codigo":"T10"},{"codigo":"T11"},{"codigo":"T12"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10014200, 'onlychoice', 'B1_P6', E'Que lugar você imagina que possa lhe acolher?',
                        13, E'[]', E'B1_P1 == \'M\'', null,
                        E'[{"label":"Casa de uma amiga ou vizinha","value":"casa-de-uma-amiga-ou-vizinha"},{"label":"Casa de um familiar","value":"casa-de-um-familiar"},{"label":"Casa-abrigo ou casa de Acolhimento","value":"casa-abrigo-ou-casa-de-acolhimento"},{"label":"Uma nova casa Alugada","value":"uma-nova-casa-alugada"}]', '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10014210, 'displaytext', 'B1_P6_R11', E'Que bom que você tem com quem contar. Isso ajuda muito! Lembre-se que é importante evitar lugares muito óbvios e cumprir as medidas de segurança necessárias, para que nem você, nem a pessoa que te acolheu fiquem em risco.',
                        13, E'[]', E'B1_P6 == \'casa-de-uma-amiga-ou-vizinha\' ', null,
                        null, '[{"codigo":"T9"},{"codigo":"T10"},{"codigo":"T11"},{"codigo":"T12"},{"codigo":"T13"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10014220, 'displaytext', 'B1_P6_R11', E'Que bom que você tem com quem contar. Isso ajuda muito! Lembre-se que é importante evitar lugares muito óbvios e cumprir as medidas de segurança necessárias, para que nem você, nem a pessoa que te acolheu fiquem em risco.',
                        13, E'[]', E'B1_P6 == \'casa-de-um-familiar\' ', null,
                        null, '[{"codigo":"T9"},{"codigo":"T10"},{"codigo":"T11"},{"codigo":"T12"},{"codigo":"T13"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10014230, 'displaytext', 'B1_P6_R12', E'Se você imagina que esses serviços podem te acolher, precisa saber a diferença entre os dois. A casa de acolhimento é um serviço temporário de curta duração (até 15 dias), de caráter não-sigiloso, que visa proteger a integridade física e emocional da mulher. Já a casa-abrigo é um local sigiloso, voltado para proteger a mulher que está em risco de morte iminente e que pode permanecer no local por até 90 dias.',
                        13, E'[]', E'B1_P6 == \'casa-abrigo-ou-casa-de-acolhimento\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10014240, 'displaytext', 'B1_P6_R13', E'O encaminhamento para os dois precisa ser feito pelo Centro de Referência de Assistência Social (CRAS). Tanto a casa de acolhimento quanto a casa-abrigo recebem crianças, mas cada um segue condições específicas.',
                        13, E'[]', E'B1_P6 == \'casa-abrigo-ou-casa-de-acolhimento\' ', null,
                        null, '[{"codigo":"T5"},{"codigo":"T6"},{"codigo":"T7"},{"codigo":"T8"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10014250, 'displaytext', 'B1_P6_R16', E'Lembre-se: Não vá para lugares onde o agressor possa te encontrar facilmente. Só comente onde estará com pessoas de extrema confiança para preservar a sua segurança. Assim que estiver segura, vá à delegacia, ao CRAS ou outro serviço especializado de atendimento mulheres vítimas de violência. Em nosso mapa, aqui no app, você pode acessar os equipamentos da rede mais próximos a você.',
                        13, E'[]', E'B1_P6 == \'casa-abrigo-ou-casa-de-acolhimento\' ', null,
                        null, '[{"codigo":"T9"},{"codigo":"T10"},{"codigo":"T11"},{"codigo":"T12"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10014260, 'displaytext', 'B1_P6_R14', E'Acredito que se você pensa nessa possibilidade, tem se organizado financeiramente para esse passo. Caso você precise, em alguns estados brasileiros mulheres em situação de violência tem direito a um auxílio-aluguel.',
                        13, E'[]', E'B1_P6 == \'uma-nova-casa-alugada\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10014270, 'displaytext', 'B1_P6_R15', E'Para solicitá-lo, você deve ter uma medida protetiva expedida e comprovar situação de vulnerabilidade econômica. Vamos adicionar alguns itens à sua lista, caso você queira checar se essa é uma possibilidade para você. Tudo bem?',
                        13, E'[]', E'B1_P6 == \'uma-nova-casa-alugada\' ', null,
                        null, '[{"codigo":"T5"},{"codigo":"T6"},{"codigo":"T7"},{"codigo":"T8"},{"codigo":"T14"},{"codigo":"T15"},{"codigo":"T16"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10014280, 'displaytext', 'B1_P6_R16', E'Lembre-se: Não vá para lugares onde o agressor possa te encontrar facilmente. Só comente onde estará com pessoas de extrema confiança para preservar a sua segurança. Assim que estiver segura, vá à delegacia, ao CRAS ou outro serviço especializado de atendimento mulheres vítimas de violência. Em nosso mapa, aqui no app, você pode acessar os equipamentos da rede mais próximos a você.',
                        13, E'[]', E'B1_P6 == \'uma-nova-casa-alugada\' ', null,
                        null, '[{"codigo":"T9"},{"codigo":"T10"},{"codigo":"T11"},{"codigo":"T12"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10015280, 'yesnomaybe', 'B1_P7', E'Você acredita que seu agressor suspeita do seu plano de fuga?',
                        13, E'[]', E'B1_P5 == \'casa-de-uma-amiga-ou-vizinha\' || B1_P5 == \'casa-de-um-familiar\' || B1_P5 == \'casa-abrigo-ou-casa-de-acolhimento\' || B1_P5 == \'uma-nova-casa-alugada\' || B1_P6 == \'casa-de-uma-amiga-ou-vizinha\' || B1_P6 == \'casa-de-um-familiar\' || B1_P6 == \'casa-abrigo-ou-casa-de-acolhimento\' || B1_P6 == \'uma-nova-casa-alugada\'', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10015290, 'displaytext', 'B1_P7_R18', E'Isso é um sinal de que precisamos redobrar os cuidados! Continue a sua rotina normal para evitar mais desconfianças.',
                        13, E'[]', E'B1_P7 == \'Y\' ', null,
                        null, '[{"codigo":"T17"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10015300, 'displaytext', 'B1_P7_R17', E'Ótimo, mantenha a calma! Sabemos que é um momento extremamente delicado, e que envolve muita coisa. Mas lembre-se: estamos nessa luta juntas para você ter o direito de viver livre de violência! Continue firme!',
                        13, E'[]', E'B1_P7 == \'N\' ', null,
                        null, '[{"codigo":"T17"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10015310, 'displaytext', 'B1_P7_R18', E'Isso é um sinal de que precisamos redobrar os cuidados! Continue a sua rotina normal para evitar mais desconfianças.',
                        13, E'[]', E'B1_P7 == \'M\' ', null,
                        null, '[{"codigo":"T17"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10016310, 'yesno', 'B1_P8', E'Você tem a possibilidade de sair de casa por algumas horas sem gerar desconfiança?',
                        13, E'[]', E'B1_P7 == \'Y\' || B1_P7 == \'N\' || B1_P7 == \'M\'', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10017310, 'auto_change_questionnaire', 'B1_P8ac', E'',
                        13, E'[]', E'B1_P8 == \'Y\' || B1_P8 == \'N\'', null,
                        null, '[]', 17, '[]');
DELETE FROM quiz_config WHERE questionnaire_id = 14;
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10023380, 'displaytext', 'B2_P10intro', E'Neste bloco, vamos tratar sobre crianças, adolescentes e outras pessoas que dependam de seus cuidados. O foco é garantir que essas pessoas estejam protegidas e possam lhe ajudar quando possível. Crianças e adolescentes não devem se sentir responsáveis por garantir sua proteção. As perguntas e orientações desse bloco são importantes para criar um ambiente seguro e garantir direitos.',
                        14, E'[]', E'1', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10024380, 'yesno', 'B2_P10', E'Deseja responder esse bloco?',
                        14, E'[]', E'1', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10024381, 'next_mf_questionnaire', 'B2_P10_PQ_N', E' ',
                        14, E'[]', E'B2_P10 == \'N\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10025380, 'yesno', 'B2_P11', E'Há criança e/ou adolescente no ambiente doméstico?',
                        14, E'[]', E'B2_P10 == \'Y\'', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10025390, 'displaytext', 'B2_P11_R29', E'Vamos juntas encontrar uma maneira de deixá-los em segurança. Tenha em mente: mesmo que eles não sejam alvo direto das ameaças ou das agressões físicas, um ambiente doméstico violento é prejudicial a todos.',
                        14, E'[]', E'B2_P11 == \'Y\' ', null,
                        null, '[{"codigo":"T12"},{"codigo":"T49"},{"codigo":"T50"},{"codigo":"T51"},{"codigo":"T52"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10025400, 'displaytext', 'B2_P11_R30', E'Está bem. Sendo assim, vamos dar continuidade ao seu plano de fuga.',
                        14, E'[]', E'B2_P11 == \'N\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10026400, 'onlychoice', 'B2_P12', E'Quem é a criança e/ou adolescente?',
                        14, E'[]', E'B2_P11 == \'Y\'', null,
                        E'[{"label":"Meu filho ou filha","value":"meu-filho-ou-filha"},{"label":"Meu enteado ou enteada","value":"meu-enteado-ou-enteada"},{"label":"Outras relações","value":"outras-relacoes"}]', '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10026410, 'displaytext', 'B2_P12_R31', E'Acolha, proteja e converse o máximo possível, de acordo com suas possibilidades. Se esse agressor é o pai, a depender da idade, essa criança e/ou adolescente pode estar em intenso conflito emocional.',
                        14, E'[]', E'B2_P12 == \'meu-filho-ou-filha\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10026420, 'displaytext', 'B2_P12_R32', E'Sabemos que sua intenção é garantir seu próprio bem-estar e segurança, mas também de seu filho(a) . Para garantir que seus passos a partir de agora não sejam compreendidos como alienação parental, ao sair de casa, denuncie o agressor e faça um boletim de ocorrência, frisando o risco que a criança/adolescente também está correndo. Infelizmente, nosso sistema judiciário ainda é muito machista e misógino, por isso, você deve se resguardar ao máximo.',
                        14, E'[]', E'B2_P12 == \'meu-filho-ou-filha\' ', null,
                        null, '[{"codigo":"T5"},{"codigo":"T6"},{"codigo":"T9"},{"codigo":"T10"},{"codigo":"T11"},{"codigo":"T53"},{"codigo":"T54"},{"codigo":"T55"},{"codigo":"T56"},{"codigo":"T57"},{"codigo":"T58"},{"codigo":"T59"},{"codigo":"T60"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10026430, 'displaytext', 'B2_P12_R33', E'É provável que você já tenha construído uma relação de afeto com essa criança e/ou adolescente. Acolha, proteja e converse o máximo possível, de acordo com suas possibilidades.',
                        14, E'[]', E'B2_P12 == \'meu-enteado-ou-enteada\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10026440, 'displaytext', 'B2_P12_R34', E'Se tiver oportunidade, busque contato com outros familiares, que possam proteger ou acolher temporariamente essa criança/adolescente. Se possível, mantenha com você os documentos da criança e/ou adolescente.',
                        14, E'[]', E'B2_P12 == \'meu-enteado-ou-enteada\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10026450, 'displaytext', 'B2_P12_R35', E'Ao sair de casa, denuncie o agressor e faça um boletim de ocorrência frisando o risco que a criança e/ou o adolescente está correndo. Infelizmente, nosso sistema judiciário ainda é muito machista e misógino, por isso, você deve se resguardar ao máximo.',
                        14, E'[]', E'B2_P12 == \'meu-enteado-ou-enteada\' ', null,
                        null, '[{"codigo":"T53"},{"codigo":"T55"},{"codigo":"T61"},{"codigo":"T62"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10026460, 'displaytext', 'B2_P12_R36', E'Acolha, proteja e converse o máximo possível, de acordo com suas possibilidades. Busque o Conselho Tutelar da sua cidade para conhecer as maneiras de ajudar essa criança e/ou adolescente sem se expor ainda mais à violência.',
                        14, E'[]', E'B2_P12 == \'outras-relacoes\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10026470, 'displaytext', 'B2_P12_R37', E'Saiba, desde já, que é possível fazer denúncia anônima. Se tiver oportunidade, busque contato com outros familiares, que possam proteger ou acolher temporariamente essa criança/adolescente. Se possível, mantenha com você os documentos dele(a).',
                        14, E'[]', E'B2_P12 == \'outras-relacoes\' ', null,
                        null, '[{"codigo":"T53"},{"codigo":"T55"},{"codigo":"T61"},{"codigo":"T62"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10027470, 'yesnomaybe', 'B2_P13', E'Você pretende incluir essa criança e/ou adolescente em seu plano de fuga?',
                        14, E'[]', E'B2_P12 == \'meu-filho-ou-filha\' || B2_P12 == \'meu-enteado-ou-enteada\' || B2_P12 == \'outras-relacoes\'', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10027480, 'displaytext', 'B2_P13_R38', E'Entendo sua decisão! Esse é um momento bastante delicado e você talvez seja a única fonte de segurança dessa criança e/ou adolescente. Sigamos juntas!',
                        14, E'[]', E'B2_P13 == \'Y\' ', null,
                        null, '[{"codigo":"T63"},{"codigo":"T64"},{"codigo":"T65"},{"codigo":"T66"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10027485, 'tag_user', 'B2_P13_tags', E'',
                        14, E'[]', E'B2_P13 == \'Y\' ', null,
                        null, '[]', null, '[{"codigo":"T3"}]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10027490, 'displaytext', 'B2_P13_R39', E'É preciso muita cautela. Sair do ambiente violento e se fortalecer pode ser o primeiro passo para, mais tarde, também proporcionar segurança a quem depende de você. Siga com seu plano.',
                        14, E'[]', E'B2_P13 == \'N\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10027500, 'displaytext', 'B2_P13_R40', E'Não se sinta culpada em deixar a criança e/ou adolescente. Você está fazendo o possível e isso é proteção. Você tem sido muito forte!',
                        14, E'[]', E'B2_P13 == \'N\' ', null,
                        null, '[{"codigo":"T63"},{"codigo":"T67"},{"codigo":"T68"},{"codigo":"T69"},{"codigo":"T70"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10027505, 'tag_user', 'B2_P13_tags', E'',
                        14, E'[]', E'B2_P13 == \'N\' ', null,
                        null, '[]', null, '[{"codigo":"T4"}]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10027510, 'displaytext', 'B2_P13_R41', E'Tudo bem, esse é um momento delicado. Continue com seu plano. Estamos à disposição para conversar sobre esse assunto a qualquer momento por meio do nosso suporte. Retorne quando se sentir mais segura.',
                        14, E'[]', E'B2_P13 == \'M\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10027515, 'tag_user', 'B2_P13_tags', E'',
                        14, E'[]', E'B2_P13 == \'M\' ', null,
                        null, '[]', null, '[{"codigo":"T2"}]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10028510, 'yesno', 'B2_P14', E'A criança e/ou adolescente sabe da sua intenção de fuga?',
                        14, E'[]', E'B2_P13 == \'Y\' || B2_P13 == \'N\' || B2_P13 == \'M\'', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10028520, 'displaytext', 'B2_P14_R42', E'A depender da idade e da linguagem, a criança e/ou adolescente é capaz de compreender a saída do ambiente familiar. Dialogue sempre que possível, e tenha cautela para não colocar o plano em risco. Crianças e/ou adolescentes são mais vulneráveis a pressões e ameaças.',
                        14, E'[]', E'B2_P14 == \'Y\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10028530, 'displaytext', 'B2_P14_R44', E'Só compartilhe o plano quando tiver certeza dele. A sensação de segurança nas crianças e/ou adolescentes depende de previsibilidade.',
                        14, E'[]', E'B2_P14 == \'Y\' ', null,
                        null, '[{"codigo":"T71"},{"codigo":"T72"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10028540, 'displaytext', 'B2_P14_R45', E'A sensação de segurança nas crianças e/ou adolescentes depende de previsibilidade. Recomendamos que compartilhe o plano no momento em que você tiver segurança quanto à sua concretização.',
                        14, E'[]', E'B2_P14 == \'N\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10028550, 'displaytext', 'B2_P14_R46', E'Dialogue sempre que possível e, com muito cuidado, ajuste as fantasias e expectativas da criança e/ou adolescente à realidade. Quando se sentir segura para compartilhar, busque adaptar a linguagem à idade.',
                        14, E'[]', E'B2_P14 == \'N\' ', null,
                        null, '[{"codigo":"T71"},{"codigo":"T72"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10029550, 'yesno', 'B2_P15', E'A criança e/ou adolescente possui alguma condição especial de saúde, limitação física e/ou intelectual?',
                        14, E'[]', E'B2_P14 == \'Y\' || B2_P14 == \'N\'', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10029560, 'displaytext', 'B2_P15_R47', E'Neste caso, além da preparação de documentos, é importante ficar atenta à rotina de remédios, atendimentos médicos e tudo o que for necessário para a convivência com a condição. Vamos incluir itens relativos a isso em seu plano de fuga.',
                        14, E'[]', E'B2_P15 == \'Y\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10029570, 'displaytext', 'B2_P15_R48', E'Além disso, a depender da situação, você pode necessitar de mais ajuda antes, durante e depois da fuga. Avalie quem pode lhe acompanhar ao longo deste processo.',
                        14, E'[]', E'B2_P15 == \'Y\' ', null,
                        null, '[{"codigo":"T73"},{"codigo":"T74"},{"codigo":"T75"},{"codigo":"T76"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10029580, 'displaytext', 'B2_P15_R49', E'Muito bem. Já estamos finalizando este bloco. Siga com o plano.',
                        14, E'[]', E'B2_P15 == \'N\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10030580, 'yesno', 'B2_P16', E'Há outro adulto e/ou idoso submetido a alguma forma de violência?',
                        14, E'[]', E'B2_P11 == \'N\' || B2_P15 == \'Y\' || B2_P15 == \'N\'', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10030590, 'displaytext', 'B2_P16_R50', E'Este é um plano de fuga individual, focado em sua própria segurança. Certifique-se se é seguro dividir estratégias ou mesmo incluir mais alguém nele.',
                        14, E'[]', E'B2_P16 == \'Y\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10030600, 'displaytext', 'B2_P16_R51', E'Se achar necessário, converse com essa pessoa e compartilhe os itens do seu plano. Se essa pessoa for uma mulher, sugira também que ela baixe o aplicativo PenhaS para criar um plano de fuga personalizado e receber orientação especializada da nossa equipe.',
                        14, E'[]', E'B2_P16 == \'Y\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10030610, 'displaytext', 'B2_P16_R52', E'Compartilhe informações sobre como denunciar, solicitar medida protetiva e onde encontrar orientações que possam ajudar a romper o ciclo de violência. Ela também pode criar o próprio plano de fuga aqui no PenhaS.',
                        14, E'[]', E'B2_P16 == \'Y\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10030620, 'displaytext', 'B2_P16_R53', E'Você acabou de finalizar este bloco. Parabéns! Obrigada por ter respondido até aqui. Você é forte e corajosa! O PenhaS quer te ajudar a romper com o ciclo de violência. Certifique-se de todos os itens que aparecerão no seu plano. Eles são personalizados a partir de suas respostas, por isso é tão importante que você responda a todos os blocos.',
                        14, E'[]', E'B2_P16 == \'N\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10030621, 'next_mf_questionnaire', 'B2_P16_PQ_N', E' ',
                        14, E'[]', E'B2_P16 == \'N\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10031620, 'yesno', 'B2_P17', E'A pessoa reconhece que também é vítima de violência?',
                        14, E'[]', E'B2_P16 == \'Y\'', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10031630, 'displaytext', 'B2_P17_R54', E'Se estiver diante de outras mulheres vítimas de violência, oriente-as a buscarem uma medida protetiva contra o agressor, assim como cadastrar-se ou atualizar o Cadastro Único (CadÚnico) e levar ao CRAS toda documentação necessária, dela e de filhos, se houver.',
                        14, E'[]', E'B2_P17 == \'Y\' ', null,
                        null, '[{"codigo":"T77"},{"codigo":"T78"},{"codigo":"T79"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10031640, 'displaytext', 'B2_P17_R55', E'É difícil se perceber vítima de uma situação de violência. Muita gente acredita que violência é apenas abuso físico. Quando esse sinal não está presente, as vítimas tendem a minimizar o risco. Além disso, há o medo e a vergonha. Por isso, esteja por perto, acolhendo e informando essa pessoa. Só tome a iniciativa de denunciar sem o consentimento dela se perceber que há risco à vida.',
                        14, E'[]', E'B2_P17 == \'N\' ', null,
                        null, '[{"codigo":"T77"},{"codigo":"T78"},{"codigo":"T79"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10032640, 'yesno', 'B2_P18', E'A pessoa tem condições físicas, psíquicas e/ou emocionais para buscar ajuda?',
                        14, E'[]', E'B2_P17 == \'Y\' || B2_P17 == \'N\'', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10032650, 'displaytext', 'B2_P18_R56', E'Sabemos que reconhecer a violência é apenas o primeiro passo. Sempre que possível, compartilhe informações úteis e incentive outras vítimas a romperem o ciclo de violência.',
                        14, E'[]', E'B2_P18 == \'Y\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10032660, 'displaytext', 'B2_P18_R57', E'É dever de todos, especialmente das pessoas mais próximas, denunciar o caso à polícia, ao Ministério Público, à Justiça ou outro órgão de proteção. Lembre-se que a denúncia pode ser feita de forma anônima.',
                        14, E'[]', E'B2_P18 == \'Y\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10032670, 'displaytext', 'B2_P18_R59', E'Você acabou de finalizar este bloco. Parabéns! Obrigada por ter respondido até aqui. Você é forte e corajosa! O PenhaS quer te ajudar a romper com o ciclo de violência. Certifique-se de todos os itens que aparecerão no seu plano. Eles são personalizados a partir de suas respostas, por isso é tão importante que você responda a todos os blocos.',
                        14, E'[]', E'B2_P18 == \'Y\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10032671, 'next_mf_questionnaire', 'B2_P18_PQ_Y', E' ',
                        14, E'[]', E'B2_P18 == \'Y\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10032680, 'displaytext', 'B2_P18_R57', E'É dever de todos, especialmente das pessoas mais próximas, denunciar o caso à polícia, ao Ministério Público, à Justiça ou outro órgão de proteção. Lembre-se que a denúncia pode ser feita de forma anônima.',
                        14, E'[]', E'B2_P18 == \'N\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10032690, 'displaytext', 'B2_P18_R58', E'Sempre que possível, compartilhe informações úteis e incentive outras vítimas a romperem o ciclo de violência.',
                        14, E'[]', E'B2_P18 == \'N\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10032700, 'displaytext', 'B2_P18_R59', E'Você acabou de finalizar este bloco. Parabéns! Obrigada por ter respondido até aqui. Você é forte e corajosa! O PenhaS quer te ajudar a romper com o ciclo de violência. Certifique-se de todos os itens que aparecerão no seu plano. Eles são personalizados a partir de suas respostas, por isso é tão importante que você responda a todos os blocos.',
                        14, E'[]', E'B2_P18 == \'N\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10032701, 'next_mf_questionnaire', 'B2_P18_PQ_N', E' ',
                        14, E'[]', E'B2_P18 == \'N\' ', null,
                        null, '[]', null, '[]');
DELETE FROM quiz_config WHERE questionnaire_id = 15;
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10033700, 'displaytext', 'B3_P19intro', E'Chegamos ao bloco sobre bens e renda, assunto que costuma gerar angústias e muitas dúvidas. Saiba que, independente de quem seja o agressor (companheiro, pai, irmão, sócio), há meios de garantir a efetivação dos seus direitos patrimoniais. Ao responder esse bloco, acrescentaremos à sua lista final instruções fundamentais para o processo de partilha e preservação da sua renda. Vamos juntas?',
                        15, E'[]', E'1', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10034700, 'onlychoice', 'B3_P19', E'Você possui renda?',
                        15, E'[]', E'1', null,
                        E'[{"label":"Trabalho e tenho liberdade com o meu dinheiro.","value":"trabalho-e-tenho-liberdade-com-o-meu-dinheiro"},{"label":"Não trabalho, mas recebo benefício/ pensão.","value":"nao-trabalho-mas-recebo-beneficio-ou--pensao"},{"label":"Dependo financeiramente/ ele controla meu dinheiro.","value":"dependo-financeiramente-ou--ele-controla-meu-dinheiro"}]', '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10034710, 'displaytext', 'B3_P19_R60', E'Que ótimo que você tem autonomia financeira! Isso é fundamental para interromper o ciclo de violência. Após você responder aos blocos, incluiremos em sua lista de tarefas orientações valiosas para auxiliar no planejamento de uma fuga segura, às quais você terá acesso.',
                        15, E'[]', E'B3_P19 == \'trabalho-e-tenho-liberdade-com-o-meu-dinheiro\' ', null,
                        null, '[{"codigo":"T7"},{"codigo":"T8"},{"codigo":"T18"},{"codigo":"T29"},{"codigo":"T80"},{"codigo":"T81"},{"codigo":"T82"},{"codigo":"T83"},{"codigo":"T84"},{"codigo":"T85"},{"codigo":"T86"},{"codigo":"T87"},{"codigo":"T88"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10034720, 'displaytext', 'B3_P19_R61', E'Que bom! Ter autonomia financeira é um ponto importante na quebra do ciclo de violência. Saiba que é um direito seu ter esse acesso ao auxílio.',
                        15, E'[]', E'B3_P19 == \'nao-trabalho-mas-recebo-beneficio-ou--pensao\' ', null,
                        null, '[{"codigo":"T4"},{"codigo":"T6"},{"codigo":"T7"},{"codigo":"T8"},{"codigo":"T29"},{"codigo":"T30"},{"codigo":"T81"},{"codigo":"T89"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10034725, 'tag_user', 'B3_P19_tags', E'',
                        15, E'[]', E'B3_P19 == \'nao-trabalho-mas-recebo-beneficio-ou--pensao\' ', null,
                        null, '[]', null, '[{"codigo":"T5"}]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10034730, 'displaytext', 'B3_P19_R62', E'Tudo bem, respire fundo! Há chance de inclusão em programas de transferência de renda, benefícios socioassistenciais, entre outros. Vamos juntas buscar mecanismos para isso.',
                        15, E'[]', E'B3_P19 == \'dependo-financeiramente-ou--ele-controla-meu-dinheiro\' ', null,
                        null, '[{"codigo":"T7"},{"codigo":"T8"},{"codigo":"T29"},{"codigo":"T30"},{"codigo":"T81"},{"codigo":"T82"},{"codigo":"T83"},{"codigo":"T86"},{"codigo":"T90"},{"codigo":"T91"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10034735, 'tag_user', 'B3_P19_tags', E'',
                        15, E'[]', E'B3_P19 == \'dependo-financeiramente-ou--ele-controla-meu-dinheiro\' ', null,
                        null, '[]', null, '[{"codigo":"T6"}]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035730, 'onlychoice', 'B3_P20', E'O imóvel que você mora é próprio ou alugado?',
                        15, E'[]', E'B3_P19 == \'trabalho-e-tenho-liberdade-com-o-meu-dinheiro\' || B3_P19 == \'nao-trabalho-mas-recebo-beneficio-ou--pensao\' || B3_P19 == \'dependo-financeiramente-ou--ele-controla-meu-dinheiro\'', null,
                        E'[{"label":"O imóvel é meu","value":"o-imovel-e-meu"},{"label":"O imóvel é próprio/alugado em nome do agressor","value":"o-imovel-e-proprio-ou-alugado-em-nome-do-agressor"},{"label":"O imóvel é alugado no meu nome","value":"o-imovel-e-alugado-no-meu-nome"},{"label":"O imóvel é financiado no nome dos dois","value":"o-imovel-e-financiado-no-nome-dos-dois"},{"label":"Construímos um imóvel no terreno da família","value":"construimos-um-imovel-no-terreno-da-familia"}]', '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035740, 'displaytext', 'B3_P20_R63', E'Neste caso, você pode procurar uma delegacia, de preferência especializada no atendimento às mulheres, e solicitar uma medida protetiva para que o agressor seja afastado do ambiente doméstico e de você.',
                        15, E'[]', E'B3_P20 == \'o-imovel-e-meu\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035750, 'displaytext', 'B3_P20_R64', E'Se julgar que sua saída é a única chance de romper o ciclo de violência, siga com o plano. Não é abandono de lar querer sobreviver.',
                        15, E'[]', E'B3_P20 == \'o-imovel-e-meu\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035760, 'displaytext', 'B3_P20_R65', E'Deixar o lar não invalida seus direitos patrimoniais ou à guarda de filhos, caso os tenha.',
                        15, E'[]', E'B3_P20 == \'o-imovel-e-meu\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035770, 'displaytext', 'B3_P20_R66', E'Por isso, iremos acrescentar em seu plano algumas orientações pra que, após a fuga, você possa entrar com uma ação judicial sobre seu patrimônio.',
                        15, E'[]', E'B3_P20 == \'o-imovel-e-meu\' ', null,
                        null, '[{"codigo":"T92"},{"codigo":"T93"},{"codigo":"T94"},{"codigo":"T95"},{"codigo":"T96"},{"codigo":"T97"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035780, 'displaytext', 'B3_P20_R76', E'Estamos finalizando o bloco "Bens, trabalho e renda". Obrigada por ter respondido até aqui. Certifique-se de todos os itens que aparecerão no seu plano. Eles são personalizados a partir de suas respostas, por isso é tão importante que você siga completando todos os blocos.',
                        15, E'[]', E'B3_P20 == \'o-imovel-e-meu\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035781, 'next_mf_questionnaire', 'B3_P20_PQ_O_IMOVEL_E_MEU', E' ',
                        15, E'[]', E'B3_P20 == \'o-imovel-e-meu\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035790, 'displaytext', 'B3_P20_R67', E'Neste caso, você pode procurar uma delegacia, de preferência especializada no atendimento às mulheres, e solicitar uma medida protetiva para que o agressor seja afastado do ambiente doméstico e de você.',
                        15, E'[]', E'B3_P20 == \'o-imovel-e-proprio-ou-alugado-em-nome-do-agressor\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035800, 'displaytext', 'B3_P20_R68', E'Ao permanecer no imóvel que tem contrato em nome do agressor, você será dispensada de pagar aluguel se comprovar a situação de violência. O Judiciário entende que você precisa restabelecer sua integridade física, financeira e mental.',
                        15, E'[]', E'B3_P20 == \'o-imovel-e-proprio-ou-alugado-em-nome-do-agressor\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035810, 'displaytext', 'B3_P20_R69', E'Se julgar que sua saída é a única chance de romper o ciclo de violência, siga com o plano. Não é abandono de lar querer sobreviver.',
                        15, E'[]', E'B3_P20 == \'o-imovel-e-proprio-ou-alugado-em-nome-do-agressor\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035820, 'displaytext', 'B3_P20_R70', E'Deixar o lar não invalida a sua participação em possíveis divisões de bens ou no direito à guarda de filhos, caso os tenha.',
                        15, E'[]', E'B3_P20 == \'o-imovel-e-proprio-ou-alugado-em-nome-do-agressor\' ', null,
                        null, '[{"codigo":"T92"},{"codigo":"T96"},{"codigo":"T97"},{"codigo":"T98"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035830, 'displaytext', 'B3_P20_R76', E'Estamos finalizando o bloco "Bens, trabalho e renda". Obrigada por ter respondido até aqui. Certifique-se de todos os itens que aparecerão no seu plano. Eles são personalizados a partir de suas respostas, por isso é tão importante que você siga completando todos os blocos.',
                        15, E'[]', E'B3_P20 == \'o-imovel-e-proprio-ou-alugado-em-nome-do-agressor\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035831, 'next_mf_questionnaire', 'B3_P20_PQ_O_IMOVEL_E_PROPRIO_OU_ALUGADO_EM_NOME_DO_AGRESSOR', E' ',
                        15, E'[]', E'B3_P20 == \'o-imovel-e-proprio-ou-alugado-em-nome-do-agressor\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035840, 'displaytext', 'B3_P20_R71', E'Neste caso, você pode procurar uma delegacia, de preferência especializada no atendimento às mulheres, e solicitar uma medida protetiva para que o agressor seja afastado do ambiente doméstico e de você.',
                        15, E'[]', E'B3_P20 == \'o-imovel-e-alugado-no-meu-nome\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035850, 'displaytext', 'B3_P20_R72', E'Se julgar que sua saída é a única chance de romper o ciclo de violência, siga com o plano. Dialogue com o proprietário (a) e negocie possíveis multas em caso de quebra de regra contratual e afins.',
                        15, E'[]', E'B3_P20 == \'o-imovel-e-alugado-no-meu-nome\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035860, 'displaytext', 'B3_P20_R73', E'Deixar o lar não invalida a sua participação em possíveis divisões de bens ou no direito à guarda de filhos, caso os tenha.',
                        15, E'[]', E'B3_P20 == \'o-imovel-e-alugado-no-meu-nome\' ', null,
                        null, '[{"codigo":"T92"},{"codigo":"T94"},{"codigo":"T96"},{"codigo":"T97"},{"codigo":"T99"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035870, 'displaytext', 'B3_P20_R76', E'Estamos finalizando o bloco "Bens, trabalho e renda". Obrigada por ter respondido até aqui. Certifique-se de todos os itens que aparecerão no seu plano. Eles são personalizados a partir de suas respostas, por isso é tão importante que você siga completando todos os blocos.',
                        15, E'[]', E'B3_P20 == \'o-imovel-e-alugado-no-meu-nome\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035871, 'next_mf_questionnaire', 'B3_P20_PQ_O_IMOVEL_E_ALUGADO_NO_MEU_NOME', E' ',
                        15, E'[]', E'B3_P20 == \'o-imovel-e-alugado-no-meu-nome\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035880, 'displaytext', 'B3_P20_R74', E'Entendi! Você possui direitos nessa situação e eles devem ser respeitados. Saiba também que deixar o ambiente de violência não invalida sua participação em possíveis divisões de bens ou o direito à guarda de filhos.',
                        15, E'[]', E'B3_P20 == \'o-imovel-e-financiado-no-nome-dos-dois\' ', null,
                        null, '[{"codigo":"T92"},{"codigo":"T94"},{"codigo":"T96"},{"codigo":"T97"},{"codigo":"T100"},{"codigo":"T101"},{"codigo":"T102"},{"codigo":"T103"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035890, 'displaytext', 'B3_P20_R76', E'Estamos finalizando o bloco "Bens, trabalho e renda". Obrigada por ter respondido até aqui. Certifique-se de todos os itens que aparecerão no seu plano. Eles são personalizados a partir de suas respostas, por isso é tão importante que você siga completando todos os blocos.',
                        15, E'[]', E'B3_P20 == \'o-imovel-e-financiado-no-nome-dos-dois\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035891, 'next_mf_questionnaire', 'B3_P20_PQ_O_IMOVEL_E_FINANCIADO_NO_NOME_DOS_DOIS', E' ',
                        15, E'[]', E'B3_P20 == \'o-imovel-e-financiado-no-nome-dos-dois\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035900, 'displaytext', 'B3_P20_R75', E'Construir um imóvel no terreno de outra pessoa é uma questão delicada, ainda mais se esse terreno pertencer à família do agressor. Ainda assim, você tem direitos à divisão de bens. Vamos incluir em seu plano de fuga orientações importantes para resolver isso na Justiça após a fuga.',
                        15, E'[]', E'B3_P20 == \'construimos-um-imovel-no-terreno-da-familia\' ', null,
                        null, '[{"codigo":"T92"},{"codigo":"T94"},{"codigo":"T96"},{"codigo":"T97"},{"codigo":"T101"},{"codigo":"T103"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035910, 'displaytext', 'B3_P20_R76', E'Estamos finalizando o bloco "Bens, trabalho e renda". Obrigada por ter respondido até aqui. Certifique-se de todos os itens que aparecerão no seu plano. Eles são personalizados a partir de suas respostas, por isso é tão importante que você siga completando todos os blocos.',
                        15, E'[]', E'B3_P20 == \'construimos-um-imovel-no-terreno-da-familia\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10035911, 'next_mf_questionnaire', 'B3_P20_PQ_CONSTRUIMOS_UM_IMOVEL_NO_TERRENO_DA_FAMILIA', E' ',
                        15, E'[]', E'B3_P20 == \'construimos-um-imovel-no-terreno-da-familia\' ', null,
                        null, '[]', null, '[]');
DELETE FROM quiz_config WHERE questionnaire_id = 16;
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10036910, 'displaytext', 'B4_P21intro', E'O objetivo primeiro deste plano é garantir sua integridade física. Por isso, neste bloco vamos fazer perguntas sobre suas rotinas dentro e fora de casa, além de aspectos da convivência com o agressor que podem denotar o nível de risco ao qual você pode estar submetida. Reforçamos que as informações aqui compartilhadas permanecerão em sigilo, pois reconhecemos sua autonomia e capacidade para decidir sobre a própria realidade.',
                        16, E'[]', E'1', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10037910, 'yesno', 'B4_P21', E'Você mora com o agressor?',
                        16, E'[]', E'1', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10037920, 'displaytext', 'B4_P21_R77', E'Sabemos que, neste caso, você pode ser surpreendida com brigas e agressões.',
                        16, E'[]', E'B4_P21 == \'Y\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10037930, 'displaytext', 'B4_P21_R78', E'Quando situações de conflito forem inevitáveis, fique longe da cozinha, de objetos que possam ser usados para lhe machucar e de ambientes em que você possa ser presa pelo agressor. Se a situação se agravar, acione a Polícia Militar pelo 190 e/ou grite por socorro.',
                        16, E'[]', E'B4_P21 == \'Y\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10037940, 'displaytext', 'B4_P21_R79', E'A violência doméstica é cíclica. Por isso, mesmo em momentos de aparente calmaria, mantenha seu plano em segredo.',
                        16, E'[]', E'B4_P21 == \'Y\' ', null,
                        null, '[{"codigo":"T7"},{"codigo":"T8"},{"codigo":"T57"},{"codigo":"T58"},{"codigo":"T59"},{"codigo":"T104"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10037950, 'displaytext', 'B4_P21_R80', E'Certo! Ainda assim é importante que você tenha muita atenção até conseguir executar o seu plano de fuga.',
                        16, E'[]', E'B4_P21 == \'N\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10037960, 'displaytext', 'B4_P21_R81', E'Não permita que o agressor acesse sua residência, mesmo que alegue boas intenções e que a situação pareça controlada.',
                        16, E'[]', E'B4_P21 == \'N\' ', null,
                        null, '[{"codigo":"T7"},{"codigo":"T8"},{"codigo":"T12"},{"codigo":"T57"},{"codigo":"T58"},{"codigo":"T59"},{"codigo":"T105"},{"codigo":"T106"},{"codigo":"T107"},{"codigo":"T108"},{"codigo":"T109"},{"codigo":"T110"},{"codigo":"T111"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10038960, 'yesno', 'B4_P22', E'Você já foi trancada em casa e ficou sem ter como sair ou se comunicar com outras pessoas?',
                        16, E'[]', E'B4_P21 == \'Y\'', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10038970, 'displaytext', 'B4_P22_R82', E'Sinto muito que você tenha sido submetida a essa violência. Prender alguém indevidamente e contra vontade é crime de cárcere privado, com pena prevista de 1 a 3 anos de reclusão. Devido a esse histórico, vou incluir em seu plano de fuga algumas orientações importantes para sua segurança pessoal.',
                        16, E'[]', E'B4_P22 == \'Y\' ', null,
                        null, '[{"codigo":"T11"},{"codigo":"T12"},{"codigo":"T23"},{"codigo":"T112"},{"codigo":"T113"},{"codigo":"T114"},{"codigo":"T115"},{"codigo":"T116"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10038980, 'displaytext', 'B4_P22_R83', E'Que bom! Mas, caso venha a acontecer, deixaremos orientações específicas em seu plano de fuga para te auxiliar a sair ilesa dessa situação.',
                        16, E'[]', E'B4_P22 == \'N\' ', null,
                        null, '[{"codigo":"T11"},{"codigo":"T12"},{"codigo":"T23"},{"codigo":"T112"},{"codigo":"T113"},{"codigo":"T114"},{"codigo":"T115"},{"codigo":"T116"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10039980, 'yesno', 'B4_P23', E'O agressor costuma tomar/danificar seu celular e/ou monitorar suas ligações e mensagens?',
                        16, E'[]', E'B4_P22 == \'Y\' || B4_P22 == \'N\'', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10039990, 'displaytext', 'B4_P23_R84', E'Sinto muito por isso! Danificar objetos pessoais é um sinal de risco grave em casos de violência doméstica. Esse plano não é para situações de emergência. Caso esteja passando uma, busque ajuda imediatamente. Acione alguém de sua confiança e/ou a Polícia Militar pelo telefone 190.',
                        16, E'[]', E'B4_P23 == \'Y\' ', null,
                        null, '[{"codigo":"T20"},{"codigo":"T24"},{"codigo":"T117"},{"codigo":"T118"},{"codigo":"T119"},{"codigo":"T120"},{"codigo":"T121"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10040000, 'displaytext', 'B4_P23_R85', E'Está bem! Vamos seguir com as etapas do seu plano!',
                        16, E'[]', E'B4_P23 == \'N\' ', null,
                        null, '[{"codigo":"T20"},{"codigo":"T24"},{"codigo":"T117"},{"codigo":"T118"},{"codigo":"T119"},{"codigo":"T120"},{"codigo":"T121"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10041000, 'onlychoice', 'B4_P24', E'Você já denunciou o agressor e/ou tem medida protetiva contra ele?',
                        16, E'[]', E'B4_P21 == \'N\' || B4_P23 == \'Y\' || B4_P23 == \'N\'', null,
                        E'[{"label":"Sim, tenho medida protetiva","value":"sim-tenho-medida-protetiva"},{"label":"Já denunciei, mas não tenho medida protetiva.","value":"ja-denunciei-mas-nao-tenho-medida-protetiva"},{"label":"Nunca denunciei","value":"nunca-denunciei"}]', '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10041010, 'displaytext', 'B4_P24_R86', E'Ter a medida protetiva é um grande passo, mas você deve manter os cuidados. Caso ele ainda tente contato ou lhe ameace, vá à Defensoria Pública ou entre em contato com o(a) advogado(a) particular para informar que a medida protetiva está sendo descumprida.',
                        16, E'[]', E'B4_P24 == \'sim-tenho-medida-protetiva\' ', null,
                        null, '[{"codigo":"T8"},{"codigo":"T122"},{"codigo":"T123"},{"codigo":"T124"},{"codigo":"T125"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10041020, 'displaytext', 'B4_P24_R87', E'É muito importante solicitar uma medida protetiva. Além de te afastar do ciclo de violência, ela é um meio legal de garantia de assistências e direitos, não importa quem seja o agressor (companheiro, pai, irmão, filho, outros).',
                        16, E'[]', E'B4_P24 == \'ja-denunciei-mas-nao-tenho-medida-protetiva\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10041030, 'displaytext', 'B4_P24_R88', E'A violência doméstica é cíclica e gradual, e os abusos tendem a piorar com o tempo. Não se intimide.',
                        16, E'[]', E'B4_P24 == \'ja-denunciei-mas-nao-tenho-medida-protetiva\' ', null,
                        null, '[{"codigo":"T8"},{"codigo":"T122"},{"codigo":"T123"},{"codigo":"T124"},{"codigo":"T125"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10041040, 'displaytext', 'B4_P24_R89', E'Infelizmente, existe um alto volume de desinformação circulando por aí. Mas saiba, medidas protetivas ajudam a salvar vidas.',
                        16, E'[]', E'B4_P24 == \'nunca-denunciei\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10041050, 'displaytext', 'B4_P24_R90', E'Respeite o seu tempo. Quando se sentir preparada, vá até uma delegacia, de preferência especializada em atendimento à mulher, denuncie o agressor e solicite medida protetiva.',
                        16, E'[]', E'B4_P24 == \'nunca-denunciei\' ', null,
                        null, '[{"codigo":"T8"},{"codigo":"T122"},{"codigo":"T123"},{"codigo":"T124"},{"codigo":"T125"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10042050, 'onlychoice', 'B4_P25', E'O agressor tem acesso a arma de fogo?',
                        16, E'[]', E'B4_P24 == \'sim-tenho-medida-protetiva\' || B4_P24 == \'ja-denunciei-mas-nao-tenho-medida-protetiva\' || B4_P24 == \'nunca-denunciei\'', null,
                        E'[{"label":"Sim, a atividade profissional autoriza a posse","value":"sim-a-atividade-profissional-autoriza-a-posse"},{"label":"Sim, mas não sei a procedência e/ou não é registrada","value":"sim-mas-nao-sei-a-procedencia-e_ou-nao-e-registrada"},{"label":"Não/Não sei","value":"nao-ou-nao-sei"}]', '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10042060, 'displaytext', 'B4_P25_R91', E'Entendi! Nesse caso, é importante ressaltar que a arma só pode ser usada na necessidade de exercer atividade profissional de risco. Caso ele esteja usando a arma para intimidar e ameaçar, não deixe de avisar a quem confia e às autoridades competentes. Sua proteção é prioridade!',
                        16, E'[]', E'B4_P25 == \'sim-a-atividade-profissional-autoriza-a-posse\' ', null,
                        null, '[{"codigo":"T9"},{"codigo":"T10"},{"codigo":"T11"},{"codigo":"T126"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10042070, 'displaytext', 'B4_P25_R92', E'Entendi! Ter arma em casa é um fator de risco. Prezando sua segurança, é importante que comunique a pessoas de confiança e às autoridades para que sua vida seja protegida.',
                        16, E'[]', E'B4_P25 == \'sim-mas-nao-sei-a-procedencia-e_ou-nao-e-registrada\' ', null,
                        null, '[{"codigo":"T9"},{"codigo":"T10"},{"codigo":"T11"},{"codigo":"T126"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10042080, 'displaytext', 'B4_P25_R93', E'Siga com o planejamento. Se em outro momento você desejar orientações específicas sobre essa questão, nossa equipe estará à disposição no Suporte PenhaS.',
                        16, E'[]', E'B4_P25 == \'nao-ou-nao-sei\' ', null,
                        null, '[{"codigo":"T9"},{"codigo":"T10"},{"codigo":"T11"},{"codigo":"T126"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10043080, 'yesno', 'B4_P26', E'Você possui alguma deficiência física e/ou intelectual?',
                        16, E'[]', E'B4_P25 == \'sim-a-atividade-profissional-autoriza-a-posse\' || B4_P25 == \'sim-mas-nao-sei-a-procedencia-e_ou-nao-e-registrada\' || B4_P25 == \'nao-ou-nao-sei\'', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10043090, 'displaytext', 'B4_P26_R94', E'Tá bem! A depender da situação, e só você pode avaliar, talvez a ajuda de alguém de confiança seja necessária antes, durante e depois da fuga. Avalie quem pode estar com você durante esse processo.',
                        16, E'[]', E'B4_P26 == \'Y\' ', null,
                        null, '[{"codigo":"T94"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10043100, 'displaytext', 'B4_P26_R95', E'Até que a fuga seja efetivada, mantenha a rotina de medicações (se houver) e cuidados.',
                        16, E'[]', E'B4_P26 == \'Y\' ', null,
                        null, '[{"codigo":"T23"},{"codigo":"T73"},{"codigo":"T74"},{"codigo":"T127"},{"codigo":"T128"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10043105, 'tag_user', 'B4_P26_tags', E'',
                        16, E'[]', E'B4_P26 == \'Y\' ', null,
                        null, '[]', null, '[{"codigo":"T7"}]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10044100, 'yesno', 'B4_P27', E'Você está grávida?',
                        16, E'[]', E'B4_P26 == \'Y\' || B4_P26 == \'N\'', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10044110, 'displaytext', 'B4_P27_R96', E'Sinta-se acolhida e encorajada a encontrar um local seguro.',
                        16, E'[]', E'B4_P27 == \'Y\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10044120, 'displaytext', 'B4_P27_R97', E'Tanto na rede privada quanto no SUS, as equipes de saúde são obrigadas por lei a denunciar à polícia casos de violência contra a mulher. A depender da condição, uma visita de rotina pode te ajudar a romper o ciclo de violência.',
                        16, E'[]', E'B4_P27 == \'Y\' ', null,
                        null, '[{"codigo":"T73"},{"codigo":"T74"},{"codigo":"T129"},{"codigo":"T130"},{"codigo":"T131"},{"codigo":"T132"},{"codigo":"T133"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10044130, 'displaytext', 'B4_P27_R98', E'Estamos finalizando o bloco "Segurança Pessoal". Obrigada por ter respondido até aqui. Você é forte e corajosa! Certifique-se de todos os itens que aparecerão no seu plano. Eles são personalizados a partir de suas respostas, por isso é tão importante que você siga respondendo a todos os blocos.',
                        16, E'[]', E'B4_P27 == \'Y\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10044131, 'next_mf_questionnaire', 'B4_P27_PQ_Y', E' ',
                        16, E'[]', E'B4_P27 == \'Y\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10044140, 'displaytext', 'B4_P27_R98', E'Estamos finalizando o bloco "Segurança Pessoal". Obrigada por ter respondido até aqui. Você é forte e corajosa! Certifique-se de todos os itens que aparecerão no seu plano. Eles são personalizados a partir de suas respostas, por isso é tão importante que você siga respondendo a todos os blocos.',
                        16, E'[]', E'B4_P27 == \'N\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10044141, 'next_mf_questionnaire', 'B4_P27_PQ_N', E' ',
                        16, E'[]', E'B4_P27 == \'N\' ', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10044145, 'tag_user', 'B4_P27_tags', E'',
                        16, E'[]', E'B4_P27 == \'N\' ', null,
                        null, '[]', null, '[{"codigo":"T8"}]');
DELETE FROM quiz_config WHERE questionnaire_id = 17;
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10018310, 'displaytext', 'B5_P9intro', E'Agora é o momento de traçar as estratégias de deslocamento até que você se sinta em um ambiente seguro e confiável. Ao finalizar o preenchimento dos blocos de perguntas, apresentaremos uma lista de tarefas adequadas a sua situação.',
                        17, E'[]', E'1', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10019310, 'multiplechoices', 'B5_P9', E'Qual o meio de transporte que pretende utilizar durante a fuga?',
                        17, E'[]', E'1', null,
                        E'[{"label":"Transporte público","value":"transporte-publico"},{"label":"Moto/ Carro próprio","value":"moto-ou--carro-proprio"},{"label":"Carona","value":"carona"},{"label":"Bicicleta/a pé","value":"bicicleta-ou-a-pe"},{"label":"Táxi ou carro por aplicativo","value":"taxi-ou-carro-por-aplicativo"},{"label":"Não sei","value":"nao-sei"}]', '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10019320, 'displaytext', 'B5_P9_R21', E'Os horários dos transportes públicos variam muito, por isso, você deve ficar atenta a alguns itens que vamos incluir ao final do seu plano.',
                        17, E'[]', E'is_json_member(\'transporte-publico\', B5_P9_json)', null,
                        null, '[{"codigo":"T27"},{"codigo":"T28"},{"codigo":"T29"},{"codigo":"T30"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10019330, 'displaytext', 'B5_P9_R22', E'Bom que você tenha essa possibilidade! Sair de casa dirigindo requer preparação e bastante cuidado. Por isso, vou incluir alguns itens de atenção ao final do seu plano.',
                        17, E'[]', E'is_json_member(\'moto-ou--carro-proprio\', B5_P9_json)', null,
                        null, '[{"codigo":"T24"},{"codigo":"T25"},{"codigo":"T26"},{"codigo":"T31"},{"codigo":"T32"},{"codigo":"T33"},{"codigo":"T34"},{"codigo":"T35"},{"codigo":"T36"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10019340, 'displaytext', 'B5_P9_R23', E'Que bom que você conseguiu essa carona! Nesse caso, é importante ter alguns cuidados tanto antes, quanto depois da fuga. Por isso, vou incluir alguns itens relacionados a carona no final do seu plano.',
                        17, E'[]', E'is_json_member(\'carona\', B5_P9_json)', null,
                        null, '[{"codigo":"T37"},{"codigo":"T38"},{"codigo":"T39"},{"codigo":"T40"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10019350, 'displaytext', 'B5_P9_R24', E'Que bom que você conseguirá se deslocar a pé ou de bicicleta. Provavelmente, o local para onde você irá fugir não é tão distante de onde você mora. Por isso, vou incluir alguns itens relacionados ao deslocamento no final do seu plano.',
                        17, E'[]', E'is_json_member(\'bicicleta-ou-a-pe\', B5_P9_json)', null,
                        null, '[{"codigo":"T41"},{"codigo":"T42"},{"codigo":"T43"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10019360, 'displaytext', 'B5_P9_R25', E'Bom que você tenha essa possibilidade! Sair de casa com táxi ou carro de aplicativo requer uma preparação, sobretudo financeira. Por isso, vou incluir alguns pontos de atenção para esse deslocamento ao final do seu plano.',
                        17, E'[]', E'is_json_member(\'taxi-ou-carro-por-aplicativo\', B5_P9_json)', null,
                        null, '[{"codigo":"T44"},{"codigo":"T45"},{"codigo":"T46"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10019370, 'displaytext', 'B5_P9_R26', E'Tudo bem não saber como irá se deslocar. Estamos montando esse plano juntas para você começar a pensar em possibilidades. Por isso, vou incluir alguns pontos de atenção em relação a esse deslocamento ao final do seu plano.',
                        17, E'[]', E'is_json_member(\'nao-sei\', B5_P9_json)', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10019380, 'displaytext', 'B5_P9_R27', E'Tudo bem! Quando souber, volte a esse bloco para encontrar as orientações de acordo com sua decisão! Vá no seu tempo!',
                        17, E'[]', E'is_json_member(\'nao-sei\', B5_P9_json)', null,
                        null, '[{"codigo":"T47"}]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10020380, 'displaytext', 'B5_P9gb', E'[%IF refazer==\'Y\'%][%ELSE%]Estamos chegando ao final do bloco "Passos para a fuga". Obrigada por ter respondido até aqui. Você é forte e corajosa! O PenhaS quer te ajudar a sair de casa e a romper com o ciclo de violência, conseguindo organizar os itens mais importantes para que a sua saída seja mais segura. Por isso, certifique-se de todos os itens que aparecerão no seu plano. Eles são personalizados a partir de suas respostas, por isso é tão importante que você siga respondendo a todos os blocos.[%END%]',
                        17, E'[]', E'is_json_member(\'transporte-publico\', B5_P9_json) || is_json_member(\'moto-ou--carro-proprio\', B5_P9_json) || is_json_member(\'carona\', B5_P9_json) || is_json_member(\'bicicleta-ou-a-pe\', B5_P9_json) || is_json_member(\'taxi-ou-carro-por-aplicativo\', B5_P9_json) || is_json_member(\'nao-sei\', B5_P9_json)', null,
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10021380, 'botao_fim', 'B5_btnOut', E'Obrigada por fornecer uma nova resposta. Vamos ajustar o bloco "Passos para a fuga" com base nas informações mais recentes. Sua persistência e coragem são notáveis! O PenhaS está aqui para te apoiar em cada passo do caminho.',
                        17, E'[]', E'refazer==\'Y\' ', 'Concluir',
                        null, '[]', null, '[]');
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10022380, 'next_mf_questionnaire', 'B5_P9out', E'',
                        17, E'[]', E'1', null,
                        null, '[]', null, '[]');
DELETE FROM quiz_config WHERE questionnaire_id = 18;
INSERT INTO quiz_config(status, sort, type, code, question, questionnaire_id, intro, relevance, button_label, options, tarefas, change_to_questionnaire_id, tag)
                        VALUES ('published', 10045140, 'botao_fim', 'BF_P999', E'Você respondeu a todas as perguntas! Agora é possível ver sua lista de tarefas para colocar o plano em ação. Qualquer coisa estou disponível no Suporte PenhaS. Um abraço carinhoso!',
                        18, E'[]', E'1', 'Concluir',
                        null, '[]', null, '[]');
