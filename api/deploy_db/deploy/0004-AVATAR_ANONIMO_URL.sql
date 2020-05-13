-- Deploy penhas:0004-AVATAR_ANONIMO_URL to pg
-- requires: 0003-cpf2

BEGIN;


insert into penhas_config(name, value)
values
('AVATAR_ANONIMO_URL','https://elasv2-api.appcivico.com/avatar/anonimo.svg'),
('AVATAR_PADRAO_URL','https://elasv2-api.appcivico.com/avatar/padrao.svg');



COMMIT;
