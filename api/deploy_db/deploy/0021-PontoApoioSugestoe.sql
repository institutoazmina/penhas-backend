-- Deploy penhas:0021-PontoApoioSugestoe to pg
-- requires: 0020-relatorio_cliente_suporte

BEGIN;

alter table ponto_apoio_sugestoes
add column endereco varchar,
add column cep varchar,
add column telefone_formatted_as_national varchar,
add column telefone_e164 varchar;


COMMIT;
