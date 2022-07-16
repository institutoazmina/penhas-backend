-- Deploy penhas:0024-sugestao_ponto_apoio_2 to pg
-- requires: 0023-ponto_apoio_keywords_log
BEGIN;

CREATE TABLE ponto_apoio_sugestoes_v2 (
    id serial NOT NULL PRIMARY KEY,
    cliente_id int REFERENCES clientes (id) NOT NULL,
    status varchar NOT NULL DEFAULT 'awaiting-moderation',
    created_on timestamp without time zone NOT NULL DEFAULT now(),
    updated_by_admin_at timestamp without time zone,
    created_ponto_apoio_id bigint REFERENCES ponto_apoio (id),
    nome varchar(255) NOT NULL,
    categoria int NOT NULL REFERENCES ponto_apoio_categoria (id),
    nome_logradouro varchar(255) NOT NULL,
    cep varchar(8),
    abrangencia varchar(255) NOT NULL,
    complemento varchar(255),
    numero varchar(255),
    bairro varchar(255),
    municipio varchar(255) NOT NULL,
    uf varchar(2) NOT NULL,
    email varchar(255),
    horario varchar(255),
    ddd1 int,
    telefone1 bigint,
    ddd2 int,
    telefone2 bigint,
    eh_24h boolean,
    has_whatsapp boolean,
    observacao varchar
);

COMMIT;

