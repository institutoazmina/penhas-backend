-- Deploy penhas:0003-cpf2 to pg
-- requires: 0002-emaildb

BEGIN;

drop table cpf_cache;

CREATE TABLE cpf_cache (
  cpf_hashed varchar(200) NOT NULL,
  created_at timestamp without time zone DEFAULT NULL,
  dt_nasc date NOT NULL,
  nome_hashed varchar(200) NOT NULL,
  situacao varchar(200) DEFAULT NULL,
  genero varchar(200) DEFAULT NULL,
  primary key (cpf_hashed, dt_nasc)
);

insert into penhas_config(name, value) values ('CPF_CACHE_HASH_SALT', md5(md5(random()::text)));

alter table cpf_cache add column __created_at_real timestamp without time zone not null default now();

COMMIT;
