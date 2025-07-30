# Stack Tecnológico

## Tecnologias Principais

### Linguagem de Programação
- **Perl 5.20+** - Linguagem principal
- Práticas e módulos **Modern Perl**

### Framework Web
- **Mojolicious 8.0+** - Framework web moderno para Perl
- Recursos web em tempo real
- Framework de testes integrado
- Suporte a WebSocket

### Banco de Dados
- **PostgreSQL 13+** - Banco de dados principal
- **PostGIS** - Extensão geoespacial
- **pgcrypto** - Funções criptográficas
- **uuid-ossp** - Geração de UUID

### Cache
- **Redis 5+** - Armazenamento de dados em memória
- Gerenciamento de sessões
- Rate limiting
- Armazenamento de dados temporários

### Plataforma de Container
- **Docker CE 19+** - Containerização de aplicações
- **Docker Compose 1.21+** - Orquestração multi-container

## Módulos Perl Principais

### Módulos do Framework Principal

```perl
# Framework Web
Mojolicious                    # Framework web principal
Mojolicious::Plugin::JWT       # Autenticação JWT
Mojolicious::Plugin::Minion    # Processamento de jobs em background

# ORM de Banco de Dados
DBIx::Class                    # ORM de banco de dados
DBD::Pg                        # Driver PostgreSQL
SQL::Abstract                  # Geração de SQL
DBIx::Class::Schema::Loader    # Auto-geração de schema

# Manipulação de Data/Hora
DateTime                       # Manipulação de data e hora
DateTime::Format::Pg           # Parsing de datetime PostgreSQL
DateTime::Format::ISO8601      # Parsing de data ISO 8601
```

### Validação e Tipos

```perl
# Sistema de Tipos
MooseX::Types                  # Sistema de restrições de tipo
MooseX::Types::Email          # Validação de email
Type::Tiny                    # Restrições de tipo
Types::Standard               # Biblioteca de tipos padrão

# Validação
Data::Validate::CPF           # Validação de CPF brasileiro
Email::Valid                  # Validação de email
```

### Integração com Serviços Externos

```perl
# Serviços AWS
Paws                          # SDK AWS para Perl
Paws::S3                      # Integração S3
Paws::SNS                     # Integração SNS

# Clientes HTTP
LWP::UserAgent                # Cliente HTTP
Mojo::UserAgent               # Cliente HTTP assíncrono
HTTP::Request                 # Objetos de requisição HTTP

# Outros Serviços
Net::SMTP                     # Envio de email
WWW::Correios::CEP           # Busca de CEP brasileiro
```

### Segurança e Criptografia

```perl
# Criptografia
Digest::SHA                   # Hashing SHA
Digest::MD5                   # Hashing MD5 (suporte legado)
Crypt::JWT                    # Manipulação de tokens JWT
Crypt::Random                 # Geração segura de números aleatórios

# Segurança
Authen::Passphrase           # Manipulação de senhas
MIME::Base64                 # Codificação Base64
```

### Módulos Utilitários

```perl
# Processamento JSON
JSON                         # Codificação/decodificação JSON
JSON::XS                     # Processamento JSON rápido
Cpanel::JSON::XS            # Processador JSON alternativo

# Manipulação de Arquivos
File::Temp                   # Criação de arquivos temporários
File::Slurp                  # Utilitários de leitura de arquivos
Path::Tiny                   # Manipulação de caminhos de arquivo

# Processamento de Imagem
Imager                       # Manipulação de imagem
Image::ExifTool              # Extração de dados EXIF

# Processamento de Áudio
Audio::Wav                   # Processamento de arquivos WAV
FFmpeg::Command              # Wrapper FFmpeg
```

### Desenvolvimento e Testes

```perl
# Testes
Test::More                   # Framework de testes básico
Test::Mojo                   # Testes Mojolicious
Test::Deep                   # Comparação de estruturas profundas
Test::Exception              # Testes de exceção

# Ferramentas de Desenvolvimento
Devel::Cover                 # Cobertura de código
Perl::Critic                 # Análise de qualidade de código
Perl::Tidy                   # Formatação de código
```

## Dependências Externas

### Pacotes do Sistema

```bash
# Pacotes do sistema necessários
postgresql-13
postgresql-13-postgis-3
redis-server
nginx
ffmpeg                       # Processamento de áudio
imagemagick                  # Processamento de imagem
git
curl
build-essential
```

### Serviços de Infraestrutura

#### Serviços Obrigatórios
1. **Banco de Dados PostgreSQL**
   - Versão: 13 ou superior
   - Extensões: PostGIS, uuid-ossp, unaccent

2. **Servidor Redis**
   - Versão: 5 ou superior
   - Usado para: Cache, sessões, rate limiting

3. **Armazenamento Compatível com S3**
   - Opções: AWS S3, Backblaze B2, MinIO
   - Propósito: Armazenamento de arquivos de mídia

4. **Servidor SMTP**
   - Para emails transacionais
   - Suporte para TLS/SSL

5. **Gateway SMS**
   - Amazon SNS (principal)
   - Provedores SMS alternativos suportados

#### Serviços Opcionais
1. **CDN (Content Delivery Network)**
   - Para entrega de assets estáticos
   - Reduz carga do servidor

2. **Monitoramento**
   - Prometheus/Grafana
   - Stack ELK para logs
   - Sentry para rastreamento de erros

3. **Serviços de Backup**
   - Backups automatizados do banco
   - Replicação de backup S3

## Ferramentas de Desenvolvimento

### Ferramentas Necessárias

```bash
# Desenvolvimento Perl
cpanm                        # Instalador de módulos CPAN
carton                       # Gerenciamento de dependências
local::lib                   # Instalação local de módulos

# Ferramentas de Banco de Dados
sqitch                       # Ferramenta de migração de banco
pgcli                        # CLI PostgreSQL
redis-cli                    # CLI Redis

# Ferramentas de Container
docker                       # Runtime de container
docker-compose              # Orquestração de container
```

### Plugins Recomendados para IDE/Editor

1. **Extensões VS Code**
   - Perl Language Server
   - Perl Debug
   - Docker
   - PostgreSQL

2. **Plugins Vim**
   - perl-support.vim
   - syntastic (verificação de sintaxe Perl)

## Requisitos de Versão

### Versões Mínimas

| Componente | Versão Mínima | Versão Recomendada |
|-----------|----------------|-------------------|
| Perl | 5.20 | 5.30+ |
| PostgreSQL | 13.0 | 14.0+ |
| Redis | 5.0 | 6.2+ |
| Docker | 19.03 | 20.10+ |
| Nginx | 1.18 | 1.20+ |

### Versões de Módulos Perl

Os requisitos de versão dos módulos principais são especificados no `cpanfile`:

```perl
requires 'Mojolicious', '>= 8.0';
requires 'DBIx::Class', '>= 0.082';
requires 'DateTime', '>= 1.50';
requires 'Redis', '>= 1.991';
```

## Considerações de Performance

### Extensões Compiladas
Vários módulos Perl têm versões XS (compiladas) para melhor performance:
- JSON::XS (mais rápido que JSON::PP)
- DateTime (aceleração XS)
- DBD::Pg (driver PostgreSQL compilado)

### Camadas de Cache
1. **Redis** - Cache em nível de aplicação
2. **PostgreSQL** - Cache de resultados de consulta
3. **Nginx** - Cache de arquivos estáticos
4. **CDN** - Distribuição geográfica

### Ferramentas de Otimização
- **Devel::NYTProf** - Profiler Perl
- **pgBadger** - Analisador de log PostgreSQL
- **redis-benchmark** - Teste de performance Redis