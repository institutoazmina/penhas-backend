-- Deploy penhas:0022-segment-actions to pg
-- requires: 0021-PontoApoioSugestoe

BEGIN;

alter table cliente_ativacoes_panico add column estava_em_situacao_risco boolean not null default false;
alter table cliente_ativacoes_policia add column estava_em_situacao_risco boolean not null default false;
alter table clientes_guardioes add column estava_em_situacao_risco boolean not null default false;
alter table clientes_audios_eventos add column estava_em_situacao_risco boolean not null default false;

update cliente_ativacoes_panico set estava_em_situacao_risco=true where cliente_id in (select id from clientes where modo_anonimo_ativo);
update cliente_ativacoes_policia set estava_em_situacao_risco=true where cliente_id in (select id from clientes where modo_anonimo_ativo);
update clientes_guardioes set estava_em_situacao_risco=true where cliente_id in (select id from clientes where modo_anonimo_ativo);
update clientes_audios_eventos set estava_em_situacao_risco=true where cliente_id in (select id from clientes where modo_anonimo_ativo);



CREATE FUNCTION f_set_estava_em_situacao_risco() RETURNS trigger AS $emp_stamp$
    BEGIN

         NEW.estava_em_situacao_risco := (select modo_anonimo_ativo from clientes where id = new.cliente_id );

        RETURN NEW;
    END;
$emp_stamp$ LANGUAGE plpgsql;

CREATE TRIGGER tgr_cliente_ativacoes_panico_sit_risco BEFORE INSERT OR UPDATE ON cliente_ativacoes_panico
    FOR EACH ROW EXECUTE FUNCTION f_set_estava_em_situacao_risco();

CREATE TRIGGER tgr_cliente_ativacoes_policia_sit_risco BEFORE INSERT OR UPDATE ON cliente_ativacoes_policia
    FOR EACH ROW EXECUTE FUNCTION f_set_estava_em_situacao_risco();

CREATE TRIGGER tgr_clientes_guardioes_sit_risco BEFORE INSERT OR UPDATE ON clientes_guardioes
    FOR EACH ROW EXECUTE FUNCTION f_set_estava_em_situacao_risco();

CREATE TRIGGER tgr_clientes_audios_eventos_sit_risco BEFORE INSERT OR UPDATE ON clientes_audios_eventos
    FOR EACH ROW EXECUTE FUNCTION f_set_estava_em_situacao_risco();

COMMIT;
