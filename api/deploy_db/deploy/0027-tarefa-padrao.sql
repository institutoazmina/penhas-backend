-- Deploy penhas:0027-tarefa-padrao to pg
-- requires: 0026-block-users

BEGIN;


-- alter table mf_tarefa drop column campo_livre_1, drop column campo_livre_2, drop column campo_livre_3;
-- alter table mf_tarefa add column campo_livre json;

create table mf_tarefa (
    id serial primary key not null,

    titulo varchar not null,
    descricao varchar not null,

    tipo varchar not null default 'checkbox',
    codigo varchar,

    campo_livre json,

    agrupador varchar(120) not null default 'Outros',

    criado_em timestamp without time zone not null default now(),
    -- se é editável ou não pela usuária
    eh_customizada boolean not null default false
);

create table mf_cliente_tarefa (
    id serial primary key not null,

    mf_tarefa_id int not null references mf_tarefa(id),
    cliente_id bigint not null references clientes(id),

    checkbox_feito boolean not null default false,

    checkbox_feito_checked_first_updated_at timestamp without time zone,
    checkbox_feito_checked_last_updated_at timestamp without time zone,

    checkbox_feito_unchecked_first_updated_at timestamp without time zone,
    checkbox_feito_unchecked_last_updated_at timestamp without time zone,

    criado_em timestamp without time zone not null default now(),
    removido_em timestamp without time zone,

    last_from_questionnaire int references questionnaires(id),

    atualizado_em timestamp without time zone not null default now()
);

COMMIT;
