# Autenticação e Segurança

## Visão Geral

O backend PenhaS implementa um sistema de segurança abrangente usando tokens JWT, rate limiting, validação de entrada e múltiplas camadas de proteção para dados do usuário.

## Autenticação JWT

### Estrutura do Token

```json
{
  "ses": 12345,    // ID da sessão de clientes_active_sessions
  "typ": "usr",    // Tipo do token (sempre "usr" para usuários)
  "iat": 1234567890,
  "exp": 1234567890
}
```

### Fluxo de Autenticação

#### 1. Login do Usuário (`POST /login`)

```perl
# Requisição
POST /login
{
  "email": "usuario@exemplo.com",
  "senha": "senha123",
  "app_version": "1.0.0"
}

# Processo
1. Validar formato de email e força da senha
2. Aplicar rate limiting (3 requisições/minuto por IP)
3. Hash da senha com SHA256
4. Verificar credenciais do usuário
5. Verificar status da conta (ativa/banida/excluída)
6. Criar sessão em clientes_active_sessions
7. Gerar token JWT
8. Registrar tentativa de login

# Resposta
{
  "session": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "deleted_scheduled": false
}
```

#### 2. Validação do Token

Toda requisição autenticada deve incluir o token JWT:

```perl
# Headers
x-api-key: eyJ0eXAiOiJKV1QiLCJhbGc...

# Ou Parâmetro de Query
GET /me?api_key=eyJ0eXAiOiJKV1QiLCJhbGc...
```

Processo de validação:
1. Decodificar token JWT
2. Verificar assinatura do token
3. Verificar expiração do token
4. Validar sessão no cache Redis
5. Carregar contexto do usuário
6. Aplicar rate limiting

### Gerenciamento de Sessão

#### Estratégia de Cache Redis

```perl
# Formato da chave de cache de sessão
CaS:$session_id => $user_id

# TTL do cache: 5 minutos
# Reduz consultas ao banco para usuários ativos
```

#### Invalidação de Sessão

Sessões são invalidadas quando:
- Usuário faz logout explicitamente
- Usuário altera senha
- Admin força logout
- Sessão expira (configurável)

## Rate Limiting

### Camadas de Implementação

#### 1. Rate Limiting por IP

```perl
# Endpoint de login: 3 requisições por minuto
$c->stash(apply_rps_on => 'login' . substr($remote_ip, 0, 18));
$c->apply_request_per_second_limit(3, 60);

# Endpoints públicos: 30 requisições por minuto
$c->stash(apply_rps_on => 'pa_list:' . substr($remote_ip, 0, 18));
$c->apply_request_per_second_limit(30, 60);
```

#### 2. Rate Limiting por Usuário

```perl
# Usuários autenticados: 120 requisições por minuto
$c->stash(apply_rps_on => 'D' . $user_id);
$c->apply_request_per_second_limit(120, 60);

# Operações específicas têm limites adicionais
# Upload de áudio: 10 por hora
# Sugestões de centro de apoio: 120 por hora
```

#### 3. Limites Específicos por Endpoint

| Endpoint | Limite | Janela |
|----------|--------|---------|
| `/login` | 3 | 1 minuto |
| `/signup` | 5 | 1 hora |
| `/reset-password` | 3 | 1 hora |
| `/me/audios/upload` | 10 | 1 hora |
| `/pontos-de-apoio` | 30 | 1 minuto |

### Headers de Rate Limit

```http
X-RateLimit-Limit: 120
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1234567890
```

## Segurança de Senha

### Requisitos de Senha

```perl
# Requisitos mínimos aplicados
- Comprimento: mínimo 8 caracteres
- Complexidade: Mix de letras e números recomendado
- Verificação de força via check_password_or_die()
```

### Armazenamento de Senha

```perl
# Principal: hash SHA256
$senha = sha256_hex($senha_crua);

# Suporte legado: MD5 (sendo descontinuado)
$senha_md5 = md5_hex($senha_crua);

# Nunca armazenar senhas em texto puro
```

### Fluxo de Reset de Senha

1. Usuário solicita reset (`POST /reset-password/request-new`)
2. Sistema gera token seguro
3. Token enviado via email
4. Usuário submete nova senha com token
5. Sessões antigas invalidadas
6. Histórico de senha verificado (opcional)

## Segurança da Conta

### Monitoramento de Tentativas de Login

```perl
# Configuração
MAX_EMAIL_ERRORS_BEFORE_LOCK = 15
WAIT_SECONDS_TO_ACCOUNT_UNLOCK = 86400 (24 horas)

# Bloqueio de conta após falhas repetidas
if ($login_errors >= $max_email_errors_before_lock) {
    $user->update({
        login_status => 'blocked',
        login_status_last_blocked_at => \'now()'
    });
}
```

### Gerenciamento de Status da Conta

```sql
-- Status de contas
'active'           -- Conta ativa normal
'banned'           -- Banida administrativamente
'deleted_scheduled' -- Exclusão pendente
'blocked'          -- Muitas tentativas de login
```

## Proteção de Dados

### Informações Pessoalmente Identificáveis (PII)

#### Proteção de CPF (ID Fiscal Brasileiro)

```perl
# Armazenar apenas hash e prefixo
$cpf_hash = sha256_hex($cpf);
$cpf_prefix = substr($cpf, 0, 3);

# Nunca armazenar CPF completo
```

#### Privacidade de Localização

```perl
# Dados de localização são opcionais
# Usuários podem habilitar modo anônimo
# Localização precisa apenas armazenada com consentimento
```

### Modo Anônimo

Quando `modo_anonimo_ativo` está habilitado:
- Coleta limitada de dados
- Sem rastreamento de localização
- Analytics reduzidos
- Tratamento especial em relatórios

### Modo Camuflado

Quando `modo_camuflado_ativo` está habilitado:
- App aparece como calculadora/jogo
- Considerações especiais de UI
- Notificações ocultas

## Validação de Entrada

### Framework de Validação

```perl
# Todas as entradas validadas usando restrições de tipo
$c->validate_request_params(
    email => {
        required => 1,
        type => EmailAddress,
        max_length => 200
    },
    senha => {
        required => 1,
        type => 'Str',
        max_length => 200,
        min_length => 8
    }
);
```

### Validações Comuns

```perl
# Validação de email
use MooseX::Types::Email qw/EmailAddress/;

# Validação de CPF
use Penhas::Types qw/CPF/;

# Validação de número de telefone
use Penhas::Types qw/MobileNumber/;

# Validação de geolocalização
use Penhas::Types qw/Latitude Longitude/;
```

### Prevenção de SQL Injection

```perl
# Usar ORM DBIx::Class previne SQL injection
# Todas as consultas usam statements parametrizados
# Sem concatenação de SQL bruto

# Seguro
$schema->resultset('Cliente')->search({
    email => $email  # Automaticamente escapado
});

# Nunca faça isso
my $sql = "SELECT * FROM clientes WHERE email = '$email'";
```

## Headers de Segurança da API

### Headers de Segurança Configurados

```perl
# Headers CORS (configurável)
Access-Control-Allow-Origin: https://app.penhas.com.br
Access-Control-Allow-Methods: GET, POST, PUT, DELETE
Access-Control-Allow-Headers: Content-Type, x-api-key

# Headers de segurança
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

## Segurança de Upload de Arquivo

### Validação de Upload

```perl
# Limites de tamanho de arquivo
- Imagens: máximo 5MB
- Áudio: máximo 35MB

# Validação de tipo de arquivo
- Imagens: apenas JPEG, PNG
- Áudio: apenas AAC, M4A, MP4

# Escaneamento de vírus (opcional)
# Integração com ClamAV ou similar
```

### Armazenamento Seguro

```perl
# Arquivos armazenados no S3 com:
- ACL privada
- URLs pré-assinadas para acesso
- Links com expiração (configurável)
- Criptografado em repouso
```

## Segurança Admin

### Autenticação Admin

```perl
# Sistema de autenticação separado
# Requisitos de senha mais fortes
# Lista branca de IP (opcional)
# Autenticação de dois fatores (opcional)
```

### Permissões Admin

```perl
# Controle de acesso baseado em papéis
- Super Admin: Acesso total
- Moderador: Moderação de conteúdo
- Suporte: Funções de suporte ao usuário
- Analytics: Relatórios somente leitura
```

## Monitoramento de Segurança

### Log de Auditoria

```perl
# Todos os eventos de segurança registrados
- Tentativas de login (sucesso/falha)
- Alterações de senha
- Alterações de permissão
- Exportações de dados
- Ações admin
```

### Detecção de Intrusão

```perl
# Padrões monitorados:
- Falhas repetidas de login
- Padrões de requisição incomuns
- Anomalias geográficas
- Anomalias baseadas em tempo
```

## Conformidade LGPD/GDPR

### Minimização de Dados

- Coletar apenas dados necessários
- Purga regular de dados
- Opções anônimas disponíveis

### Direito à Exclusão

```perl
# Processo completo de exclusão de dados
1. Usuário solicita exclusão
2. Período de carência de 30 dias
3. Job em background remove todos os dados
4. Trilha de auditoria mantida (anonimizada)
```

### Exportação de Dados

```perl
# Usuários podem solicitar seus dados
- Exportação em formato JSON
- Inclui todo conteúdo gerado pelo usuário
- Exclui dados do sistema/segurança
```

## Melhores Práticas de Segurança

### Desenvolvimento

1. **Revisões de Código**: Revisões focadas em segurança
2. **Escaneamento de Dependências**: Atualizações regulares
3. **Análise Estática**: Regras Perl::Critic
4. **Testes**: Suíte de testes de segurança

### Deploy

1. **Apenas HTTPS**: Sem fallback HTTP
2. **Gerenciamento de Secrets**: Variáveis de ambiente
3. **Isolamento de Rede**: Subnets privadas
4. **Atualizações Regulares**: SO e dependências

### Resposta a Incidentes

1. **Detecção**: Monitoramento e alertas
2. **Resposta**: Procedimentos definidos
3. **Recuperação**: Restauração de backup
4. **Post-mortem**: Aprender e melhorar

## Configurações Comuns de Segurança

### Variáveis de Ambiente

```bash
# Configuração JWT
JWT_SECRET="string-aleatoria-longa"
JWT_EXPIRES_IN="7d"

# Rate Limiting
MAX_EMAIL_ERRORS_BEFORE_LOCK=15
WAIT_SECONDS_TO_ACCOUNT_UNLOCK=86400

# Gerenciamento de Sessão
DELETE_PREVIOUS_SESSIONS=1
SESSION_TIMEOUT=3600

# Recursos de Segurança
ENABLE_2FA=0
REQUIRE_STRONG_PASSWORDS=1
PASSWORD_HISTORY_COUNT=3
```