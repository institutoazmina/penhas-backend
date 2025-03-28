-- Deploy penhas:0020-circulopenhas to pg
-- requires: 0019-municipality-sp
BEGIN;

CREATE TABLE badges (
    id serial primary key,
    code varchar(200) not null,
    name varchar(200) not null,
    description text not null,
    image_url varchar(1000) not null,
    linked_cep_cidade character varying(200),
    created_on timestamp not null default now(),
    modified_on timestamp not null default now()
);

ALTER TABLE cliente_tag ADD COLUMN badge_id integer references badges(id);
ALTER TABLE cliente_tag ALTER COLUMN mf_tag_id DROP NOT NULL;

ALTER TABLE cliente_tag ADD COLUMN valid_until timestamp without time zone not null default 'infinity';

ALTER table badges add column image_url_black varchar(1000) ;
update badges set image_url_black = image_url ;
ALTER table badges alter column image_url_black set not null;

INSERT INTO preferences (name, label, active, initial_value, sort, admin_only)
VALUES
('NOTIFY_POST_FROM_BADGE_HOLDER_IN_MY_CITY', 'Receber notificações quando alguém com um selo especial postar na minha cidade', TRUE, '1', 100, FALSE),
('NOTIFY_POST_FROM_BADGE_HOLDER_FOR_LINKED_CITY', '', TRUE, '1', 110, FALSE);

UPDATE preferences
SET label = 'Receber notificações quando alguém postar na minha região'
WHERE name = 'NOTIFY_POST_FROM_BADGE_HOLDER_FOR_LINKED_CITY';

COMMIT;