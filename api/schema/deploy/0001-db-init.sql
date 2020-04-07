BEGIN;

CREATE TABLE penhas_config (
    id serial NOT NULL primary key,
    name character varying NOT NULL,
    value character varying NOT NULL,
    valid_from timestamp without time zone DEFAULT now() NOT NULL,
    valid_to timestamp without time zone DEFAULT 'infinity'::timestamp without time zone NOT NULL
);


CREATE UNIQUE INDEX idx_config_key ON penhas_config USING btree (name) WHERE (valid_to = 'infinity'::timestamp without time zone);


END;