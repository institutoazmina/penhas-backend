-- Deploy penhas:0006-has_message to pg
-- requires: 0005-chat

BEGIN;

alter table chat_session add column has_message boolean not null default false;
update chat_session set has_message=true where id in (select chat_session_id from chat_message );

COMMIT;
