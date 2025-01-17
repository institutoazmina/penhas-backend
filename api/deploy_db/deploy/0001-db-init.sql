CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

BEGIN;

CREATE TYPE public.minion_state AS ENUM (
    'inactive',
    'active',
    'failed',
    'finished'
);

CREATE FUNCTION public.email_inserted_notify() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        NOTIFY newemail;
        RETURN NULL;
    END;
$$;


--
-- Name: f_set_estava_em_situacao_risco(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.f_set_estava_em_situacao_risco() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN

         NEW.estava_em_situacao_risco := (select modo_anonimo_ativo from clientes where id = new.cliente_id );

        RETURN NEW;
    END;
$$;


--
-- Name: f_tgr_clientes_app_activity_log(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.f_tgr_clientes_app_activity_log() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    insert into clientes_app_activity_log (cliente_id, created_at)
    VALUES(NEW.cliente_id, coalesce(NEW.last_activity, now()));

    RETURN NEW;
END;
$$;


--
-- Name: f_tgr_quiz_config_after_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.f_tgr_quiz_config_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    update questionnaires
     set modified_on = now()
     where id = NEW.questionnaire_id OR id = OLD.questionnaire_id;
    RETURN NEW;
END;

$$;


--
-- Name: ft_ponto_apoio_geo_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ft_ponto_apoio_geo_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: ft_ponto_apoio_reindex_all(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ft_ponto_apoio_reindex_all() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE
        ponto_apoio
    SET
        indexed_at = NULL
    WHERE indexed_at IS NOT NULL;
    RETURN NULL;
END;
$$;


--
-- Name: minion_jobs_notify_workers(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.minion_jobs_notify_workers() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  begin
    if new.delayed <= now() then
      notify "minion.job";
    end if;
    return null;
  end;
$$;


--
-- Name: minion_lock(text, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.minion_lock(text, integer, integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
declare
  new_expires timestamp with time zone = now() + (interval '1 second' * $2);
begin
  lock table minion_locks in exclusive mode;
  delete from minion_locks where expires < now();
  if (select count(*) >= $3 from minion_locks where name = $1) then
    return false;
  end if;
  if new_expires > now() then
    insert into minion_locks (name, expires) values ($1, new_expires);
  end if;
  return true;
end;
$_$;


--
-- Name: prevent_duplicate_cliente_tag(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.prevent_duplicate_cliente_tag() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Se já existe uma tag igual para o cliente, não permitir a inserção
    IF EXISTS (SELECT 1 FROM cliente_tag WHERE cliente_id = NEW.cliente_id AND mf_tag_id = NEW.mf_tag_id) THEN
        RETURN NULL;
    END IF;

    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admin_big_numbers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_big_numbers (
    id bigint NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    sort bigint,
    created_on timestamp with time zone,
    modified_on timestamp with time zone,
    label character varying(200) NOT NULL,
    comment character varying(200) DEFAULT NULL::character varying,
    sql text NOT NULL,
    background_class character varying(100) DEFAULT 'bg-light'::character varying NOT NULL,
    text_class character varying(100) DEFAULT 'text-dark'::character varying NOT NULL,
    owner_new uuid,
    modified_by_new uuid
);


--
-- Name: admin_big_numbers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_big_numbers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_big_numbers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_big_numbers_id_seq OWNED BY public.admin_big_numbers.id;


--
-- Name: admin_clientes_segments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_clientes_segments (
    id bigint NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    created_on timestamp with time zone,
    modified_on timestamp with time zone,
    is_test boolean DEFAULT false NOT NULL,
    label character varying(200) NOT NULL,
    last_count bigint,
    last_run_at timestamp with time zone,
    cond json DEFAULT '{}'::json NOT NULL,
    attr json DEFAULT '{}'::json NOT NULL,
    sort bigint DEFAULT '0'::bigint NOT NULL,
    owner uuid,
    modified_by uuid
);


--
-- Name: admin_clientes_segments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_clientes_segments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_clientes_segments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_clientes_segments_id_seq OWNED BY public.admin_clientes_segments.id;


--
-- Name: anonymous_quiz_session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.anonymous_quiz_session (
    id bigint NOT NULL,
    remote_id character varying NOT NULL,
    questionnaire_id bigint NOT NULL,
    finished_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    stash json DEFAULT '{}'::json,
    responses json DEFAULT '{}'::json,
    deleted_at timestamp with time zone,
    deleted boolean DEFAULT false NOT NULL
);


--
-- Name: anonymous_quiz_session_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.anonymous_quiz_session_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: anonymous_quiz_session_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.anonymous_quiz_session_id_seq OWNED BY public.anonymous_quiz_session.id;


--
-- Name: antigo_clientes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.antigo_clientes (
    id bigint NOT NULL,
    avatar character varying(255) DEFAULT NULL::character varying,
    nome character varying(255) DEFAULT NULL::character varying,
    apelido character varying(255) DEFAULT NULL::character varying,
    email character varying(255) DEFAULT NULL::character varying,
    cpf character varying(25) DEFAULT NULL::character varying,
    rg character varying(255) DEFAULT NULL::character varying,
    celular character varying(15) DEFAULT NULL::character varying,
    data_nascimento date,
    genero character varying(255) DEFAULT 'Personalizado'::character varying,
    cep character varying(9) DEFAULT NULL::character varying,
    endereco character varying(255) DEFAULT NULL::character varying,
    bairro character varying(255) DEFAULT NULL::character varying,
    numero character varying(255) DEFAULT NULL::character varying,
    complemento character varying(255) DEFAULT NULL::character varying,
    estado character varying(2) DEFAULT NULL::character varying,
    cidade character varying(255) DEFAULT NULL::character varying,
    status character varying(255) DEFAULT 'Ativo'::character varying NOT NULL,
    introducao text,
    senha character varying(255) DEFAULT NULL::character varying,
    senhafalsa character varying(255) DEFAULT NULL::character varying,
    icone character varying(255) DEFAULT NULL::character varying,
    exibir_audios character varying(255) DEFAULT 'Sim'::character varying NOT NULL,
    sofrendo_violencia character varying(255) DEFAULT 'Não'::character varying NOT NULL,
    data_sofrendo_violencia date,
    google_id character varying(255) DEFAULT NULL::character varying,
    facebook_id character varying(255) DEFAULT NULL::character varying,
    codigo_senha character varying(255) DEFAULT NULL::character varying,
    data_codigo_senha character varying(255) DEFAULT NULL::character varying,
    banido_chat character varying(255) DEFAULT 'Não'::character varying NOT NULL,
    grita_penha character varying(255) DEFAULT 'Não'::character varying NOT NULL,
    avaliou_delegacia character varying(255) DEFAULT 'Não'::character varying NOT NULL,
    latitude character varying(255) DEFAULT NULL::character varying,
    longitude character varying(255) DEFAULT NULL::character varying,
    latitude_atual character varying(255) DEFAULT NULL::character varying,
    longitude_atual character varying(255) DEFAULT NULL::character varying,
    quantidade_gravacoes bigint DEFAULT '0'::bigint NOT NULL,
    quantidade_190 bigint DEFAULT '0'::bigint NOT NULL,
    quantidade_sms bigint DEFAULT '0'::bigint NOT NULL,
    quantidade_mensagens bigint DEFAULT '0'::bigint NOT NULL,
    quantidade_noticias bigint DEFAULT '0'::bigint NOT NULL,
    quantidade_acionou_guardioes bigint DEFAULT '0'::bigint,
    quantidade_quiz_respondido bigint DEFAULT '0'::bigint,
    quantidade_acionou_guaridioes bigint DEFAULT '0'::bigint,
    data_cadastro timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    aparelho character varying(255) DEFAULT NULL::character varying,
    endpoint character varying(255) DEFAULT NULL::character varying,
    ip character varying(255) DEFAULT NULL::character varying,
    conta_id bigint DEFAULT '1'::bigint,
    usuario_id bigint DEFAULT '1'::bigint,
    "time" bigint,
    cpf_hashed text,
    salt_key text
);


--
-- Name: COLUMN antigo_clientes.genero; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.antigo_clientes.genero IS 'Masculino/Feminino/Personalizado';


--
-- Name: COLUMN antigo_clientes.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.antigo_clientes.status IS 'Ativo/Inativo';


--
-- Name: COLUMN antigo_clientes.exibir_audios; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.antigo_clientes.exibir_audios IS 'Sim/Não';


--
-- Name: COLUMN antigo_clientes.sofrendo_violencia; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.antigo_clientes.sofrendo_violencia IS 'Sim/Não';


--
-- Name: COLUMN antigo_clientes.banido_chat; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.antigo_clientes.banido_chat IS 'Sim/Não';


--
-- Name: antigo_clientes_guardioes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.antigo_clientes_guardioes (
    id bigint NOT NULL,
    cliente_id bigint,
    apelido character varying(255) DEFAULT NULL::character varying,
    nome character varying(255) DEFAULT NULL::character varying,
    celular character varying(15) DEFAULT NULL::character varying,
    status character varying(255) DEFAULT 'Pendente'::character varying NOT NULL,
    ip character varying(255) DEFAULT NULL::character varying,
    conta_id bigint DEFAULT '1'::bigint,
    usuario_id bigint DEFAULT '1'::bigint,
    "time" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    celular_e164 text,
    celular_formatted_as_national text,
    token text
);


--
-- Name: COLUMN antigo_clientes_guardioes.cliente_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.antigo_clientes_guardioes.cliente_id IS 'clientes';


--
-- Name: antigo_clientes_guardioes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.antigo_clientes_guardioes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: antigo_clientes_guardioes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.antigo_clientes_guardioes_id_seq OWNED BY public.antigo_clientes_guardioes.id;


--
-- Name: antigo_clientes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.antigo_clientes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: antigo_clientes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.antigo_clientes_id_seq OWNED BY public.antigo_clientes.id;


--
-- Name: chat_clientes_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_clientes_notifications (
    id bigint NOT NULL,
    cliente_id bigint NOT NULL,
    messaged_at timestamp with time zone NOT NULL,
    notification_created boolean DEFAULT false NOT NULL,
    pending_message_cliente_id bigint NOT NULL
);


--
-- Name: chat_clientes_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_clientes_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_clientes_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_clientes_notifications_id_seq OWNED BY public.chat_clientes_notifications.id;


--
-- Name: chat_message; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_message (
    id bigint NOT NULL,
    is_compressed boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    chat_session_id integer NOT NULL,
    cliente_id integer NOT NULL,
    message bytea NOT NULL
);


--
-- Name: chat_message_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_message_id_seq OWNED BY public.chat_message.id;


--
-- Name: chat_session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_session (
    id integer NOT NULL,
    session_key character(10) NOT NULL,
    participants integer[] NOT NULL,
    session_started_by integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    last_message_at timestamp without time zone DEFAULT now(),
    last_message_by integer NOT NULL,
    has_message boolean DEFAULT false NOT NULL
);


--
-- Name: chat_session_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_session_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_session_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_session_id_seq OWNED BY public.chat_session.id;


--
-- Name: chat_support; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_support (
    id bigint NOT NULL,
    cliente_id bigint NOT NULL,
    last_msg_is_support boolean DEFAULT false NOT NULL,
    last_msg_at timestamp with time zone,
    created_at timestamp with time zone,
    last_msg_preview character varying(200) DEFAULT NULL::character varying,
    last_msg_by character varying(200) DEFAULT NULL::character varying
);


--
-- Name: chat_support_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_support_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_support_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_support_id_seq OWNED BY public.chat_support.id;


--
-- Name: chat_support_message; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_support_message (
    id bigint NOT NULL,
    cliente_id bigint,
    created_at timestamp with time zone,
    chat_support_id bigint NOT NULL,
    admin_user_id_directus8 bigint,
    message text NOT NULL,
    admin_user_id uuid
);


--
-- Name: chat_support_message_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_support_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_support_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_support_message_id_seq OWNED BY public.chat_support_message.id;


--
-- Name: cliente_ativacoes_panico; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cliente_ativacoes_panico (
    id bigint NOT NULL,
    cliente_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    alert_sent_to json DEFAULT '{}'::json NOT NULL,
    gps_lat character varying(20) DEFAULT NULL::character varying,
    gps_long character varying(20) DEFAULT NULL::character varying,
    meta json DEFAULT '{}'::json,
    sms_enviados bigint DEFAULT '0'::bigint NOT NULL,
    estava_em_situacao_risco boolean DEFAULT false NOT NULL
);


--
-- Name: COLUMN cliente_ativacoes_panico.alert_sent_to; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.cliente_ativacoes_panico.alert_sent_to IS 'lista de números que o SMS foi enviado';


--
-- Name: COLUMN cliente_ativacoes_panico.sms_enviados; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.cliente_ativacoes_panico.sms_enviados IS 'número de SMS enviados';


--
-- Name: cliente_ativacoes_panico_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cliente_ativacoes_panico_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cliente_ativacoes_panico_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cliente_ativacoes_panico_id_seq OWNED BY public.cliente_ativacoes_panico.id;


--
-- Name: cliente_ativacoes_policia; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cliente_ativacoes_policia (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    cliente_id bigint NOT NULL,
    estava_em_situacao_risco boolean DEFAULT false NOT NULL
);


--
-- Name: cliente_ativacoes_policia_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cliente_ativacoes_policia_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cliente_ativacoes_policia_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cliente_ativacoes_policia_id_seq OWNED BY public.cliente_ativacoes_policia.id;


--
-- Name: cliente_bloqueios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cliente_bloqueios (
    id bigint NOT NULL,
    cliente_id bigint NOT NULL,
    blocked_cliente_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: COLUMN cliente_bloqueios.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.cliente_bloqueios.created_at IS 'horario do bloqueio';


--
-- Name: cliente_bloqueios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cliente_bloqueios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cliente_bloqueios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cliente_bloqueios_id_seq OWNED BY public.cliente_bloqueios.id;


--
-- Name: cliente_mf_session_control; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cliente_mf_session_control (
    cliente_id integer NOT NULL,
    status character varying DEFAULT 'onboarding'::character varying NOT NULL,
    current_clientes_quiz_session integer,
    completed_questionnaires_id integer[] DEFAULT '{}'::integer[] NOT NULL,
    started_at timestamp without time zone DEFAULT now() NOT NULL,
    completed_at timestamp without time zone
);


--
-- Name: cliente_ponto_apoio_avaliacao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cliente_ponto_apoio_avaliacao (
    id bigint NOT NULL,
    cliente_id bigint NOT NULL,
    ponto_apoio_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    avaliacao bigint NOT NULL
);


--
-- Name: cliente_ponto_apoio_avaliacao_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cliente_ponto_apoio_avaliacao_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cliente_ponto_apoio_avaliacao_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cliente_ponto_apoio_avaliacao_id_seq OWNED BY public.cliente_ponto_apoio_avaliacao.id;


--
-- Name: cliente_skills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cliente_skills (
    id bigint NOT NULL,
    cliente_id bigint NOT NULL,
    skill_id bigint NOT NULL
);


--
-- Name: cliente_skills_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cliente_skills_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cliente_skills_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cliente_skills_id_seq OWNED BY public.cliente_skills.id;


--
-- Name: cliente_tag; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cliente_tag (
    id integer NOT NULL,
    cliente_id integer NOT NULL,
    mf_tag_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: cliente_tag_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cliente_tag_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cliente_tag_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cliente_tag_id_seq OWNED BY public.cliente_tag.id;


--
-- Name: clientes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes (
    id bigint NOT NULL,
    status character varying(20) DEFAULT 'setup'::character varying NOT NULL,
    created_on timestamp with time zone NOT NULL,
    cpf_hash character varying(200) NOT NULL,
    cpf_prefix character varying(200) NOT NULL,
    dt_nasc date NOT NULL,
    email character varying(200) NOT NULL,
    cep character varying(8) NOT NULL,
    cep_cidade character varying(200) DEFAULT NULL::character varying,
    cep_estado character varying(200) DEFAULT NULL::character varying,
    genero character varying(100) NOT NULL,
    raca character varying(100) DEFAULT NULL::character varying,
    minibio character varying(2200) DEFAULT NULL::character varying,
    nome_completo character varying(200) NOT NULL,
    login_status character varying(20) DEFAULT 'OK'::character varying,
    login_status_last_blocked_at timestamp with time zone,
    ja_foi_vitima_de_violencia boolean,
    senha_sha256 character varying(200) NOT NULL,
    modo_camuflado_ativo boolean DEFAULT false NOT NULL,
    modo_anonimo_ativo boolean DEFAULT false NOT NULL,
    ja_foi_vitima_de_violencia_atualizado_em timestamp with time zone,
    qtde_login_senha_normal bigint DEFAULT '1'::bigint NOT NULL,
    apelido character varying(200) NOT NULL,
    nome_social character varying(200) DEFAULT NULL::character varying,
    avatar_url character varying(200) DEFAULT NULL::character varying,
    genero_outro character varying(200) DEFAULT NULL::character varying,
    upload_status character varying(20) DEFAULT 'ok'::character varying,
    qtde_ligar_para_policia bigint DEFAULT '0'::bigint NOT NULL,
    modo_anonimo_atualizado_em timestamp with time zone,
    modo_camuflado_atualizado_em timestamp with time zone,
    qtde_guardioes_ativos bigint DEFAULT '0'::bigint NOT NULL,
    salt_key character(10) NOT NULL,
    quiz_detectou_violencia boolean,
    quiz_detectou_violencia_atualizado_em timestamp with time zone,
    skills_cached text,
    perform_delete_at timestamp with time zone,
    deleted_scheduled_meta text,
    deletion_started_at timestamp with time zone,
    primeiro_quiz_detectou_violencia boolean,
    primeiro_quiz_detectou_violencia_atualizado_em timestamp with time zone,
    quiz_assistant_yes_count bigint DEFAULT '0'::bigint NOT NULL,
    private_chat_messages_sent bigint DEFAULT '0'::bigint NOT NULL,
    support_chat_messages_sent bigint DEFAULT '0'::bigint NOT NULL,
    eh_admin boolean DEFAULT false NOT NULL,
    timeline_clientes_bloqueados_ids integer[] DEFAULT '{}'::integer[] NOT NULL,
    qtde_login_offline integer DEFAULT 0 NOT NULL,
    ja_completou_mf boolean DEFAULT false
);


--
-- Name: COLUMN clientes.dt_nasc; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes.dt_nasc IS 'data nascimento';


--
-- Name: COLUMN clientes.login_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes.login_status IS 'pode ou nao fazer login';


--
-- Name: COLUMN clientes.login_status_last_blocked_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes.login_status_last_blocked_at IS 'Horrio que iniciou-se o ltimo bloqueio de 24h, pelo sistema';


--
-- Name: COLUMN clientes.ja_foi_vitima_de_violencia; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes.ja_foi_vitima_de_violencia IS 'Se j foi vima de violncia';


--
-- Name: COLUMN clientes.modo_camuflado_ativo; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes.modo_camuflado_ativo IS 'Se est com o modo camuflado ativo';


--
-- Name: COLUMN clientes.modo_anonimo_ativo; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes.modo_anonimo_ativo IS 'Se j est com o modo anonimo ativado';


--
-- Name: COLUMN clientes.qtde_login_senha_normal; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes.qtde_login_senha_normal IS 'quantidade de login normal';


--
-- Name: COLUMN clientes.qtde_ligar_para_policia; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes.qtde_ligar_para_policia IS 'quantidade de ativações do botão de ligar para policia';


--
-- Name: COLUMN clientes.qtde_guardioes_ativos; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes.qtde_guardioes_ativos IS 'número de guardiões ativos no momento';


--
-- Name: COLUMN clientes.salt_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes.salt_key IS 'campo onde é salvo o salt para usar junto com a chave. se mudar ou for perdido, os chats e audios não são mais legíveis.';


--
-- Name: COLUMN clientes.perform_delete_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes.perform_delete_at IS 'Preencher YYYY-MM-DD HH:MM:SS com segundos (ou não ficará salvo)';


--
-- Name: COLUMN clientes.quiz_assistant_yes_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes.quiz_assistant_yes_count IS 'número de vezes que o usuário respondeu "sim" para refazer o quiz no assitente.';


--
-- Name: clientes_active_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes_active_sessions (
    id bigint NOT NULL,
    cliente_id bigint NOT NULL
);


--
-- Name: clientes_active_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_active_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_active_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_active_sessions_id_seq OWNED BY public.clientes_active_sessions.id;


--
-- Name: clientes_app_activity; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes_app_activity (
    id bigint NOT NULL,
    cliente_id bigint NOT NULL,
    last_tm_activity timestamp with time zone,
    last_activity timestamp with time zone
);


--
-- Name: clientes_app_activity_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_app_activity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_app_activity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_app_activity_id_seq OWNED BY public.clientes_app_activity.id;


--
-- Name: clientes_app_activity_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes_app_activity_log (
    id bigint NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    cliente_id integer NOT NULL
);


--
-- Name: clientes_app_activity_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_app_activity_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_app_activity_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_app_activity_log_id_seq OWNED BY public.clientes_app_activity_log.id;


--
-- Name: clientes_app_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes_app_notifications (
    id bigint NOT NULL,
    cliente_id bigint NOT NULL,
    read_until timestamp with time zone NOT NULL
);


--
-- Name: clientes_app_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_app_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_app_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_app_notifications_id_seq OWNED BY public.clientes_app_notifications.id;


--
-- Name: clientes_audios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes_audios (
    id bigint NOT NULL,
    cliente_id bigint NOT NULL,
    played_count bigint DEFAULT '0'::bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    cliente_created_at timestamp with time zone NOT NULL,
    media_upload_id character varying(200) NOT NULL,
    event_id character varying(200) NOT NULL,
    event_sequence integer NOT NULL,
    waveform_base64 text,
    audio_duration double precision NOT NULL,
    duplicated_upload boolean DEFAULT false NOT NULL,
    first_downloaded_at timestamp with time zone
);


--
-- Name: clientes_audios_eventos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes_audios_eventos (
    cliente_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    event_id character varying(200) NOT NULL,
    audio_duration numeric(10,5) NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    status character varying(20) DEFAULT 'free_access'::character varying NOT NULL,
    requested_by_user boolean DEFAULT false NOT NULL,
    total_bytes bigint DEFAULT '0'::bigint NOT NULL,
    last_cliente_created_at timestamp with time zone NOT NULL,
    requested_by_user_at timestamp with time zone,
    deleted_at timestamp with time zone,
    estava_em_situacao_risco boolean DEFAULT false NOT NULL
);


--
-- Name: COLUMN clientes_audios_eventos.deleted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes_audios_eventos.deleted_at IS 'se o usuario apagar o audio, essa coluna é preenchida';


--
-- Name: clientes_audios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_audios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_audios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_audios_id_seq OWNED BY public.clientes_audios.id;


--
-- Name: clientes_guardioes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes_guardioes (
    id bigint NOT NULL,
    cliente_id bigint NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    celular_e164 character varying(25) NOT NULL,
    nome character varying(200) NOT NULL,
    token character varying(200) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    accepted_at timestamp with time zone,
    accepted_meta text DEFAULT '{}'::text NOT NULL,
    celular_formatted_as_national character varying(25) NOT NULL,
    refused_at timestamp with time zone,
    deleted_at timestamp with time zone,
    expires_at timestamp with time zone NOT NULL,
    estava_em_situacao_risco boolean DEFAULT false NOT NULL
);


--
-- Name: COLUMN clientes_guardioes.celular_e164; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes_guardioes.celular_e164 IS 'celular em formatado em E.164';


--
-- Name: COLUMN clientes_guardioes.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes_guardioes.created_at IS 'até que dia o convite está valido para ser usado antes de expirar.';


--
-- Name: COLUMN clientes_guardioes.accepted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes_guardioes.accepted_at IS 'até que dia o convite está valido para ser usado antes de expirar.';


--
-- Name: COLUMN clientes_guardioes.accepted_meta; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes_guardioes.accepted_meta IS 'informações sobre o computador/celular de quem aceitou';


--
-- Name: COLUMN clientes_guardioes.celular_formatted_as_national; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes_guardioes.celular_formatted_as_national IS 'celular em formatado de acordo com o pais';


--
-- Name: COLUMN clientes_guardioes.refused_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes_guardioes.refused_at IS 'data/hora que foi recusado';


--
-- Name: COLUMN clientes_guardioes.deleted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes_guardioes.deleted_at IS 'data/hora que foi apagado pelo usuário';


--
-- Name: COLUMN clientes_guardioes.expires_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes_guardioes.expires_at IS 'até que dia o convite está valido para ser usado antes de expirar.';


--
-- Name: clientes_guardioes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_guardioes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_guardioes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_guardioes_id_seq OWNED BY public.clientes_guardioes.id;


--
-- Name: clientes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_id_seq OWNED BY public.clientes.id;


--
-- Name: clientes_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes_preferences (
    id bigint NOT NULL,
    value character varying(200) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    cliente_id bigint NOT NULL,
    preference_id bigint NOT NULL
);


--
-- Name: clientes_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_preferences_id_seq OWNED BY public.clientes_preferences.id;


--
-- Name: clientes_quiz_session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes_quiz_session (
    id bigint NOT NULL,
    cliente_id bigint NOT NULL,
    questionnaire_id bigint NOT NULL,
    finished_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL,
    stash json DEFAULT '{}'::json,
    responses json DEFAULT '{}'::json,
    deleted_at timestamp with time zone,
    deleted boolean DEFAULT false NOT NULL
);


--
-- Name: COLUMN clientes_quiz_session.deleted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes_quiz_session.deleted_at IS 'horario que o usuario pediu para refazer';


--
-- Name: clientes_quiz_session_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_quiz_session_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_quiz_session_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_quiz_session_id_seq OWNED BY public.clientes_quiz_session.id;


--
-- Name: clientes_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes_reports (
    id bigint NOT NULL,
    cliente_id integer NOT NULL,
    reported_cliente_id integer NOT NULL,
    reason character varying(200) NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: clientes_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_reports_id_seq OWNED BY public.clientes_reports.id;


--
-- Name: clientes_reset_password; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes_reset_password (
    id bigint NOT NULL,
    cliente_id bigint NOT NULL,
    token character varying(200) NOT NULL,
    valid_until timestamp with time zone NOT NULL,
    used_at timestamp with time zone,
    requested_by_remote_ip character varying(200) NOT NULL,
    used_by_remote_ip character varying(200) DEFAULT NULL::character varying,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: clientes_reset_password_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_reset_password_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_reset_password_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_reset_password_id_seq OWNED BY public.clientes_reset_password.id;


--
-- Name: configuracoes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configuracoes (
    id bigint NOT NULL,
    termos_de_uso text NOT NULL,
    privacidade text NOT NULL,
    texto_faq_index text,
    texto_faq_contato text,
    texto_conta_exclusao character varying
);


--
-- Name: configuracoes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.configuracoes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: configuracoes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.configuracoes_id_seq OWNED BY public.configuracoes.id;


--
-- Name: cpf_cache; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cpf_cache (
    cpf_hashed character varying(200) NOT NULL,
    created_at timestamp without time zone,
    dt_nasc date NOT NULL,
    nome_hashed character varying(200) NOT NULL,
    situacao character varying(200) DEFAULT NULL::character varying,
    genero character varying(200) DEFAULT NULL::character varying,
    __created_at_real timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: cpf_erros; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cpf_erros (
    id bigint NOT NULL,
    cpf_hash character varying(200) NOT NULL,
    cpf_start character varying(200) NOT NULL,
    count bigint DEFAULT '1'::bigint NOT NULL,
    reset_at timestamp with time zone NOT NULL,
    remote_ip character varying(200) NOT NULL
);


--
-- Name: cpf_erros_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cpf_erros_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cpf_erros_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cpf_erros_id_seq OWNED BY public.cpf_erros.id;


--
-- Name: delete_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delete_log (
    id bigint NOT NULL,
    data json DEFAULT '{}'::json NOT NULL,
    email_md5 character varying(200) NOT NULL,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: delete_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.delete_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delete_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.delete_log_id_seq OWNED BY public.delete_log.id;


--
-- Name: emaildb_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.emaildb_config (
    id integer NOT NULL,
    "from" character varying NOT NULL,
    template_resolver_class character varying(60) NOT NULL,
    template_resolver_config json DEFAULT '{}'::json NOT NULL,
    email_transporter_class character varying(60) NOT NULL,
    email_transporter_config json DEFAULT '{}'::json NOT NULL,
    delete_after interval DEFAULT '7 days'::interval NOT NULL
);


--
-- Name: emaildb_config_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.emaildb_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: emaildb_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.emaildb_config_id_seq OWNED BY public.emaildb_config.id;


--
-- Name: emaildb_queue; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.emaildb_queue (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    config_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    template character varying NOT NULL,
    "to" character varying NOT NULL,
    subject character varying NOT NULL,
    variables json NOT NULL,
    sent boolean,
    updated_at timestamp without time zone,
    visible_after timestamp without time zone,
    errmsg character varying
);


--
-- Name: faq_tela_guardiao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.faq_tela_guardiao (
    id bigint NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    sort bigint,
    created_on timestamp with time zone,
    modified_on timestamp with time zone,
    title text NOT NULL,
    content_html text NOT NULL,
    owner uuid,
    modified_by uuid
);


--
-- Name: COLUMN faq_tela_guardiao.title; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.faq_tela_guardiao.title IS 'Titulo para pergunta';


--
-- Name: COLUMN faq_tela_guardiao.content_html; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.faq_tela_guardiao.content_html IS 'HTML da resposta';


--
-- Name: faq_tela_guardiao_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.faq_tela_guardiao_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: faq_tela_guardiao_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.faq_tela_guardiao_id_seq OWNED BY public.faq_tela_guardiao.id;


--
-- Name: faq_tela_sobre; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.faq_tela_sobre (
    id bigint NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    sort bigint,
    created_on timestamp with time zone,
    modified_on timestamp with time zone,
    title text,
    content_html text NOT NULL,
    fts_categoria_id bigint NOT NULL,
    exibir_titulo_inline boolean DEFAULT false,
    owner uuid,
    modified_by uuid
);


--
-- Name: faq_tela_sobre_categoria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.faq_tela_sobre_categoria (
    id bigint NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    sort bigint,
    created_on timestamp with time zone,
    modified_on timestamp with time zone,
    title text NOT NULL,
    is_test boolean DEFAULT false NOT NULL,
    owner uuid,
    modified_by uuid
);


--
-- Name: faq_tela_sobre_categoria_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.faq_tela_sobre_categoria_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: faq_tela_sobre_categoria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.faq_tela_sobre_categoria_id_seq OWNED BY public.faq_tela_sobre_categoria.id;


--
-- Name: faq_tela_sobre_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.faq_tela_sobre_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: faq_tela_sobre_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.faq_tela_sobre_id_seq OWNED BY public.faq_tela_sobre.id;


--
-- Name: geo_cache; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.geo_cache (
    id bigint NOT NULL,
    key character varying(200) NOT NULL,
    value character varying(200) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    valid_until timestamp with time zone NOT NULL
);


--
-- Name: geo_cache_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.geo_cache_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: geo_cache_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.geo_cache_id_seq OWNED BY public.geo_cache.id;


--
-- Name: login_erros; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.login_erros (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    remote_ip character varying(200) NOT NULL,
    cliente_id bigint NOT NULL
);


--
-- Name: login_erros_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.login_erros_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: login_erros_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.login_erros_id_seq OWNED BY public.login_erros.id;


--
-- Name: login_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.login_logs (
    id bigint NOT NULL,
    remote_ip character varying(200) NOT NULL,
    cliente_id bigint,
    app_version character varying(800) DEFAULT NULL::character varying,
    created_at timestamp with time zone
);


--
-- Name: login_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.login_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: login_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.login_logs_id_seq OWNED BY public.login_logs.id;


--
-- Name: media_upload; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.media_upload (
    id character varying(200) NOT NULL,
    file_info text,
    file_sha1 character varying(200) NOT NULL,
    file_size bigint,
    s3_path text NOT NULL,
    cliente_id bigint NOT NULL,
    intention character varying(200) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    s3_path_avatar text,
    file_size_avatar bigint
);


--
-- Name: COLUMN media_upload.file_sha1; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.media_upload.file_sha1 IS 'SHA1 do arquivo original (upload); não é o SHA1 dos arquivos do S3';


--
-- Name: mf_cliente_tarefa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mf_cliente_tarefa (
    id integer NOT NULL,
    mf_tarefa_id integer NOT NULL,
    cliente_id bigint NOT NULL,
    checkbox_feito boolean DEFAULT false NOT NULL,
    checkbox_feito_checked_first_updated_at timestamp without time zone,
    checkbox_feito_checked_last_updated_at timestamp without time zone,
    checkbox_feito_unchecked_first_updated_at timestamp without time zone,
    checkbox_feito_unchecked_last_updated_at timestamp without time zone,
    criado_em timestamp without time zone DEFAULT now() NOT NULL,
    removido_em timestamp without time zone,
    last_from_questionnaire integer,
    atualizado_em timestamp without time zone DEFAULT now() NOT NULL,
    campo_livre json
);


--
-- Name: mf_cliente_tarefa_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mf_cliente_tarefa_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mf_cliente_tarefa_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mf_cliente_tarefa_id_seq OWNED BY public.mf_cliente_tarefa.id;


--
-- Name: mf_questionnaire_order; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mf_questionnaire_order (
    id integer NOT NULL,
    sort integer DEFAULT 0 NOT NULL,
    outstanding_order boolean DEFAULT false NOT NULL,
    is_last boolean DEFAULT false NOT NULL,
    published character varying(20) DEFAULT 'testing'::character varying,
    questionnaire_id integer NOT NULL
);


--
-- Name: mf_questionnaire_order_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mf_questionnaire_order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mf_questionnaire_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mf_questionnaire_order_id_seq OWNED BY public.mf_questionnaire_order.id;


--
-- Name: mf_questionnaire_remove_tarefa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mf_questionnaire_remove_tarefa (
    id integer NOT NULL,
    questionnaire_id integer NOT NULL,
    codigo_tarefa character varying NOT NULL
);


--
-- Name: mf_questionnaire_remove_tarefa_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mf_questionnaire_remove_tarefa_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mf_questionnaire_remove_tarefa_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mf_questionnaire_remove_tarefa_id_seq OWNED BY public.mf_questionnaire_remove_tarefa.id;


--
-- Name: mf_tag; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mf_tag (
    id integer NOT NULL,
    code character varying NOT NULL,
    description character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: mf_tag_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mf_tag_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mf_tag_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mf_tag_id_seq OWNED BY public.mf_tag.id;


--
-- Name: mf_tarefa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mf_tarefa (
    id integer NOT NULL,
    titulo character varying NOT NULL,
    descricao character varying NOT NULL,
    tipo character varying DEFAULT 'checkbox'::character varying NOT NULL,
    codigo character varying,
    agrupador character varying(120) DEFAULT 'Outros'::character varying NOT NULL,
    criado_em timestamp without time zone DEFAULT now() NOT NULL,
    eh_customizada boolean DEFAULT false NOT NULL
);


--
-- Name: mf_tarefa_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mf_tarefa_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mf_tarefa_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mf_tarefa_id_seq OWNED BY public.mf_tarefa.id;


--
-- Name: minion_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.minion_jobs (
    id bigint NOT NULL,
    args jsonb NOT NULL,
    attempts integer DEFAULT 1 NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    delayed timestamp with time zone NOT NULL,
    finished timestamp with time zone,
    notes jsonb DEFAULT '{}'::jsonb NOT NULL,
    parents bigint[] DEFAULT '{}'::bigint[] NOT NULL,
    priority integer NOT NULL,
    queue text DEFAULT 'default'::text NOT NULL,
    result jsonb,
    retried timestamp with time zone,
    retries integer DEFAULT 0 NOT NULL,
    started timestamp with time zone,
    state public.minion_state DEFAULT 'inactive'::public.minion_state NOT NULL,
    task text NOT NULL,
    worker bigint,
    expires timestamp with time zone,
    lax boolean DEFAULT false NOT NULL,
    CONSTRAINT minion_jobs_args_check CHECK ((jsonb_typeof(args) = 'array'::text)),
    CONSTRAINT minion_jobs_notes_check CHECK ((jsonb_typeof(notes) = 'object'::text))
);


--
-- Name: minion_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.minion_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: minion_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.minion_jobs_id_seq OWNED BY public.minion_jobs.id;


--
-- Name: minion_locks; Type: TABLE; Schema: public; Owner: -
--

CREATE UNLOGGED TABLE public.minion_locks (
    id bigint NOT NULL,
    name text NOT NULL,
    expires timestamp with time zone NOT NULL
);


--
-- Name: minion_locks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.minion_locks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: minion_locks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.minion_locks_id_seq OWNED BY public.minion_locks.id;


--
-- Name: minion_workers; Type: TABLE; Schema: public; Owner: -
--

CREATE UNLOGGED TABLE public.minion_workers (
    id bigint NOT NULL,
    host text NOT NULL,
    inbox jsonb DEFAULT '[]'::jsonb NOT NULL,
    notified timestamp with time zone DEFAULT now() NOT NULL,
    pid integer NOT NULL,
    started timestamp with time zone DEFAULT now() NOT NULL,
    status jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT minion_workers_inbox_check CHECK ((jsonb_typeof(inbox) = 'array'::text)),
    CONSTRAINT minion_workers_status_check CHECK ((jsonb_typeof(status) = 'object'::text))
);


--
-- Name: minion_workers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.minion_workers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: minion_workers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.minion_workers_id_seq OWNED BY public.minion_workers.id;


--
-- Name: mojo_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mojo_migrations (
    name text NOT NULL,
    version bigint NOT NULL,
    CONSTRAINT mojo_migrations_version_check CHECK ((version >= 0))
);


--
-- Name: municipalities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.municipalities (
    ogc_fid integer NOT NULL,
    id character varying,
    cd_mun character varying,
    nm_mun character varying,
    sigla_uf character varying,
    area_km2 double precision,
    wkb_geometry public.geometry
);


--
-- Name: municipalities_ogc_fid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.municipalities_ogc_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: municipalities_ogc_fid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.municipalities_ogc_fid_seq OWNED BY public.municipalities.ogc_fid;


--
-- Name: noticias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.noticias (
    id bigint NOT NULL,
    title character varying(2000) NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    display_created_time timestamp with time zone NOT NULL,
    hyperlink character varying,
    indexed boolean DEFAULT false NOT NULL,
    indexed_at timestamp with time zone,
    rss_feed_id bigint,
    author character varying(200) DEFAULT NULL::character varying,
    info json DEFAULT '{}'::json NOT NULL,
    fonte character varying,
    published character varying(20) DEFAULT 'hidden'::character varying,
    logs text,
    image_hyperlink character varying,
    tags_index character varying(2000) DEFAULT ',,'::character varying NOT NULL,
    has_topic_tags boolean DEFAULT false NOT NULL
);


--
-- Name: COLUMN noticias.author; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.noticias.author IS 'campo author quando que vem no feed';


--
-- Name: COLUMN noticias.info; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.noticias.info IS 'JSON com informações para o tagamento automatico';


--
-- Name: COLUMN noticias.fonte; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.noticias.fonte IS 'campo author quando que vem no feed';


--
-- Name: COLUMN noticias.image_hyperlink; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.noticias.image_hyperlink IS 'URL para a imagem (extraída do metameta[property="og:image"] no caso do feed]';


--
-- Name: noticias_aberturas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.noticias_aberturas (
    id bigint NOT NULL,
    noticias_id bigint NOT NULL,
    cliente_id bigint NOT NULL,
    track_id character varying(200) NOT NULL,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: COLUMN noticias_aberturas.track_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.noticias_aberturas.track_id IS 'id do link gerado, se tiver repetido em menos de 1h, pro mesmo user/noticia, clicou mais de uma vez';


--
-- Name: noticias_aberturas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.noticias_aberturas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: noticias_aberturas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.noticias_aberturas_id_seq OWNED BY public.noticias_aberturas.id;


--
-- Name: noticias_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.noticias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: noticias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.noticias_id_seq OWNED BY public.noticias.id;


--
-- Name: noticias_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.noticias_tags (
    id integer NOT NULL,
    noticias_id bigint,
    tags_id bigint
);


--
-- Name: noticias_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.noticias_tags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: noticias_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.noticias_tags_id_seq OWNED BY public.noticias_tags.id;


--
-- Name: noticias_vitrine; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.noticias_vitrine (
    id bigint NOT NULL,
    status character varying(20) DEFAULT 'prod'::character varying NOT NULL,
    noticias text DEFAULT '[]'::text NOT NULL,
    "order" bigint DEFAULT '0'::bigint NOT NULL,
    meta text DEFAULT '{}'::text NOT NULL,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: noticias_vitrine_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.noticias_vitrine_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: noticias_vitrine_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.noticias_vitrine_id_seq OWNED BY public.noticias_vitrine.id;


--
-- Name: notification_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_log (
    id bigint NOT NULL,
    created_at timestamp with time zone,
    cliente_id bigint NOT NULL,
    notification_message_id bigint NOT NULL
);


--
-- Name: notification_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notification_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notification_log_id_seq OWNED BY public.notification_log.id;


--
-- Name: notification_message; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_message (
    id bigint NOT NULL,
    is_test boolean DEFAULT true NOT NULL,
    title text NOT NULL,
    content text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    meta text DEFAULT '{}'::text NOT NULL,
    subject_id bigint,
    icon bigint
);


--
-- Name: notification_message_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notification_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notification_message_id_seq OWNED BY public.notification_message.id;


--
-- Name: penhas_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.penhas_config (
    id integer NOT NULL,
    name character varying NOT NULL,
    value character varying NOT NULL,
    valid_from timestamp without time zone DEFAULT now() NOT NULL,
    valid_to timestamp without time zone DEFAULT 'infinity'::timestamp without time zone NOT NULL
);


--
-- Name: penhas_config_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.penhas_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: penhas_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.penhas_config_id_seq OWNED BY public.penhas_config.id;


--
-- Name: ponto_apoio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ponto_apoio (
    id bigint NOT NULL,
    status character varying(20) DEFAULT 'disabled'::character varying NOT NULL,
    created_on timestamp with time zone NOT NULL,
    nome character varying(255) NOT NULL,
    sigla character varying(10) DEFAULT NULL::character varying,
    natureza character varying(20) NOT NULL,
    categoria bigint NOT NULL,
    descricao text,
    tipo_logradouro character varying(20) NOT NULL,
    nome_logradouro character varying(255) NOT NULL,
    numero bigint,
    numero_sem_numero boolean DEFAULT false NOT NULL,
    complemento character varying(255) DEFAULT NULL::character varying,
    bairro character varying(255) NOT NULL,
    municipio character varying(255) NOT NULL,
    uf character varying(2) NOT NULL,
    cep character varying(8) NOT NULL,
    ddd bigint,
    telefone1 bigint,
    telefone2 bigint,
    email character varying(255) DEFAULT NULL::character varying,
    eh_24h boolean DEFAULT false,
    horario_inicio character varying(5) DEFAULT NULL::character varying,
    horario_fim character varying(5) DEFAULT NULL::character varying,
    dias_funcionamento character varying(25) DEFAULT NULL::character varying,
    eh_presencial boolean DEFAULT false,
    eh_online boolean DEFAULT false,
    funcionamento_pandemia boolean DEFAULT false,
    observacao_pandemia text,
    latitude numeric(22,6) DEFAULT NULL::numeric,
    longitude numeric(22,6) DEFAULT NULL::numeric,
    ja_passou_por_moderacao boolean DEFAULT false NOT NULL,
    avaliacao double precision DEFAULT '0'::double precision NOT NULL,
    test_status character varying(20) DEFAULT 'prod'::character varying NOT NULL,
    cliente_id bigint,
    qtde_avaliacao bigint DEFAULT '0'::bigint NOT NULL,
    observacao text,
    horario_correto boolean DEFAULT false,
    delegacia_mulher boolean DEFAULT false,
    endereco_correto boolean DEFAULT false,
    telefone_correto boolean DEFAULT false,
    existe_delegacia boolean DEFAULT false,
    eh_importacao boolean DEFAULT false,
    updated_at timestamp with time zone NOT NULL,
    indexed_at timestamp with time zone,
    index text,
    geog public.geography,
    owner uuid,
    abrangencia character varying NOT NULL,
    eh_whatsapp boolean DEFAULT false NOT NULL,
    ramal1 bigint,
    ramal2 bigint,
    cod_ibge bigint,
    fonte character varying
);


--
-- Name: COLUMN ponto_apoio.sigla; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ponto_apoio.sigla IS 'Utilizar apenas letras maiúsculas';


--
-- Name: COLUMN ponto_apoio.uf; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ponto_apoio.uf IS 'Utilizar sigla padrão para estados (duas letras maiúsculas)';


--
-- Name: COLUMN ponto_apoio.ddd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ponto_apoio.ddd IS 'Utilizar apenas 2 números inteiros, sem espaços, vírgulas, hífens, pontos, etc.';


--
-- Name: COLUMN ponto_apoio.telefone1; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ponto_apoio.telefone1 IS 'Utilizar apenas 8 ou 9 números inteiros, sem espaços, vírgulas, hífens, pontos, etc.';


--
-- Name: COLUMN ponto_apoio.telefone2; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ponto_apoio.telefone2 IS 'Utilizar apenas 8 ou 9 números inteiros, sem espaços, vírgulas, hífens, pontos, etc.';


--
-- Name: COLUMN ponto_apoio.email; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ponto_apoio.email IS 'Utilizar apenas letras minúsculas e não utilizar acentos.  Preencher somente com hífen - quando não for informada. Formato: nome@provedor.bla.br';


--
-- Name: COLUMN ponto_apoio.observacao_pandemia; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ponto_apoio.observacao_pandemia IS 'Descrição do que mudou no atendimento um função da pandemia.';


--
-- Name: COLUMN ponto_apoio.observacao; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ponto_apoio.observacao IS 'Descrição do que mudou no atendimento um função da pandemia.';


--
-- Name: ponto_apoio2projetos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ponto_apoio2projetos (
    ponto_apoio_id integer NOT NULL,
    ponto_apoio_projeto_id integer NOT NULL
);


--
-- Name: ponto_apoio_categoria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ponto_apoio_categoria (
    id bigint NOT NULL,
    status character varying(20) DEFAULT 'prod'::character varying NOT NULL,
    created_on timestamp with time zone,
    label character varying(200) NOT NULL,
    color character varying(7) DEFAULT '#000000'::character varying NOT NULL,
    owner uuid
);


--
-- Name: ponto_apoio_categoria_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ponto_apoio_categoria_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ponto_apoio_categoria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ponto_apoio_categoria_id_seq OWNED BY public.ponto_apoio_categoria.id;


--
-- Name: ponto_apoio_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ponto_apoio_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ponto_apoio_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ponto_apoio_id_seq OWNED BY public.ponto_apoio.id;


--
-- Name: ponto_apoio_keywords_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ponto_apoio_keywords_log (
    id bigint NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    cliente_id integer,
    keywords character varying NOT NULL
);


--
-- Name: ponto_apoio_keywords_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ponto_apoio_keywords_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ponto_apoio_keywords_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ponto_apoio_keywords_log_id_seq OWNED BY public.ponto_apoio_keywords_log.id;


--
-- Name: ponto_apoio_projeto; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ponto_apoio_projeto (
    id bigint NOT NULL,
    status character varying(20) DEFAULT 'prod'::character varying NOT NULL,
    created_on timestamp with time zone,
    label character varying(200) NOT NULL,
    owner uuid
);


--
-- Name: ponto_apoio_projeto_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ponto_apoio_projeto_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ponto_apoio_projeto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ponto_apoio_projeto_id_seq OWNED BY public.ponto_apoio_projeto.id;


--
-- Name: ponto_apoio_sugestoes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ponto_apoio_sugestoes (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    endereco_ou_cep character varying(200) NOT NULL,
    nome character varying(255) NOT NULL,
    categoria bigint NOT NULL,
    descricao_servico text NOT NULL,
    cliente_id bigint NOT NULL,
    metainfo json DEFAULT '{}'::json NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    endereco character varying,
    cep character varying,
    telefone_formatted_as_national character varying,
    telefone_e164 character varying
);


--
-- Name: ponto_apoio_sugestoes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ponto_apoio_sugestoes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ponto_apoio_sugestoes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ponto_apoio_sugestoes_id_seq OWNED BY public.ponto_apoio_sugestoes.id;


--
-- Name: ponto_apoio_sugestoes_v2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ponto_apoio_sugestoes_v2 (
    id integer NOT NULL,
    cliente_id integer NOT NULL,
    status character varying DEFAULT 'awaiting-moderation'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by_admin_at timestamp without time zone,
    created_ponto_apoio_id bigint,
    nome character varying(255) NOT NULL,
    categoria integer NOT NULL,
    nome_logradouro character varying(255) NOT NULL,
    cep character varying(8),
    abrangencia character varying(255) NOT NULL,
    complemento character varying(255),
    numero character varying(255),
    bairro character varying(255),
    municipio character varying(255) NOT NULL,
    uf character varying(2) NOT NULL,
    email character varying(255),
    horario character varying(255),
    ddd1 integer,
    telefone1 bigint,
    ddd2 integer,
    telefone2 bigint,
    eh_24h boolean,
    has_whatsapp boolean,
    observacao character varying,
    metainfo json DEFAULT '{}'::json NOT NULL,
    saved_form json DEFAULT '{}'::json NOT NULL
);


--
-- Name: ponto_apoio_sugestoes_v2_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ponto_apoio_sugestoes_v2_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ponto_apoio_sugestoes_v2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ponto_apoio_sugestoes_v2_id_seq OWNED BY public.ponto_apoio_sugestoes_v2.id;


--
-- Name: preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.preferences (
    id bigint NOT NULL,
    name character varying(200) NOT NULL,
    label character varying(200) NOT NULL,
    active boolean NOT NULL,
    initial_value character varying(200) NOT NULL,
    sort bigint DEFAULT '1'::bigint NOT NULL,
    admin_only boolean DEFAULT false NOT NULL
);


--
-- Name: preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.preferences_id_seq OWNED BY public.preferences.id;


--
-- Name: private_chat_session_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.private_chat_session_metadata (
    id bigint NOT NULL,
    cliente_id bigint NOT NULL,
    other_cliente_id bigint NOT NULL,
    started_at date NOT NULL
);


--
-- Name: private_chat_session_metadata_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.private_chat_session_metadata_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: private_chat_session_metadata_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.private_chat_session_metadata_id_seq OWNED BY public.private_chat_session_metadata.id;


--
-- Name: questionnaires; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.questionnaires (
    id bigint NOT NULL,
    created_on timestamp with time zone,
    modified_on timestamp with time zone,
    active boolean NOT NULL,
    name character varying(200) NOT NULL,
    condition character varying(2000) DEFAULT '0'::character varying NOT NULL,
    end_screen character varying(200) DEFAULT 'home'::character varying NOT NULL,
    owner uuid,
    modified_by uuid,
    penhas_start_automatically boolean DEFAULT true NOT NULL,
    penhas_cliente_required boolean DEFAULT true NOT NULL
);


--
-- Name: COLUMN questionnaires.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.questionnaires.name IS 'Nome interno';


--
-- Name: COLUMN questionnaires.condition; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.questionnaires.condition IS 'Pra quem deve aparecer';


--
-- Name: questionnaires_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.questionnaires_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: questionnaires_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.questionnaires_id_seq OWNED BY public.questionnaires.id;


--
-- Name: quiz_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quiz_config (
    id bigint NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    sort bigint,
    modified_on timestamp with time zone,
    type character varying(100) NOT NULL,
    code character varying NOT NULL,
    question character varying(800) NOT NULL,
    questionnaire_id bigint NOT NULL,
    yesnogroup json DEFAULT '[]'::json,
    intro json DEFAULT '[]'::json,
    relevance character varying(2000) DEFAULT '1'::character varying NOT NULL,
    button_label character varying(200) DEFAULT NULL::character varying,
    modified_by uuid,
    options json,
    change_to_questionnaire_id integer,
    tarefas json DEFAULT '[]'::json NOT NULL,
    tag json DEFAULT '[]'::json NOT NULL
);


--
-- Name: COLUMN quiz_config.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quiz_config.code IS 'Identificador da resposta, precisa iniciar com A-Z, depois A-Z0-9 e _';


--
-- Name: COLUMN quiz_config.question; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quiz_config.question IS 'Pode usar template TT para  formatar o texto e usar respostas anteriores';


--
-- Name: COLUMN quiz_config.yesnogroup; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quiz_config.yesnogroup IS 'Até 20 questões sim/não. Cada resposta "sim" será "adicionada" {AND operation} para a resposta, baseado em Power2anwser. ';


--
-- Name: COLUMN quiz_config.intro; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quiz_config.intro IS 'Textos de intrução';


--
-- Name: COLUMN quiz_config.button_label; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quiz_config.button_label IS 'Texto para ser usado no label do botão';


--
-- Name: quiz_config_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.quiz_config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quiz_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.quiz_config_id_seq OWNED BY public.quiz_config.id;


--
-- Name: relatorio_chat_cliente_suporte; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.relatorio_chat_cliente_suporte (
    id integer NOT NULL,
    cliente_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: relatorio_chat_cliente_suporte_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.relatorio_chat_cliente_suporte_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: relatorio_chat_cliente_suporte_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.relatorio_chat_cliente_suporte_id_seq OWNED BY public.relatorio_chat_cliente_suporte.id;


--
-- Name: rss_feeds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rss_feeds (
    id bigint NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    created_on timestamp with time zone,
    modified_on timestamp with time zone,
    url character varying(2000) NOT NULL,
    next_tick timestamp with time zone,
    last_run timestamp with time zone,
    fonte character varying(200) DEFAULT NULL::character varying,
    autocapitalize boolean DEFAULT false NOT NULL,
    last_error_message text,
    owner uuid,
    modified_by uuid
);


--
-- Name: COLUMN rss_feeds.url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.rss_feeds.url IS 'URL do XML do feed RSS/Atom feed';


--
-- Name: COLUMN rss_feeds.next_tick; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.rss_feeds.next_tick IS 'proxima vez que irá ser verificado';


--
-- Name: COLUMN rss_feeds.last_run; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.rss_feeds.last_run IS 'ultima vez que rodou';


--
-- Name: COLUMN rss_feeds.fonte; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.rss_feeds.fonte IS 'Salvo no campo Fonte da noticia';


--
-- Name: COLUMN rss_feeds.autocapitalize; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.rss_feeds.autocapitalize IS 'Transformar Title Em CapitalCase';


--
-- Name: rss_feeds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rss_feeds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rss_feeds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rss_feeds_id_seq OWNED BY public.rss_feeds.id;


--
-- Name: rss_feeds_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rss_feeds_tags (
    id integer NOT NULL,
    tags_id bigint,
    rss_feeds_id bigint
);


--
-- Name: rss_feeds_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rss_feeds_tags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rss_feeds_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rss_feeds_tags_id_seq OWNED BY public.rss_feeds_tags.id;


--
-- Name: sent_sms_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sent_sms_log (
    id bigint NOT NULL,
    phonenumber character varying(200) NOT NULL,
    message character varying(2000) NOT NULL,
    notes text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    sns_message_id character varying(200) DEFAULT NULL::character varying
);


--
-- Name: COLUMN sent_sms_log.phonenumber; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sent_sms_log.phonenumber IS 'numero do telefone';


--
-- Name: COLUMN sent_sms_log.message; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sent_sms_log.message IS 'texto enviado no sms';


--
-- Name: COLUMN sent_sms_log.notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sent_sms_log.notes IS 'notas';


--
-- Name: COLUMN sent_sms_log.sns_message_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sent_sms_log.sns_message_id IS 'ID do  envio no SNS, caso tenha sido com sucesso';


--
-- Name: sent_sms_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sent_sms_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sent_sms_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sent_sms_log_id_seq OWNED BY public.sent_sms_log.id;


--
-- Name: skills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skills (
    id bigint NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    created_on timestamp with time zone,
    modified_on timestamp with time zone,
    skill character varying(100),
    sort integer,
    owner uuid,
    modified_by uuid
);


--
-- Name: skills_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.skills_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: skills_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.skills_id_seq OWNED BY public.skills.id;


--
-- Name: tag_indexing_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tag_indexing_config (
    id bigint NOT NULL,
    created_on timestamp with time zone,
    status character varying(20) DEFAULT 'prod'::character varying NOT NULL,
    tag_id bigint NOT NULL,
    description character varying(200) DEFAULT NULL::character varying,
    page_title_match text,
    page_title_not_match text,
    html_article_match text,
    html_article_not_match character varying(200) DEFAULT NULL::character varying,
    page_description_match text,
    page_description_not_match text,
    url_match text,
    url_not_match text,
    rss_feed_tags_match text,
    rss_feed_tags_not_match text,
    rss_feed_content_match character varying(200) DEFAULT NULL::character varying,
    rss_feed_content_not_match text,
    regexp boolean DEFAULT true NOT NULL,
    verified boolean DEFAULT false NOT NULL,
    error_msg text DEFAULT ''::text,
    verified_at timestamp with time zone,
    modified_on timestamp with time zone,
    owner uuid,
    modified_by uuid
);


--
-- Name: COLUMN tag_indexing_config.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.description IS 'Descrição (não é usado pelo sistema)';


--
-- Name: COLUMN tag_indexing_config.page_title_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.page_title_match IS 'match no atributo <title> do html da pagina (Feed + HTML)';


--
-- Name: COLUMN tag_indexing_config.page_title_not_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.page_title_not_match IS 'match no atributo <title> do html da pagina (Feed + HTML)';


--
-- Name: COLUMN tag_indexing_config.html_article_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.html_article_match IS 'match em text dentro de tags <article> (usar com cautela!)';


--
-- Name: COLUMN tag_indexing_config.html_article_not_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.html_article_not_match IS 'match em text dentro de tags <article> (usar com cautela!)';


--
-- Name: COLUMN tag_indexing_config.page_description_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.page_description_match IS 'match na meta og:description do html da pagina (Feed + HTML)';


--
-- Name: COLUMN tag_indexing_config.page_description_not_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.page_description_not_match IS 'match na meta og:description do html da pagina (Feed + HTML)';


--
-- Name: COLUMN tag_indexing_config.url_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.url_match IS 'match na URL';


--
-- Name: COLUMN tag_indexing_config.url_not_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.url_not_match IS 'match na URL';


--
-- Name: COLUMN tag_indexing_config.rss_feed_tags_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.rss_feed_tags_match IS 'match no tags do RSS, se existir';


--
-- Name: COLUMN tag_indexing_config.rss_feed_tags_not_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.rss_feed_tags_not_match IS 'match no tags do RSS, se existir';


--
-- Name: COLUMN tag_indexing_config.rss_feed_content_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.rss_feed_content_match IS 'match em text dentro do content do RSS Feed se existir';


--
-- Name: COLUMN tag_indexing_config.rss_feed_content_not_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.rss_feed_content_not_match IS 'match em text dentro do content do RSS Feed se existir';


--
-- Name: COLUMN tag_indexing_config.regexp; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.regexp IS 'Se os valores são regexp ou texto. Quando texto, use PIPE para criar uma lista de palavras, quando regexp';


--
-- Name: COLUMN tag_indexing_config.verified; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.verified IS 'Se o sistema conseguiu validar esta config';


--
-- Name: COLUMN tag_indexing_config.error_msg; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.error_msg IS 'Erro informado pelo sistema';


--
-- Name: COLUMN tag_indexing_config.verified_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.verified_at IS 'o sistema verifica novamente todas que verified_at < modified_on';


--
-- Name: tag_indexing_config_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tag_indexing_config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tag_indexing_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tag_indexing_config_id_seq OWNED BY public.tag_indexing_config.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    id bigint NOT NULL,
    status character varying(20) DEFAULT 'prod'::character varying NOT NULL,
    title character varying(200) NOT NULL,
    is_topic boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone NOT NULL,
    show_on_filters boolean DEFAULT false NOT NULL,
    topic_order bigint DEFAULT '0'::bigint NOT NULL
);


--
-- Name: tags_highlight; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags_highlight (
    id bigint NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    created_on timestamp with time zone,
    modified_on timestamp with time zone,
    tag_id bigint NOT NULL,
    match character varying(200) NOT NULL,
    is_regexp boolean DEFAULT false NOT NULL,
    error_msg character varying(200) DEFAULT ''::character varying,
    owner uuid,
    modified_by uuid
);


--
-- Name: COLUMN tags_highlight.match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tags_highlight.match IS 'Não use ^ nem $ para marcar, tambem não use .+ no incio ou fim, pois irá pegar o tweet inteiro';


--
-- Name: COLUMN tags_highlight.is_regexp; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tags_highlight.is_regexp IS 'Se o match é uma regexp ou não';


--
-- Name: tags_highlight_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tags_highlight_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_highlight_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tags_highlight_id_seq OWNED BY public.tags_highlight.id;


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;


--
-- Name: timeline_clientes_bloqueados; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.timeline_clientes_bloqueados (
    id bigint NOT NULL,
    cliente_id integer NOT NULL,
    block_cliente_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    valid_until timestamp without time zone DEFAULT 'infinity'::timestamp without time zone NOT NULL
);


--
-- Name: timeline_clientes_bloqueados_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.timeline_clientes_bloqueados_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: timeline_clientes_bloqueados_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.timeline_clientes_bloqueados_id_seq OWNED BY public.timeline_clientes_bloqueados.id;


--
-- Name: tweets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tweets (
    id character varying(20) NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    content text,
    parent_id character varying(20) DEFAULT NULL::character varying,
    anonimo boolean DEFAULT false NOT NULL,
    qtde_reportado bigint DEFAULT '0'::bigint,
    qtde_expansoes bigint DEFAULT '0'::bigint,
    qtde_likes bigint DEFAULT '0'::bigint NOT NULL,
    qtde_comentarios bigint DEFAULT '0'::bigint,
    escondido boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone,
    cliente_id bigint NOT NULL,
    ultimo_comentario_id character varying(20) DEFAULT NULL::character varying,
    media_ids text,
    disable_escape boolean DEFAULT false NOT NULL,
    tags_index character varying(5000) DEFAULT ',,'::character varying NOT NULL,
    original_parent_id character varying(20) DEFAULT NULL::character varying,
    tweet_depth smallint DEFAULT 1 NOT NULL,
    use_penhas_avatar boolean DEFAULT false NOT NULL
);


--
-- Name: COLUMN tweets.qtde_reportado; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tweets.qtde_reportado IS 'quantidade de vezes que foi reportado';


--
-- Name: COLUMN tweets.media_ids; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tweets.media_ids IS 'ID das medias usadas neste tweet';


--
-- Name: COLUMN tweets.disable_escape; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tweets.disable_escape IS 'Ligar para quando o conteúdo deve ser interpretado como HTML (postagens de admins)';


--
-- Name: tweets_likes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tweets_likes (
    id bigint NOT NULL,
    created_on timestamp with time zone DEFAULT now(),
    cliente_id bigint NOT NULL,
    tweet_id character varying(20) NOT NULL
);


--
-- Name: tweets_likes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tweets_likes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tweets_likes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tweets_likes_id_seq OWNED BY public.tweets_likes.id;


--
-- Name: tweets_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tweets_reports (
    id bigint NOT NULL,
    cliente_id bigint NOT NULL,
    reported_id character varying(20) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    reason character varying(200) NOT NULL
);


--
-- Name: tweets_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tweets_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tweets_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tweets_reports_id_seq OWNED BY public.tweets_reports.id;


--
-- Name: twitter_bot_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.twitter_bot_config (
    id integer NOT NULL,
    user_created uuid,
    date_created timestamp with time zone,
    user_updated uuid,
    date_updated timestamp with time zone,
    config json DEFAULT '{}'::json NOT NULL
);


--
-- Name: twitter_bot_config_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.twitter_bot_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: twitter_bot_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.twitter_bot_config_id_seq OWNED BY public.twitter_bot_config.id;


--
-- Name: view_user_preferences; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.view_user_preferences AS
 SELECT p.name,
    c.id AS cliente_id,
    COALESCE(cp.value, p.initial_value) AS value
   FROM ((public.preferences p
     CROSS JOIN public.clientes c)
     LEFT JOIN public.clientes_preferences cp ON (((cp.cliente_id = c.id) AND (cp.preference_id = p.id))));


--
-- Name: admin_big_numbers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_big_numbers ALTER COLUMN id SET DEFAULT nextval('public.admin_big_numbers_id_seq'::regclass);


--
-- Name: admin_clientes_segments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_clientes_segments ALTER COLUMN id SET DEFAULT nextval('public.admin_clientes_segments_id_seq'::regclass);


--
-- Name: anonymous_quiz_session id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anonymous_quiz_session ALTER COLUMN id SET DEFAULT nextval('public.anonymous_quiz_session_id_seq'::regclass);


--
-- Name: antigo_clientes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.antigo_clientes ALTER COLUMN id SET DEFAULT nextval('public.antigo_clientes_id_seq'::regclass);


--
-- Name: antigo_clientes_guardioes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.antigo_clientes_guardioes ALTER COLUMN id SET DEFAULT nextval('public.antigo_clientes_guardioes_id_seq'::regclass);


--
-- Name: chat_clientes_notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_clientes_notifications ALTER COLUMN id SET DEFAULT nextval('public.chat_clientes_notifications_id_seq'::regclass);


--
-- Name: chat_message id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message ALTER COLUMN id SET DEFAULT nextval('public.chat_message_id_seq'::regclass);


--
-- Name: chat_session id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_session ALTER COLUMN id SET DEFAULT nextval('public.chat_session_id_seq'::regclass);


--
-- Name: chat_support id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_support ALTER COLUMN id SET DEFAULT nextval('public.chat_support_id_seq'::regclass);


--
-- Name: chat_support_message id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_support_message ALTER COLUMN id SET DEFAULT nextval('public.chat_support_message_id_seq'::regclass);


--
-- Name: cliente_ativacoes_panico id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_ativacoes_panico ALTER COLUMN id SET DEFAULT nextval('public.cliente_ativacoes_panico_id_seq'::regclass);


--
-- Name: cliente_ativacoes_policia id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_ativacoes_policia ALTER COLUMN id SET DEFAULT nextval('public.cliente_ativacoes_policia_id_seq'::regclass);


--
-- Name: cliente_bloqueios id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_bloqueios ALTER COLUMN id SET DEFAULT nextval('public.cliente_bloqueios_id_seq'::regclass);


--
-- Name: cliente_ponto_apoio_avaliacao id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_ponto_apoio_avaliacao ALTER COLUMN id SET DEFAULT nextval('public.cliente_ponto_apoio_avaliacao_id_seq'::regclass);


--
-- Name: cliente_skills id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_skills ALTER COLUMN id SET DEFAULT nextval('public.cliente_skills_id_seq'::regclass);


--
-- Name: cliente_tag id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_tag ALTER COLUMN id SET DEFAULT nextval('public.cliente_tag_id_seq'::regclass);


--
-- Name: clientes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes ALTER COLUMN id SET DEFAULT nextval('public.clientes_id_seq'::regclass);


--
-- Name: clientes_active_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_active_sessions ALTER COLUMN id SET DEFAULT nextval('public.clientes_active_sessions_id_seq'::regclass);


--
-- Name: clientes_app_activity id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_app_activity ALTER COLUMN id SET DEFAULT nextval('public.clientes_app_activity_id_seq'::regclass);


--
-- Name: clientes_app_activity_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_app_activity_log ALTER COLUMN id SET DEFAULT nextval('public.clientes_app_activity_log_id_seq'::regclass);


--
-- Name: clientes_app_notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_app_notifications ALTER COLUMN id SET DEFAULT nextval('public.clientes_app_notifications_id_seq'::regclass);


--
-- Name: clientes_audios id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_audios ALTER COLUMN id SET DEFAULT nextval('public.clientes_audios_id_seq'::regclass);


--
-- Name: clientes_guardioes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_guardioes ALTER COLUMN id SET DEFAULT nextval('public.clientes_guardioes_id_seq'::regclass);


--
-- Name: clientes_preferences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_preferences ALTER COLUMN id SET DEFAULT nextval('public.clientes_preferences_id_seq'::regclass);


--
-- Name: clientes_quiz_session id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_quiz_session ALTER COLUMN id SET DEFAULT nextval('public.clientes_quiz_session_id_seq'::regclass);


--
-- Name: clientes_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_reports ALTER COLUMN id SET DEFAULT nextval('public.clientes_reports_id_seq'::regclass);


--
-- Name: clientes_reset_password id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_reset_password ALTER COLUMN id SET DEFAULT nextval('public.clientes_reset_password_id_seq'::regclass);


--
-- Name: configuracoes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuracoes ALTER COLUMN id SET DEFAULT nextval('public.configuracoes_id_seq'::regclass);


--
-- Name: cpf_erros id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cpf_erros ALTER COLUMN id SET DEFAULT nextval('public.cpf_erros_id_seq'::regclass);


--
-- Name: delete_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delete_log ALTER COLUMN id SET DEFAULT nextval('public.delete_log_id_seq'::regclass);


--
-- Name: emaildb_config id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emaildb_config ALTER COLUMN id SET DEFAULT nextval('public.emaildb_config_id_seq'::regclass);


--
-- Name: faq_tela_guardiao id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faq_tela_guardiao ALTER COLUMN id SET DEFAULT nextval('public.faq_tela_guardiao_id_seq'::regclass);


--
-- Name: faq_tela_sobre id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faq_tela_sobre ALTER COLUMN id SET DEFAULT nextval('public.faq_tela_sobre_id_seq'::regclass);


--
-- Name: faq_tela_sobre_categoria id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faq_tela_sobre_categoria ALTER COLUMN id SET DEFAULT nextval('public.faq_tela_sobre_categoria_id_seq'::regclass);


--
-- Name: geo_cache id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.geo_cache ALTER COLUMN id SET DEFAULT nextval('public.geo_cache_id_seq'::regclass);


--
-- Name: login_erros id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_erros ALTER COLUMN id SET DEFAULT nextval('public.login_erros_id_seq'::regclass);


--
-- Name: login_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_logs ALTER COLUMN id SET DEFAULT nextval('public.login_logs_id_seq'::regclass);


--
-- Name: mf_cliente_tarefa id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mf_cliente_tarefa ALTER COLUMN id SET DEFAULT nextval('public.mf_cliente_tarefa_id_seq'::regclass);


--
-- Name: mf_questionnaire_order id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mf_questionnaire_order ALTER COLUMN id SET DEFAULT nextval('public.mf_questionnaire_order_id_seq'::regclass);


--
-- Name: mf_questionnaire_remove_tarefa id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mf_questionnaire_remove_tarefa ALTER COLUMN id SET DEFAULT nextval('public.mf_questionnaire_remove_tarefa_id_seq'::regclass);


--
-- Name: mf_tag id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mf_tag ALTER COLUMN id SET DEFAULT nextval('public.mf_tag_id_seq'::regclass);


--
-- Name: mf_tarefa id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mf_tarefa ALTER COLUMN id SET DEFAULT nextval('public.mf_tarefa_id_seq'::regclass);


--
-- Name: minion_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.minion_jobs ALTER COLUMN id SET DEFAULT nextval('public.minion_jobs_id_seq'::regclass);


--
-- Name: minion_locks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.minion_locks ALTER COLUMN id SET DEFAULT nextval('public.minion_locks_id_seq'::regclass);


--
-- Name: minion_workers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.minion_workers ALTER COLUMN id SET DEFAULT nextval('public.minion_workers_id_seq'::regclass);


--
-- Name: municipalities ogc_fid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.municipalities ALTER COLUMN ogc_fid SET DEFAULT nextval('public.municipalities_ogc_fid_seq'::regclass);


--
-- Name: noticias id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias ALTER COLUMN id SET DEFAULT nextval('public.noticias_id_seq'::regclass);


--
-- Name: noticias_aberturas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias_aberturas ALTER COLUMN id SET DEFAULT nextval('public.noticias_aberturas_id_seq'::regclass);


--
-- Name: noticias_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias_tags ALTER COLUMN id SET DEFAULT nextval('public.noticias_tags_id_seq'::regclass);


--
-- Name: noticias_vitrine id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias_vitrine ALTER COLUMN id SET DEFAULT nextval('public.noticias_vitrine_id_seq'::regclass);


--
-- Name: notification_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_log ALTER COLUMN id SET DEFAULT nextval('public.notification_log_id_seq'::regclass);


--
-- Name: notification_message id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_message ALTER COLUMN id SET DEFAULT nextval('public.notification_message_id_seq'::regclass);


--
-- Name: penhas_config id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.penhas_config ALTER COLUMN id SET DEFAULT nextval('public.penhas_config_id_seq'::regclass);


--
-- Name: ponto_apoio id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ponto_apoio ALTER COLUMN id SET DEFAULT nextval('public.ponto_apoio_id_seq'::regclass);


--
-- Name: ponto_apoio_categoria id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ponto_apoio_categoria ALTER COLUMN id SET DEFAULT nextval('public.ponto_apoio_categoria_id_seq'::regclass);


--
-- Name: ponto_apoio_keywords_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ponto_apoio_keywords_log ALTER COLUMN id SET DEFAULT nextval('public.ponto_apoio_keywords_log_id_seq'::regclass);


--
-- Name: ponto_apoio_projeto id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ponto_apoio_projeto ALTER COLUMN id SET DEFAULT nextval('public.ponto_apoio_projeto_id_seq'::regclass);


--
-- Name: ponto_apoio_sugestoes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ponto_apoio_sugestoes ALTER COLUMN id SET DEFAULT nextval('public.ponto_apoio_sugestoes_id_seq'::regclass);


--
-- Name: ponto_apoio_sugestoes_v2 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ponto_apoio_sugestoes_v2 ALTER COLUMN id SET DEFAULT nextval('public.ponto_apoio_sugestoes_v2_id_seq'::regclass);


--
-- Name: preferences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preferences ALTER COLUMN id SET DEFAULT nextval('public.preferences_id_seq'::regclass);


--
-- Name: private_chat_session_metadata id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.private_chat_session_metadata ALTER COLUMN id SET DEFAULT nextval('public.private_chat_session_metadata_id_seq'::regclass);


--
-- Name: questionnaires id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questionnaires ALTER COLUMN id SET DEFAULT nextval('public.questionnaires_id_seq'::regclass);


--
-- Name: quiz_config id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_config ALTER COLUMN id SET DEFAULT nextval('public.quiz_config_id_seq'::regclass);


--
-- Name: relatorio_chat_cliente_suporte id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relatorio_chat_cliente_suporte ALTER COLUMN id SET DEFAULT nextval('public.relatorio_chat_cliente_suporte_id_seq'::regclass);


--
-- Name: rss_feeds id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rss_feeds ALTER COLUMN id SET DEFAULT nextval('public.rss_feeds_id_seq'::regclass);


--
-- Name: rss_feeds_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rss_feeds_tags ALTER COLUMN id SET DEFAULT nextval('public.rss_feeds_tags_id_seq'::regclass);


--
-- Name: sent_sms_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sent_sms_log ALTER COLUMN id SET DEFAULT nextval('public.sent_sms_log_id_seq'::regclass);


--
-- Name: skills id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skills ALTER COLUMN id SET DEFAULT nextval('public.skills_id_seq'::regclass);


--
-- Name: tag_indexing_config id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag_indexing_config ALTER COLUMN id SET DEFAULT nextval('public.tag_indexing_config_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: tags_highlight id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags_highlight ALTER COLUMN id SET DEFAULT nextval('public.tags_highlight_id_seq'::regclass);


--
-- Name: timeline_clientes_bloqueados id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timeline_clientes_bloqueados ALTER COLUMN id SET DEFAULT nextval('public.timeline_clientes_bloqueados_id_seq'::regclass);


--
-- Name: tweets_likes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tweets_likes ALTER COLUMN id SET DEFAULT nextval('public.tweets_likes_id_seq'::regclass);


--
-- Name: tweets_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tweets_reports ALTER COLUMN id SET DEFAULT nextval('public.tweets_reports_id_seq'::regclass);


--
-- Name: twitter_bot_config id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.twitter_bot_config ALTER COLUMN id SET DEFAULT nextval('public.twitter_bot_config_id_seq'::regclass);


--
-- Name: anonymous_quiz_session anonymous_quiz_session_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anonymous_quiz_session
    ADD CONSTRAINT anonymous_quiz_session_pkey PRIMARY KEY (id);


--
-- Name: chat_message chat_message_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT chat_message_pkey PRIMARY KEY (id);


--
-- Name: chat_session chat_session_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_session
    ADD CONSTRAINT chat_session_pkey PRIMARY KEY (id);


--
-- Name: cliente_mf_session_control cliente_mf_session_control_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_mf_session_control
    ADD CONSTRAINT cliente_mf_session_control_pkey PRIMARY KEY (cliente_id);


--
-- Name: cliente_tag cliente_tag_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_tag
    ADD CONSTRAINT cliente_tag_pkey PRIMARY KEY (id);


--
-- Name: clientes_app_activity_log clientes_app_activity_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_app_activity_log
    ADD CONSTRAINT clientes_app_activity_log_pkey PRIMARY KEY (id);


--
-- Name: clientes_reports clientes_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_reports
    ADD CONSTRAINT clientes_reports_pkey PRIMARY KEY (id);


--
-- Name: cpf_cache cpf_cache_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cpf_cache
    ADD CONSTRAINT cpf_cache_pkey PRIMARY KEY (cpf_hashed, dt_nasc);


--
-- Name: emaildb_config emaildb_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emaildb_config
    ADD CONSTRAINT emaildb_config_pkey PRIMARY KEY (id);


--
-- Name: emaildb_queue emaildb_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emaildb_queue
    ADD CONSTRAINT emaildb_queue_pkey PRIMARY KEY (id);


--
-- Name: admin_big_numbers idx_25785_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_big_numbers
    ADD CONSTRAINT idx_25785_primary PRIMARY KEY (id);


--
-- Name: admin_clientes_segments idx_25798_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_clientes_segments
    ADD CONSTRAINT idx_25798_primary PRIMARY KEY (id);


--
-- Name: antigo_clientes idx_25812_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.antigo_clientes
    ADD CONSTRAINT idx_25812_primary PRIMARY KEY (id);


--
-- Name: antigo_clientes_guardioes idx_25867_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.antigo_clientes_guardioes
    ADD CONSTRAINT idx_25867_primary PRIMARY KEY (id);


--
-- Name: chat_clientes_notifications idx_25884_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_clientes_notifications
    ADD CONSTRAINT idx_25884_primary PRIMARY KEY (id);


--
-- Name: chat_support idx_25891_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_support
    ADD CONSTRAINT idx_25891_primary PRIMARY KEY (id);


--
-- Name: chat_support_message idx_25900_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_support_message
    ADD CONSTRAINT idx_25900_primary PRIMARY KEY (id);


--
-- Name: clientes idx_25909_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT idx_25909_primary PRIMARY KEY (id);


--
-- Name: clientes_active_sessions idx_25936_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_active_sessions
    ADD CONSTRAINT idx_25936_primary PRIMARY KEY (id);


--
-- Name: clientes_app_activity idx_25942_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_app_activity
    ADD CONSTRAINT idx_25942_primary PRIMARY KEY (id);


--
-- Name: clientes_app_notifications idx_25948_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_app_notifications
    ADD CONSTRAINT idx_25948_primary PRIMARY KEY (id);


--
-- Name: clientes_audios idx_25954_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_audios
    ADD CONSTRAINT idx_25954_primary PRIMARY KEY (id);


--
-- Name: clientes_audios_eventos idx_25963_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_audios_eventos
    ADD CONSTRAINT idx_25963_primary PRIMARY KEY (event_id);


--
-- Name: clientes_guardioes idx_25971_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_guardioes
    ADD CONSTRAINT idx_25971_primary PRIMARY KEY (id);


--
-- Name: clientes_preferences idx_25982_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_preferences
    ADD CONSTRAINT idx_25982_primary PRIMARY KEY (id);


--
-- Name: clientes_quiz_session idx_25988_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_quiz_session
    ADD CONSTRAINT idx_25988_primary PRIMARY KEY (id);


--
-- Name: clientes_reset_password idx_25998_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_reset_password
    ADD CONSTRAINT idx_25998_primary PRIMARY KEY (id);


--
-- Name: cliente_ativacoes_panico idx_26008_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_ativacoes_panico
    ADD CONSTRAINT idx_26008_primary PRIMARY KEY (id);


--
-- Name: cliente_ativacoes_policia idx_26021_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_ativacoes_policia
    ADD CONSTRAINT idx_26021_primary PRIMARY KEY (id);


--
-- Name: cliente_bloqueios idx_26027_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_bloqueios
    ADD CONSTRAINT idx_26027_primary PRIMARY KEY (id);


--
-- Name: cliente_ponto_apoio_avaliacao idx_26033_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_ponto_apoio_avaliacao
    ADD CONSTRAINT idx_26033_primary PRIMARY KEY (id);


--
-- Name: cliente_skills idx_26039_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_skills
    ADD CONSTRAINT idx_26039_primary PRIMARY KEY (id);


--
-- Name: configuracoes idx_26045_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuracoes
    ADD CONSTRAINT idx_26045_primary PRIMARY KEY (id);


--
-- Name: cpf_erros idx_26054_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cpf_erros
    ADD CONSTRAINT idx_26054_primary PRIMARY KEY (id);


--
-- Name: delete_log idx_26064_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delete_log
    ADD CONSTRAINT idx_26064_primary PRIMARY KEY (id);


--
-- Name: faq_tela_guardiao idx_26266_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faq_tela_guardiao
    ADD CONSTRAINT idx_26266_primary PRIMARY KEY (id);


--
-- Name: faq_tela_sobre idx_26276_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faq_tela_sobre
    ADD CONSTRAINT idx_26276_primary PRIMARY KEY (id);


--
-- Name: faq_tela_sobre_categoria idx_26287_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faq_tela_sobre_categoria
    ADD CONSTRAINT idx_26287_primary PRIMARY KEY (id);


--
-- Name: geo_cache idx_26298_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.geo_cache
    ADD CONSTRAINT idx_26298_primary PRIMARY KEY (id);


--
-- Name: login_erros idx_26304_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_erros
    ADD CONSTRAINT idx_26304_primary PRIMARY KEY (id);


--
-- Name: login_logs idx_26310_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_logs
    ADD CONSTRAINT idx_26310_primary PRIMARY KEY (id);


--
-- Name: media_upload idx_26318_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_upload
    ADD CONSTRAINT idx_26318_primary PRIMARY KEY (id);


--
-- Name: noticias idx_26326_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias
    ADD CONSTRAINT idx_26326_primary PRIMARY KEY (id);


--
-- Name: noticias_aberturas idx_26347_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias_aberturas
    ADD CONSTRAINT idx_26347_primary PRIMARY KEY (id);


--
-- Name: noticias_vitrine idx_26353_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias_vitrine
    ADD CONSTRAINT idx_26353_primary PRIMARY KEY (id);


--
-- Name: notification_log idx_26366_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_log
    ADD CONSTRAINT idx_26366_primary PRIMARY KEY (id);


--
-- Name: notification_message idx_26372_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_message
    ADD CONSTRAINT idx_26372_primary PRIMARY KEY (id);


--
-- Name: ponto_apoio idx_26383_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ponto_apoio
    ADD CONSTRAINT idx_26383_primary PRIMARY KEY (id);


--
-- Name: ponto_apoio_categoria idx_26416_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ponto_apoio_categoria
    ADD CONSTRAINT idx_26416_primary PRIMARY KEY (id);


--
-- Name: ponto_apoio_projeto idx_26432_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ponto_apoio_projeto
    ADD CONSTRAINT idx_26432_primary PRIMARY KEY (id);


--
-- Name: ponto_apoio_sugestoes idx_26439_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ponto_apoio_sugestoes
    ADD CONSTRAINT idx_26439_primary PRIMARY KEY (id);


--
-- Name: preferences idx_26449_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preferences
    ADD CONSTRAINT idx_26449_primary PRIMARY KEY (id);


--
-- Name: private_chat_session_metadata idx_26459_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.private_chat_session_metadata
    ADD CONSTRAINT idx_26459_primary PRIMARY KEY (id);


--
-- Name: questionnaires idx_26465_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questionnaires
    ADD CONSTRAINT idx_26465_primary PRIMARY KEY (id);


--
-- Name: quiz_config idx_26476_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_config
    ADD CONSTRAINT idx_26476_primary PRIMARY KEY (id);


--
-- Name: rss_feeds idx_26488_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rss_feeds
    ADD CONSTRAINT idx_26488_primary PRIMARY KEY (id);


--
-- Name: sent_sms_log idx_26506_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sent_sms_log
    ADD CONSTRAINT idx_26506_primary PRIMARY KEY (id);


--
-- Name: skills idx_26516_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skills
    ADD CONSTRAINT idx_26516_primary PRIMARY KEY (id);


--
-- Name: tags idx_26526_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT idx_26526_primary PRIMARY KEY (id);


--
-- Name: tags_highlight idx_26536_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags_highlight
    ADD CONSTRAINT idx_26536_primary PRIMARY KEY (id);


--
-- Name: tag_indexing_config idx_26545_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag_indexing_config
    ADD CONSTRAINT idx_26545_primary PRIMARY KEY (id);


--
-- Name: tweets idx_26559_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tweets
    ADD CONSTRAINT idx_26559_primary PRIMARY KEY (id);


--
-- Name: tweets_likes idx_26579_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tweets_likes
    ADD CONSTRAINT idx_26579_primary PRIMARY KEY (id);


--
-- Name: tweets_reports idx_26585_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tweets_reports
    ADD CONSTRAINT idx_26585_primary PRIMARY KEY (id);


--
-- Name: mf_cliente_tarefa mf_cliente_tarefa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mf_cliente_tarefa
    ADD CONSTRAINT mf_cliente_tarefa_pkey PRIMARY KEY (id);


--
-- Name: mf_questionnaire_order mf_questionnaire_order_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mf_questionnaire_order
    ADD CONSTRAINT mf_questionnaire_order_pkey PRIMARY KEY (id);


--
-- Name: mf_questionnaire_remove_tarefa mf_questionnaire_remove_tarefa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mf_questionnaire_remove_tarefa
    ADD CONSTRAINT mf_questionnaire_remove_tarefa_pkey PRIMARY KEY (id);


--
-- Name: mf_tag mf_tag_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mf_tag
    ADD CONSTRAINT mf_tag_code_key UNIQUE (code);


--
-- Name: mf_tag mf_tag_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mf_tag
    ADD CONSTRAINT mf_tag_pkey PRIMARY KEY (id);


--
-- Name: mf_tarefa mf_tarefa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mf_tarefa
    ADD CONSTRAINT mf_tarefa_pkey PRIMARY KEY (id);


--
-- Name: minion_jobs minion_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.minion_jobs
    ADD CONSTRAINT minion_jobs_pkey PRIMARY KEY (id);


--
-- Name: minion_locks minion_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.minion_locks
    ADD CONSTRAINT minion_locks_pkey PRIMARY KEY (id);


--
-- Name: minion_workers minion_workers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.minion_workers
    ADD CONSTRAINT minion_workers_pkey PRIMARY KEY (id);


--
-- Name: mojo_migrations mojo_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mojo_migrations
    ADD CONSTRAINT mojo_migrations_pkey PRIMARY KEY (name);


--
-- Name: municipalities municipalities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.municipalities
    ADD CONSTRAINT municipalities_pkey PRIMARY KEY (ogc_fid);


--
-- Name: noticias_tags noticias_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias_tags
    ADD CONSTRAINT noticias_tags_pkey PRIMARY KEY (id);


--
-- Name: penhas_config penhas_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.penhas_config
    ADD CONSTRAINT penhas_config_pkey PRIMARY KEY (id);


--
-- Name: ponto_apoio2projetos ponto_apoio2projetos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ponto_apoio2projetos
    ADD CONSTRAINT ponto_apoio2projetos_pkey PRIMARY KEY (ponto_apoio_id, ponto_apoio_projeto_id);


--
-- Name: ponto_apoio_keywords_log ponto_apoio_keywords_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ponto_apoio_keywords_log
    ADD CONSTRAINT ponto_apoio_keywords_log_pkey PRIMARY KEY (id);


--
-- Name: ponto_apoio_sugestoes_v2 ponto_apoio_sugestoes_v2_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ponto_apoio_sugestoes_v2
    ADD CONSTRAINT ponto_apoio_sugestoes_v2_pkey PRIMARY KEY (id);


--
-- Name: relatorio_chat_cliente_suporte relatorio_chat_cliente_suporte_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relatorio_chat_cliente_suporte
    ADD CONSTRAINT relatorio_chat_cliente_suporte_pkey PRIMARY KEY (id);


--
-- Name: rss_feeds_tags rss_feeds_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rss_feeds_tags
    ADD CONSTRAINT rss_feeds_tags_pkey PRIMARY KEY (id);


--
-- Name: timeline_clientes_bloqueados timeline_clientes_bloqueados_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timeline_clientes_bloqueados
    ADD CONSTRAINT timeline_clientes_bloqueados_pkey PRIMARY KEY (id);


--
-- Name: twitter_bot_config twitter_bot_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.twitter_bot_config
    ADD CONSTRAINT twitter_bot_config_pkey PRIMARY KEY (id);


--
-- Name: cliente_tag unique_cliente_tag; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_tag
    ADD CONSTRAINT unique_cliente_tag UNIQUE (cliente_id, mf_tag_id);


--
-- Name: geog_municipalities; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX geog_municipalities ON public.municipalities USING gist (((wkb_geometry)::public.geography));


--
-- Name: idx_25812_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_25812_id ON public.antigo_clientes USING btree (id);


--
-- Name: idx_25867_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_25867_id ON public.antigo_clientes_guardioes USING btree (id);


--
-- Name: idx_25884_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_25884_cliente_id ON public.chat_clientes_notifications USING btree (cliente_id);


--
-- Name: idx_25884_idx_chat_clientes_notifications; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_25884_idx_chat_clientes_notifications ON public.chat_clientes_notifications USING btree (messaged_at);


--
-- Name: idx_25891_idx_chat_support_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_25891_idx_chat_support_created_at ON public.chat_support USING btree (cliente_id, created_at);


--
-- Name: idx_25891_idx_uniq_chat_support_cliente; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_25891_idx_uniq_chat_support_cliente ON public.chat_support USING btree (cliente_id);


--
-- Name: idx_25900_chat_support_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_25900_chat_support_id ON public.chat_support_message USING btree (chat_support_id);


--
-- Name: idx_25900_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_25900_cliente_id ON public.chat_support_message USING btree (cliente_id);


--
-- Name: idx_25909_cpf_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_25909_cpf_hash ON public.clientes USING btree (cpf_hash);


--
-- Name: idx_25909_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_25909_email ON public.clientes USING btree (email);


--
-- Name: idx_25936_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_25936_cliente_id ON public.clientes_active_sessions USING btree (cliente_id);


--
-- Name: idx_25942_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_25942_cliente_id ON public.clientes_app_activity USING btree (cliente_id);


--
-- Name: idx_25942_idx_last_tm_activity_desc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_25942_idx_last_tm_activity_desc ON public.clientes_app_activity USING btree (last_tm_activity);


--
-- Name: idx_25948_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_25948_cliente_id ON public.clientes_app_notifications USING btree (cliente_id);


--
-- Name: idx_25954_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_25954_cliente_id ON public.clientes_audios USING btree (cliente_id);


--
-- Name: idx_25954_media_upload_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_25954_media_upload_id ON public.clientes_audios USING btree (media_upload_id);


--
-- Name: idx_25963_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_25963_cliente_id ON public.clientes_audios_eventos USING btree (cliente_id);


--
-- Name: idx_25971_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_25971_cliente_id ON public.clientes_guardioes USING btree (cliente_id);


--
-- Name: idx_25971_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_25971_token ON public.clientes_guardioes USING btree (token);


--
-- Name: idx_25982_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_25982_cliente_id ON public.clientes_preferences USING btree (cliente_id);


--
-- Name: idx_25982_preference_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_25982_preference_id ON public.clientes_preferences USING btree (preference_id);


--
-- Name: idx_25988_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_25988_cliente_id ON public.clientes_quiz_session USING btree (cliente_id);


--
-- Name: idx_25998_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_25998_cliente_id ON public.clientes_reset_password USING btree (cliente_id);


--
-- Name: idx_26008_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26008_cliente_id ON public.cliente_ativacoes_panico USING btree (cliente_id);


--
-- Name: idx_26021_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26021_cliente_id ON public.cliente_ativacoes_policia USING btree (cliente_id);


--
-- Name: idx_26027_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26027_cliente_id ON public.cliente_bloqueios USING btree (cliente_id);


--
-- Name: idx_26033_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26033_cliente_id ON public.cliente_ponto_apoio_avaliacao USING btree (cliente_id);


--
-- Name: idx_26033_ponto_apoio_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26033_ponto_apoio_id ON public.cliente_ponto_apoio_avaliacao USING btree (ponto_apoio_id);


--
-- Name: idx_26039_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26039_cliente_id ON public.cliente_skills USING btree (cliente_id);


--
-- Name: idx_26039_skill_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26039_skill_id ON public.cliente_skills USING btree (skill_id);


--
-- Name: idx_26276_fts_categoria_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26276_fts_categoria_id ON public.faq_tela_sobre USING btree (fts_categoria_id);


--
-- Name: idx_26304_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26304_cliente_id ON public.login_erros USING btree (cliente_id);


--
-- Name: idx_26310_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26310_cliente_id ON public.login_logs USING btree (cliente_id);


--
-- Name: idx_26318_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26318_cliente_id ON public.media_upload USING btree (cliente_id);


--
-- Name: idx_26326_rss_feed_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26326_rss_feed_id ON public.noticias USING btree (rss_feed_id);


--
-- Name: idx_26366_ix_notification_log_by_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26366_ix_notification_log_by_time ON public.notification_log USING btree (created_at, cliente_id);


--
-- Name: idx_26366_notification_log_ibfk_1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26366_notification_log_ibfk_1 ON public.notification_log USING btree (cliente_id);


--
-- Name: idx_26366_notification_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26366_notification_message_id ON public.notification_log USING btree (notification_message_id);


--
-- Name: idx_26383_categoria; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26383_categoria ON public.ponto_apoio USING btree (categoria);


--
-- Name: idx_26439_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26439_cliente_id ON public.ponto_apoio_sugestoes USING btree (cliente_id);


--
-- Name: idx_26476_questionnaire_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26476_questionnaire_id ON public.quiz_config USING btree (questionnaire_id);


--
-- Name: idx_26536_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26536_tag_id ON public.tags_highlight USING btree (tag_id);


--
-- Name: idx_26545_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26545_tag_id ON public.tag_indexing_config USING btree (tag_id);


--
-- Name: idx_26559_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26559_cliente_id ON public.tweets USING btree (cliente_id);


--
-- Name: idx_26579_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26579_cliente_id ON public.tweets_likes USING btree (cliente_id);


--
-- Name: idx_26579_tweet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26579_tweet_id ON public.tweets_likes USING btree (tweet_id);


--
-- Name: idx_26585_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_26585_cliente_id ON public.tweets_reports USING btree (cliente_id);


--
-- Name: idx_config_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_config_key ON public.penhas_config USING btree (name) WHERE (valid_to = 'infinity'::timestamp without time zone);


--
-- Name: ix_index_tsvector_pt; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_index_tsvector_pt ON public.ponto_apoio USING gin (to_tsvector('portuguese'::regconfig, index));


--
-- Name: ix_messages_by_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_messages_by_time ON public.chat_message USING btree (chat_session_id, created_at DESC);


--
-- Name: ix_mf_codigo_tarefa; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_mf_codigo_tarefa ON public.mf_tarefa USING btree (codigo) WHERE ((codigo)::text <> ''::text);


--
-- Name: ix_session_by_participants; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_session_by_participants ON public.chat_session USING gin (participants);


--
-- Name: ix_user_created_at_sp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_created_at_sp ON public.clientes USING btree (created_on);


--
-- Name: ix_user_created_at_sp_2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_created_at_sp_2 ON public.clientes USING btree (created_on) INCLUDE (cep_cidade) WHERE ((cep_cidade IS NOT NULL) AND ((cep_cidade)::text <> ''::text));


--
-- Name: minion_jobs_expires_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX minion_jobs_expires_idx ON public.minion_jobs USING btree (expires);


--
-- Name: minion_jobs_finished_state_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX minion_jobs_finished_state_idx ON public.minion_jobs USING btree (finished, state);


--
-- Name: minion_jobs_notes_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX minion_jobs_notes_idx ON public.minion_jobs USING gin (notes);


--
-- Name: minion_jobs_parents_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX minion_jobs_parents_idx ON public.minion_jobs USING gin (parents);


--
-- Name: minion_jobs_state_priority_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX minion_jobs_state_priority_id_idx ON public.minion_jobs USING btree (state, priority DESC, id);


--
-- Name: minion_locks_name_expires_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX minion_locks_name_expires_idx ON public.minion_locks USING btree (name, expires);


--
-- Name: ponto_apoio_geog_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ponto_apoio_geog_idx ON public.ponto_apoio USING gist (geog);


--
-- Name: minion_jobs minion_jobs_notify_workers_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER minion_jobs_notify_workers_trigger AFTER INSERT OR UPDATE OF retries ON public.minion_jobs FOR EACH ROW EXECUTE FUNCTION public.minion_jobs_notify_workers();


--
-- Name: cliente_tag prevent_duplicate_cliente_tag_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER prevent_duplicate_cliente_tag_trigger BEFORE INSERT ON public.cliente_tag FOR EACH ROW EXECUTE FUNCTION public.prevent_duplicate_cliente_tag();


--
-- Name: cliente_ativacoes_panico tgr_cliente_ativacoes_panico_sit_risco; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tgr_cliente_ativacoes_panico_sit_risco BEFORE INSERT OR UPDATE ON public.cliente_ativacoes_panico FOR EACH ROW EXECUTE FUNCTION public.f_set_estava_em_situacao_risco();


--
-- Name: cliente_ativacoes_policia tgr_cliente_ativacoes_policia_sit_risco; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tgr_cliente_ativacoes_policia_sit_risco BEFORE INSERT OR UPDATE ON public.cliente_ativacoes_policia FOR EACH ROW EXECUTE FUNCTION public.f_set_estava_em_situacao_risco();


--
-- Name: clientes_audios_eventos tgr_clientes_audios_eventos_sit_risco; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tgr_clientes_audios_eventos_sit_risco BEFORE INSERT OR UPDATE ON public.clientes_audios_eventos FOR EACH ROW EXECUTE FUNCTION public.f_set_estava_em_situacao_risco();


--
-- Name: clientes_guardioes tgr_clientes_guardioes_sit_risco; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tgr_clientes_guardioes_sit_risco BEFORE INSERT OR UPDATE ON public.clientes_guardioes FOR EACH ROW EXECUTE FUNCTION public.f_set_estava_em_situacao_risco();


--
-- Name: emaildb_queue tgr_email_inserted; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tgr_email_inserted AFTER INSERT ON public.emaildb_queue FOR EACH STATEMENT EXECUTE FUNCTION public.email_inserted_notify();


--
-- Name: clientes_app_activity tgr_on_quiz_config_after_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tgr_on_quiz_config_after_update AFTER INSERT OR UPDATE ON public.clientes_app_activity FOR EACH ROW EXECUTE FUNCTION public.f_tgr_clientes_app_activity_log();


--
-- Name: quiz_config tgr_on_quiz_config_after_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tgr_on_quiz_config_after_update AFTER INSERT OR DELETE OR UPDATE ON public.quiz_config FOR EACH ROW EXECUTE FUNCTION public.f_tgr_quiz_config_after_update();


--
-- Name: ponto_apoio trigger_ponto_apoio_geo_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_ponto_apoio_geo_updated AFTER UPDATE OF latitude, longitude ON public.ponto_apoio FOR EACH ROW EXECUTE FUNCTION public.ft_ponto_apoio_geo_update();


--
-- Name: ponto_apoio trigger_ponto_apoio_inserted; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_ponto_apoio_inserted AFTER INSERT ON public.ponto_apoio FOR EACH ROW EXECUTE FUNCTION public.ft_ponto_apoio_geo_update();


--
-- Name: anonymous_quiz_session anonymous_quiz_session_questionnaire_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anonymous_quiz_session
    ADD CONSTRAINT anonymous_quiz_session_questionnaire_id_fkey FOREIGN KEY (questionnaire_id) REFERENCES public.questionnaires(id);


--
-- Name: chat_clientes_notifications chat_clientes_notifications_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_clientes_notifications
    ADD CONSTRAINT chat_clientes_notifications_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: chat_message chat_message_chat_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT chat_message_chat_session_id_fkey FOREIGN KEY (chat_session_id) REFERENCES public.chat_session(id);


--
-- Name: chat_support chat_support_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_support
    ADD CONSTRAINT chat_support_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: chat_support_message chat_support_message_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_support_message
    ADD CONSTRAINT chat_support_message_ibfk_1 FOREIGN KEY (chat_support_id) REFERENCES public.chat_support(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: chat_support_message chat_support_message_ibfk_2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_support_message
    ADD CONSTRAINT chat_support_message_ibfk_2 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cliente_ativacoes_panico cliente_ativacoes_panico_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_ativacoes_panico
    ADD CONSTRAINT cliente_ativacoes_panico_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cliente_ativacoes_policia cliente_ativacoes_policia_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_ativacoes_policia
    ADD CONSTRAINT cliente_ativacoes_policia_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cliente_bloqueios cliente_bloqueios_blocked_cliente_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_bloqueios
    ADD CONSTRAINT cliente_bloqueios_blocked_cliente_id_foreign FOREIGN KEY (blocked_cliente_id) REFERENCES public.clientes(id) ON DELETE SET NULL;


--
-- Name: cliente_bloqueios cliente_bloqueios_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_bloqueios
    ADD CONSTRAINT cliente_bloqueios_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cliente_mf_session_control cliente_mf_session_control_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_mf_session_control
    ADD CONSTRAINT cliente_mf_session_control_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON DELETE CASCADE;


--
-- Name: cliente_mf_session_control cliente_mf_session_control_current_clientes_quiz_session_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_mf_session_control
    ADD CONSTRAINT cliente_mf_session_control_current_clientes_quiz_session_fkey FOREIGN KEY (current_clientes_quiz_session) REFERENCES public.clientes_quiz_session(id);


--
-- Name: cliente_ponto_apoio_avaliacao cliente_ponto_apoio_avaliacao_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_ponto_apoio_avaliacao
    ADD CONSTRAINT cliente_ponto_apoio_avaliacao_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cliente_ponto_apoio_avaliacao cliente_ponto_apoio_avaliacao_ibfk_2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_ponto_apoio_avaliacao
    ADD CONSTRAINT cliente_ponto_apoio_avaliacao_ibfk_2 FOREIGN KEY (ponto_apoio_id) REFERENCES public.ponto_apoio(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cliente_skills cliente_skills_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_skills
    ADD CONSTRAINT cliente_skills_ibfk_1 FOREIGN KEY (skill_id) REFERENCES public.skills(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cliente_skills cliente_skills_ibfk_2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_skills
    ADD CONSTRAINT cliente_skills_ibfk_2 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cliente_tag cliente_tag_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_tag
    ADD CONSTRAINT cliente_tag_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON DELETE CASCADE;


--
-- Name: cliente_tag cliente_tag_mf_tag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_tag
    ADD CONSTRAINT cliente_tag_mf_tag_id_fkey FOREIGN KEY (mf_tag_id) REFERENCES public.mf_tag(id) ON DELETE CASCADE;


--
-- Name: clientes_active_sessions clientes_active_sessions_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_active_sessions
    ADD CONSTRAINT clientes_active_sessions_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: clientes_app_activity clientes_app_activity_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_app_activity
    ADD CONSTRAINT clientes_app_activity_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: clientes_app_activity_log clientes_app_activity_log_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_app_activity_log
    ADD CONSTRAINT clientes_app_activity_log_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: clientes_app_notifications clientes_app_notifications_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_app_notifications
    ADD CONSTRAINT clientes_app_notifications_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: clientes_audios_eventos clientes_audios_eventos_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_audios_eventos
    ADD CONSTRAINT clientes_audios_eventos_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: clientes_audios clientes_audios_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_audios
    ADD CONSTRAINT clientes_audios_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: clientes_audios clientes_audios_ibfk_2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_audios
    ADD CONSTRAINT clientes_audios_ibfk_2 FOREIGN KEY (media_upload_id) REFERENCES public.media_upload(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: clientes_guardioes clientes_guardioes_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_guardioes
    ADD CONSTRAINT clientes_guardioes_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: clientes_preferences clientes_preferences_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_preferences
    ADD CONSTRAINT clientes_preferences_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: clientes_preferences clientes_preferences_ibfk_2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_preferences
    ADD CONSTRAINT clientes_preferences_ibfk_2 FOREIGN KEY (preference_id) REFERENCES public.preferences(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: clientes_quiz_session clientes_quiz_session_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_quiz_session
    ADD CONSTRAINT clientes_quiz_session_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: clientes_quiz_session clientes_quiz_session_questionnaire_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_quiz_session
    ADD CONSTRAINT clientes_quiz_session_questionnaire_id_foreign FOREIGN KEY (questionnaire_id) REFERENCES public.questionnaires(id) ON DELETE SET NULL;


--
-- Name: clientes_reports clientes_reports_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_reports
    ADD CONSTRAINT clientes_reports_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.clientes(id);


--
-- Name: clientes_reports clientes_reports_reported_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_reports
    ADD CONSTRAINT clientes_reports_reported_cliente_id_fkey FOREIGN KEY (reported_cliente_id) REFERENCES public.clientes(id);


--
-- Name: clientes_reset_password clientes_reset_password_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_reset_password
    ADD CONSTRAINT clientes_reset_password_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: emaildb_queue emaildb_queue_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emaildb_queue
    ADD CONSTRAINT emaildb_queue_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.emaildb_config(id);


--
-- Name: faq_tela_sobre faq_tela_sobre_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faq_tela_sobre
    ADD CONSTRAINT faq_tela_sobre_ibfk_1 FOREIGN KEY (fts_categoria_id) REFERENCES public.faq_tela_sobre_categoria(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: login_erros login_erros_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_erros
    ADD CONSTRAINT login_erros_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: login_logs login_logs_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_logs
    ADD CONSTRAINT login_logs_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: media_upload media_upload_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_upload
    ADD CONSTRAINT media_upload_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: mf_cliente_tarefa mf_cliente_tarefa_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mf_cliente_tarefa
    ADD CONSTRAINT mf_cliente_tarefa_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.clientes(id);


--
-- Name: mf_cliente_tarefa mf_cliente_tarefa_last_from_questionnaire_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mf_cliente_tarefa
    ADD CONSTRAINT mf_cliente_tarefa_last_from_questionnaire_fkey FOREIGN KEY (last_from_questionnaire) REFERENCES public.questionnaires(id);


--
-- Name: mf_cliente_tarefa mf_cliente_tarefa_mf_tarefa_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mf_cliente_tarefa
    ADD CONSTRAINT mf_cliente_tarefa_mf_tarefa_id_fkey FOREIGN KEY (mf_tarefa_id) REFERENCES public.mf_tarefa(id);


--
-- Name: mf_questionnaire_order mf_questionnaire_order_questionnaire_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mf_questionnaire_order
    ADD CONSTRAINT mf_questionnaire_order_questionnaire_id_fkey FOREIGN KEY (questionnaire_id) REFERENCES public.questionnaires(id);


--
-- Name: mf_questionnaire_remove_tarefa mf_questionnaire_remove_tarefa_questionnaire_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mf_questionnaire_remove_tarefa
    ADD CONSTRAINT mf_questionnaire_remove_tarefa_questionnaire_id_fkey FOREIGN KEY (questionnaire_id) REFERENCES public.questionnaires(id);


--
-- Name: noticias_aberturas noticias_aberturas_cliente_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias_aberturas
    ADD CONSTRAINT noticias_aberturas_cliente_id_foreign FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON DELETE SET NULL;


--
-- Name: noticias_aberturas noticias_aberturas_noticias_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias_aberturas
    ADD CONSTRAINT noticias_aberturas_noticias_id_foreign FOREIGN KEY (noticias_id) REFERENCES public.noticias(id) ON DELETE SET NULL;


--
-- Name: noticias noticias_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias
    ADD CONSTRAINT noticias_ibfk_1 FOREIGN KEY (rss_feed_id) REFERENCES public.rss_feeds(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: noticias_tags noticias_tags_noticias_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias_tags
    ADD CONSTRAINT noticias_tags_noticias_id_foreign FOREIGN KEY (noticias_id) REFERENCES public.noticias(id) ON DELETE SET NULL;


--
-- Name: noticias_tags noticias_tags_tags_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias_tags
    ADD CONSTRAINT noticias_tags_tags_id_foreign FOREIGN KEY (tags_id) REFERENCES public.tags(id) ON DELETE SET NULL;


--
-- Name: notification_log notification_log_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_log
    ADD CONSTRAINT notification_log_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: notification_log notification_log_ibfk_2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_log
    ADD CONSTRAINT notification_log_ibfk_2 FOREIGN KEY (notification_message_id) REFERENCES public.notification_message(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: ponto_apoio2projetos ponto_apoio2projetos_ponto_apoio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ponto_apoio2projetos
    ADD CONSTRAINT ponto_apoio2projetos_ponto_apoio_id_fkey FOREIGN KEY (ponto_apoio_id) REFERENCES public.ponto_apoio(id) ON DELETE CASCADE;


--
-- Name: ponto_apoio2projetos ponto_apoio2projetos_ponto_apoio_projeto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ponto_apoio2projetos
    ADD CONSTRAINT ponto_apoio2projetos_ponto_apoio_projeto_id_fkey FOREIGN KEY (ponto_apoio_projeto_id) REFERENCES public.ponto_apoio_projeto(id) ON DELETE CASCADE;


--
-- Name: ponto_apoio ponto_apoio_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ponto_apoio
    ADD CONSTRAINT ponto_apoio_ibfk_1 FOREIGN KEY (categoria) REFERENCES public.ponto_apoio_categoria(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: ponto_apoio_sugestoes ponto_apoio_sugestoes_categoria_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ponto_apoio_sugestoes
    ADD CONSTRAINT ponto_apoio_sugestoes_categoria_foreign FOREIGN KEY (categoria) REFERENCES public.ponto_apoio_categoria(id) ON DELETE SET NULL;


--
-- Name: ponto_apoio_sugestoes ponto_apoio_sugestoes_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ponto_apoio_sugestoes
    ADD CONSTRAINT ponto_apoio_sugestoes_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ponto_apoio_sugestoes_v2 ponto_apoio_sugestoes_v2_categoria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ponto_apoio_sugestoes_v2
    ADD CONSTRAINT ponto_apoio_sugestoes_v2_categoria_fkey FOREIGN KEY (categoria) REFERENCES public.ponto_apoio_categoria(id);


--
-- Name: ponto_apoio_sugestoes_v2 ponto_apoio_sugestoes_v2_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ponto_apoio_sugestoes_v2
    ADD CONSTRAINT ponto_apoio_sugestoes_v2_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.clientes(id);


--
-- Name: ponto_apoio_sugestoes_v2 ponto_apoio_sugestoes_v2_created_ponto_apoio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ponto_apoio_sugestoes_v2
    ADD CONSTRAINT ponto_apoio_sugestoes_v2_created_ponto_apoio_id_fkey FOREIGN KEY (created_ponto_apoio_id) REFERENCES public.ponto_apoio(id);


--
-- Name: quiz_config quiz_config_change_to_questionnaire_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_config
    ADD CONSTRAINT quiz_config_change_to_questionnaire_id_fkey FOREIGN KEY (change_to_questionnaire_id) REFERENCES public.questionnaires(id);


--
-- Name: quiz_config quiz_config_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_config
    ADD CONSTRAINT quiz_config_ibfk_1 FOREIGN KEY (questionnaire_id) REFERENCES public.questionnaires(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: rss_feeds_tags rss_feeds_tags_rss_feeds_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rss_feeds_tags
    ADD CONSTRAINT rss_feeds_tags_rss_feeds_id_fkey FOREIGN KEY (rss_feeds_id) REFERENCES public.rss_feeds(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: rss_feeds_tags rss_feeds_tags_tags_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rss_feeds_tags
    ADD CONSTRAINT rss_feeds_tags_tags_id_fkey FOREIGN KEY (tags_id) REFERENCES public.tags(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tag_indexing_config tag_indexing_config_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag_indexing_config
    ADD CONSTRAINT tag_indexing_config_ibfk_1 FOREIGN KEY (tag_id) REFERENCES public.tags(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tags_highlight tags_highlight_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags_highlight
    ADD CONSTRAINT tags_highlight_ibfk_1 FOREIGN KEY (tag_id) REFERENCES public.tags(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: timeline_clientes_bloqueados timeline_clientes_bloqueados_block_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timeline_clientes_bloqueados
    ADD CONSTRAINT timeline_clientes_bloqueados_block_cliente_id_fkey FOREIGN KEY (block_cliente_id) REFERENCES public.clientes(id);


--
-- Name: timeline_clientes_bloqueados timeline_clientes_bloqueados_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timeline_clientes_bloqueados
    ADD CONSTRAINT timeline_clientes_bloqueados_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.clientes(id);


--
-- Name: tweets tweets_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tweets
    ADD CONSTRAINT tweets_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tweets_likes tweets_likes_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tweets_likes
    ADD CONSTRAINT tweets_likes_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tweets_likes tweets_likes_ibfk_2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tweets_likes
    ADD CONSTRAINT tweets_likes_ibfk_2 FOREIGN KEY (tweet_id) REFERENCES public.tweets(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tweets tweets_parent_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tweets
    ADD CONSTRAINT tweets_parent_id_foreign FOREIGN KEY (parent_id) REFERENCES public.tweets(id);


--
-- Name: tweets_reports tweets_reports_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tweets_reports
    ADD CONSTRAINT tweets_reports_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tweets_reports tweets_reports_reported_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tweets_reports
    ADD CONSTRAINT tweets_reports_reported_id_foreign FOREIGN KEY (reported_id) REFERENCES public.tweets(id) ON DELETE SET NULL;

COMMIT;