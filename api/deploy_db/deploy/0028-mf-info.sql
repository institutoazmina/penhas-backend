-- Deploy penhas:0028-mf-info to pg
-- requires: 0027-tarefa-padrao

BEGIN;

alter table quiz_config alter column intro set default '[]',
    alter column yesnogroup set default '[]';

-- guarda a ordem preferencial dos blocos de questionarios do manual de fuga
create table mf_questionnaire_order (
    id serial not null primary key,

    sort int not null default 0,
    active boolean not null default true,

    questionnaire_id int not null references questionnaires(id)
);

-- statuses:
-- onboarding
-- inProgress
-- completed
create table cliente_mf_session_control (
    id serial not null primary key,
    cliente_id int not null references clientes(id),

    status varchar not null default 'onboarding',

    current_clientes_quiz_session int not null references clientes_quiz_session(id),
    completed_questionnaires_id  int[] not null default '{}'::int[],

    started_at timestamp without time zone not null default now(),
    completed_at timestamp without time zone
);

-- novos tipo na quiz_config:
-- next_mf_questionnaire
-- auto_change_questionnaire
-- yesnomaybe

alter table quiz_config add column change_to_questionnaire_id int references questionnaires(id);
alter table quiz_config add column tarefas json   not null default '[]';


COMMIT;
