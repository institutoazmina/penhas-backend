-- Deploy penhas:0017-add-tsvector to pg
-- requires: 0016-tweet_depth

BEGIN;

create index ix_index_tsvector_pt on ponto_apoio using gin( to_tsvector('pg_catalog.portuguese', index)  );

COMMIT;
