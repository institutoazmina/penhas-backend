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
('NOTIFY_POST_FROM_BADGE_HOLDER_IN_MY_CITY', '', TRUE, '1', 100, FALSE),
('NOTIFY_POST_FROM_BADGE_HOLDER_FOR_LINKED_CITY', '', TRUE, '1', 110, FALSE);

UPDATE preferences
SET label = 'Posts feitos por usuárias perto de você'
WHERE name = 'NOTIFY_POST_FROM_BADGE_HOLDER_IN_MY_CITY';

UPDATE preferences
SET label = 'Posts de usuárias da sua região'
WHERE name = 'NOTIFY_POST_FROM_BADGE_HOLDER_FOR_LINKED_CITY';

create table badge_invite (
    id serial primary key,
    badge_id integer references badges(id),
    created_on timestamp not null default now(),
    modified_on timestamp not null default now(),
    admin_user_id uuid,
    cliente_id int references clientes(id),
    accepted boolean default false,
    accepted_on timestamp,
    accepted_ip inet,
    accepted_user_agent varchar(2000),
    deleted boolean default false,
    deleted_on timestamp
);

COMMIT;