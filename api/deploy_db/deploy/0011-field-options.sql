-- Deploy penhas:0011-field-options to pg
-- requires: 0010-fix-chat_support_message

BEGIN;

alter  table quiz_config alter column yesnogroup set default '[]';
alter  table quiz_config alter column intro set default '[]';
alter table quiz_config add column options json not null default '[]';

update "directus_fields"
set
"special" = null,
"interface" = 'list',
 "options" = '{"template":"{{label}}","addLabel":"Nova opção","fields":[{"field":"value","name":"value","type":"string","meta":{"field":"value","width":"half","type":"string","note":"valor a ser salvo na resposta","interface":"input"}},{"field":"label","name":"label","type":"string","meta":{"field":"label","width":"half","type":"string","note":"Valor a ser exibido para usuário selecionar","interface":"input"}}]}',

 "display" = 'raw',
 "display_options" = null,
 "readonly" = false,
 "hidden" =false,
 "sort" = null,
 "width" = 'full',
 "group" = null,
 "translations" = null,
  "note" = null

where "collection" = 'quiz_config' and "field" = 'options';




update "directus_fields"
set


 "options" = '{"choices":[{"text":"Sim/Não","value":"yesno"},{"text":"Texto livre (apenas twitter)","value":"text"},{"text":"Grupo de Sim/Não","value":"yesnogroup"},{"text":"Lista de skill (apenas app)","value":"skillset"},{"text":"Botão modo camuflado","value":"botao_tela_modo_camuflado"},{"text":"Apenas Exibir texto","value":"displaytext"},{"text":"Botão de finalizar","value":"botao_fim"},{"text":"Lista de opção (selecionar uma)","value":"onlychoice"},{"text":"Busca de cep","value":"cep_address_lookup"}]}',
 display_options = '{"choices":[{"text":"Sim/Não","value":"yesno"},{"text":"Texto livre","value":"text"},{"text":"Grupo de Sim/Não","value":"yesnogroup"},{"text":"Lista de skill","value":"skillset"},{"text":"Botão modo camuflado","value":"botao_tela_modo_camuflado"},{"text":"Exibir texto","value":"displaytext"},{"text":"Botão de finalizar","value":"botao_fim"},{"text":"Busca de cep","value":"cep_address_lookup"},{"text":"Lista de opção (selecionar uma)","value":"onlychoice"}]}'


where "collection" = 'quiz_config' and "field" = 'type';

insert into "quiz_config"  (code, "question", sort, "type", "options", relevance,

questionnaire_id, status )
 values (
     'chooseone', 'choose one', 10, 'onlychoice', '[{"value":"a","label":"option a"},{"value":"b","label":"option b"}]','1', 4, 'published');


alter  table quiz_config alter column sort type int;

delete from directus_fields where collection = 'quiz_config' and field ='sort';
insert into "directus_fields" ("collection", "field", "interface", "display") values ('quiz_config', 'sort','input','raw');


update quiz_config set  yesnogroup= '[]' where yesnogroup::text='{}';
update quiz_config set  intro= '[]' where intro::text='{}';


COMMIT;
