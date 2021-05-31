-- Deploy penhas:0011-field-options to pg
-- requires: 0010-fix-chat_support_message

BEGIN;

alter table quiz_config add column options json;

COMMIT;
