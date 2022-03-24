-- Deploy penhas:0020-relatorio_cliente_suporte to pg
-- requires: 0019-municipalities

BEGIN;

create table relatorio_chat_cliente_suporte (
    id serial not null primary key,
    cliente_id int  not null,
    created_at timestamp not null default now()
);

insert into relatorio_chat_cliente_suporte(cliente_id, created_at)
select cliente_id, min(created_at)
from chat_support_message
where admin_user_id is null
group by 1;



COMMIT;
