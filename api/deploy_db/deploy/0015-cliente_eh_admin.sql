-- Deploy penhas:0015-cliente_eh_admin to pg
-- requires: 0014-ponto_apoio_sug

BEGIN;

alter table clientes add column eh_admin boolean not null default false;

COMMIT;
