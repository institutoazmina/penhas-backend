-- Deploy penhas:0018-preferences-post-as-penhas to pg
-- requires: 0017-add-tsvector
--
BEGIN;
--
ALTER TABLE preferences
    ADD COLUMN admin_only boolean NOT NULL DEFAULT FALSE;
--
INSERT INTO preferences (name, label, active, initial_value, sort, admin_only)
    VALUES ('POST_AS_PENHAS', 'Postar como PenhaS', TRUE, '0', 0, TRUE);
--
ALTER TABLE tweets
    ADD COLUMN use_penhas_avatar boolean NOT NULL DEFAULT FALSE;
--


--insert into penhas_config (name,value,valid_from,valid_to)
--values ('AVATAR_ANONIMO_URL', 'https://api.penhas.com.br/avatar/penhas_avatar.png', now(), 'infinity');

-- delete from penhas_config where "name"='AVATAR_PENHAS_URL';
insert into penhas_config (name,value,valid_from,valid_to)
values ('AVATAR_PENHAS_URL', 'https://dev-penhas-api.appcivico.com/avatar/penhas_avatar.svg', now(), 'infinity');

COMMIT;

