# Estrutura do Projeto

## Layout de Diretórios

```
penhas-backend/
├── api/                           # Aplicação API principal
│   ├── lib/                       # Módulos Perl
│   │   └── Penhas/               # Namespace da aplicação
│   │       ├── Controller/       # Controladores de endpoints HTTP
│   │       ├── Helpers/          # Helpers de lógica de negócio
│   │       ├── Minion/           # Sistema de jobs em background
│   │       ├── Schema/           # Modelos ORM do banco de dados
│   │       ├── Types/            # Definições de tipos customizados
│   │       ├── Config.pm         # Gerenciamento de configuração
│   │       ├── Routes.pm         # Definições de rotas
│   │       └── Utils.pm          # Funções utilitárias
│   ├── deploy_db/                # Gerenciamento de banco de dados
│   │   ├── deploy/               # Arquivos SQL de migração
│   │   ├── revert/               # Arquivos SQL de rollback
│   │   ├── verify/               # Arquivos SQL de verificação
│   │   └── sqitch.plan           # Plano de migração
│   ├── public/                   # Arquivos estáticos
│   │   ├── avatar/               # Avatares padrão
│   │   ├── email-templates/      # Templates HTML de email
│   │   └── web-assets/           # CSS, JS, imagens
│   ├── templates/                # Templates server-side
│   │   ├── admin/                # Templates da interface admin
│   │   ├── layouts/              # Templates de layout
│   │   └── webfaq/               # Templates de FAQ
│   ├── script/                   # Scripts executáveis
│   │   └── penhas-api            # Script principal da aplicação
│   ├── t/                        # Arquivos de teste
│   │   ├── api/                  # Testes de endpoints da API
│   │   └── lib/                  # Utilitários de teste
│   ├── xt/                       # Testes estendidos
│   ├── docker/                   # Configuração Docker
│   │   ├── Dockerfile            # Definição do container
│   │   └── entrypoint.sh         # Ponto de entrada do container
│   ├── cpanfile                  # Dependências Perl
│   ├── dist.ini                  # Configuração de distribuição
│   └── envfile.sh                # Template de ambiente
├── data/                         # Dados de configuração
│   └── config/                   # Arquivos de configuração
├── docs/                         # Documentação
├── docker-compose.yaml           # Orquestração de containers
└── README.md                     # Readme do projeto
```

## Diretórios Principais

### `/api/lib/Penhas/Controller/`

Controladores de endpoints HTTP que lidam com requisição/resposta:

```
Controller/
├── Admin/                    # Endpoints administrativos
│   ├── Badges.pm            # Gerenciamento de badges
│   ├── BigNum.pm            # Dashboard de estatísticas
│   ├── Notifications.pm     # Gerenciamento de notificações push
│   ├── PontoApoio.pm        # Moderação de centros de apoio
│   ├── Session.pm           # Autenticação admin
│   └── Users.pm             # Gerenciamento de usuários
├── Login.pm                 # Autenticação de usuários
├── Logout.pm                # Término de sessão
├── SignUp.pm                # Registro de usuários
├── ResetPassword.pm         # Recuperação de senha
├── Me.pm                    # Gerenciamento de perfil do usuário
├── Me_Audios.pm            # Gerenciamento de gravações de áudio
├── Me_Chat.pm              # Funcionalidade de chat
├── Me_Guardioes.pm         # Gerenciamento de guardiões
├── Me_Media.pm             # Manipulação de upload de mídia
├── Me_Preferences.pm       # Preferências do usuário
├── Me_Quiz.pm              # Manipulação de quiz/questionário
├── Me_Tarefas.pm           # Gerenciamento de tarefas
├── PontoApoio.pm           # Endpoints de centros de apoio
├── News.pm                 # Feed de notícias
├── Timeline.pm             # Timeline do usuário
└── WebFAQ.pm               # Páginas de FAQ
```

### `/api/lib/Penhas/Helpers/`

Lógica de negócio e camada de serviço:

```
Helpers/
├── Chat.pm                  # Lógica de negócio do chat
├── ChatSupport.pm          # Lógica do chat de suporte
├── Cliente.pm              # Helpers relacionados ao usuário
├── ClienteAudio.pm         # Lógica de manipulação de áudio
├── ClienteSetSkill.pm      # Gerenciamento de habilidades do usuário
├── CPF.pm                  # Validação de CPF brasileiro
├── Geolocation.pm          # Serviços de geocodificação
├── GeolocationCached.pm    # Geocodificação com cache
├── Guardioes.pm            # Lógica do sistema de guardiões
├── Notifications.pm        # Lógica de notificações push
├── PontoApoio.pm          # Lógica de centros de apoio
├── Quiz.pm                 # Lógica do sistema de quiz
├── RSS.pm                  # Processamento de feed RSS
├── Timeline.pm             # Geração de timeline
└── WebHelpers.pm           # Helpers utilitários web
```

### `/api/lib/Penhas/Minion/Tasks/`

Definições de jobs em background:

```
Tasks/
├── CepUpdater.pm           # Atualiza localização de usuários a partir de CEPs
├── DeleteAudio.pm          # Remove arquivos de áudio do S3
├── DeleteUser.pm           # Exclusão completa de dados do usuário
├── NewNotification.pm      # Envia notificações push
├── NewsDisplayIndexer.pm   # Indexa notícias para exibição
├── NewsIndexer.pm          # Indexação para busca full-text
└── SendSMS.pm              # Entrega de mensagens SMS
```

### `/api/lib/Penhas/Schema/`

Definições de modelos ORM do banco de dados:

```
Schema/
├── Result/                  # Definições de tabelas
│   ├── Cliente.pm          # Tabela de usuários
│   ├── PontoApoio.pm       # Centros de apoio
│   ├── ChatSession.pm      # Sessões de chat
│   └── ...                 # Outras tabelas
└── ResultSet/              # Métodos de consulta customizados
    ├── Cliente.pm          # Consultas de usuário
    └── ...                 # Outros result sets
```

## Arquivos de Configuração

### `cpanfile`
Dependências de módulos Perl:
```perl
requires 'Mojolicious', '>= 8.0';
requires 'DBIx::Class', '>= 0.082';
requires 'DateTime', '>= 1.50';
# ... outras dependências
```

### `dist.ini`
Configuração do construtor de distribuição para empacotamento.

### `envfile.sh`
Template de variáveis de ambiente:
```bash
export DATABASE_URL="postgresql://user:pass@host/db"
export REDIS_URL="redis://localhost:6379"
export JWT_SECRET="sua-chave-secreta"
# ... outras variáveis
```

### `docker-compose.yaml`
Configuração de orquestração de containers.

## Arquivos de Banco de Dados

### `/api/deploy_db/`

Estrutura de migração de banco de dados Sqitch:

```
deploy_db/
├── deploy/                  # Migrações forward
│   ├── 0001-db-init.sql    # Schema inicial
│   ├── 0002-configs.sql    # Tabelas de configuração
│   └── ...                 # Outras migrações
├── revert/                  # Scripts de rollback
├── verify/                  # Scripts de verificação
└── sqitch.plan             # Plano de migração
```

## Assets Estáticos

### `/api/public/`

Arquivos acessíveis publicamente:

```
public/
├── avatar/                  # Avatares padrão de usuários
├── email-templates/         # Templates HTML de email
│   ├── welcome.html
│   ├── reset-password.html
│   └── ...
├── favicon/                 # Ícones do site
└── web-assets/             # CSS, JS para páginas web
```

## Templates

### `/api/templates/`

Templates renderizados server-side:

```
templates/
├── admin/                   # Interface admin
│   ├── dashboard.html.ep
│   ├── users.html.ep
│   └── ...
├── layouts/                 # Layouts compartilhados
│   └── default.html.ep
└── webfaq/                 # Páginas de FAQ
    ├── index.html.ep
    └── detail.html.ep
```

## Estrutura de Testes

### `/api/t/`

Testes unitários e de integração:

```
t/
├── api/                     # Testes de endpoints da API
│   ├── 001-login.t
│   ├── 002-signup.t
│   └── ...
├── lib/                     # Utilitários de teste
│   └── Penhas/
│       └── Test.pm
└── data/                    # Fixtures de teste
    ├── audio.aac
    └── image.png
```

## Scripts

### `/api/script/`

Scripts executáveis:

- `penhas-api` - Lançador principal da aplicação
- `minion` - Worker de jobs em background
- Vários scripts de manutenção

## Configuração Docker

### `/api/docker/`

Arquivos de configuração de container:

- `Dockerfile` - Definição da imagem do container
- `entrypoint.sh` - Inicialização do container
- Scripts de build e runtime

## Arquivos de Desenvolvimento

### Arquivos na Raiz

- `.gitignore` - Padrões de ignore do Git
- `.editorconfig` - Configuração do editor
- `perltidy.rc` - Regras de formatação de código Perl
- `perlcritic.rc` - Regras de qualidade de código Perl

## Convenções de Nomenclatura de Arquivos

1. **Módulos Perl**: CamelCase (ex: `PontoApoio.pm`)
2. **Scripts**: minúsculas com hífens (ex: `penhas-api`)
3. **Arquivos SQL**: numerados com descrição (ex: `0001-db-init.sql`)
4. **Templates**: minúsculas com extensão `.html.ep`
5. **Arquivos Estáticos**: minúsculas com hífens

## Arquivos Importantes

### Arquivos Principais da Aplicação

1. **`lib/Penhas.pm`** - Classe principal da aplicação
2. **`lib/Penhas/Routes.pm`** - Todas as definições de rotas
3. **`lib/Penhas/Config.pm`** - Gerenciamento de configuração
4. **`lib/Penhas/Controller.pm`** - Classe base dos controladores

### Arquivos de Configuração

1. **`cpanfile`** - Dependências Perl
2. **`envfile.sh`** - Template de variáveis de ambiente
3. **`docker-compose.yaml`** - Orquestração de containers

### Arquivos de Banco de Dados

1. **`deploy_db/sqitch.plan`** - Ordem de migração
2. **`deploy_db/deploy/0001-db-init.sql`** - Schema inicial