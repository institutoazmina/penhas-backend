-- Deploy penhas:0014-ponto_apoio_sug to pg
-- requires: 0013-clientes_activity

BEGIN;

alter table ponto_apoio_sugestoes add column status varchar not null default 'pending';

COMMIT;
