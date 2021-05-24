-- Deploy penhas:0007-view_user_preferences to pg
-- requires: 0006-has_message

BEGIN;

create  or replace view view_user_preferences as
   SELECT
        p.name,
        c.id as cliente_id,
        coalesce(cp.value, p.initial_value) as value
    FROM preferences p
    CROSS JOIN clientes c
    LEFT JOIN clientes_preferences cp ON cp.cliente_id = c.id AND cp.preference_id = p.id;


COMMIT;
