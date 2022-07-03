-- Deploy penhas:0023-ponto_apoio_keywords_log to pg
-- requires: 0022-segment-actions
BEGIN;

CREATE TABLE ponto_apoio_keywords_log (
    id bigserial primary key not null,
    created_on timestamp without time zone,
    cliente_id int,
    keywords varchar
);

COMMIT;

