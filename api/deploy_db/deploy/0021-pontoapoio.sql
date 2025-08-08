-- Deploy penhas:0021-pontoapoio to pg
-- requires: 0020-circulopenhas

BEGIN;

alter table ponto_apoio_projeto add column auto_inserir boolean not null default false;

COMMIT;
