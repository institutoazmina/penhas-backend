-- Deploy penhas:0031-mf_block_clear to pg
-- requires: 0030-ja_completou_mf

BEGIN;

create table mf_questionnaire_remove_tarefa (
    id serial not null primary key,
    questionnaire_id int not null references questionnaires(id),
    codigo_tarefa varchar not null
);

COMMIT;
