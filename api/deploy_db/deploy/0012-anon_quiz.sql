-- Deploy penhas:0012-anon_quiz to pg
-- requires: 0011-field-options

BEGIN;

create table anonymous_quiz_session (

id bigserial      not null primary key,
remote_id         varchar not null,
questionnaire_id  bigint not null references "questionnaires"(id),
finished_at       timestamp with time zone,
created_at        timestamp with time zone not null default now(),
stash             json default '{}'::json,
responses         json default '{}'::json,
deleted_at        timestamp with time zone,
deleted           boolean not null default  false
);


insert into penhas_config (name,value) values ('ANON_QUIZ_SECRET', uuid_generate_v4()::text);

alter table questionnaires add column penhas_start_automatically boolean not null default true;
alter table questionnaires add column penhas_cliente_required boolean not null default true;

insert into "questionnaires" ("id", "active", "created_on", "modified_on", "name", "owner",penhas_cliente_required,penhas_start_automatically) values
(2, false, '2021-05-31 18:31:21.186+00', '2021-05-31 18:30:31+00', 'anon-test', null, false, false);



COMMIT;
