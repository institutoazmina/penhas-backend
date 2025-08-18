# Referência da API

## Visão Geral

A API PenhaS é um serviço RESTful que fornece endpoints para o aplicativo móvel. Todas as requisições e respostas usam formato JSON, salvo indicação contrária.

## URL Base

```
Produção: https://api.penhas.com.br
Desenvolvimento: http://localhost:3000
```

## Autenticação

A maioria dos endpoints requer autenticação via token JWT. Inclua o token no header da requisição:

```http
x-api-key: eyJ0eXAiOiJKV1QiLCJhbGc...
```

## Formatos de Resposta Comuns

### Resposta de Sucesso

```json
{
  "data": { ... },
  "status": "success"
}
```

### Resposta de Erro

```json
{
  "error": "codigo_erro",
  "message": "Mensagem de erro legível",
  "field": "nome_campo", // Opcional: campo específico que causou o erro
  "status": 400
}
```

## Endpoints Públicos

### Autenticação

#### POST /signup
Criar uma nova conta de usuário.

**Requisição:**
```json
{
  "nome_completo": "Maria Silva",
  "cpf": "12345678901",
  "email": "maria@exemplo.com",
  "senha": "senhasegura123",
  "cep": "01310-100",
  "dt_nasc": "1990-01-01",
  "nome_social": "Maria",
  "genero": "feminino"
}
```

**Resposta:**
```json
{
  "session": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "_test_only_id": 123 // Apenas em ambiente de teste
}
```

#### POST /login
Autenticar usuário e receber token JWT.

**Requisição:**
```json
{
  "email": "maria@exemplo.com",
  "senha": "senhasegura123",
  "app_version": "1.0.0"
}
```

**Resposta:**
```json
{
  "session": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "deleted_scheduled": false
}
```

#### POST /reset-password/request-new
Solicitar token de reset de senha.

**Requisição:**
```json
{
  "email": "maria@exemplo.com"
}
```

**Resposta:**
```json
{
  "message": "E-mail enviado com sucesso"
}
```

#### POST /reset-password/write-new
Definir nova senha usando token de reset.

**Requisição:**
```json
{
  "email": "maria@exemplo.com",
  "token": "token-reset-do-email",
  "senha": "novasenha123"
}
```

**Resposta:**
```json
{
  "message": "Senha alterada com sucesso"
}
```

### Centros de Apoio (Pontos de Apoio)

#### GET /pontos-de-apoio
Listar centros de apoio próximos a uma localização.

**Parâmetros de Query:**
- `latitude` (obrigatório se não houver location_token): Latitude
- `longitude` (obrigatório se não houver location_token): Longitude
- `location_token`: Token JWT com localização codificada
- `categorias`: IDs de categorias separados por vírgula
- `keywords`: Palavras-chave de busca
- `rows`: Número de resultados (padrão: 10, máx: 50)
- `max_distance`: Distância máxima em metros (padrão: 10000)
- `eh_24h`: Filtrar centros 24 horas (booleano)
- `dias_funcionamento`: Filtro de dias de funcionamento

**Resposta:**
```json
{
  "rows": [
    {
      "id": 123,
      "nome": "Delegacia da Mulher - Centro",
      "categoria": "Delegacia Especializada",
      "endereco": "Rua Exemplo, 123",
      "telefone": "(11) 1234-5678",
      "distance": 1234.5,
      "eh_24h": false,
      "has_whatsapp": true
    }
  ],
  "has_more": false,
  "next_page": null
}
```

#### GET /pontos-de-apoio/:id
Obter informações detalhadas sobre um centro de apoio.

**Resposta:**
```json
{
  "id": 123,
  "nome": "Delegacia da Mulher - Centro",
  "nome_completo": "Delegacia de Defesa da Mulher - Centro",
  "categoria": "Delegacia Especializada",
  "endereco": "Rua Exemplo, 123, Centro",
  "cep": "01234-567",
  "telefone": "(11) 1234-5678",
  "telefone2": "(11) 9876-5432",
  "email": "ddm.centro@exemplo.gov.br",
  "horario_funcionamento": "Segunda a Sexta, 8h às 18h",
  "eh_24h": false,
  "dias_funcionamento": "seg,ter,qua,qui,sex",
  "descricao": "Atendimento especializado para mulheres...",
  "has_whatsapp": true,
  "latitude": -23.550520,
  "longitude": -46.633309
}
```

#### GET /geocode
Converter endereço em coordenadas.

**Parâmetros de Query:**
- `address`: Endereço para geocodificar

**Resposta:**
```json
{
  "location_token": "eyJ0eXAiOiJKV1QiLCJpc3M...",
  "label": "São Paulo, SP, Brasil"
}
```

### Conteúdo Web

#### GET /web/faq
Obter conteúdo da página de FAQ.

#### GET /web/termos-de-uso
Obter termos de uso.

#### GET /web/politica-privacidade
Obter política de privacidade.

## Endpoints Autenticados

Todos os endpoints abaixo requerem autenticação JWT.

### Perfil do Usuário

#### GET /me
Obter perfil do usuário atual e módulos disponíveis.

**Resposta:**
```json
{
  "user_profile": {
    "email": "maria@exemplo.com",
    "nome_completo": "Maria Silva",
    "apelido": "Maria",
    "avatar_url": "https://...",
    "skills": ["psychologist", "lawyer"],
    "modo_anonimo_ativo": false,
    "modo_camuflado_ativo": false,
    "ja_foi_vitima_de_violencia": false
  },
  "modules": [
    {
      "code": "chat",
      "meta": {}
    },
    {
      "code": "guardioes",
      "meta": {}
    }
  ],
  "quiz_session": null,
  "modo_camuflado_ativo": false,
  "modo_anonimo_ativo": false
}
```

#### PUT /me
Atualizar perfil do usuário.

**Requisição:**
```json
{
  "nome_completo": "Maria Silva Santos",
  "apelido": "Mari",
  "minibio": "Psicóloga especializada em violência doméstica"
}
```

#### DELETE /me
Agendar exclusão da conta.

**Requisição:**
```json
{
  "senha": "senhaatual123",
  "app_version": "1.0.0"
}
```

#### POST /reactivate
Cancelar exclusão agendada da conta.

### Guardiões (Guardiões)

#### GET /me/guardioes
Listar guardiões do usuário.

**Resposta:**
```json
{
  "guardioes": [
    {
      "id": 1,
      "nome": "Ana Silva",
      "celular": "+5511999999999",
      "status": "pending"
    }
  ]
}
```

#### POST /me/guardioes
Adicionar ou atualizar um guardião.

**Requisição:**
```json
{
  "nome": "Ana Silva",
  "celular": "+5511999999999"
}
```

#### DELETE /me/guardioes/:id
Remover um guardião.

#### POST /me/guardioes/alert
Enviar alerta para todos os guardiões.

**Requisição:**
```json
{
  "gps_lat": "-23.550520",
  "gps_long": "-46.633309"
}
```

### Gravação de Áudio

#### POST /me/audios/upload
Upload de gravação de áudio de emergência.

**Requisição:**
Dados multipart form com:
- `media`: Arquivo de áudio (AAC, M4A, MP4)
- `cliente_created_at`: Timestamp do cliente
- `current_time`: Timestamp atual
- `event_id`: UUID v4
- `event_sequence`: Número de sequência (0-1000)

**Resposta:**
```json
{
  "id": 123,
  "event_id": "550e8400-e29b-41d4-a716-446655440000",
  "event_sequence": 1,
  "waveform": [0.1, 0.5, 0.8, ...],
  "audio_duration": 120.5
}
```

#### GET /me/audios/eventos
Listar eventos de gravação de áudio.

**Parâmetros de Query:**
- `rows`: Número de resultados
- `next_page`: Token de paginação

**Resposta:**
```json
{
  "rows": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "created_at": "2023-01-01T10:00:00Z",
      "total_audios": 5,
      "total_duration": 600.5,
      "status": "free",
      "can_download": true
    }
  ],
  "has_more": false
}
```

#### GET /me/audios/:event_id
Obter detalhes do evento com lista de áudios.

**Resposta:**
```json
{
  "event": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "created_at": "2023-01-01T10:00:00Z",
    "status": "free"
  },
  "audios": [
    {
      "id": 123,
      "event_sequence": 1,
      "waveform": [0.1, 0.5, 0.8, ...],
      "audio_duration": 120.5,
      "created_at": "2023-01-01T10:00:00Z"
    }
  ]
}
```

#### POST /me/audios/:event_id/download
Baixar arquivos de áudio.

**Requisição:**
```json
{
  "audio_sequences": "1,2,3" // ou "all"
}
```

**Resposta:**
Stream de arquivo de áudio (formato AAC)

### Chat

#### GET /me/chat/sessions
Listar sessões de chat.

**Parâmetros de Query:**
- `rows`: Número de resultados
- `next_page`: Token de paginação
- `cliente_id`: Filtrar por usuário específico

**Resposta:**
```json
{
  "sessions": [
    {
      "session_key": "chat_auth_token",
      "other_cliente": {
        "id": 456,
        "nome_completo": "Equipe de Suporte",
        "avatar_url": "https://..."
      },
      "last_message": "Olá, como posso ajudar?",
      "last_message_at": "2023-01-01T10:00:00Z",
      "last_message_is_me": false,
      "unread_count": 2
    }
  ],
  "has_more": false
}
```

#### POST /me/chat/open-session
Abrir chat com outro usuário.

**Requisição:**
```json
{
  "cliente_id": 456,
  "prefetch": true
}
```

#### POST /me/chat/send-message
Enviar mensagem de chat.

**Requisição:**
```json
{
  "chat_auth": "chat_auth_token",
  "message": "Olá, preciso de ajuda"
}
```

#### GET /me/chat/messages
Obter histórico de mensagens do chat.

**Parâmetros de Query:**
- `chat_auth`: Token da sessão de chat
- `rows`: Número de mensagens
- `before`: ID da mensagem para paginação

### Centros de Apoio (Autenticado)

#### GET /me/pontos-de-apoio
Mesmo que endpoint público mas com contexto do usuário.

#### POST /me/pontos-de-apoio/sugerir
Sugerir um novo centro de apoio.

**Requisição:**
```json
{
  "categoria_id": 1,
  "nome": "Novo Centro de Apoio",
  "endereco": "Rua Exemplo, 123",
  "cep": "01234-567",
  "telefone": "(11) 1234-5678",
  "email": "contato@exemplo.org",
  "horario_funcionamento": "Segunda a Sexta, 8h às 18h",
  "descricao": "Centro especializado em..."
}
```

#### POST /me/pontos-de-apoio/:id/avaliar
Avaliar um centro de apoio.

**Requisição:**
```json
{
  "rating": 5,
  "comment": "Excelente atendimento"
}
```

### Quiz e Tarefas

#### POST /me/quiz
Processar respostas do quiz.

**Requisição:**
```json
{
  "session_id": "quiz_session_id",
  "responses": {
    "question_1": "yes",
    "question_2": "no"
  }
}
```

#### GET /me/tarefas
Obter tarefas do manual de fuga.

**Resposta:**
```json
{
  "tarefas": [
    {
      "id": 1,
      "title": "Documentos importantes",
      "description": "Separe cópias de documentos",
      "completed": false
    }
  ]
}
```

### Feed e Conteúdo

#### GET /timeline
Obter feed de notícias.

**Parâmetros de Query:**
- `rows`: Número de itens
- `next_page`: Token de paginação
- `tags`: Filtrar por tags

**Resposta:**
```json
{
  "tweets": [
    {
      "id": 123,
      "content": "Conteúdo do post...",
      "created_at": "2023-01-01T10:00:00Z",
      "owner": {
        "name": "PenhaS",
        "avatar_url": "https://..."
      },
      "likes_count": 10,
      "i_liked": false
    }
  ],
  "has_more": true,
  "next_page": "token"
}
```

## Códigos de Erro

Códigos de erro comuns retornados pela API:

| Código | Descrição |
|--------|-----------|
| `missing_required_param` | Parâmetro obrigatório ausente |
| `invalid_param` | Falha na validação do parâmetro |
| `expired_jwt` | Token JWT expirado |
| `jwt_logout` | Sessão invalidada |
| `notfound` | Recurso não encontrado |
| `wrongpassword` | Senha inválida |
| `email_already_exists` | Email já cadastrado |
| `upload_blocked` | Permissão de upload negada |
| `media_too_big` | Tamanho do arquivo excede limite |
| `unsupported_media_type` | Tipo de arquivo inválido |

## Rate Limiting

A API implementa rate limiting. Verifique os headers de resposta:

```http
X-RateLimit-Limit: 120
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1234567890
```

Quando o rate limit é excedido:
```json
{
  "error": "rate_limit_exceeded",
  "message": "Muitas requisições",
  "status": 429
}
```