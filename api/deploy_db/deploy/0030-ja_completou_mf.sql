-- Deploy penhas:0030-ja_completou_mf to pg
-- requires: 0029-cliente_offline

BEGIN;

alter table clientes add column ja_completou_mf boolean default false;

COMMIT;
