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
        indexed_at = NULL;
    RETURN NULL;
END;
$body$
LANGUAGE plpgsql;

CREATE TRIGGER trigger_ponto_apoio_projeto_inserted
    AFTER INSERT OR UPDATE OR DELETE ON ponto_apoio_categoria2projetos
    FOR EACH STATEMENT
    EXECUTE PROCEDURE ft_ponto_apoio_reindex_all ();

CREATE OR REPLACE FUNCTION f_tgr_quiz_config_after_update ()
    RETURNS TRIGGER
    AS $body$
BEGIN
    update questionnaires
     set modified_on = now()
     where id = NEW.questionnaire_id OR id = OLD.questionnaire_id;
    RETURN NEW;
END;

$body$
LANGUAGE plpgsql;

CREATE TRIGGER tgr_on_quiz_config_after_update
    AFTER INSERT OR UPDATE OR DELETE ON quiz_config
    FOR EACH ROW
    EXECUTE PROCEDURE f_tgr_quiz_config_after_update ();




COMMIT;
