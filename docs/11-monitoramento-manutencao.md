# Monitoramento e Manutenção

## Visão Geral

Este guia cobre estratégias de monitoramento, procedimentos de manutenção e boas práticas operacionais para manter o backend PenhaS funcionando perfeitamente em produção.

## Monitoramento de Saúde

### Verificações de Saúde da Aplicação

#### Endpoint Básico de Saúde

```perl
# GET /health
sub health {
    my $c = shift;
    
    my $health = {
        status => 'ok',
        timestamp => time,
        version => $VERSION,
        checks => {}
    };
    
    # Verificação do banco de dados
    eval {
        $c->schema->storage->dbh->ping();
        $health->{checks}{database} = 'ok';
    };
    $health->{checks}{database} = 'error: ' . $@ if $@;
    
    # Verificação do Redis
    eval {
        $c->kv->redis->ping();
        $health->{checks}{redis} = 'ok';
    };
    $health->{checks}{redis} = 'error: ' . $@ if $@;
    
    # Verificação do S3
    eval {
        my $s3 = Paws->service('S3');
        $s3->HeadBucket(Bucket => $ENV{S3_MEDIA_BUCKET});
        $health->{checks}{s3} = 'ok';
    };
    $health->{checks}{s3} = 'error: ' . $@ if $@;
    
    # Status geral
    my $has_error = grep { $_ =~ /error/ } values %{$health->{checks}};
    $health->{status} = $has_error ? 'degraded' : 'ok';
    
    return $c->render(
        json => $health,
        status => $has_error ? 503 : 200
    );
}
```

#### Métricas Detalhadas de Saúde

```perl
# GET /health/detailed (requires auth)
sub health_detailed {
    my $c = shift;
    
    return $c->render(json => {
        database => {
            connections => $c->get_db_connection_count(),
            slow_queries => $c->get_slow_query_count(),
            replication_lag => $c->get_replication_lag(),
        },
        redis => {
            memory_used => $c->get_redis_memory(),
            connected_clients => $c->get_redis_clients(),
            ops_per_sec => $c->get_redis_ops(),
        },
        minion => {
            active_workers => $c->get_minion_workers(),
            job_queue_size => $c->get_job_queue_size(),
            failed_jobs => $c->get_failed_job_count(),
        },
        api => {
            requests_per_minute => $c->get_request_rate(),
            average_response_time => $c->get_avg_response_time(),
            error_rate => $c->get_error_rate(),
        }
    });
}
```

### Stack de Monitoramento

#### 1. Configuração do Prometheus

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'penhas-api'
    metrics_path: '/metrics'
    static_configs:
      - targets: 
        - 'api1.penhas.internal:3000'
        - 'api2.penhas.internal:3000'
        - 'api3.penhas.internal:3000'

  - job_name: 'postgres-exporter'
    static_configs:
      - targets: ['postgres-exporter:9187']

  - job_name: 'redis-exporter'
    static_configs:
      - targets: ['redis-exporter:9121']

  - job_name: 'node-exporter'
    static_configs:
      - targets: 
        - 'node1:9100'
        - 'node2:9100'
        - 'node3:9100'
```

#### 2. Métricas Principais para Monitorar

**Métricas da Aplicação:**
- Taxa de requisições (req/seg)
- Tempo de resposta (p50, p95, p99)
- Taxa de erro (4xx, 5xx)
- Conexões ativas
- Profundidade da fila de requisições

**Métricas do Banco de Dados:**
- Uso do pool de conexões
- Tempo de execução de consultas
- Atraso de replicação
- Inchaço de tabelas/índices
- Taxa de acerto do cache

**Métricas de Infraestrutura:**
- Uso de CPU
- Uso de memória
- I/O de disco
- Throughput de rede
- Espaço em disco

**Métricas de Negócio:**
- Usuários ativos
- Uploads de áudio/hora
- Buscas em centros de apoio
- Alertas de guardiões enviados

### Regras de Alerta

```yaml
# alerts.yml
groups:
  - name: penhas-api
    interval: 30s
    rules:
      - alert: HighErrorRate
        expr: |
          (sum(rate(http_requests_total{status=~"5.."}[5m])) 
           / sum(rate(http_requests_total[5m]))) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Alta taxa de erro detectada"
          description: "Taxa de erro está em {{ $value | humanizePercentage }}"

      - alert: SlowResponseTime
        expr: |
          histogram_quantile(0.95, 
            rate(http_request_duration_seconds_bucket[5m])
          ) > 2
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Tempos de resposta lentos da API"
          description: "Tempo de resposta do percentil 95 é {{ $value }}s"

      - alert: DatabaseConnectionsHigh
        expr: pg_stat_database_numbackends > 150
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Conexões de banco de dados próximas do limite"
          description: "{{ $value }} conexões em uso"

      - alert: MinionJobQueueHigh
        expr: minion_jobs_inactive > 1000
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Fila de jobs do Minion crescendo"
          description: "{{ $value }} jobs aguardando"

      - alert: DiskSpaceLow
        expr: |
          (node_filesystem_avail_bytes{mountpoint="/"} 
           / node_filesystem_size_bytes{mountpoint="/"}) < 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Espaço em disco baixo"
          description: "Apenas {{ $value | humanizePercentage }} livre"
```

## Logging

### Configuração de Logs

#### Logging da Aplicação

```perl
# lib/Penhas/Logger.pm
use Log::Log4perl;

sub get_logger {
    my $conf = q{
        log4perl.rootLogger = INFO, FILE, SYSLOG
        
        # Anexador de arquivo
        log4perl.appender.FILE = Log::Log4perl::Appender::File
        log4perl.appender.FILE.filename = /var/log/penhas/app.log
        log4perl.appender.FILE.mode = append
        log4perl.appender.FILE.layout = PatternLayout
        log4perl.appender.FILE.layout.ConversionPattern = %d{ISO8601} [%p] %c - %m%n
        
        # Anexador do syslog
        log4perl.appender.SYSLOG = Log::Dispatch::Syslog
        log4perl.appender.SYSLOG.facility = local0
        log4perl.appender.SYSLOG.layout = PatternLayout
        log4perl.appender.SYSLOG.layout.ConversionPattern = [%p] %c - %m
        
        # Níveis específicos por categoria
        log4perl.logger.Penhas.Controller = DEBUG
        log4perl.logger.Penhas.Minion = INFO
        log4perl.logger.Mojolicious = WARN
    };
    
    Log::Log4perl->init(\$conf);
    return Log::Log4perl->get_logger();
}
```

#### Logging Estruturado

```perl
# Log com contexto
sub log_request {
    my ($c, $level, $message, $data) = @_;
    
    my $log_entry = {
        timestamp => time,
        level => $level,
        message => $message,
        request_id => $c->req->request_id,
        user_id => $c->stash('user_id'),
        endpoint => $c->req->url->path,
        method => $c->req->method,
        ip => $c->remote_addr,
        %{$data || {}}
    };
    
    $c->app->log->$level(encode_json($log_entry));
}
```

### Agregação de Logs

#### Configuração da Stack ELK

```yaml
# logstash.conf
input {
  syslog {
    port => 5514
    type => "penhas-api"
  }
  
  file {
    path => "/var/log/penhas/*.log"
    codec => json
    type => "penhas-app"
  }
}

filter {
  if [type] == "penhas-api" {
    grok {
      match => {
        "message" => "%{TIMESTAMP_ISO8601:timestamp} \[%{LOGLEVEL:level}\] %{GREEDYDATA:message}"
      }
    }
  }
  
  # Adicionar GeoIP para endereços IP
  if [ip] {
    geoip {
      source => "ip"
      target => "geoip"
    }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "penhas-%{+YYYY.MM.dd}"
  }
}
```

### Retenção de Logs

```bash
# Configuração de rotação de logs
# /etc/logrotate.d/penhas

/var/log/penhas/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0644 penhas penhas
    sharedscripts
    postrotate
        # Sinalizar app para reabrir arquivos de log
        kill -USR1 $(cat /var/run/penhas.pid) 2>/dev/null || true
    endscript
}

# Nginx logs
/var/log/nginx/penhas-*.log {
    daily
    rotate 90
    compress
    delaycompress
    missingok
    notifempty
    create 0644 www-data adm
    sharedscripts
    postrotate
        nginx -s reload
    endscript
}
```

## Manutenção Programada

### Cron Jobs

```bash
# Crontab para usuário penhas
MAILTO=ops@penhas.com.br

# Tarefas horárias
0 * * * * /opt/penhas/scripts/housekeeping.sh

# Tarefas diárias
0 3 * * * /opt/penhas/scripts/daily-maintenance.sh
0 4 * * * /opt/penhas/scripts/backup-database.sh
0 5 * * * /opt/penhas/scripts/cleanup-old-files.sh

# Tarefas semanais
0 2 * * 0 /opt/penhas/scripts/weekly-maintenance.sh
0 3 * * 0 /opt/penhas/scripts/reindex-search.sh

# Tarefas mensais
0 1 1 * * /opt/penhas/scripts/monthly-reports.sh
```

### Scripts de Manutenção

#### Limpeza Horária

```bash
#!/bin/bash
# /opt/penhas/scripts/housekeeping.sh

# Endpoint da API com secret de manutenção
API_URL="http://localhost:3000/maintenance"
SECRET=$MAINTENANCE_SECRET

# Executar limpeza
curl -X GET "$API_URL/housekeeping?secret=$SECRET"

# Verificar fila de jobs do Minion
QUEUE_SIZE=$(curl -s "$API_URL/minion-stats?secret=$SECRET" | jq '.inactive')
if [ $QUEUE_SIZE -gt 1000 ]; then
    echo "Aviso: Tamanho da fila do Minion é $QUEUE_SIZE" | mail -s "Alerta de Fila do Minion" ops@penhas.com.br
fi
```

#### Manutenção Diária

```bash
#!/bin/bash
# /opt/penhas/scripts/daily-maintenance.sh

# Atualizar dados de localização
curl -X GET "$API_URL/tick-notifications?secret=$SECRET"

# Limpar sessões expiradas
psql $DATABASE_URL -c "DELETE FROM clientes_active_sessions WHERE created_at < NOW() - INTERVAL '30 days';"

# Vacuum analyze nas tabelas importantes
psql $DATABASE_URL << EOF
VACUUM ANALYZE clientes;
VACUUM ANALYZE ponto_apoio;
VACUUM ANALYZE chat_message;
VACUUM ANALYZE clientes_audios;
EOF

# Limpar chaves antigas do Redis
redis-cli --scan --pattern "penhas:CaS:*" | while read key; do
    TTL=$(redis-cli TTL "$key")
    if [ $TTL -eq -1 ]; then
        redis-cli DEL "$key"
    fi
done
```

#### Manutenção do Banco de Dados

```sql
-- /opt/penhas/scripts/db-maintenance.sql

-- Atualizar estatísticas das tabelas
ANALYZE;

-- Reconstruir índices se necessário
REINDEX TABLE CONCURRENTLY ponto_apoio;
REINDEX TABLE CONCURRENTLY clientes;

-- Encontrar e corrigir tabelas inchadas
WITH bloat_info AS (
    SELECT
        schemaname,
        tablename,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
        CASE WHEN pg_total_relation_size(schemaname||'.'||tablename) > 1073741824 
             THEN 'VACUUM FULL ' || schemaname || '.' || tablename || ';'
             ELSE 'VACUUM ' || schemaname || '.' || tablename || ';'
        END AS vacuum_command
    FROM pg_tables
    WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
    ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
)
SELECT * FROM bloat_info;
```

## Monitoramento de Performance

### Performance de Consultas

```sql
-- Habilitar pg_stat_statements
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Encontrar consultas lentas
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    stddev_time,
    rows
FROM pg_stat_statements
WHERE mean_time > 1000  -- consultas que levam mais de 1 segundo
ORDER BY mean_time DESC
LIMIT 20;

-- Encontrar consultas mais frequentes
SELECT 
    query,
    calls,
    total_time,
    mean_time
FROM pg_stat_statements
ORDER BY calls DESC
LIMIT 20;
```

### Performance da Aplicação

```perl
# Middleware para rastreamento de performance
sub startup {
    my $self = shift;
    
    $self->hook(before_dispatch => sub {
        my $c = shift;
        $c->stash('request_start' => [gettimeofday]);
    });
    
    $self->hook(after_dispatch => sub {
        my $c = shift;
        my $elapsed = tv_interval($c->stash('request_start'));
        
        # Registrar requisições lentas
        if ($elapsed > 1.0) {
            $c->app->log->warn(sprintf(
                "Requisição lenta: %s %s levou %.3fs",
                $c->req->method,
                $c->req->url->path,
                $elapsed
            ));
        }
        
        # Atualizar métricas
        $c->prometheus->histogram_observe(
            'http_request_duration_seconds',
            $elapsed,
            {
                method => $c->req->method,
                endpoint => $c->req->url->path,
                status => $c->res->code
            }
        );
    });
}
```

## Guia de Solução de Problemas

### Problemas Comuns

#### 1. Alto Uso de Memória

**Sintomas:**
- OOM killer ativando
- Tempos de resposta lentos
- Evicções do Redis

**Diagnóstico:**
```bash
# Verificar uso de memória por processo
ps aux --sort=-%mem | head -20

# Verificar uso de memória do Perl
perl -MDevel::Peek -e 'Dump(main::)'

# Verificar vazamentos de memória
valgrind --leak-check=full perl script/penhas-api daemon
```

**Soluções:**
- Aumentar memória do servidor
- Otimizar consultas que retornam grandes datasets
- Implementar paginação
- Corrigir vazamentos de memória

#### 2. Esgotamento de Conexões do Banco de Dados

**Sintomas:**
- Erros "Too many connections"
- Timeouts
- Performance degradada

**Diagnóstico:**
```sql
-- Conexões atuais
SELECT count(*) FROM pg_stat_activity;

-- Conexões por estado
SELECT state, count(*) 
FROM pg_stat_activity 
GROUP BY state;

-- Consultas de longa duração
SELECT pid, now() - pg_stat_activity.query_start AS duration, query 
FROM pg_stat_activity 
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';
```

**Soluções:**
- Aumentar max_connections
- Implementar pool de conexões
- Corrigir vazamentos de conexão
- Otimizar consultas de longa duração

#### 3. Falhas em Jobs do Minion

**Sintomas:**
- Jobs travados na fila
- Contagem de jobs falhos aumentando
- Tarefas em background não completando

**Diagnóstico:**
```bash
# Verificar status dos jobs
./script/penhas-api minion job -s

# Visualizar jobs falhos
./script/penhas-api minion job -f

# Verificar job específico
./script/penhas-api minion job -v <job_id>
```

**Soluções:**
- Reiniciar workers
- Retentar jobs falhos
- Verificar logs dos jobs
- Corrigir problemas subjacentes

### Procedimentos de Emergência

#### 1. Degradação do Serviço

```bash
#!/bin/bash
# emergency-mode.sh

# Habilitar modo somente leitura
redis-cli SET "penhas:read_only_mode" "1"

# Desabilitar jobs em background
systemctl stop penhas-minion

# Aumentar TTLs do cache
redis-cli CONFIG SET maxmemory-policy allkeys-lru

# Notificar equipe
echo "Modo de emergência ativado em $(date)" | \
  mail -s "PenhaS Modo de Emergência" ops@penhas.com.br
```

#### 2. Recuperação do Banco de Dados

```bash
#!/bin/bash
# db-recovery.sh

# Parar aplicação
systemctl stop penhas-api

# Restaurar do backup
pg_restore -h localhost -U penhas -d penhas_prod_restore backup.dump

# Verificar restauração
psql -U penhas -d penhas_prod_restore -c "SELECT count(*) FROM clientes;"

# Trocar bancos de dados
psql -U postgres << EOF
ALTER DATABASE penhas_prod RENAME TO penhas_prod_old;
ALTER DATABASE penhas_prod_restore RENAME TO penhas_prod;
EOF

# Reiniciar aplicação
systemctl start penhas-api
```

## Planejamento de Capacidade

### Métricas para Escalonamento

```sql
-- Growth metrics
SELECT 
    DATE_TRUNC('month', created_at) as month,
    COUNT(*) as new_users,
    SUM(COUNT(*)) OVER (ORDER BY DATE_TRUNC('month', created_at)) as total_users
FROM clientes
GROUP BY month
ORDER BY month;

-- Tendências de uso de recursos
SELECT 
    DATE_TRUNC('day', created_at) as day,
    COUNT(*) as audio_uploads,
    SUM(file_size) as total_size
FROM media_upload
WHERE intention = 'guardiao'
GROUP BY day
ORDER BY day;
```

### Gatilhos de Escalonamento

| Métrica | Aviso | Crítico | Ação |
|---------|-------|---------|------|
| Tempo de Resposta da API | > 500ms | > 1s | Adicionar servidores API |
| CPU do Banco de Dados | > 70% | > 85% | Atualizar instância |
| Memória Redis | > 80% | > 90% | Aumentar memória |
| Uso de Disco | > 70% | > 85% | Adicionar armazenamento |
| Fila de Jobs | > 500 | > 1000 | Adicionar workers |