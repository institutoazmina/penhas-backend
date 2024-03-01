-- Deploy penhas:0032-fix-campo_livre to pg
-- requires: 0031-mf_block_clear

BEGIN;

alter table mf_tarefa drop column campo_livre;
alter table mf_cliente_tarefa add column campo_livre json;


COMMIT;
