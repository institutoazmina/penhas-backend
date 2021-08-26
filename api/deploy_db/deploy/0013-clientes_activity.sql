-- Deploy penhas:0013-clientes_activity to pg
-- requires: 0012-anon_quiz

BEGIN;

create table clientes_app_activity_log (
    id bigserial not null primary key,
    created_at timestamp without time zone not null default now(),
    cliente_id int not null references clientes(id)
);

alter table public.clientes_app_activity_log
drop constraint clientes_app_activity_log_cliente_id_fkey,
add constraint clientes_app_activity_log_cliente_id_fkey
   foreign key (cliente_id)
   references clientes(id)
   on delete cascade on update cascade;

CREATE OR REPLACE FUNCTION public.f_tgr_clientes_app_activity_log() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    insert into clientes_app_activity_log (cliente_id, created_at)
    VALUES(NEW.cliente_id, coalesce(NEW.last_activity, now()));

    RETURN NEW;
END;
$$;

drop trigger if exists tgr_on_quiz_config_after_update on clientes_app_activity ;

CREATE TRIGGER tgr_on_quiz_config_after_update
    AFTER INSERT OR UPDATE ON clientes_app_activity
    FOR EACH ROW
    EXECUTE PROCEDURE f_tgr_clientes_app_activity_log ();

COMMIT;
