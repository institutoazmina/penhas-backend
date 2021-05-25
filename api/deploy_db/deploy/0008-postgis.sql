-- Deploy penhas:0008-postgis to pg
-- requires: 0007-view_user_preferences
CREATE EXTENSION IF NOT EXISTS postgis;

BEGIN;

ALTER TABLE ponto_apoio
    ADD COLUMN geog geography;

CREATE INDEX ponto_apoio_geog_idx ON ponto_apoio USING gist (geog);

CREATE OR REPLACE FUNCTION ft_ponto_apoio_geo_update ()
    RETURNS TRIGGER
    AS $body$
BEGIN
    UPDATE
        ponto_apoio
    SET
        geog = ST_SetSRID (ST_MakePoint (NEW.longitude, NEW.latitude), 4326)::geography
    WHERE
        id = NEW.id;
    RAISE NOTICE 'UPDATING geo data for ponto_apoio %, [%,%]', NEW.id, NEW.latitude, NEW.longitude;
    RETURN NULL;
END;
$body$
LANGUAGE plpgsql;

CREATE TRIGGER trigger_ponto_apoio_inserted
    AFTER INSERT ON ponto_apoio
    FOR EACH ROW
    EXECUTE PROCEDURE ft_ponto_apoio_geo_update ();

CREATE TRIGGER trigger_ponto_apoio_geo_updated
    AFTER UPDATE OF latitude,
    longitude ON ponto_apoio
    FOR EACH ROW
    EXECUTE PROCEDURE ft_ponto_apoio_geo_update ();

UPDATE
    ponto_apoio
SET
    latitude = latitude;


alter table ponto_apoio_categoria drop column show_on_web;


COMMIT;

