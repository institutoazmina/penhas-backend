-- Deploy penhas:0009-trigger-ponto-apoio-reindex to pg
-- requires: 0008-postgis


BEGIN;

CREATE OR REPLACE FUNCTION ft_ponto_apoio_reindex_all ()
    RETURNS TRIGGER
    AS $body$
BEGIN
    UPDATE
        ponto_apoio
    SET
        indexed_at = NULL
    WHERE indexed_at IS NOT NULL;
    RETURN NULL;
END;
$body$
LANGUAGE plpgsql;

CREATE TRIGGER trigger_ponto_apoio_projeto_inserted
    AFTER INSERT OR UPDATE OR DELETE ON ponto_apoio_categoria2projetos
    FOR EACH ROW
    EXECUTE PROCEDURE ft_ponto_apoio_reindex_all ();

CREATE OR REPLACE FUNCTION public.f_tgr_quiz_config_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    IF (TG_OP = 'UPDATE') THEN

        update questionnaires
         set modified_on = now()
         where id = NEW.questionnaire_id OR  id = OLD.questionnaire_id;
     ELSIF (TG_OP = 'INSERT') THEN
        update questionnaires
         set modified_on = now()
         where id = NEW.questionnaire_id;
     END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER tgr_on_quiz_config_after_update
    AFTER INSERT OR UPDATE OR DELETE ON quiz_config
    FOR EACH ROW
    EXECUTE PROCEDURE f_tgr_quiz_config_after_update ();




COMMIT;
