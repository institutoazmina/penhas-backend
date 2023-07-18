INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T1',
                      E'',
                      E'Separe ou faça cópia dos seguintes documentos de identificação (tanto seu, quanto dos filhos, caso os tenha): RG, CPF, CNH,  Título de Eleitor, Passaporte, Certidão de Nascimento, Cartão de Vacinação, Cartão de Saúde do SUS ou do Plano de Saúde, Cartão do Auxílio Brasil',
                      E'checkbox',
                      E'Itens Básicos'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T2',
                      E'',
                      E'Organize uma mochila com roupas. Se achar que a mochila levantará suspeita, separe em sacolas plásticas algumas mudas de roupa. Você pode ir separando as peças de roupas no decorrer dos dias para não levantar suspeitas.',
                      E'checkbox',
                      E'Itens Básicos'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T3',
                      E'',
                      E'Ponha na mochila medicamentos básicos e de uso contínuo',
                      E'checkbox',
                      E'Itens Básicos'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T4',
                      E'',
                      E'Cadastre-se e/ou verifique se o seu Cadastro Único (CadÚnico) está ativo.',
                      E'checkbox',
                      E'Passos para fuga'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T5',
                      E'',
                      E'Busque o Centro de Referência de Assistência Social (CRAS).',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T6',
                      E'',
                      E'Leve ao CRAS toda documentação necessária, tanto sua, quanto das crianças, se houver.',
                      E'checkbox',
                      E'Passos para fuga'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T7',
                      E'',
                      E'Solicite uma medida protetiva contra seu agressor em uma delegacia, de preferência especializada em atendimento a mulheres
.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T8',
                      E'',
                      E'Caso já tenha uma medida protetiva, e siga sendo alvo de ameaças, faça um novo boletim de ocorrência.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T9',
                      E'',
                      E'Digite aqui o telefone das pessoas de sua confiança e de quem vai te acolher, pois  ao final você terá registrado no Plano de Segurança, juntamente com o checklist.',
                      E'checkbox',
                      E'Passos para fuga'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T10',
                      E'',
                      E'Salve esses contatos na sua agenda de celular com as letras AAA na frente do nome para que eles sejam os primeiros na sua lista de contatos. Exemplo: AAAJoana.',
                      E'checkbox',
                      E'Passos para fuga'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T11',
                      E'',
                      E'Cadastre pessoas de sua confiança como guardiões no aplicativo PenhaS. Essa função faz com que elas recebam uma mensagem de pedido de ajuda junto com o link da sua localização quando acionar o botão de pânico. Você consegue adicionar até cinco guardiões.',
                      E'checkbox',
                      E'Passos para fuga'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T12',
                      E'',
                      E'Peça para que algum vizinho de confiança sempre observe a sua casa e acione o 190 da Polícia Militar caso perceba algum episódio de violência ou movimento estranho.',
                      E'checkbox',
                      E'Passos para fuga'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T13',
                      E'',
                      E'Solicite companhia de alguém da confiança para ir até a delegacia ou aos serviços especializados de atendimento à vítima de violência.',
                      E'checkbox',
                      E'Passos para fuga'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T14',
                      E'',
                      E'Pesquise com cuidado para onde você deseja ir, e informe somente a pessoas sejam da sua extrema confiança sobre seu novo endereço.',
                      E'checkbox',
                      E'Passos para fuga'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T15',
                      E'',
                      E'Verifique como é o acesso à sua nova residência, se há grades e outros equipamentos que possam lhe manter segura nesse novo local.',
                      E'checkbox',
                      E'Passos para fuga'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T16',
                      E'',
                      E'Ao sair/retornar da sua futura casa/abrigo, opte por rotas e caminhos diferentes, de modo que possa despistar o agressor em caso se persguições/stalking.',
                      E'checkbox',
                      E'Passos para fuga'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T17',
                      E'',
                      E'Evite falar sobre seus planos de fuga com pessoas que não sejam da sua extrema confiança, para que isso não chegue aos ouvidos do agressor.',
                      E'checkbox',
                      E'Passos para fuga'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T18',
                      E'',
                      E'Em sua próxima oportunidade de sair de casa, aproveite para ir ao banco e sacar um dinheiro reserva ou ir encontrar alguém que possa lhe emprestar uma quantia para a fuga.',
                      E'checkbox',
                      E'Passos para fuga'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T19',
                      E'',
                      E'Revise o trajeto que irá fazer quando sair definitivamente de casa.',
                      E'checkbox',
                      E'Passos para fuga'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T20',
                      E'',
                      E'Combine algum código de perigo com alguém confiável.',
                      E'checkbox',
                      E'Passos para fuga'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T21',
                      E'',
                      E'No dia da fuga, mantenha sua rotina comum e tente se manter calma para não gerar desconfiança.',
                      E'checkbox',
                      E'Passos para fuga'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T22',
                      E'',
                      E'Se puder, alguns dias antes, comece a fazer pequenas saídas para que próximo ao dia da fuga, não gere nenhuma desconfiança. Exemplo: bancos, padarias, supermercados, casa de amigos, médico.',
                      E'checkbox',
                      E'Passos para fuga'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T23',
                      E'',
                      E'Certifique horários do seu agressor e programe sua fuga no momento em que você tiver maior margem de tempo, para que possa se distanciar o máximo possível do seu endereço sem ser notada.',
                      E'checkbox',
                      E'Passos para fuga'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T24',
                      E'',
                      E'Verifique se o seu celular possui algum dispositivo de localização conectado com o celular do agressor. Saiba mais a partir das informações disponíveis aqui (https://oab-brusque.org.br/wp-content/uploads/2020/07/Cartilha-Mapa-do-Acolhimento_QuarentenaSemViole%CC%82ncia_BR.pdf).',
                      E'checkbox',
                      E'Passos para fuga'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T25',
                      E'',
                      E'Informe ao agressor que vai a algum lugar como farmácia, médico, supermercado, para que você ganhe tempo caso ele vá atrás de você.',
                      E'checkbox',
                      E'Passos para fuga'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T26',
                      E'',
                      E'Em situações de ameaças, evite dizer que vai para a casa de alguma amiga, pois essa pessoa pode ser colocada em situações de risco.',
                      E'checkbox',
                      E'Passos para fuga'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T27',
                      E'',
                      E'Verifique os dias e horários de funcionamento do transporte público, especialmente das linhas que te levarão (próximo) ao local de abrigo após a fuga.',
                      E'checkbox',
                      E'Transporte'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T28',
                      E'',
                      E'Verifique se existem rotas que te levarão (próximo) ao local de abrigo após a fuga.',
                      E'checkbox',
                      E'Transporte'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T29',
                      E'',
                      E'Separe o valor das passagens/tarifas necessárias para a sua fuga, considerando os diversos modos, baldeações e filhos, se houver.',
                      E'checkbox',
                      E'Transporte'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T30',
                      E'',
                      E'Caso não tenha dinheiro, certifique se alguma amiga ou familiar pode te emprestar.',
                      E'checkbox',
                      E'Transporte'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T31',
                      E'',
                      E'Deixe o carro estacionado de uma maneira prática para sair ou mesmo fora da garagem para evitar barulho e sinalizar algo.',
                      E'checkbox',
                      E'Transporte'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T32',
                      E'',
                      E'Separe os documentos do carro e seguro.',
                      E'checkbox',
                      E'Transporte'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T33',
                      E'',
                      E'Providencie uma chave reserva do carro e a esconda junto das chaves da casa, caso as chaves não estejam sob sua posse.',
                      E'checkbox',
                      E'Transporte'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T34',
                      E'',
                      E'Caso a fuga seja planejada, verifique se o carro está abastecido com antecedência para que não ocorra nenhum imprevisto. Mas, é muito importante que sempre esteja com gasolina.',
                      E'checkbox',
                      E'Transporte'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T35',
                      E'',
                      E'Verifique se o carro possui rastreador alguns dias antes. Siga essas dicas: https://pt.wikihow.com/Encontrar-um-Rastreador-Escondido-em-um-Carro',
                      E'checkbox',
                      E'Transporte'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T36',
                      E'',
                      E'Se precisar de alguma cadeira de segurança para criança, tenha o hábito de deixar sempre no carro para não perder tempo e, em situação de extrema urgência, não se prender a esse detalhe, pois é possível parar em outro lugar onde vocês estejam em segurança para fazer isso.',
                      E'checkbox',
                      E'Transporte'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T37',
                      E'',
                      E'Veja com a pessoa que vai lhe dar carona quanto tempo ela leva para chegar na sua casa.',
                      E'checkbox',
                      E'Transporte'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T38',
                      E'',
                      E'Verifique com a pessoa que vai lhe dar carona se ela pode lhe socorrer em situações de emergência ou somente se combinarem antes.',
                      E'checkbox',
                      E'Transporte'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T39',
                      E'',
                      E'Reforce com a pessoa que lhe dará carona que seu local de destino precisa ficar em sigilo para sua segurança.',
                      E'checkbox',
                      E'Transporte'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T40',
                      E'',
                      E'Se por acaso desconfiar que a pessoa que for te dar carona pode falar onde você está, se pressionada, pense em outra pessoa, ou peça para que ela te deixe num terminal de transporte público onde você faça a última parte da viagem por sua conta.',
                      E'checkbox',
                      E'Transporte'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T41',
                      E'',
                      E'Ao fugir a pé, vá por caminhos diferentes do que você costuma ir para despistar o agressor, caso o agressor resolva ir atrás de você.',
                      E'checkbox',
                      E'Transporte'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T42',
                      E'',
                      E'Se seu agressor pode segui-la de carro, opte por andar / pedalar (nas calçadas) em ruas de mão única, no sentido contrário ao dos carros e em passagens que sejam somente para pedestres.',
                      E'checkbox',
                      E'Transporte'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T43',
                      E'',
                      E'Se seu agressor pode segui-la também a pé ou de bicicleta, busque fugir em locais que tenham muita gente, leve uma troca de roupa na bolsa e troque assim que possível.',
                      E'checkbox',
                      E'Transporte'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T44',
                      E'',
                      E'Antes de usar carro por aplicativo para fugir, certifique-se que o agressor tem acesso aos seus aplicativos para que ele não descubra a sua localização.',
                      E'checkbox',
                      E'Transporte'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T45',
                      E'',
                      E'Ao usar carro por aplicativo para fugir, não entre em detalhes com o motorista do app.',
                      E'checkbox',
                      E'Transporte'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T46',
                      E'',
                      E'Ao usar carro por aplicativo para fugir, peça que o motorista lhe deixe somente na localização desejada ou mesmo em algum lugar próximo ao destino final.',
                      E'checkbox',
                      E'Transporte'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T47',
                      E'',
                      E'Definir meio de transporte a ser usado na fuga e responder novamente o bloco "Passos para a fuga".',
                      E'checkbox',
                      E'Transporte'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T49',
                      E'',
                      E'Explique a situação utilizando linguagem adequada à idade dele(a).',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T50',
                      E'',
                      E'Informe sobre violência contra a mulher de maneira adequada para a idade. Explique regras como "ninguém pode machucar ninguém", por exemplo.',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T51',
                      E'',
                      E'Em caso de emergência, oriente a criança a se proteger, sair de casa e buscar ajuda, se possível de alguém da vizinhança já ciente da situação.',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T52',
                      E'',
                      E'Ensaie com a criança como ligar para polícia (190): "Oi, eu me chamo ______, tenho ___ anos. Meu endereço é _______, estou com a minha mãe/madrasta/irmã sofrendo violência e ela precisa de ajuda urgente".',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T53',
                      E'',
                      E'Procure o Conselho Tutelar da sua cidade e ligue para o Disque 100 para denunciar violências e violações de direitos de crianças e adolescentes',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T54',
                      E'',
                      E'Se houver possibilidade, entre em contato com a escola e comunique o que está acontecendo em casa, deixando contatos de pessoas da sua confiança que possam ser acionadas, se necessário.',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T55',
                      E'',
                      E'Busque acompanhamento psicológico tanto para a criança/adolescente quanto para você. O Mapa do Acolhimento oferta esse serviço gratuitamente para mulheres vítimas de violência https://mapadoacolhimento.org/',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T56',
                      E'',
                      E'Junte o máximo de provas sobre situações de violência em que seu filho(a) também está sendo vítima ou que corra algum risco para que possa garantir que a medida protetiva valha para ele(a) também.',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T57',
                      E'',
                      E'Sempre que possível, tire fotos / prints, grave vídeos / áudios  que possam servir de prova, principalmente em situações de violência psicológica e moral. Aqui mesmo no PenhaS você consegue gravar o áudio.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T58',
                      E'',
                      E'Envie esses registros para mais de uma pessoa de sua confiança (usando Whatsapp ou Signal). Caso seu agressor possa acessar seu celular ou e-mail, apague o material após enviar e confirmar que receberam.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T59',
                      E'',
                      E'Procure um(a) advogado(a) ou a Defensoria Pública para se informar sobre qual o melhor modo de fazer registro de provas digitais com validade jurídica.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T60',
                      E'',
                      E'Após a fuga, registre um boletim de ocorrência e solicite medida protetiva tanto para você, quanto para seu filho(a), informando que ele(a) também corre risco de vida e que a saída de casa foi necessária para preservar a integridade física de vocês.',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T61',
                      E'',
                      E'Caso a criança/adolescente não seja seu filho, busque outros familiares que possam protegê-lo(a) ou abrigá-lo(a) por um tempo.',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T62',
                      E'',
                      E'Incentive a criança e/ou adolescente a ter sempre consigo cópias de seus próprios documentos, explicando a importância disso.',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T63',
                      E'',
                      E'Previamente, oriente a criança/adolescente a buscar um lugar que ofereça menos risco em caso de briga, seja dentro ou fora de casa (siga demais instruções dos blocos Segurança pessoal e Passos para a fuga).',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T64',
                      E'',
                      E'Separe uma mochila com brinquedos para distraí-la(lo), além de água e comida.',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T65',
                      E'',
                      E'Faça um trabalho de sensibilização alguns dias antes, como por exemplo: "Iremos passar um tempo em outra casa só nossa", "precisaremos fazer uma viagem por um tempo", "Iremos ficar na casa da vovó ou da tia fulana".',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T66',
                      E'',
                      E'Após a fuga, registre um boletim de ocorrência dizendo que precisou sair de casa com a criança/ adolescente para preservar a integridade física de vocês.',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T67',
                      E'',
                      E'Oriente a criança e/ou adolescente a não entrar em conflito com o agressor.',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T68',
                      E'',
                      E'Deixe claro que quando você conseguir se estabelecer em um lugar seguro, você irá buscá-lo(a).',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T69',
                      E'',
                      E'Deixe mensagens de afeto guardadas em lugares que você saiba que a criança/adolescente possa ver.',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T70',
                      E'',
                      E'Após a fuga, registre um boletim de ocorrência dizendo que precisou sair de casa sem a criança/ adolescente por não ter um local seguro para ir com ele(a). Isso é importante para não caracterizar abandono.',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T71',
                      E'',
                      E'É importante construir pequenos diálogos sobre a ideia de "ter um lugar só nosso", "de fazer uma viagem juntos", "de ir morar um tempo na casa da fulana". Isso poderá servir de termômetro para dar um próximo passo.',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T72',
                      E'',
                      E'Avalie o risco e a necessidade de contar sobre a intenção de fuga com antecedência com base na idade e na capacidade de entendimento da criança/ adolescente.',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T73',
                      E'',
                      E'Separe as medicações de uso contínuo.',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T74',
                      E'',
                      E'Separe documentos de encaminhamentos e exames que sejam importantes para continuidade do tratamento ou garantia de recebimento de benefício assistencial.',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T75',
                      E'',
                      E'Peça ajuda a alguém da sua confiança para poder lhe dar suporte com a criança e/ou adolescente no momento da fuga.',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T76',
                      E'',
                      E'Comunique o quanto antes à equipe de profissionais de saúde a situação, informando sobre a interrupção do tratamento por questões de segurança, sua e da criança/adolescente.',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T77',
                      E'',
                      E'Oriente a pessoa adulta a buscar formas de se proteger, explicando sobre a necessidade da medida protetiva.',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T78',
                      E'',
                      E'Caso essa pessoa seja uma mulher, oriente ela a baixar o Penhas para fazer o próprio plano de fuga.',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T79',
                      E'',
                      E'Se possível, acompanhe ele(a) a uma delegacia ou aos serviços especializados de atendimento à vítima de violência.',
                      E'checkbox',
                      E'Crianças, adolescentes e dependentes'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T80',
                      E'',
                      E'Guarde com você cartões de banco, senhas e outros dados necessários para a movimentação bancária.',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T81',
                      E'',
                      E'Acione a polícia e/ou seu banco caso seja retirado de você o acesso a cartões e senhas, inclusive de benefícios sociais.',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T82',
                      E'',
                      E'Se possível, tenha sempre algum dinheiro vivo em mãos. Se for guardar em casa, mantenha em local sigiloso. Você também pode deixar essa quantia com alguém da sua confiança.',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T83',
                      E'',
                      E'Anote contatos da sua agência bancária e gerente para o caso de alguma necessidade.',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T84',
                      E'',
                      E'Se possível, guarde fotos dos cartões e salve o código de segurança em lugar seguro caso seja necessário fazer compras online ou cadastrar o cartão em app de transporte, por exemplo.',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T85',
                      E'',
                      E'É importante ter uma conta, de preferência banco digital onde é mais fácil de abrir a conta, que o agressor desconheça para que você possa ter uma reserva para situações de emergência. Não se esqueça de optar por não receber correspondências em casa.',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T86',
                      E'',
                      E'Sempre que possível, guarde trocos e economias das despesas da casa. Qualquer quantia faz diferença neste momento.',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T87',
                      E'',
                      E'Verifique se a empresa na qual você trabalha possui programação de apoio ou acompanhamento a mulheres em situação de violência.',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T88',
                      E'',
                      E'Busque acompanhamento psicológico. O Mapa do Acolhimento oferta esse serviço gratuitamente para mulheres vítimas de violência https://mapadoacolhimento.org/',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T89',
                      E'',
                      E'No CRAS, informe que o agressor não compõe mais o núcleo familiar, caso receba algum benefício assistencial.',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T90',
                      E'',
                      E'Dirija-se ao banco no qual possui conta e veja possibilidades com a gerência para que bloqueie o uso e solicite novo cartão.',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T91',
                      E'',
                      E'Cadastre a sua digital como forma de validação para caixas eletrônicos.',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T92',
                      E'',
                      E'Busque um (a) advogado (a) de família ou a Defensoria Pública para ter orientação jurídica especializada.',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T93',
                      E'',
                      E'Guarde com você documentos como matrícula, escritura, contrato de compra e venda, comprovantes de residência em seu nome e/ou comprovantes bancários.',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T94',
                      E'',
                      E'Faça cópias de notas fiscais de móveis e eletrodomésticos da casa comprados por você, para que isso conste no processo de partilha de bens.',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T95',
                      E'',
                      E'Guarde recibos/comprovantes de reformas e manutenções que tenham sido realizadas na casa por você.',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T96',
                      E'',
                      E'Guarde com você cópia da certidão de casamento ou a declaração de união estável. Se não tiver acesso, solicite segunda via no cartório em que foi realizado o procedimento.',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T97',
                      E'',
                      E'Se você passou procuração pública para o agressor, vá ao cartório e solicite o cancelamento dessa procuração.',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T98',
                      E'',
                      E'Caso ainda esteja quitando o financiamento, mas precise de dinheiro para planejar a fuga, suspenda o pagamento de sua parte e dê entrada em uma ação de divórcio/ dissolução de união estável c/ partilha de bens.',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T99',
                      E'',
                      E'Dialogue com o proprietário/imobiliária sobre a situação e negocie possíveis multas em caso de quebra de regra contratual e afins.',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T100',
                      E'',
                      E'Caso ainda esteja quitando o financiamento, mas precise de dinheiro para planejar a fuga, suspenda o pagamento de sua parte e dê entrada em uma ação de divórcio/ dissolução de união estável c/ partilha de bens.',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T101',
                      E'',
                      E'Guarde os comprovantes de pagamento do imóvel, principalmente se for dinheiro de herança e/ou FGTS, pois esse dinheiro é seu e não entrará na partilha  (exceto quando o casamento é pelo regime universal de bens).',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T102',
                      E'',
                      E'Vá ao banco, converse com a sua gerência e verifique se todas as parcelas estão em dia.',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T103',
                      E'',
                      E'Verifique se há algum empréstimo feito em seu nome sem que fosse devidamente autorizado por você.',
                      E'checkbox',
                      E'Bens e renda'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T104',
                      E'',
                      E'Se não for possível evitar a violência, mergulhe em um canto e enrole-se com o rosto protegido e os braços ao redor de cada lado da cabeça, os dedos entrelaçados.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T105',
                      E'',
                      E'Se julgar necessário, substitua fechaduras e cadeados de acesso ao imóvel.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T106',
                      E'',
                      E'Se dividir o imóvel com outras pessoas, mesmo que crianças/adolescente com vínculo com o agressor, oriente para que não permitam a entrada sem o seu conhecimento.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T107',
                      E'',
                      E'Caso more em condomínio com portaria, comunique que não é permitida a entrada do agressor.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T108',
                      E'',
                      E'Se possível, escolha caminhos e horários diferenciados ao sair e retornar para casa. Se perceber que está sendo seguida, entre no estabelecimento mais próximo e peça ajuda imediatamente.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T109',
                      E'',
                      E'Evite publicar em redes sociais informações que pemitam identificar sua localização em eventuais saídas e/ou destinos.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T110',
                      E'',
                      E'Mantenha as suas redes sociais com restrições, de preferência dê acesso somente para "melhores amigos" e bloqueie o agressor de todas as redes.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T111',
                      E'',
                      E'Oriente as pessoas do seu convívio sobre a necessidade de manter em sigilo sua rotina e trajetos.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T112',
                      E'',
                      E'Faça cópia de todas as chaves de acesso à casa e mantenha em local seguro, desconhecido do agressor.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T113',
                      E'',
                      E'Retire todas as chaves dos cômodos (quartos e banheiros) para que não haja risco de ser trancada em um deles.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T114',
                      E'',
                      E'Durante uma discussão, evite estar em lugares que tenham objetos que possam te machucar (Ex.: faca, vidro, tesoura, lâmina, facão, fogo e etc).',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T115',
                      E'',
                      E'Deixe os talheres em lugares de difícil acesso, por exemplo, nas gavetas que estiverem mais baixas.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T116',
                      E'',
                      E'Caso precise pedir ajuda, grite "socorro" ou "alguém me ajude" e diga o número do apartamento.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T117',
                      E'',
                      E'Desinstale aplicativos que você não conhece ou que julgue estranhos.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T118',
                      E'',
                      E'Tenha anotado em algum lugar seguro telefones e endereços de pessoas da sua confiança.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T119',
                      E'',
                      E'Evite dar detalhes sobre a sua fuga para outras pessoas, especialmente por mensagens.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T120',
                      E'',
                      E'Deixe o app PenhaS em modo camuflado para que ele não consiga acessar suas informações.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T121',
                      E'',
                      E'Se tiver possibilidade, tenha um aparelho celular reserva para casos de urgência.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T122',
                      E'',
                      E'Procure a Defensoria Pública ou, se possível, contrate um (a) advogado (a) particular.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T123',
                      E'',
                      E'Verifique se em seu município existem ações tipo Ronda ou Patrulha Maria da Penha e solicite acompanhamento da sua residência.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T124',
                      E'',
                      E'Caso sofra qualquer tentativa de privação do seu direito de acesso à medida protetiva por parte das autoridades competentes, denuncie à Secretaria de Segurança do seu estado, ao Ministério Público e à OAB.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T125',
                      E'',
                      E'Em caso de possível divórcio ou dissolução de união estável, não encontre com o agressor, solicite que o contato seja diretamente com o(a) advogado(a) ou com a Defensoria Pública.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T126',
                      E'',
                      E'Informe na delegacia que o agressor possui arma de fogo, a situação será analisada e possivelmente haverá a suspensão da autorização do porte  e a apreensão da arma.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T127',
                      E'',
                      E'Caso julgue necessário, peça ajuda a alguém da sua confiança para poder lhe dar suporte no momento da fuga.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T128',
                      E'',
                      E'Comunique à equipe de profissionais de saúde a situação, informando sobre a interrupção do tratamento por questões de segurança',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T129',
                      E'',
                      E'Separe os exames do pré-natal.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T130',
                      E'',
                      E'Caso tenha baixa renda, procure a Defensoria Pública para entrar com uma ação de alimentos gravídicos; leve exame que ateste gravidez e provas da relação mantida com o genitor do bebê.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T131',
                      E'',
                      E'Separe documentos de encaminhamentos e exames que sejam importantes para continuidade do pré-natal ou garantia de recebimento de benefício assistencial.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T132',
                      E'',
                      E'Peça ajuda a alguém da sua confiança para poder lhe dar suporte no momento da fuga.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
INSERT INTO mf_tarefa(codigo, titulo, descricao, tipo, agrupador)
                   VALUES (
                      E'T133',
                      E'',
                      E'Comunique à equipe de profissionais de saúde a situação, informando sobre a interrupção do tratamento por questões de segurança.',
                      E'checkbox',
                      E'Segurança pessoal'
                   )
                   ON CONFLICT (codigo) WHERE (codigo::text <> ''::text) DO UPDATE
                   SET descricao = EXCLUDED.descricao,
                       agrupador = EXCLUDED.agrupador;
