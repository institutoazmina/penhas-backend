# Guia de Performance

## Visão Geral

Este guia aborda estratégias de otimização de performance, técnicas de benchmarking e melhores práticas para manter o desempenho ideal no backend PenhaS.

## Arquitetura de Performance

### Princípios-Chave de Performance

1. **Minimizar Consultas ao Banco de Dados** - Usar carregamento antecipado e cache
2. **Otimizar Caminhos Críticos** - Focar em endpoints frequentemente usados
3. **Processamento Assíncrono** - Delegar tarefas pesadas para jobs em background
4. **Cache Eficiente** - Cache em múltiplos níveis
5. **Pool de Recursos** - Reutilizar conexões e recursos

### Metas de Performance

| Métrica | Meta | Máximo |
|---------|------|--------|
| Tempo de Resposta da API (p50) | < 100ms | 200ms |
| Tempo de Resposta da API (p95) | < 500ms | 1s |
| Tempo de Resposta da API (p99) | < 1s | 2s |
| Tempo de Consulta ao Banco | < 50ms | 100ms |
| Processamento de Jobs em Background | < 30s | 5min |
| Usuários Concorrentes | 10.000 | 50.000 |

## Otimização do Banco de Dados

### Otimização de Consultas

#### 1. Usar Índices Efetivamente

```sql
-- Analisar performance de consultas
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM ponto_apoio 
WHERE ST_DWithin(geog, ST_MakePoint(-46.633, -23.550)::geography, 5000);

-- Criar índices apropriados
CREATE INDEX idx_ponto_apoio_categoria_status 
ON ponto_apoio(categoria, status) 
WHERE status = 'active';

-- Índices parciais para consultas comuns
CREATE INDEX idx_clientes_active 
ON clientes(email) 
WHERE status = 'active';

-- Índices compostos para consultas complexas
CREATE INDEX idx_chat_session_lookup 
ON chat_session(cliente_a_id, cliente_b_id, last_message_at DESC);
```

#### 2. Padrões de Otimização de Consultas

```perl
# Ruim: Problema de consulta N+1
my @users = $schema->resultset('Cliente')->all;
foreach my $user (@users) {
    my @guardians = $user->guardians->all;  # N consultas
}

# Bom: Carregamento antecipado
my @users = $schema->resultset('Cliente')->search(
    {},
    { prefetch => 'guardians' }  # 1 consulta
)->all;

# Ruim: Carregando colunas desnecessárias
my $user = $schema->resultset('Cliente')->find($id);

# Bom: Selecionar apenas colunas necessárias
my $user = $schema->resultset('Cliente')->search(
    { id => $id },
    { columns => [qw/id nome_completo email/] }
)->single;
```

#### 3. Pool de Conexões do Banco de Dados

```perl
# Conexão DBIx::Class com pooling
my $schema = Penhas::Schema->connect(
    $dsn, $user, $pass,
    {
        pg_enable_utf8 => 1,
        AutoCommit => 1,
        RaiseError => 1,
        PrintError => 0,
        pg_server_prepare => 0,  # Desabilitar para melhor pooling de conexão
        quote_char => '"',
        name_sep => '.',
        # Configurações do pool de conexões
        connect_info => {
            dbh_maker => sub {
                my $dbh = DBI->connect(@_);
                $dbh->{pg_server_prepare} = 0;
                return $dbh;
            }
        }
    }
);
```

### Ajuste do PostgreSQL

#### 1. Otimização de Configuração

```ini
# Otimizações do postgresql.conf

# Configuração de Memória
shared_buffers = 4GB              # 25% da RAM
effective_cache_size = 12GB       # 75% da RAM
work_mem = 50MB                   # Por operação
maintenance_work_mem = 1GB        # Para VACUUM, índices

# Configurações de Checkpoint
checkpoint_completion_target = 0.9
checkpoint_timeout = 15min
max_wal_size = 4GB
min_wal_size = 1GB

# Planejamento de Consultas
random_page_cost = 1.1            # Para SSD
effective_io_concurrency = 200    # Para SSD
default_statistics_target = 100

# Consultas Paralelas
max_parallel_workers_per_gather = 4
max_parallel_workers = 8
parallel_leader_participation = on

# Configurações de Conexão
max_connections = 200
superuser_reserved_connections = 3
```

#### 2. Otimização de Tabelas

```sql
-- Analisar tabelas regularmente
VACUUM ANALYZE clientes;

-- Encontrar tabelas inchadas
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS tamanho,
    ROUND(100 * pg_total_relation_size(schemaname||'.'||tablename) / 
          pg_database_size(current_database()))::numeric, 2) AS percentual
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 20;

-- Reconstruir índices inchados
REINDEX INDEX CONCURRENTLY idx_name;

-- Particionar tabelas grandes
CREATE TABLE clientes_audios_2023 PARTITION OF clientes_audios
FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');
```

## Estratégia de Cache

### Cache Multi-Nível

```
┌─────────────┐
│  Navegador  │ ← Headers de Cache HTTP
├─────────────┤
│     CDN     │ ← Assets Estáticos
├─────────────┤
│    Nginx    │ ← Micro-cache
├─────────────┤
│ Cache App   │ ← Redis
├─────────────┤
│ Cache BD    │ ← Resultados de Consultas
└─────────────┘
```

### Implementação de Cache Redis

#### 1. Helpers de Cache

```perl
# lib/Penhas/Helpers/Cache.pm
sub cache_get_or_set {
    my ($self, $key, $ttl, $callback) = @_;
    
    my $redis = $self->redis;
    my $cached = $redis->get($key);
    
    if ($cached) {
        $self->stash(cache_hit => 1);
        return decode_json($cached);
    }
    
    my $data = $callback->();
    
    if ($data) {
        $redis->setex($key, $ttl, encode_json($data));
    }
    
    $self->stash(cache_hit => 0);
    return $data;
}

# Invalidar caches relacionados
sub cache_invalidate_pattern {
    my ($self, $pattern) = @_;
    
    my $redis = $self->redis;
    my @keys = $redis->keys($pattern);
    
    if (@keys) {
        $redis->del(@keys);
    }
}
```

#### 2. Padrões de Cache

```perl
# Cache de dados do usuário
sub get_user_modules {
    my ($self, $user_id) = @_;
    
    return $self->cache_get_or_set(
        "MOD:$user_id",
        3600,  # 1 hora
        sub {
            my $user = $self->schema->resultset('Cliente')->find($user_id);
            return $user->access_modules_as_config;
        }
    );
}

# Cache com tags para invalidação
sub get_ponto_apoio_list {
    my ($self, %params) = @_;
    
    my $cache_key = "PA:" . md5_hex(encode_json(\%params));
    
    return $self->cache_get_or_set(
        $cache_key,
        300,  # 5 minutos
        sub {
            # Consulta geoespacial custosa
            return $self->_query_ponto_apoio(%params);
        }
    );
}
```

### Cache HTTP

```perl
# Definir headers de cache
sub set_cache_headers {
    my ($self, $ttl) = @_;
    
    my $res = $self->res;
    
    if ($ttl > 0) {
        $res->headers->cache_control("public, max-age=$ttl");
        $res->headers->expires(time + $ttl);
        
        # ETag para requisições condicionais
        my $etag = md5_hex($res->body);
        $res->headers->etag(qq{"$etag"});
    } else {
        $res->headers->cache_control('no-cache, no-store, must-revalidate');
        $res->headers->pragma('no-cache');
        $res->headers->expires(0);
    }
}

# Lidar com requisições condicionais
sub handle_etag {
    my $self = shift;
    
    my $etag = $self->req->headers->if_none_match;
    my $current_etag = $self->calculate_etag;
    
    if ($etag && $etag eq qq{"$current_etag"}) {
        $self->rendered(304);
        return 1;
    }
    
    return 0;
}
```

## Otimização da Aplicação

### Otimização de Código

#### 1. Minimizar Criação de Objetos

```perl
# Ruim: Criando objetos desnecessários
sub process_users {
    my @results;
    foreach my $id (@user_ids) {
        my $user = $schema->resultset('Cliente')->find($id);
        push @results, {
            id => $user->id,
            name => $user->nome_completo,
        };
    }
    return \@results;
}

# Bom: Processamento em lote
sub process_users {
    my $users = $schema->resultset('Cliente')->search(
        { id => { -in => \@user_ids } },
        { columns => [qw/id nome_completo/] }
    );
    
    return [
        map { { id => $_->id, name => $_->nome_completo } }
        $users->all
    ];
}
```

#### 2. Carregamento Preguiçoso

```perl
# Carregamento preguiçoso de atributos
has '_expensive_data' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_expensive_data',
);

sub _build_expensive_data {
    my $self = shift;
    # Computado apenas quando acessado pela primeira vez
    return $self->compute_expensive_data;
}
```

### Processamento Assíncrono

#### 1. I/O Não-Bloqueante

```perl
# Usar Mojo::UserAgent para requisições HTTP assíncronas
sub fetch_multiple_apis {
    my $self = shift;
    
    my $ua = Mojo::UserAgent->new;
    my @promises;
    
    # Fazer requisições paralelas
    push @promises, $ua->get_p('https://api1.example.com/data');
    push @promises, $ua->get_p('https://api2.example.com/data');
    push @promises, $ua->get_p('https://api3.example.com/data');
    
    # Aguardar todas completarem
    Mojo::Promise->all(@promises)->then(sub {
        my @results = @_;
        # Processar resultados
    })->catch(sub {
        my $err = shift;
        # Lidar com erros
    })->wait;
}
```

#### 2. Otimização de Jobs em Background

```perl
# Processamento em lote em jobs background
sub process_notifications {
    my ($job, $user_ids) = @_;
    
    # Processar em lotes
    my $batch_size = 100;
    
    while (my @batch = splice @$user_ids, 0, $batch_size) {
        # Inserção em massa
        my @notifications = map {
            {
                user_id => $_,
                message => 'Texto da notificação',
                created_at => \'NOW()'
            }
        } @batch;
        
        $schema->resultset('Notification')->populate(\@notifications);
        
        # Atualizar progresso do job
        $job->note(processed => $job->info->{notes}{processed} + @batch);
    }
}
```

## Otimização de Carga

### Otimização de Requisições

#### 1. Paginação

```perl
sub list_with_pagination {
    my ($self, %params) = @_;
    
    my $page = $params{page} || 1;
    my $rows = $params{rows} || 20;
    
    # Limitar máximo de linhas
    $rows = 100 if $rows > 100;
    
    my $rs = $schema->resultset('News')->search(
        { status => 'published' },
        {
            rows => $rows,
            page => $page,
            order_by => { -desc => 'created_at' },
            # Selecionar apenas colunas necessárias
            columns => [qw/id title summary created_at/],
        }
    );
    
    return {
        rows => [$rs->all],
        total => $rs->pager->total_entries,
        page => $page,
        total_pages => $rs->pager->last_page,
    };
}
```

#### 2. Filtragem de Campos

```perl
# Permitir que clientes requisitem campos específicos
sub get_user_profile {
    my $self = shift;
    
    my $fields = $self->param('fields');
    my @columns = $fields 
        ? split(',', $fields)
        : qw/id nome_completo email avatar_url/;
    
    # Validar campos requisitados
    my %allowed = map { $_ => 1 } qw/
        id nome_completo email avatar_url 
        created_at skills modo_anonimo_ativo
    /;
    
    @columns = grep { $allowed{$_} } @columns;
    
    my $user = $schema->resultset('Cliente')->search(
        { id => $self->stash('user_id') },
        { columns => \@columns }
    )->single;
    
    return $self->render(json => { $user->get_columns });
}
```

### Pool de Recursos

#### 1. Pool de Conexões

```perl
# Reutilizar conexões de banco de dados
package Penhas::ConnectionPool;

use Moo;
use DBI;

has 'pool' => (is => 'ro', default => sub { [] });
has 'size' => (is => 'ro', default => 10);

sub get_connection {
    my $self = shift;
    
    # Retornar conexão existente
    if (my $dbh = pop @{$self->pool}) {
        return $dbh if $dbh->ping;
    }
    
    # Criar nova conexão
    return DBI->connect($dsn, $user, $pass, {
        RaiseError => 1,
        AutoCommit => 1,
        pg_server_prepare => 0,
    });
}

sub return_connection {
    my ($self, $dbh) = @_;
    
    if (@{$self->pool} < $self->size && $dbh->ping) {
        push @{$self->pool}, $dbh;
    } else {
        $dbh->disconnect;
    }
}
```

## Monitoramento de Performance

### Métricas da Aplicação

```perl
# Métricas Prometheus
use Prometheus::Tiny;

has prometheus => sub {
    my $prom = Prometheus::Tiny->new;
    
    # Definir métricas
    $prom->declare('http_requests_total', 
        help => 'Total de requisições HTTP',
        type => 'counter'
    );
    
    $prom->declare('http_request_duration_seconds',
        help => 'Duração de requisições HTTP',
        type => 'histogram',
        buckets => [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
    );
    
    $prom->declare('db_query_duration_seconds',
        help => 'Duração de consultas ao banco',
        type => 'histogram'
    );
    
    return $prom;
};

# Rastrear métricas
$app->hook(around_action => sub {
    my ($next, $c, $action, $last) = @_;
    
    my $start = [gettimeofday];
    
    $next->();
    
    my $elapsed = tv_interval($start);
    
    $c->prometheus->inc('http_requests_total', {
        method => $c->req->method,
        endpoint => $action,
        status => $c->res->code
    });
    
    $c->prometheus->histogram_observe(
        'http_request_duration_seconds',
        $elapsed,
        { endpoint => $action }
    );
});
```

### Testes de Performance

#### 1. Script de Teste de Carga

```bash
#!/bin/bash
# load-test.sh

# Configuração do teste
API_URL="https://api.penhas.com.br"
CONCURRENT_USERS=100
REQUESTS_PER_USER=1000
AUTH_TOKEN="test-jwt-token"

# Executar teste de carga com Apache Bench
ab -n $((CONCURRENT_USERS * REQUESTS_PER_USER)) \
   -c $CONCURRENT_USERS \
   -H "x-api-key: $AUTH_TOKEN" \
   -H "Content-Type: application/json" \
   "$API_URL/me"

# Testar com wrk para métricas mais detalhadas
wrk -t12 -c400 -d30s \
    -H "x-api-key: $AUTH_TOKEN" \
    --latency \
    "$API_URL/timeline"

# Testar endpoint de upload de arquivo
for i in {1..100}; do
    curl -X POST "$API_URL/me/audios/upload" \
        -H "x-api-key: $AUTH_TOKEN" \
        -F "media=@test-audio.aac" \
        -F "event_id=$(uuidgen)" \
        -F "event_sequence=$i" \
        -w "\n%{http_code} %{time_total}s\n" &
done
wait
```

#### 2. Teste de Performance do Banco de Dados

```sql
-- Testar performance de consultas
\timing on

-- Performance de consultas geoespaciais
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT id, nome, 
       ST_Distance(geog, ST_MakePoint(-46.633, -23.550)::geography) as distancia
FROM ponto_apoio
WHERE ST_DWithin(geog, ST_MakePoint(-46.633, -23.550)::geography, 5000)
ORDER BY distancia
LIMIT 20;

-- Testar conexões concorrentes
DO $$
DECLARE
    i INTEGER;
BEGIN
    FOR i IN 1..100 LOOP
        PERFORM pg_sleep(0.1);
        PERFORM count(*) FROM clientes WHERE id = (random() * 10000)::int;
    END LOOP;
END $$;
```

## Checklist de Otimização

### Pré-Deploy
- [ ] Índices do banco de dados revisados e otimizados
- [ ] Consultas lentas identificadas e corrigidas
- [ ] Estratégia de cache implementada
- [ ] Pool de conexões configurado
- [ ] Teste de carga concluído
- [ ] Métricas de monitoramento implementadas

### Manutenção Regular
- [ ] Semanal: Analisar log de consultas lentas
- [ ] Semanal: Revisar taxas de acerto de cache
- [ ] Mensal: Atualizar estatísticas de tabelas
- [ ] Mensal: Revisar e otimizar índices
- [ ] Trimestral: Teste de regressão de performance
- [ ] Trimestral: Revisão de planejamento de capacidade

### Resposta a Emergências
- [ ] Identificar gargalo de performance
- [ ] Habilitar cache de emergência
- [ ] Escalar recursos se necessário
- [ ] Desabilitar funcionalidades não-críticas
- [ ] Implementar rate limiting
- [ ] Revisar e otimizar caminho crítico