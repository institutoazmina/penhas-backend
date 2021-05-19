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

