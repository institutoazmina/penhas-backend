-- Deploy penhas:0005-chat to pg
-- requires: 0004-AVATAR_ANONIMO_URL

BEGIN;

create table chat_session (
    id serial not null primary key,
    salt varchar(10) not null,
    participants int[] not null,
    created_at timestamp without time zone default now(),
    last_message_at timestamp without time zone default now()
);

create table chat_messages (
    created_at timestamp without time zone default now(),
    chat_session int not null references chat_session(id),
    message_id uuid not null,
    cliente_id int not null,
    message varchar not null,
    primary key (created_at,chat_session,message_id)
);


COMMIT;
