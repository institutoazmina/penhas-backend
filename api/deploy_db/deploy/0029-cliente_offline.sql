-- Deploy penhas:0029-cliente_offline to pg
-- requires: 0028-mf-info

BEGIN;

alter table clientes add column qtde_login_offline int not null default 0;

COMMIT;
