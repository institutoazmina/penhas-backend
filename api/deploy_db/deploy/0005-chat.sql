-- Deploy penhas:0005-chat to pg
-- requires: 0004-AVATAR_ANONIMO_URL

BEGIN;

create table chat_session (
    id serial not null primary key,
    session_key char(30) not null,
    participants int[] not null,
    session_started_by int not null,
    created_at timestamp without time zone default now(),
    last_message_at timestamp without time zone default now(),
    last_message_by int not null
);
CREATE INDEX ix_session_by_participants ON chat_session USING GIN(participants);

create table chat_message (
    id bigserial not null primary key,
    created_at timestamp without time zone default now(),
    chat_session_id int not null references chat_session(id),
    cliente_id int not null,
    message varchar not null
);
create index ix_messages_by_time on chat_message (chat_session_id, created_at desc);


COMMIT;
