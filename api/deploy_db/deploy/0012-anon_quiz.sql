-- Deploy penhas:0012-anon_quiz to pg
-- requires: 0011-field-options

BEGIN;

create table anonymous_quiz_session (

id bigserial      not null primary key,
remote_id         varchar not null,
questionnaire_id  bigint not null references "questionnaires"(id),
finished_at       timestamp with time zone,
created_at        timestamp with time zone not null default now(),
stash             json default '{}'::json,
responses         json default '{}'::json,
deleted_at        timestamp with time zone,
deleted           boolean not null default  false
);


insert into penhas_config (name,value) values ('ANON_QUIZ_SECRET', uuid_generate_v4()::text);

alter table questionnaires add column penhas_start_automatically boolean not null default true;
alter table questionnaires add column penhas_cliente_required boolean not null default true;

insert into "questionnaires" ("id", "active", "created_on", "modified_on", "name", "owner",penhas_cliente_required,penhas_start_automatically) values
(2, false, '2021-05-31 18:31:21.186+00', '2021-05-31 18:30:31+00', 'anon-test', null, false, false);


CREATE TABLE public.twitter_bot_config (
    id integer NOT NULL,
    user_created uuid,
    date_created timestamp with time zone,
    user_updated uuid,
    date_updated timestamp with time zone,
    config json DEFAULT '{}'::json NOT NULL
);

CREATE SEQUENCE public.twitter_bot_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE ONLY public.twitter_bot_config ALTER COLUMN id SET DEFAULT nextval('public.twitter_bot_config_id_seq'::regclass);

INSERT INTO public.twitter_bot_config (id, user_created, date_created, user_updated, date_updated, config) VALUES (1, 'ee6a474a-02d0-4fa9-8fd6-62665efa5938', '2021-07-01 16:44:24.582+00', 'ee6a474a-02d0-4fa9-8fd6-62665efa5938', '2021-07-29 20:56:34.885+00', '{"nodes":[{"code":"node_tos","type":"text_message","input_type":"quick_reply","messages":["Olá! Seja bem-vinda ao PenhaS, o projeto de enfrentamento à violência contra mulher da Revista AzMina. Aqui no Twitter, a gente fornece informações sobre relacionamentos abusivos tanto para quem está passando por isso, quanto para quem conhece alguma mulher nessa situação e quer ajudar. Não armazenamos nenhuma informação pessoal e tudo que você responder aqui será utilizado com o único objetivo de lhe orientar sobre o assunto. Vocē concorda com os termos ?"],"quick_replies":[{"label":"👍 Sim","metadata":"node_tos_accepted"},{"label":"👎 Não","metadata":"node_tos_refused"}],"children":["node_tos_accepted","node_tos_refused"]},{"code":"node_welcome_back","type":"text_message","input_type":"quick_reply","messages":["Bem-vinda de volta! Aperte no botão abaixo para começar novamente"],"quick_replies":[{"label":"🔃 Começar novamente","metadata":"node_tos_accepted"}],"children":["node_tos_accepted"]},{"code":"node_tos_refused","type":"text_message","input_type":"quick_reply","messages":["Infelizmente não podemos continuar a nossa conversa por aqui. Se quiser, você pode baixar gratuitamente o app do PenhaS em seu celular. Para saber mais, acesse: www.penhas.com.br. Um abraço carinhoso"],"quick_replies":[{"label":"🔙 Voltar","metadata":"node_tos"}],"children":["node_tos"]},{"code":"node_tos_accepted","type":"questionnaire","questionnaire_id":"8","is_conversation_end":true,"on_conversation_end":"restart","parent":"node_1","children":null}],"tag_code_config":{"default":0,"scenarios":[{"tag_code_value":1,"check_code":"P3a_para_mim"},{"tag_code_value":2,"check_code":"P3a_para_outra"},{"tag_code_value":3,"check_code":"P2b"}]},"timeout_seconds":86400,"timeout_message":"vamos nos falar mais tarde!","error_msg":"Não entendi! Utilize os botões abaixo","finish_condition":{"scenarios":[{"check_code":["btn_fim_1","btn_fim_2"]}]}}');


COMMIT;
