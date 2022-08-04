-- Deploy penhas:0025-pa-sug-form to pg
-- requires: 0024-sugestao_ponto_apoio_2

BEGIN;

alter table ponto_apoio_sugestoes_v2 add column saved_form json not null default '{}';

COMMIT;
