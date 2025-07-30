# Configuração de Desenvolvimento

## Pré-requisitos

### Requisitos do Sistema

- **Sistema Operacional**: Linux, macOS, ou Windows com WSL2
- **RAM**: Mínimo 4GB, recomendado 8GB
- **Espaço em Disco**: Pelo menos 10GB de espaço livre
- **CPU**: 2+ cores recomendado

### Software Necessário

1. **Docker & Docker Compose**
   ```bash
   # Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install docker.io docker-compose
   
   # macOS
   brew install docker docker-compose
   ```

2. **PostgreSQL 13+ with PostGIS**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install postgresql-13 postgresql-13-postgis-3
   
   # macOS
   brew install postgresql@13 postgis
   ```

3. **Redis 5+**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install redis-server
   
   # macOS
   brew install redis
   ```

4. **Git**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install git
   
   # macOS
   brew install git
   ```

5. **Ferramentas de Build**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install build-essential libssl-dev libpq-dev
   
   # macOS
   xcode-select --install
   ```

## Configuração do Repositório

### 1. Clonar o Repositório

```bash
git clone https://github.com/institutoazmina/penhas-backend.git
cd penhas-backend
```

### 2. Configuração do Ambiente

Crie seu arquivo de ambiente local:

```bash
cd api
cp envfile.sh envfile_local.sh
```

Edite `envfile_local.sh` com sua configuração:

```bash
#!/bin/bash

# Banco de Dados
export DATABASE_URL="postgresql://penhas:penhas@localhost/penhas_dev"
export POSTGRESQL_HOST="localhost"
export POSTGRESQL_PORT="5432"
export POSTGRESQL_DBNAME="penhas_dev"
export POSTGRESQL_USERNAME="penhas"
export POSTGRESQL_PASSWORD="penhas"

# Redis
export REDIS_URL="redis://localhost:6379"
export REDIS_NS="penhas_dev:"

# Segredo JWT (gere uma string aleatória segura)
export JWT_SECRET="your-very-long-random-secret-key-here"

# Armazenamento S3 (use MinIO para desenvolvimento local)
export AWS_ACCESS_KEY_ID="minioadmin"
export AWS_SECRET_ACCESS_KEY="minioadmin"
export S3_MEDIA_BUCKET="penhas-dev"
export S3_ENDPOINT_URL="http://localhost:9000"

# Aplicação
export MOJO_MODE="development"
export MOJO_LOG_LEVEL="debug"
export PENHAS_API_PORT="3000"

# Segredo de Manutenção
export MAINTENANCE_SECRET="dev-maintenance-secret"

# Admin do Minion
export MINION_ADMIN_SECRET="dev-minion-secret"

# Serviços Externos (opcional para desenvolvimento)
export HERE_APPID=""
export HERE_APPCODE=""
export GOOGLE_MAPS_API_KEY=""

# Email (use SMTP local ou serviço)
export SMTP_HOST="localhost"
export SMTP_PORT="1025"
export SMTP_USER=""
export SMTP_PASS=""
export SMTP_FROM="PenhaS Dev <dev@localhost>"

# Flags de Funcionalidades
export ENABLE_OLD_PA_SUGG="1"
export DELETE_PREVIOUS_SESSIONS="0"
```

## Configuração do Banco de Dados

### 1. Criar Usuário e Banco de Dados

```bash
# Acessar PostgreSQL
sudo -u postgres psql

# Criar usuário e banco de dados
CREATE USER penhas WITH PASSWORD 'penhas';
CREATE DATABASE penhas_dev OWNER penhas;
\c penhas_dev
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS unaccent;
\q
```

### 2. Instalar Sqitch

Sqitch é usado para migrações de banco de dados:

```bash
# Ubuntu/Debian
sudo apt-get install sqitch libdbd-pg-perl

# macOS
brew install sqitch --with-postgres-support

# Ou via CPAN
cpanm App::Sqitch DBD::Pg
```

### 3. Executar Migrações

```bash
cd api/deploy_db

# Configurar sqitch
sqitch config --user user.name "Your Name"
sqitch config --user user.email "your.email@example.com"

# Inicializar sqitch
sqitch init penhas --engine pg

# Executar migrações
sqitch deploy --target db:pg://penhas:penhas@localhost/penhas_dev
```

### 4. Verificar Banco de Dados

```bash
# Verificar status das migrações
sqitch status --target db:pg://penhas:penhas@localhost/penhas_dev

# Conectar ao banco de dados
psql postgresql://penhas:penhas@localhost/penhas_dev

# Listar tabelas
\dt

# Verificar PostGIS
SELECT PostGIS_Version();
```

## Configuração do Ambiente Perl

### 1. Instalar Perl (se necessário)

```bash
# Verificar versão do Perl (precisa 5.20+)
perl -v

# Ubuntu/Debian
sudo apt-get install perl

# macOS (geralmente pré-instalado)
# Ou use perlbrew para gerenciamento de versões
```

### 2. Instalar cpanminus

```bash
# Instalar cpanm
curl -L https://cpanmin.us | perl - --sudo App::cpanminus

# Ou no Ubuntu/Debian
sudo apt-get install cpanminus
```

### 3. Instalar Carton (gerenciador de dependências Perl)

```bash
cpanm Carton
```

### 4. Instalar Dependências

```bash
cd api

# Instalar do cpanfile
carton install

# Ou instalar globalmente
cpanm --installdeps .
```

## Configuração de Serviços Locais

### 1. MinIO (armazenamento compatível com S3)

```bash
# Usando Docker
docker run -d \
  -p 9000:9000 \
  -p 9001:9001 \
  --name minio \
  -e "MINIO_ROOT_USER=minioadmin" \
  -e "MINIO_ROOT_PASSWORD=minioadmin" \
  -v ~/minio/data:/data \
  minio/minio server /data --console-address ":9001"

# Criar bucket
docker exec -it minio mc alias set myminio http://localhost:9000 minioadmin minioadmin
docker exec -it minio mc mb myminio/penhas-dev
```

### 2. MailHog (teste de email)

```bash
# Usando Docker
docker run -d \
  -p 1025:1025 \
  -p 8025:8025 \
  --name mailhog \
  mailhog/mailhog

# Acessar interface web em http://localhost:8025
```

### 3. Redis

```bash
# Iniciar Redis
redis-server

# Ou com Docker
docker run -d \
  -p 6379:6379 \
  --name redis \
  redis:6-alpine
```

## Executando a Aplicação

### 1. Usando Morbo (Servidor de Desenvolvimento)

```bash
cd api

# Carregar ambiente
source envfile_local.sh

# Executar com auto-reload
carton exec morbo script/penhas-api -l http://0.0.0.0:3000

# Ou sem carton
morbo script/penhas-api -l http://0.0.0.0:3000
```

### 2. Usando Docker

```bash
# Construir imagem
cd api
./build-container.sh

# Executar com docker-compose
cd ..
docker-compose up
```

### 3. Iniciar Workers do Minion

Em um terminal separado:

```bash
cd api
source envfile_local.sh

# Iniciar worker
carton exec script/penhas-api minion worker

# Ou iniciar múltiplos workers
carton exec script/penhas-api minion worker -j 4
```

## Ferramentas de Desenvolvimento

### 1. GUI para Banco de Dados

- **pgAdmin**: Administração PostgreSQL baseada em web
- **DBeaver**: Ferramenta universal de banco de dados
- **TablePlus**: GUI moderna para banco de dados

### 2. GUI para Redis

- **RedisInsight**: GUI oficial do Redis
- **Another Redis Desktop Manager**: GUI Redis multiplataforma

### 3. Teste de API

- **Postman**: Ambiente de desenvolvimento de API
- **Insomnia**: Cliente REST
- **HTTPie**: Cliente HTTP de linha de comando

```bash
# Exemplo com HTTPie
http POST localhost:3000/login \
  email=test@example.com \
  senha=password123 \
  app_version=dev
```

### 4. Desenvolvimento Perl

#### Extensões VS Code
- Perl Language Server
- Perl Debug
- Perl Toolbox

#### Configuração Vim
```vim
" ~/.vimrc
Plugin 'vim-perl/vim-perl'
Plugin 'c9s/perlomni.vim'
```

## Testes

### 1. Executar Testes Unitários

```bash
cd api

# Executar todos os testes
prove -lv t/

# Executar teste específico
prove -lv t/api/001-login.t

# Com cobertura
cover -test
```

### 2. Executar Testes de Integração

```bash
# Definir ambiente de teste
export HARNESS_ACTIVE=1

# Executar testes de integração
prove -lv xt/
```

### 3. Banco de Dados de Teste

Criar um banco de dados de teste separado:

```bash
CREATE DATABASE penhas_test OWNER penhas;
```

## Tarefas Comuns de Desenvolvimento

### 1. Adicionando um Novo Endpoint

1. Adicionar rota em `lib/Penhas/Routes.pm`
2. Criar controller em `lib/Penhas/Controller/`
3. Adicionar testes em `t/api/`
4. Atualizar documentação da API

### 2. Adicionando uma Migração de Banco de Dados

```bash
cd api/deploy_db

# Criar nova migração
sqitch add new-feature -n "Add new feature tables"

# Editar os arquivos
edit deploy/new-feature.sql
edit revert/new-feature.sql
edit verify/new-feature.sql

# Implantar
sqitch deploy
```

### 3. Adicionando um Job em Background

1. Criar tarefa em `lib/Penhas/Minion/Tasks/`
2. Registrar em `lib/Penhas/Minion/Tasks.pm`
3. Adicionar testes
4. Documentar o job

## Solução de Problemas

### Problemas Comuns

#### 1. Erro de Conexão com Banco de Dados

```bash
# Verificar se PostgreSQL está rodando
sudo systemctl status postgresql

# Verificar conexão
psql postgresql://penhas:penhas@localhost/penhas_dev
```

#### 2. Erro de Conexão com Redis

```bash
# Verificar se Redis está rodando
redis-cli ping

# Deve retornar: PONG
```

#### 3. Módulo Perl Ausente

```bash
# Instalar módulo ausente
cpanm Module::Name

# Ou com carton
carton install
```

#### 4. Erros de Permissão

```bash
# Corrigir permissões
sudo chown -R $USER:$USER ~/penhas-backend
```

### Modo Debug

Habilitar log detalhado:

```bash
export MOJO_LOG_LEVEL=debug
export PENHAS_DEBUG=1
export DBI_TRACE=1  # Log de consultas ao banco de dados
```

### Análise de Performance

```bash
# Executar com NYTProf
perl -d:NYTProf script/penhas-api daemon

# Gerar relatório
nytprofhtml

# Abrir nytprof/index.html
```

## Configuração de IDE

### VS Code

`.vscode/settings.json`:
```json
{
  "perl.perlInc": ["./lib", "./local/lib/perl5"],
  "perl.perlCmd": "carton exec perl",
  "editor.formatOnSave": true,
  "files.associations": {
    "*.ep": "html",
    "cpanfile": "perl"
  }
}
```

### Git Hooks

Configurar hooks pre-commit:

```bash
# .git/hooks/pre-commit
#!/bin/bash
# Executar testes antes do commit
prove -l t/ || exit 1

# Verificar sintaxe Perl
find lib -name "*.pm" -exec perl -c {} \; || exit 1
```

## Próximos Passos

1. Revisar a [Referência da API](./06-referencia-api.md)
2. Entender a [Estrutura do Projeto](./03-estrutura-projeto.md)
3. Aprender sobre [Jobs em Background](./07-jobs-background.md)
4. Configurar [Integrações Externas](./08-integracoes-externas.md) conforme necessário