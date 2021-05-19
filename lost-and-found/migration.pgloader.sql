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

alter table "faq_tela_guardiao" drop column "owner";
alter table "faq_tela_guardiao" add column "owner" uuid null;

alter table "faq_tela_guardiao" drop column "modified_by";
alter table "faq_tela_guardiao" add column "modified_by" uuid null;



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
('ponto_apoio', 'categoria', 'id', 'ponto_apoio_categoria', 'id');
insert into directus_fields( collection, field, interface, options, display, display_options, readonly, hidden, width) values
('ponto_apoio', 'categoria', 'select-dropdown-m2o', '{"template":"({{id}})  "}', 'related-values', '{"template":"({{id}})"}',false, false, 'full');


