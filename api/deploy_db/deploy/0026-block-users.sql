-- Deploy penhas:0026-block-users to pg
-- requires: 0025-pa-sug-form

BEGIN;

create table clientes_reports (
    id bigserial not null primary key,
    cliente_id int not null references clientes(id),
    reported_cliente_id int not null references clientes(id),
    reason varchar(200) not null,
    created_at timestamp without time zone not null default now()
);

-- já existe uma cliente_bloqueios que é a do chat
create table timeline_clientes_bloqueados (
    id bigserial not null primary key,
    cliente_id int not null references clientes(id),
    block_cliente_id int not null references clientes(id),
    created_at timestamp without time zone not null default now(),
    -- se um dia a gente fazer o 'unblock' a gente controla o log por aqui
    valid_until timestamp without time zone not null default 'infinity'
);

-- ids dos clientes que estão blocked no momento
alter table clientes add column timeline_clientes_bloqueados_ids int[] not null default '{}'::int[];

COMMIT;
