-- Deploy penhas:0033-texto_conta_exclusao to pg
-- requires: 0032-fix-campo_livre

BEGIN;

ALTER TABLE configuracoes ADD COLUMN texto_conta_exclusao VARCHAR;

COMMIT;
