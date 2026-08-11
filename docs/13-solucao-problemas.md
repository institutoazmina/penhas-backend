# Guia de Solução de Problemas

## Visão Geral

Este guia fornece soluções para problemas comuns, técnicas de debug e procedimentos de emergência para o sistema backend PenhaS.

## Diagnósticos Rápidos

### Verificação de Saúde do Sistema

```bash
#!/bin/bash
# health-check.sh

echo "=== Verificação de Saúde do Sistema PenhaS ==="
echo

# Verificar serviços
echo "1. Status dos Serviços:"
systemctl is-active penhas-api || echo "  ❌ API está inativa"
systemctl is-active postgresql || echo "  ❌ PostgreSQL está inativo"
systemctl is-active redis || echo "  ❌ Redis está inativo"
systemctl is-active nginx || echo "  ❌ Nginx está inativo"

# Verificar conectividade
echo -e "\n2. Conexão com Banco de Dados:"
psql $DATABASE_URL -c "SELECT 1" > /dev/null 2>&1 && echo "  ✓ Banco de dados conectado" || echo "  ❌ Falha na conexão com banco de dados"

echo -e "\n3. Conexão com Redis:"
redis-cli ping > /dev/null 2>&1 && echo "  ✓ Redis conectado" || echo "  ❌ Falha na conexão com Redis"

# Verificar espaço em disco
echo -e "\n4. Espaço em Disco:"
df -h | grep -E "/$|/var|/opt"

# Verificar memória
echo -e "\n5. Uso de Memória:"
free -h

# Verificar carga
echo -e "\n6. Carga do Sistema:"
uptime

# Erros recentes
echo -e "\n7. Erros Recentes (últimos 10):"
tail -10 /var/log/penhas/error.log 2>/dev/null || echo "  Log de erros não encontrado"
```

## Problemas Comuns

### 1. API Não Responde

#### Sintomas
- Erros 502 Bad Gateway
- Timeouts de conexão
- Sem resposta dos endpoints

#### Diagnóstico
```bash
# Verificar se API está rodando
ps aux | grep penhas-api

# Verificar binding de porta
netstat -tlnp | grep 3000

# Verificar logs
tail -f /var/log/penhas/app.log

# Testar conexão local
curl -I http://localhost:3000/health
```

#### Soluções

**Serviço não está rodando:**
```bash
# Reiniciar serviço
sudo systemctl restart penhas-api

# Verificar status
sudo systemctl status penhas-api

# Ver logs de inicialização
journalctl -u penhas-api -n 50
```

**Conflito de porta:**
```bash
# Encontrar processo usando a porta
sudo lsof -i :3000

# Matar processo conflitante
sudo kill -9 <PID>
```

**Erro de configuração:**
```bash
# Validar ambiente
source /opt/penhas/envfile_local.sh
env | grep -E "DATABASE_URL|REDIS_URL|JWT_SECRET"

# Testar configuração
cd /opt/penhas/api
perl -c script/penhas-api
```

### 2. Erros de Conexão com Banco de Dados

#### Sintomas
- "FATAL: too many connections"
- "could not connect to server"
- Consultas lentas ou timeouts

#### Diagnóstico
```sql
-- Verificar conexões atuais
SELECT count(*) FROM pg_stat_activity;

-- Ver detalhes das conexões
SELECT pid, usename, application_name, client_addr, state 
FROM pg_stat_activity 
ORDER BY backend_start;

-- Encontrar consultas de longa duração
SELECT pid, now() - pg_stat_activity.query_start AS duration, query 
FROM pg_stat_activity 
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';
```

#### Soluções

**Muitas conexões:**
```bash
# Aumentar limite de conexões (temporariamente)
sudo -u postgres psql -c "ALTER SYSTEM SET max_connections = 300;"
sudo systemctl reload postgresql

# Matar conexões ociosas
sudo -u postgres psql << EOF
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE state = 'idle' 
  AND state_change < current_timestamp - interval '10 minutes';
EOF
```

**Esgotamento do pool de conexões:**
```perl
# Verificar configurações do pool no código
# lib/Penhas/SchemaConnected.pm
my $schema = Penhas::Schema->connect(
    $dsn, $user, $pass,
    {
        # Adicionar pool de conexões
        connection_pool => {
            max_connections => 20,
            min_connections => 5,
            connection_timeout => 30,
        }
    }
);
```

**Problemas de performance:**
```sql
-- Atualizar estatísticas
ANALYZE;

-- Encontrar índices faltando
SELECT schemaname, tablename, attname, n_distinct, correlation
FROM pg_stats
WHERE schemaname = 'public'
  AND n_distinct > 100
  AND correlation < 0.1
ORDER BY n_distinct DESC;

-- Reconstruir índices inchados
REINDEX TABLE CONCURRENTLY clientes;
```

### 3. Problemas com Redis

#### Sintomas
- Erros de sessão
- Cache misses
- Erros "Connection refused"

#### Diagnóstico
```bash
# Verificar status do Redis
redis-cli ping

# Verificar uso de memória
redis-cli info memory

# Monitorar comandos
redis-cli monitor

# Verificar log de comandos lentos
redis-cli slowlog get 10
```

#### Soluções

**Problemas de memória:**
```bash
# Verificar política de evicção
redis-cli config get maxmemory-policy

# Definir política apropriada
redis-cli config set maxmemory-policy allkeys-lru

# Limpar dados antigos (cuidado!)
redis-cli --scan --pattern "penhas:CaS:*" | xargs redis-cli del
```

**Problemas de conexão:**
```bash
# Verificar binding do Redis
grep "^bind" /etc/redis/redis.conf

# Testar conexão
redis-cli -h localhost -p 6379 ping

# Verificar firewall
sudo ufw status | grep 6379
```

### 4. Alto Uso de Memória

#### Sintomas
- OOM killer ativado
- Performance lenta
- Alto uso de swap

#### Diagnóstico
```bash
# Encontrar processos que consomem muita memória
ps aux --sort=-%mem | head -20

# Verificar memória do processo Perl
pmap -x $(pgrep -f penhas-api) | tail -1

# Memória por tipo
smem -t -k -c "pid user command swap vss rss pss uss" | grep penhas
```

#### Soluções

**Vazamentos de memória da aplicação:**
```perl
# Adicionar monitoramento de memória
use Devel::Size qw(total_size);

sub check_memory_usage {
    my $self = shift;
    
    # Registrar objetos grandes
    foreach my $key (keys %{$self->stash}) {
        my $size = total_size($self->stash->{$key});
        if ($size > 1_000_000) {  # 1MB
            $self->log->warn("Large stash object: $key = " . ($size/1024/1024) . "MB");
        }
    }
}

# Limpar caches periodicamente
sub clear_caches {
    my $self = shift;
    
    # Limpar caches do DBIx::Class
    $self->schema->storage->clear_cache;
    
    # Limpar caches da aplicação
    undef %{$self->app->renderer->cache};
}
```

**Ajuste do sistema:**
```bash
# Ajustar OOM killer
echo -1000 > /proc/$(pgrep -f penhas-api)/oom_score_adj

# Limitar uso de memória
systemctl set-property penhas-api.service MemoryMax=4G
```

### 5. Falhas no Upload de Arquivos

#### Sintomas
- Erros "File too large"
- Timeouts durante upload
- Erros do S3

#### Diagnóstico
```bash
# Verificar limites do nginx
grep client_max_body_size /etc/nginx/nginx.conf

# Verificar espaço em disco
df -h /tmp

# Testar conectividade com S3
aws s3 ls s3://$S3_MEDIA_BUCKET --endpoint-url=$S3_ENDPOINT_URL
```

#### Soluções

**Limites de tamanho:**
```nginx
# Aumentar limite do nginx
client_max_body_size 50M;
client_body_timeout 300s;

# Recarregar nginx
nginx -s reload
```

**Problemas com S3:**
```perl
# Adicionar lógica de retry
sub upload_with_retry {
    my ($self, $file, $max_attempts) = @_;
    
    $max_attempts //= 3;
    my $attempt = 0;
    
    while ($attempt < $max_attempts) {
        $attempt++;
        
        eval {
            $self->s3->upload($file);
        };
        
        if (!$@) {
            return 1;
        }
        
        $self->log->error("Upload S3 falhou (tentativa $attempt): $@");
        sleep(2 ** $attempt);  # Backoff exponencial
    }
    
    die "Upload S3 falhou após $max_attempts tentativas";
}
```

### 6. Falhas em Jobs em Background

#### Sintomas
- Jobs travados na fila
- Falhas repetidas
- Workers não processando

#### Diagnóstico
```bash
# Verificar status dos workers
ps aux | grep "minion worker"

# Ver estatísticas dos jobs
./script/penhas-api minion job -s

# Verificar jobs falhados
./script/penhas-api minion job -f

# Ver job específico
./script/penhas-api minion job -v <job_id>
```

#### Soluções

**Reiniciar workers:**
```bash
# Parar todos os workers
pkill -f "minion worker"

# Iniciar novos workers
./script/penhas-api minion worker -j 4

# Ou via systemd
systemctl restart penhas-minion
```

**Corrigir jobs travados:**
```perl
# Resetar jobs travados
$minion->reset({states => ['active'], older => 3600});

# Tentar novamente jobs falhados
$minion->retry_jobs({states => ['failed'], queues => ['default']});

# Remover jobs finalizados antigos
$minion->remove_jobs({states => ['finished'], older => 86400 * 7});
```

## Técnicas de Debug

### 1. Habilitar Logs de Debug

```bash
# Variáveis de ambiente
export MOJO_LOG_LEVEL=debug
export PENHAS_DEBUG=1
export DBI_TRACE=1  # Consultas ao banco de dados
export REDIS_DEBUG=1

# Na aplicação
$app->log->level('debug');
```

### 2. Rastreamento de Requisições

```perl
# Adicionar ID de requisição para rastreamento
$app->hook(before_dispatch => sub {
    my $c = shift;
    
    my $request_id = $c->req->headers->header('X-Request-ID') 
                  || generate_uuid();
    
    $c->stash(request_id => $request_id);
    $c->res->headers->header('X-Request-ID' => $request_id);
    
    # Adicionar ao contexto do log
    Log::Log4perl::MDC->put('request_id', $request_id);
});
```

### 3. Profiling de Performance

```bash
# Fazer profile com NYTProf
NYTPROF=start=no perl -d:NYTProf script/penhas-api daemon

# Iniciar profiling via sinal
kill -USR1 $(pgrep -f penhas-api)

# Parar profiling
kill -USR2 $(pgrep -f penhas-api)

# Gerar relatório
nytprofhtml --open
```

### 4. Profiling de Memória

```perl
# Rastrear uso de memória
use Devel::Size qw(size total_size);
use Memory::Usage;

my $mu = Memory::Usage->new();
$mu->record('Antes da operação');

# ... fazer algo ...

$mu->record('Após a operação');
$mu->dump();
```

## Procedimentos de Emergência

### 1. Interrupção do Serviço

```bash
#!/bin/bash
# emergency-recovery.sh

echo "Iniciando recuperação de emergência..."

# 1. Habilitar modo de manutenção
redis-cli SET "penhas:maintenance_mode" "1"
redis-cli SET "penhas:maintenance_message" "Sistema em manutenção. Voltaremos em breve."

# 2. Parar serviços
systemctl stop penhas-api penhas-minion

# 3. Limpar dados problemáticos
redis-cli FLUSHDB  # Aviso: limpa todos os dados do Redis!

# 4. Resetar conexões do banco de dados
sudo -u postgres psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'penhas_prod';"

# 5. Iniciar serviços
systemctl start postgresql redis
sleep 5
systemctl start penhas-api penhas-minion

# 6. Verificar serviços
curl -f http://localhost:3000/health || exit 1

# 7. Desabilitar modo de manutenção
redis-cli DEL "penhas:maintenance_mode"

echo "Recuperação completa!"
```

### 2. Corrupção de Dados

```bash
#!/bin/bash
# data-recovery.sh

# 1. Parar escritas
redis-cli SET "penhas:read_only_mode" "1"

# 2. Fazer backup do estado atual
pg_dump penhas_prod > backup_$(date +%Y%m%d_%H%M%S).sql

# 3. Identificar corrupção
psql penhas_prod << EOF
-- Verificar corrupção
SELECT schemaname, tablename 
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- Verificar constraints
SELECT conname, contype, convalidated 
FROM pg_constraint 
WHERE NOT convalidated;
EOF

# 4. Corrigir corrupção
psql penhas_prod << EOF
-- Revalidar constraints
ALTER TABLE clientes VALIDATE CONSTRAINT ALL;

-- Reconstruir índices
REINDEX DATABASE penhas_prod;

-- Atualizar estatísticas
ANALYZE;
EOF

# 5. Reabilitar escritas
redis-cli DEL "penhas:read_only_mode"
```

### 3. Violação de Segurança

```bash
#!/bin/bash
# security-response.sh

# 1. Isolar sistema
iptables -I INPUT -j DROP
iptables -I INPUT -s 127.0.0.1 -j ACCEPT

# 2. Revogar todas as sessões
redis-cli --scan --pattern "penhas:CaS:*" | xargs redis-cli del

# 3. Forçar reset de senhas
psql penhas_prod -c "UPDATE clientes SET force_password_reset = true;"

# 4. Rotacionar secrets
NEW_JWT_SECRET=$(openssl rand -base64 32)
sed -i "s/JWT_SECRET=.*/JWT_SECRET=$NEW_JWT_SECRET/" /opt/penhas/.env

# 5. Auditar logs
tar -czf security_logs_$(date +%Y%m%d).tar.gz /var/log/penhas/

# 6. Notificar
echo "Violação de segurança detectada em $(date)" | mail -s "URGENTE: Alerta de Segurança" security@penhas.com.br
```

## Comandos de Monitoramento

### Verificações Rápidas de Status

```bash
# Endpoints da API
curl -s http://localhost:3000/health | jq .

# Status do banco de dados
psql $DATABASE_URL -c "SELECT version();"

# Status do Redis
redis-cli info server | grep redis_version

# Uso de disco
df -h | grep -E "Filesystem|penhas|postgres"

# Uso de memória
free -m | grep -E "Mem|Swap"

# Status dos processos
ps aux | grep -E "penhas|postgres|redis|nginx" | grep -v grep

# Arquivos abertos
lsof -p $(pgrep -f penhas-api) | wc -l

# Conexões de rede
netstat -an | grep -E ":3000|:5432|:6379" | wc -l
```

## Análise de Logs

### Padrões de Log Comuns

```bash
# Encontrar erros
grep -E "ERROR|FATAL|CRITICAL" /var/log/penhas/app.log | tail -50

# Requisições lentas
grep -E "took [0-9]+\.[0-9]+s" /var/log/penhas/app.log | awk '$NF > 1'

# Logins falhados
grep "login_failed" /var/log/penhas/app.log | awk '{print $4}' | sort | uniq -c

# Erros 5xx
grep "status=5" /var/log/nginx/access.log | awk '{print $7}' | sort | uniq -c

# Problemas de memória
dmesg | grep -i "out of memory"
```

### Consultas de Agregação de Logs

```sql
-- Consultas Elasticsearch para Kibana
GET /penhas-*/_search
{
  "query": {
    "bool": {
      "must": [
        {"match": {"level": "ERROR"}},
        {"range": {"@timestamp": {"gte": "now-1h"}}}
      ]
    }
  },
  "aggs": {
    "errors_by_endpoint": {
      "terms": {"field": "endpoint.keyword"}
    }
  }
}
```

## Procedimentos de Recuperação

### Recuperação do Banco de Dados

```bash
# Recuperação point-in-time
pg_restore -h localhost -U penhas -d penhas_restore -v backup.dump

# Verificar restauração
psql penhas_restore -c "SELECT count(*) FROM clientes;"

# Trocar bancos de dados
psql -U postgres << EOF
BEGIN;
ALTER DATABASE penhas_prod RENAME TO penhas_old;
ALTER DATABASE penhas_restore RENAME TO penhas_prod;
COMMIT;
EOF
```

### Recuperação do Redis

```bash
# Restaurar do backup RDB
service redis stop
cp /backup/redis/dump.rdb /var/lib/redis/
chown redis:redis /var/lib/redis/dump.rdb
service redis start
```

## Informações de Contato

### Caminho de Escalonamento

1. **Nível 1**: Desenvolvedor de plantão
   - Verificar alertas de monitoramento
   - Seguir runbooks
   - Solução de problemas básica

2. **Nível 2**: Desenvolvedor sênior
   - Debug complexo
   - Correções a nível de código
   - Ajuste de performance

3. **Nível 3**: Arquiteto de sistema
   - Problemas de infraestrutura
   - Decisões de design
   - Incidentes graves

### Contatos de Emergência

- **Plantão**: Verificar PagerDuty
- **Administrador de Banco de Dados**: dba@penhas.com.br
- **Equipe de Segurança**: security@penhas.com.br
- **Gerência**: ops-manager@penhas.com.br