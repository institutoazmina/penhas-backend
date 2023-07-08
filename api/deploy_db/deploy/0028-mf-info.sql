-- Deploy penhas:0028-mf-info to pg
-- requires: 0027-tarefa-padrao

BEGIN;

create unique index ix_mf_codigo_tarefa on mf_tarefa (codigo) where codigo != '';

alter table quiz_config alter column intro set default '[]',
    alter column yesnogroup set default '[]';

-- guarda a ordem preferencial dos blocos de questionarios do manual de fuga
create table mf_questionnaire_order (
    id serial not null primary key,

    sort int not null default 0,

    outstanding_order  boolean not null default false,

    is_last  boolean not null default false,

    published character varying(20) default 'testing',

    questionnaire_id int not null references questionnaires(id)
);

-- statuses:
-- onboarding
-- inProgress
-- completed
create table cliente_mf_session_control (
    cliente_id int not null references clientes(id) ON DELETE CASCADE primary key,

    status varchar not null default 'onboarding',

    current_clientes_quiz_session int references clientes_quiz_session(id),
    completed_questionnaires_id  int[] not null default '{}'::int[],

    started_at timestamp without time zone not null default now(),
    completed_at timestamp without time zone
);

-- novos tipo na quiz_config:
-- next_mf_questionnaire
-- next_mf_questionnaire_outstanding
-- auto_change_questionnaire
-- yesnomaybe
-- multiplechoice
-- tag_user
-- text << já existia, mas não tem no app

alter table quiz_config add column change_to_questionnaire_id int references questionnaires(id) default null;
alter table quiz_config add column tarefas json   not null default '[]';

-- not really mf, mas já tem uma table "tags" lá pro feed/noticias
create table mf_tag (
    id serial not null primary key,
    code varchar not null unique,
    description varchar,
    created_on timestamp without time zone not null default now()
);

create table cliente_tag (
    id serial not null primary key,

    cliente_id int not null references clientes(id) ON DELETE CASCADE,
    mf_tag_id int not null references mf_tag(id) ON DELETE CASCADE ,

    created_on timestamp without time zone not null default now()
);

alter table quiz_config add column tag json not null default '[]';
alter table quiz_config alter tag set not null;

COMMIT;
