# Guia de Deploy

## Visão Geral

Este guia cobre o deploy do backend PenhaS para ambientes de produção, incluindo configuração de servidor, configuração, monitoramento e procedimentos de manutenção.

## Requisitos de Infraestrutura

### Requisitos Mínimos de Produção

- **Servidores de Aplicação**: 2+ instâncias (4GB RAM, 2 vCPU cada)
- **Servidor de Banco de Dados**: 8GB RAM, 4 vCPU, 100GB SSD
- **Servidor Redis**: 2GB RAM, 1 vCPU
- **Load Balancer**: Nginx ou LB do provedor cloud
- **Armazenamento**: Armazenamento de objetos compatível com S3
- **Certificados SSL**: Certificados válidos para HTTPS

### Arquitetura Recomendada

```
                    ┌─────────────────┐
                    │   CloudFlare    │
                    │      (CDN)      │
                    └────────┬────────┘
                             │
                    ┌────────┴────────┐
                    │  Load Balancer  │
                    │    (Nginx)      │
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
    ┌────┴────┐        ┌────┴────┐        ┌────┴────┐
    │  API    │        │  API    │        │  API    │
    │ Server 1│        │ Server 2│        │ Server 3│
    └─────────┘        └─────────┘        └─────────┘
         │                   │                   │
         └───────────────────┼───────────────────┘
                             │
    ┌────────────────────────┼────────────────────────┐
    │                        │                        │
┌───┴────┐  ┌───────────┐  ┌┴────────┐  ┌──────────┐│
│ Redis  │  │PostgreSQL │  │ Minion  │  │   S3     ││
│ Master │  │  Primary  │  │Workers  │  │ Storage  ││
└───┬────┘  └─────┬─────┘  └─────────┘  └──────────┘│
    │             │                                   │
┌───┴────┐  ┌─────┴─────┐                           │
│ Redis  │  │PostgreSQL │                           │
│ Slave  │  │  Replica  │                           │
└────────┘  └───────────┘                           │
```

## Checklist Pré-deploy

- [ ] Certificados SSL obtidos
- [ ] DNS do domínio configurado
- [ ] Estratégia de backup do banco de dados definida
- [ ] Ferramentas de monitoramento configuradas
- [ ] Auditoria de segurança concluída
- [ ] Teste de carga realizado
- [ ] Plano de rollback documentado
- [ ] Equipe treinada nos procedimentos de deploy

## Configuração do Servidor

### 1. Configuração Base do Sistema

```bash
# Atualizar sistema
sudo apt-get update && sudo apt-get upgrade -y

# Instalar pacotes necessários
sudo apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    vim \
    htop \
    fail2ban \
    ufw \
    postgresql-client \
    redis-tools

# Configurar firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Configurar fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 2. Criar Usuário da Aplicação

```bash
# Criar usuário penhas
sudo useradd -m -s /bin/bash penhas
sudo usermod -aG sudo penhas

# Configurar diretórios
sudo mkdir -p /opt/penhas
sudo chown penhas:penhas /opt/penhas
```

### 3. Instalar Docker

```bash
# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker penhas

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

## Configuração do Banco de Dados

### 1. Instalação do PostgreSQL

```bash
# Instalar PostgreSQL 13
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y postgresql-13 postgresql-13-postgis-3

# Configurar PostgreSQL
sudo -u postgres psql << EOF
CREATE USER penhas WITH PASSWORD 'strong-password-here';
CREATE DATABASE penhas_prod OWNER penhas;
\c penhas_prod
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS unaccent;
EOF
```

### 2. Configuração do PostgreSQL

Editar `/etc/postgresql/13/main/postgresql.conf`:

```conf
# Configurações de conexão
listen_addresses = 'localhost,10.0.0.0/8'
max_connections = 200

# Configurações de memória
shared_buffers = 2GB
effective_cache_size = 6GB
work_mem = 10MB
maintenance_work_mem = 512MB

# Configurações de checkpoint
checkpoint_completion_target = 0.9
wal_buffers = 16MB
min_wal_size = 2GB
max_wal_size = 8GB

# Ajuste de consultas
random_page_cost = 1.1
effective_io_concurrency = 200

# Log
log_min_duration_statement = 1000
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
```

### 3. Migrações de Banco de Dados

```bash
# Instalar sqitch
sudo apt-get install -y sqitch libdbd-pg-perl

# Executar migrações
cd /opt/penhas/api/deploy_db
sqitch deploy --target db:pg://penhas:password@localhost/penhas_prod
```

## Configuração do Redis

### 1. Instalação do Redis

```bash
# Instalar Redis
sudo apt-get install -y redis-server

# Configurar Redis
sudo vim /etc/redis/redis.conf
```

Configuração do Redis:
```conf
# Rede
bind 127.0.0.1 ::1
protected-mode yes
port 6379

# Persistência
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes

# Memória
maxmemory 1gb
maxmemory-policy allkeys-lru

# Segurança
requirepass your-redis-password
```

### 2. Otimização do Redis

```bash
# Configurações do sistema para Redis
echo "vm.overcommit_memory = 1" | sudo tee -a /etc/sysctl.conf
echo "net.core.somaxconn = 65535" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Desabilitar THP
echo never | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
```

## Deploy da Aplicação

### 1. Construir Imagem Docker

```bash
cd /opt/penhas/api
./build-container.sh

# Tag para registro
docker tag penhas-api:latest registry.example.com/penhas-api:latest
docker push registry.example.com/penhas-api:latest
```

### 2. Configuração do Docker Compose

Criar `/opt/penhas/docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  api:
    image: registry.example.com/penhas-api:latest
    restart: always
    environment:
      - DATABASE_URL=postgresql://penhas:password@db:5432/penhas_prod
      - REDIS_URL=redis://:password@redis:6379
      - JWT_SECRET=${JWT_SECRET}
      - S3_MEDIA_BUCKET=${S3_MEDIA_BUCKET}
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '2'
          memory: 4G
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - penhas-net

  minion:
    image: registry.example.com/penhas-api:latest
    restart: always
    command: ["minion", "worker", "-j", "4"]
    environment:
      - DATABASE_URL=postgresql://penhas:password@db:5432/penhas_prod
      - REDIS_URL=redis://:password@redis:6379
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '2'
          memory: 4G
    networks:
      - penhas-net

networks:
  penhas-net:
    driver: bridge
```

### 3. Configuração de Ambiente

Criar `/opt/penhas/.env`:

```bash
# Banco de Dados
DATABASE_URL=postgresql://penhas:password@localhost/penhas_prod

# Redis
REDIS_URL=redis://:password@localhost:6379
REDIS_NS=penhas:

# JWT
JWT_SECRET=your-production-secret-key

# S3
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
S3_MEDIA_BUCKET=penhas-prod

# Serviços Externos
HERE_APPID=your-here-app-id
HERE_APPCODE=your-here-app-code

# Email
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASS=your-sendgrid-api-key

# Manutenção
MAINTENANCE_SECRET=your-maintenance-secret
MINION_ADMIN_SECRET=your-minion-secret
```

## Configuração do Nginx

### 1. Instalar Nginx

```bash
sudo apt-get install -y nginx
```

### 2. Configuração do Certificado SSL

```bash
# Instalar Certbot
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

# Obter certificado
sudo certbot --nginx -d api.penhas.com.br
```

### 3. Configuração do Nginx

Criar `/etc/nginx/sites-available/penhas-api`:

```nginx
upstream penhas_backend {
    least_conn;
    server 127.0.0.1:3001 max_fails=3 fail_timeout=30s;
    server 127.0.0.1:3002 max_fails=3 fail_timeout=30s;
    server 127.0.0.1:3003 max_fails=3 fail_timeout=30s;
    keepalive 32;
}

# Limitação de taxa
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=login_limit:10m rate=3r/m;

server {
    listen 80;
    server_name api.penhas.com.br;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.penhas.com.br;

    # Configuração SSL
    ssl_certificate /etc/letsencrypt/live/api.penhas.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.penhas.com.br/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Cabeçalhos de segurança
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Logs
    access_log /var/log/nginx/penhas-api-access.log;
    error_log /var/log/nginx/penhas-api-error.log;

    # Tamanho da requisição
    client_max_body_size 50M;
    client_body_timeout 60s;

    # Limitação de taxa
    location /login {
        limit_req zone=login_limit burst=5 nodelay;
        proxy_pass http://penhas_backend;
        include /etc/nginx/proxy_params;
    }

    location / {
        limit_req zone=api_limit burst=20 nodelay;
        
        proxy_pass http://penhas_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Endpoint de verificação de saúde
    location /health {
        access_log off;
        proxy_pass http://penhas_backend;
        include /etc/nginx/proxy_params;
    }

    # Arquivos estáticos
    location /public {
        alias /opt/penhas/api/public;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### 4. Habilitar Site

```bash
sudo ln -s /etc/nginx/sites-available/penhas-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## Serviços Systemd

### 1. Serviço da API

Criar `/etc/systemd/system/penhas-api.service`:

```ini
[Unit]
Description=PenhaS API
After=network.target postgresql.service redis.service
Requires=postgresql.service redis.service

[Service]
Type=simple
User=penhas
Group=penhas
WorkingDirectory=/opt/penhas
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
ExecStart=/usr/local/bin/docker-compose -f docker-compose.prod.yml up
ExecStop=/usr/local/bin/docker-compose -f docker-compose.prod.yml down
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### 2. Habilitar Serviços

```bash
sudo systemctl daemon-reload
sudo systemctl enable penhas-api
sudo systemctl start penhas-api
```

## Configuração de Monitoramento

### 1. Configuração do Prometheus

```yaml
# /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'penhas-api'
    static_configs:
      - targets: ['localhost:3001', 'localhost:3002', 'localhost:3003']
    
  - job_name: 'postgres'
    static_configs:
      - targets: ['localhost:9187']
    
  - job_name: 'redis'
    static_configs:
      - targets: ['localhost:9121']
```

### 2. Dashboards do Grafana

Importar dashboards para:
- Métricas da API (tempos de resposta, taxas de erro)
- Performance do PostgreSQL
- Performance do Redis
- Métricas do sistema (CPU, memória, disco)

### 3. Regras de Alerta

```yaml
# /etc/prometheus/alerts.yml
groups:
  - name: penhas
    rules:
      - alert: APIHighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        annotations:
          summary: "Taxa de erro alta na API"
          
      - alert: DatabaseConnectionsHigh
        expr: pg_stat_database_numbackends > 150
        for: 5m
        annotations:
          summary: "Conexões do banco de dados próximas do limite"
```

## Estratégia de Backup

### 1. Backup do Banco de Dados

```bash
#!/bin/bash
# /opt/penhas/scripts/backup-db.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/postgres"
DB_NAME="penhas_prod"

# Criar backup
pg_dump -h localhost -U penhas -d $DB_NAME | gzip > $BACKUP_DIR/penhas_$DATE.sql.gz

# Enviar para S3
aws s3 cp $BACKUP_DIR/penhas_$DATE.sql.gz s3://penhas-backups/postgres/

# Manter apenas últimos 7 dias localmente
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete
```

### 2. Agendamento de Backup

```bash
# Crontab
0 2 * * * /opt/penhas/scripts/backup-db.sh
0 */6 * * * /opt/penhas/scripts/backup-redis.sh
```

## Fortalecimento de Segurança

### 1. Segurança do Sistema

```bash
# Desabilitar SSH root
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Configurar atualizações automáticas
sudo apt-get install -y unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades
```

### 2. Segurança da Aplicação

- Usar variáveis de ambiente para segredos
- Habilitar logs de auditoria
- Implementar detecção de intrusão
- Scans de segurança regulares

## Processo de Deploy

### 1. Deploy Blue-Green

```bash
#!/bin/bash
# deploy.sh

# Construir nova imagem
docker build -t penhas-api:new .

# Iniciar novos containers
docker-compose -f docker-compose.blue.yml up -d

# Verificação de saúde
./health-check.sh blue

# Alternar tráfego
./switch-traffic.sh blue

# Parar containers antigos
docker-compose -f docker-compose.green.yml down
```

### 2. Procedimento de Rollback

```bash
#!/bin/bash
# rollback.sh

# Alternar tráfego de volta
./switch-traffic.sh green

# Parar containers problemáticos
docker-compose -f docker-compose.blue.yml down

# Investigar problemas
docker logs penhas-api-blue
```

## Procedimentos de Manutenção

### 1. Manutenção Agendada

```bash
# Modo de manutenção
curl -X POST https://api.penhas.com.br/maintenance/enable \
  -H "X-Maintenance-Secret: $MAINTENANCE_SECRET"

# Executar tarefas de manutenção
./maintenance-tasks.sh

# Desabilitar modo de manutenção
curl -X POST https://api.penhas.com.br/maintenance/disable \
  -H "X-Maintenance-Secret: $MAINTENANCE_SECRET"
```

### 2. Rotação de Logs

```bash
# /etc/logrotate.d/penhas
/var/log/penhas/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 penhas penhas
    sharedscripts
    postrotate
        systemctl reload penhas-api
    endscript
}
```

## Ajuste de Performance

### 1. Parâmetros do Kernel

```bash
# /etc/sysctl.conf
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_max_tw_buckets = 2000000
net.ipv4.ip_local_port_range = 10000 65000
```

### 2. Ajuste da Aplicação

- Configurar pool de conexões
- Otimizar consultas do banco de dados
- Habilitar cache de consultas
- Usar CDN para assets estáticos

## Checklist Pós-Deploy

- [ ] Todos os serviços rodando
- [ ] Verificações de saúde passando
- [ ] Certificados SSL válidos
- [ ] Monitoramento ativo
- [ ] Backups configurados
- [ ] Logs rotacionando
- [ ] Performance aceitável
- [ ] Scan de segurança concluído
- [ ] Documentação atualizada
- [ ] Equipe notificada