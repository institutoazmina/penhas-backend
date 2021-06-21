/*
                                        url                                         |   collection   |  directus_action
------------------------------------------------------------------------------------+----------------+-------------------
 https://api.penhas.com.br/maintenance/tags-clear-cache?secret=LKsmj3KSK4JCMRJtPy3y | tags           | item.create:after
 https://api.penhas.com.br/maintenance/tags-clear-cache?secret=LKsmj3KSK4JCMRJtPy3y | tags           | item.update:after
 https://api.penhas.com.br/maintenance/tags-clear-cache?secret=LKsmj3KSK4JCMRJtPy3y | tags           | item.delete:after
 https://api.penhas.com.br/maintenance/tags-clear-cache?secret=LKsmj3KSK4JCMRJtPy3y | tags_highlight | item.create:after
 https://api.penhas.com.br/maintenance/tags-clear-cache?secret=LKsmj3KSK4JCMRJtPy3y | tags_highlight | item.update:after
 https://api.penhas.com.br/maintenance/tags-clear-cache?secret=LKsmj3KSK4JCMRJtPy3y | tags_highlight | item.delete:after
*/

drop table directus_activity          ;
drop table directus_collection_presets;
drop table directus_collections       ;
drop table directus_fields            ;
drop table directus_files             ;
drop table directus_folders           ;
drop table directus_migrations        ;
drop table directus_permissions       ;
drop table directus_relations         ;
drop table directus_revisions         ;
drop table directus_roles             ;
drop table directus_settings          ;
drop table directus_user_sessions     ;
drop table directus_users             ;
drop table directus_webhooks          ;

-- 17:09:00 ✨ No admin email provided. Defaulting to "renato.santos@appcivico.com"
-- 17:09:00 ✨ No admin password provided. Defaulting to "46KvZ2a0DB5w@2"

alter table "admin_big_numbers" add column "owner_new" uuid null;
alter table "admin_big_numbers" add column "modified_by_new" uuid null;

alter table "admin_big_numbers" drop column "owner";
alter table "admin_big_numbers" drop column "modified_by";

alter table admin_clientes_segments alter column cond drop default;
alter table admin_clientes_segments alter column cond type json using cond::json;
alter table admin_clientes_segments alter column cond set default '{}';

alter table admin_clientes_segments alter column attr drop default;
alter table admin_clientes_segments alter column attr type json using attr::json;
alter table admin_clientes_segments alter column attr set default '{}';


alter table cliente_ativacoes_panico alter column alert_sent_to drop default;
alter table cliente_ativacoes_panico alter column alert_sent_to type json using alert_sent_to::json;
alter table cliente_ativacoes_panico alter column alert_sent_to set default '{}';


alter table cliente_ativacoes_panico alter column meta drop default;
alter table cliente_ativacoes_panico alter column meta type json using meta::json;
alter table cliente_ativacoes_panico alter column meta set default '{}';

alter table "ponto_apoio" drop column "owner";
alter table "ponto_apoio" add column "owner" uuid null;

alter table "ponto_apoio_projeto" drop column "owner";
alter table "ponto_apoio_projeto" add column "owner" uuid null;


alter table "ponto_apoio_categoria" drop column "owner";
alter table "ponto_apoio_categoria" add column "owner" uuid null;

alter table delete_log alter column data drop default;
alter table delete_log alter column data type json using data::json;
alter table delete_log alter column data set default '{}';


alter table ponto_apoio_sugestoes alter column metainfo drop default;
alter table ponto_apoio_sugestoes alter column metainfo type json using metainfo::json;
alter table ponto_apoio_sugestoes alter column metainfo set default '{}';

alter table "faq_tela_guardiao" drop column "owner";
alter table "faq_tela_guardiao" add column "owner" uuid null;

alter table "faq_tela_guardiao" drop column "modified_by";
alter table "faq_tela_guardiao" add column "modified_by" uuid null;

alter table "faq_tela_sobre_categoria" drop column "owner";
alter table "faq_tela_sobre_categoria" add column "owner" uuid null;

alter table "faq_tela_sobre_categoria" drop column "modified_by";
alter table "faq_tela_sobre_categoria" add column "modified_by" uuid null;


alter table "rss_feeds" drop column "owner";
alter table "rss_feeds" add column "owner" uuid null;

alter table "rss_feeds" drop column "modified_by";
alter table "rss_feeds" add column "modified_by" uuid null;

create table "rss_feeds_tags" ("id" serial primary key);
alter table "rss_feeds_tags" add column "tags_id" bigint null;
alter table "rss_feeds_tags" add column "rss_feeds_id" bigint null;
insert into rss_feeds_tags (tags_id, rss_feeds_id) select tag_id, rss_feed_id from rss_feed_forced_tags;
drop table rss_feed_forced_tags;

create table "noticias_tags" ("id" serial primary key);
alter table "noticias_tags" add column "noticias_id" bigint null;;
alter table "noticias_tags" add column "tags_id" bigint null;

insert into noticias_tags (noticias_id, tags_id) select noticias_id, tag_id from public.noticias2tags;
drop table public.noticias2tags;


alter table "faq_tela_sobre" drop column "owner";
alter table "faq_tela_sobre" add column "owner" uuid null;

alter table "faq_tela_sobre" drop column "modified_by";
alter table "faq_tela_sobre" add column "modified_by" uuid null;

alter table "skills" drop column "owner";
alter table "skills" add column "owner" uuid null;

alter table "skills" drop column "modified_by";
alter table "skills" add column "modified_by" uuid null;


alter table "admin_clientes_segments" drop column "owner";
alter table "admin_clientes_segments" add column "owner" uuid null;

alter table "admin_clientes_segments" drop column "modified_by";
alter table "admin_clientes_segments" add column "modified_by" uuid null;

alter table "tags_highlight" drop column "owner";
alter table "tags_highlight" add column "owner" uuid null;

alter table "tags_highlight" drop column "modified_by";
alter table "tags_highlight" add column "modified_by" uuid null;

alter table "tag_indexing_config" drop column "owner";
alter table "tag_indexing_config" add column "owner" uuid null;

alter table "tag_indexing_config" drop column "modified_by";
alter table "tag_indexing_config" add column "modified_by" uuid null;


alter table "skills" alter column skill type varchar(100);
alter table "skills" alter column sort type int;

alter table noticias alter column hyperlink type varchar;
alter table noticias alter column fonte type varchar;
alter table noticias alter column image_hyperlink type varchar;


alter table noticias alter column info drop default;
alter table noticias alter column info type json using info::json;
alter table noticias alter column info set default '{}';



alter table "questionnaires" drop column "owner";
alter table "questionnaires" add column "owner" uuid null;

alter table "questionnaires" drop column "modified_by";
alter table "questionnaires" add column "modified_by" uuid null;

alter table "questionnaires" alter column "condition" set default '0';


alter table clientes_quiz_session alter column stash drop default;
alter table clientes_quiz_session alter column stash type json using stash::json;
alter table clientes_quiz_session alter column stash set default '{}';

alter table clientes_quiz_session alter column responses drop default;
alter table clientes_quiz_session alter column responses type json using responses::json;
alter table clientes_quiz_session alter column responses set default '{}';

alter table quiz_config alter column yesnogroup drop default;
alter table quiz_config alter column yesnogroup type json using yesnogroup::json;
alter table quiz_config alter column yesnogroup set default '{}';

alter table quiz_config alter column intro drop default;
alter table quiz_config alter column intro type json using intro::json;
alter table quiz_config alter column intro set default '{}';

alter table "quiz_config" drop column "modified_by";
alter table "quiz_config" add column "modified_by" uuid null;

alter table "quiz_config" alter column code type varchar;

alter table clientes_audios_eventos  alter  COLUMN event_id type varchar(200);




------------


delete from directus_relations where many_field = 'cliente_id';
insert into directus_relations( many_collection, many_field, many_primary, one_collection, one_primary) values
('chat_clientes_notifications', 'cliente_id', 'id', 'clientes', 'id'),
('chat_support', 'cliente_id', 'id', 'clientes', 'id'),
('chat_support_message', 'cliente_id', 'id', 'clientes', 'id'),
('cliente_ativacoes_panico', 'cliente_id', 'id', 'clientes', 'id'),
('cliente_ativacoes_policia', 'cliente_id', 'id', 'clientes', 'id'),
('cliente_bloqueios', 'cliente_id', 'id', 'clientes', 'id'),
('cliente_ponto_apoio_avaliacao', 'cliente_id', 'id', 'clientes', 'id'),
('cliente_skills', 'cliente_id', 'id', 'clientes', 'id'),
('clientes_active_sessions', 'cliente_id', 'id', 'clientes', 'id'),
('clientes_app_activity', 'cliente_id', 'id', 'clientes', 'id'),
('clientes_app_notifications', 'cliente_id', 'id', 'clientes', 'id'),
('clientes_audios_eventos', 'cliente_id', 'id', 'clientes', 'id'),
('clientes_audios', 'cliente_id', 'id', 'clientes', 'id'),
('clientes_guardioes', 'cliente_id', 'id', 'clientes', 'id'),
('clientes_preferences', 'cliente_id', 'id', 'clientes', 'id'),
('clientes_quiz_session', 'cliente_id', 'id', 'clientes', 'id'),
('clientes_reset_password', 'cliente_id', 'id', 'clientes', 'id'),
('login_erros', 'cliente_id', 'id', 'clientes', 'id'),
('login_logs', 'cliente_id', 'id', 'clientes', 'id'),
('media_upload', 'cliente_id', 'id', 'clientes', 'id'),
('notification_log', 'cliente_id', 'id', 'clientes', 'id'),
('ponto_apoio_sugestoes', 'cliente_id', 'id', 'clientes', 'id'),
('tweets', 'cliente_id', 'id', 'clientes', 'id'),
('tweets_likes', 'cliente_id', 'id', 'clientes', 'id'),
('tweets_reports', 'cliente_id', 'id', 'clientes', 'id');
delete from directus_fields where field = 'cliente_id';
insert into directus_fields( collection, field, interface, options, display, display_options, readonly, hidden, width) values
('chat_clientes_notifications', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('chat_support', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('chat_support_message', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('cliente_ativacoes_panico', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('cliente_ativacoes_policia', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('cliente_bloqueios', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('cliente_ponto_apoio_avaliacao', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('cliente_skills', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('clientes_active_sessions', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('clientes_app_activity', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('clientes_app_notifications', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('clientes_audios_eventos', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('clientes_audios', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('clientes_guardioes', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('clientes_preferences', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('clientes_quiz_session', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('clientes_reset_password', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('login_erros', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('login_logs', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('media_upload', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('notification_log', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('ponto_apoio_sugestoes', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('tweets', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('tweets_likes', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full'),
('tweets_reports', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full')
;


insert into directus_relations( many_collection, many_field, many_primary, one_collection, one_primary) values
('cliente_bloqueios', 'blocked_cliente_id', 'id', 'clientes', 'id');
insert into directus_fields( collection, field, interface, options, display, display_options, readonly, hidden, width) values
('cliente_bloqueios', 'blocked_cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full');

insert into directus_fields( collection, field, interface, options, display, display_options, readonly, hidden, width) values
('ponto_apoio', 'cliente_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}', 'related-values', '{"template":"({{id}}) {{nome_completo}}, {{apelido}}"}',false, false, 'full');


insert into directus_relations( many_collection, many_field, many_primary, one_collection, one_primary) values
('cliente_ponto_apoio_avaliacao', 'ponto_apoio_id', 'id', 'ponto_apoio', 'id');
insert into directus_fields( collection, field, interface, options, display, display_options, readonly, hidden, width) values
('cliente_ponto_apoio_avaliacao', 'ponto_apoio_id', 'select-dropdown-m2o', '{"template":"({{id}}) {{nome}}"}', 'related-values', '{"template":"({{id}}) {{nome}}"}',false, false, 'full');


insert into directus_relations( many_collection, many_field, many_primary, one_collection, one_primary) values
('cliente_skills', 'skill_id', 'id', 'skills', 'id');
insert into directus_fields( collection, field, interface, options, display, display_options, readonly, hidden, width) values
('cliente_skills', 'skill_id', 'select-dropdown-m2o', '{"template":"({{id}})  "}', 'related-values', '{"template":"({{id}}"}',false, false, 'full');

insert into directus_relations( many_collection, many_field, many_primary, one_collection, one_primary) values
('cliente_skills', 'skill_id', 'id', 'skills', 'id');
insert into directus_fields( collection, field, interface, options, display, display_options, readonly, hidden, width) values
('cliente_skills', 'skill_id', 'select-dropdown-m2o', '{"template":"({{id}})  "}', 'related-values', '{"template":"({{id}}"}',false, false, 'full');



insert into directus_relations( many_collection, many_field, many_primary, one_collection, one_primary) values
('ponto_apoio_categoria2projetos', 'ponto_apoio_categoria_id', 'id', 'ponto_apoio_categoria', 'id');
insert into directus_fields( collection, field, interface, options, display, display_options, readonly, hidden, width) values
('ponto_apoio_categoria2projetos', 'ponto_apoio_categoria_id', 'select-dropdown-m2o', '{"template":"({{id}})  "}', 'related-values', '{"template":"({{id}}"}',false, false, 'full');



insert into directus_relations( many_collection, many_field, many_primary, one_collection, one_primary) values
('clientes_preferences', 'preference_id', 'id', 'preferences', 'id');
insert into directus_fields( collection, field, interface, options, display, display_options, readonly, hidden, width) values
('clientes_preferences', 'preference_id', 'select-dropdown-m2o', '{"template":"({{id}})  "}', 'related-values', '{"template":"({{id}})"}',false, false, 'full');



insert into directus_relations( many_collection, many_field, many_primary, one_collection, one_primary) values
('quiz_config', 'questionnaire_id', 'id', 'questionnaires', 'id');
insert into directus_fields( collection, field, interface, options, display, display_options, readonly, hidden, width) values
('quiz_config', 'questionnaire_id', 'select-dropdown-m2o', '{"template":"({{id}})  "}', 'related-values', '{"template":"({{id}})"}',false, false, 'full');


