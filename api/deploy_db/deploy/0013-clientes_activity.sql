-- Deploy penhas:0013-clientes_activity to pg
-- requires: 0012-anon_quiz

BEGIN;

create table clientes_app_activity_log (
    id bigserial not null primary key,
    created_at timestamp without time zone not null default now(),
    cliente_id int not null references clientes(id)
);


CREATE OR REPLACE FUNCTION public.f_tgr_clientes_app_activity_log() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    insert into clientes_app_activity_log (cliente_id, created_at)
    VALUES(NEW.cliente_id, NEW.last_activity);

    RETURN NEW;
END;
$$;

CREATE TRIGGER tgr_on_quiz_config_after_update
    AFTER INSERT OR UPDATE OR DELETE ON clientes_app_activity
    FOR EACH ROW
    EXECUTE PROCEDURE f_tgr_clientes_app_activity_log ();

COMMIT;
