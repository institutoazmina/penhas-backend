CREATE OR REPLACE VIEW view_clientes_menos_admin AS
SELECT
    id
FROM
    public.clientes
WHERE
    eh_admin = FALSE
    AND email NOT IN (...);


--            Table "public.mf_cliente_tarefa"
--
-- mf_tarefa_id                              | integer                     |           | not null |
-- cliente_id                                | bigint                      |           | not null |
-- checkbox_feito                            | boolean                     |           | not null | false
-- checkbox_feito_checked_first_updated_at   | timestamp without time zone |           |          |
-- checkbox_feito_checked_last_updated_at    | timestamp without time zone |           |          |
-- checkbox_feito_unchecked_first_updated_at | timestamp without time zone |           |          |
-- checkbox_feito_unchecked_last_updated_at  | timestamp without time zone |           |          |
-- criado_em                                 | timestamp without time zone |           | not null | now()
-- removido_em                               | timestamp without time zone |           |          |
-- last_from_questionnaire                   | integer                     |           |          |
-- atualizado_em                             | timestamp without time zone |           | not null | now()
-- campo_livre                               | json                        |           |          |

-- 1 - Quantos manuais foram iniciados? (Data de início)
-- 2 - Quantos manuais foram finalizados? (Data de término)
-- 3 - Quantos formulários tiveram tarefas marcadas como concluídas?
-- 13 - Recorte racial das usuárias que preencheram o Manual de Fuga (Cadastro)
-- 14 - De onde são (cidade/estado) as usuárias distintas que preencheram o Manual de Fuga?

CREATE OR REPLACE VIEW view_clientes_mf_session_control AS
WITH cliente_tarefa_esteve_concluida AS (
    SELECT distinct cliente_id
    FROM mf_cliente_tarefa
    WHERE checkbox_feito_checked_first_updated_at IS NOT NULL
)
SELECT
    c.cliente_id,
    CASE WHEN c.status = 'onboarding' THEN
        'Introdução'
    WHEN c.status = 'inProgress' THEN
        'Em Progresso'
    ELSE
        'Finalizado'
    END AS "status",
    c.current_clientes_quiz_session,
    c.completed_questionnaires_id,
    c.started_at AS dt_inicio,
    c.completed_at AS dt_termino,
    CASE WHEN cli.raca = 'nao_declarado' THEN
        'Não Declarado'
    WHEN cli.raca = 'preto' THEN
        'Preto'
    WHEN cli.raca = 'amarelo' THEN
        'Amarelo'
    WHEN cli.raca = 'branco' THEN
        'Branco'
    WHEN cli.raca = 'indigena' THEN
        'Indígena'
    WHEN cli.raca = 'pardo' THEN
        'Pardo'
    ELSE
        'Não Declarado'
    END AS raca,
    cli.genero,
    (case WHEN cli.cep_estado = '' then 'N/A' else cli.cep_estado end)::varchar(200) as cep_estado,
    (case WHEN cli.cep_cidade = '' then 'N/A' else cli.cep_cidade end)::varchar(200) as cep_cidade,
    t.cliente_id IS NOT NULL AS tarefa_concluida
FROM
    public.cliente_mf_session_control c
    JOIN view_clientes_menos_admin v ON c.cliente_id = v.id
    JOIN clientes cli ON c.cliente_id = cli.id
    LEFT JOIN cliente_tarefa_esteve_concluida t ON c.cliente_id = t.cliente_id;

                                               Table "public.questionnaires"
           Column           |           Type           | Collation | Nullable |                  Default
----------------------------+--------------------------+-----------+----------+--------------------------------------------
 id                         | bigint                   |           | not null | nextval('questionnaires_id_seq'::regclass)
 created_on                 | timestamp with time zone |           |          |
 modified_on                | timestamp with time zone |           |          |
 active                     | boolean                  |           | not null |
 name                       | character varying(200)   |           | not null |
 condition                  | character varying(2000)  |           | not null | '0'::character varying
 end_screen                 | character varying(200)   |           | not null | 'home'::character varying
 owner                      | uuid                     |           |          |
 modified_by                | uuid                     |           |          |
 penhas_start_automatically | boolean                  |           | not null | true
 penhas_cliente_required    | boolean                  |           | not null | true

CREATE OR REPLACE VIEW view_blocos_mf AS
SELECT
    id as questionnaire_id,
    (case
        when "name" like '%B0%' then 'Itens Básicos'
        when "name" like '%B1%' then 'Passos para fuga'
        when "name" like '%B2%' then 'Crianças, adolescentes e dependentes'
        when "name" like '%B3%' then 'Bens e renda'
        when "name" like '%B4%' then 'Segurança pessoal'
        when "name" like '%B5%' then 'Transporte'
        else 'outros'
    end)::varchar(200)
AS "bloco"
FROM questionnaires
WHERE "name" in (
    'Produção - B0',
    'Produção - B1',
    'Produção - B2',
    'Produção - B3',
    'Produção - B4',
    'Produção - B5'
);


CREATE OR REPLACE VIEW view_blocos_acoes_mf AS
SELECT
id as questionnaire_id,

case when "name" like '%BF%' then 'Finalizou Quiz'
when "name" like 'Refazer B5' then 'Editar bloco transporte'
else 'outros'
end::varchar(200) AS "bloco"
FROM questionnaires
WHERE "name" in (
    'Refazer B5',
    'Produção - BF'
);

-- para responder isso, cruza com a session
-- 5 - Quantas usuárias distintas responderam ao bloco Crianças, Adolescentes e Dependentes?
-- 6 - Quantas usuárias distintas responderam ao bloco Bens, Trabalho e Renda?
-- 7 - Quantas usuárias distintas responderam ao bloco Segurança Pessoal?
-- 8 - Quantas usuárias distintas responderam ao bloco Passos para Fuga?
-- 9 - Quantas usuárias distintas responderam ao complemento Transporte?
-- 10 - Quantas usuárias distintas editaram o bloco transporte?
-- 11 - Quantas vezes o bloco de transporte foi editado por usuárias distintas?

--                                          Table "public.clientes_quiz_session"
--      Column      |           Type           | Collation | Nullable |                      Default
--------------------+--------------------------+-----------+----------+---------------------------------------------------
-- id               | bigint                   |           | not null | nextval('clientes_quiz_session_id_seq'::regclass)
-- cliente_id       | bigint                   |           | not null |
-- questionnaire_id | bigint                   |           | not null |
-- finished_at      | timestamp with time zone |           |          |
-- created_at       | timestamp with time zone |           | not null |
-- stash            | json                     |           |          | '{}'::json
-- responses        | json                     |           |          | '{}'::json
-- deleted_at       | timestamp with time zone |           |          |
-- deleted          | boolean                  |           | not null | false

CREATE OR REPLACE VIEW view_clientes_mf_blocos AS
SELECT
    csc.cliente_id,
    b.questionnaire_id as questionnaire_id,
    b.bloco,
    case when b.questionnaire_id = any(completed_questionnaires_id) or status='completed' then 1 else 0 end as qtd_respostas_completas
FROM cliente_mf_session_control csc,
view_blocos_mf b;

CREATE OR REPLACE VIEW view_clientes_acoes_mf AS
SELECT
    cs.cliente_id,
    b.questionnaire_id as questionnaire_id,
    b.bloco,
    sum(case when cs.finished_at is not null then 1 else 0 end) as qtd_respostas_completas,
    sum(case when cs.id is not null then 1 else 0 end) as qtd_respostas_iniciadas
FROM view_blocos_acoes_mf b
LEFT JOIN clientes_quiz_session cs on cs.questionnaire_id = b.questionnaire_id
GROUP BY 1,2,3;

-- 4 - Quantas usuárias distintas preencheram apenas um bloco?


CREATE OR REPLACE VIEW view_clientes_apenas_um_bloco AS
SELECT
    csc.cliente_id
FROM cliente_mf_session_control csc
where array_length(completed_questionnaires_id, 1) = 2;


CREATE OR REPLACE VIEW view_clientes_por_qtde_bloco AS
SELECT
    csc.cliente_id,
    case when "status"='completed' then 5 else
         coalesce(array_length(completed_questionnaires_id, 1) - 1, 0)
    end
          as qtde_blocos
FROM cliente_mf_session_control csc;


CREATE OR REPLACE VIEW view_clientes_mf_tag AS
SELECT
    ct.cliente_id,
    t.code,
    case
        when t.code='T1' then 'Interesse em saber mais sobre os serviços de apoio'
        when t.code='T2' then 'Incluíram crianças ou adolescentes no plano de fuga'
    END as tag

FROM mf_tag t
JOIN cliente_tag ct ON t.id = ct.mf_tag_id
WHERE t.code in ('T1', 'T2');








------ falta debuggar isso
SELECT
    "public"."view_clientes_mf_blocos"."bloco" AS "bloco",
    SUM("public"."view_clientes_mf_blocos"."qtd_respostas_completas") AS "sum",
    count(DISTINCT "public"."view_clientes_mf_blocos"."cliente_id") AS "count"
FROM
    "public"."view_clientes_mf_blocos"
    LEFT JOIN "public"."view_clientes_mf_session_control" AS "View Clientes Mf Session Control" ON "public"."view_clientes_mf_blocos"."cliente_id" = "View Clientes Mf Session Control"."cliente_id"
GROUP BY
    "public"."view_clientes_mf_blocos"."bloco"
ORDER BY
    "sum" DESC,
    "public"."view_clientes_mf_blocos"."bloco" ASC
