-- Deploy penhas:0010-fix-chat_support_message to pg
-- requires: 0009-trigger-ponto-apoio-reindex

BEGIN;

alter table chat_support_message rename column admin_user_id to admin_user_id_directus8;
alter table chat_support_message add column admin_user_id uuid;

update chat_support_message set admin_user_id = (select id from directus_users limit 1) where admin_user_id_directus8 is not null;

COMMIT;
