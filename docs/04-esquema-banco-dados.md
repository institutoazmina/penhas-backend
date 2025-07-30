# Esquema do Banco de Dados

## Visão Geral

O banco de dados PenhaS usa PostgreSQL 13+ com extensão PostGIS para recursos geoespaciais. O esquema é projetado para suportar privacidade do usuário, segurança de dados e consultas eficientes.

## Tabelas Principais

### Usuários e Autenticação

#### `clientes` - Tabela Principal de Usuários

```sql
CREATE TABLE public.clientes (
    id SERIAL PRIMARY KEY,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    email character varying(200) UNIQUE NOT NULL,
    senha_sha256 character varying(200),
    senha_md5 character varying(200), -- Legado, sendo descontinuado
    
    -- Informações do Perfil
    nome_completo character varying(200),
    apelido character varying(200),
    genero character varying(20),
    raca character varying(20),
    data_nascimento date,
    
    -- Privacidade e Segurança
    cpf_hash character varying(200),
    cpf_prefix character varying(20),
    modo_anonimo_ativo boolean DEFAULT false,
    modo_camuflado_ativo boolean DEFAULT false,
    
    -- Localização
    cep character varying(20),
    cep_estado character varying(2),
    cep_cidade character varying(200),
    cep_bairro character varying(200),
    latitude double precision,
    longitude double precision,
    
    -- Gerenciamento de Conta
    created_at timestamp with time zone DEFAULT now(),
    deleted_at timestamp with time zone,
    perform_delete_at timestamp with time zone,
    deletion_started_at timestamp with time zone,
    
    -- Segurança de Login
    qtde_login_senha_normal integer DEFAULT 0,
    login_status character varying(20) DEFAULT 'OK'::character varying,
    login_status_last_blocked_at timestamp with time zone,
    
    -- Preferências
    skills jsonb DEFAULT '[]'::jsonb,
    access_modules jsonb DEFAULT '[]'::jsonb,
    upload_status character varying(20) DEFAULT 'ok_all'::character varying
);

-- Índices
CREATE INDEX idx_clientes_email ON clientes(email);
CREATE INDEX idx_clientes_status ON clientes(status);
CREATE INDEX idx_clientes_cpf_hash ON clientes(cpf_hash);
```

#### `clientes_active_sessions` - Sessões Ativas de Usuários

```sql
CREATE TABLE public.clientes_active_sessions (
    id SERIAL PRIMARY KEY,
    cliente_id integer NOT NULL REFERENCES clientes(id),
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE INDEX idx_cas_cliente_id ON clientes_active_sessions(cliente_id);
```

#### `login_logs` - Trilha de Auditoria de Autenticação

```sql
CREATE TABLE public.login_logs (
    id SERIAL PRIMARY KEY,
    cliente_id integer REFERENCES clientes(id),
    remote_ip character varying(200) NOT NULL,
    app_version character varying(800),
    created_at timestamp with time zone DEFAULT now()
);

CREATE INDEX idx_login_logs_cliente ON login_logs(cliente_id);
CREATE INDEX idx_login_logs_created ON login_logs(created_at);
```

### Centros de Apoio (Pontos de Apoio)

#### `ponto_apoio` - Diretório de Centros de Apoio

```sql
CREATE TABLE public.ponto_apoio (
    id SERIAL PRIMARY KEY,
    status character varying(20) DEFAULT 'active'::character varying,
    
    -- Informações Básicas
    nome character varying(255) NOT NULL,
    nome_completo character varying(400),
    categoria integer,
    tipo_de_servico character varying(200),
    
    -- Localização
    endereco text,
    cep character varying(20),
    abrangencia character varying(200),
    latitude double precision,
    longitude double precision,
    geog geography(Point,4326),
    
    -- Contato
    telefone character varying(200),
    telefone2 character varying(200),
    email character varying(200),
    
    -- Horário de Funcionamento
    horario_funcionamento text,
    eh_24h boolean DEFAULT false,
    dias_funcionamento character varying(100),
    
    -- Informações Adicionais
    descricao text,
    has_whatsapp boolean DEFAULT false,
    
    -- Busca e Indexação
    indexed_at timestamp with time zone,
    indexed_document tsvector,
    
    -- Metadados
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone
);

-- Índices
CREATE INDEX idx_ponto_apoio_geog ON ponto_apoio USING gist(geog);
CREATE INDEX idx_ponto_apoio_document ON ponto_apoio USING gin(indexed_document);
CREATE INDEX idx_ponto_apoio_categoria ON ponto_apoio(categoria);
```

#### `ponto_apoio_sugestoes_v2` - Sugestões de Usuários

```sql
CREATE TABLE public.ponto_apoio_sugestoes_v2 (
    id SERIAL PRIMARY KEY,
    cliente_id integer REFERENCES clientes(id),
    categoria_id integer,
    status character varying(50) DEFAULT 'awaiting-moderation'::character varying,
    
    -- Informações Sugeridas (similar a ponto_apoio)
    nome character varying(255),
    endereco text,
    cep character varying(20),
    -- ... outros campos ...
    
    -- Processo de Revisão
    moderated_by integer,
    moderated_at timestamp with time zone,
    moderation_notes text,
    
    created_at timestamp with time zone DEFAULT now()
);
```

### Sistema de Gravação de Áudio

#### `clientes_audios_eventos` - Eventos de Gravação de Áudio

```sql
CREATE TABLE public.clientes_audios_eventos (
    id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    cliente_id integer NOT NULL REFERENCES clientes(id),
    
    -- Gerenciamento de Status
    status character varying(50) DEFAULT 'free'::character varying,
    requested_by_user boolean DEFAULT false,
    
    -- Timestamps
    created_at timestamp with time zone NOT NULL,
    ultimo_audio_criado_em timestamp with time zone,
    
    -- Estatísticas
    total_audios integer DEFAULT 0,
    total_audio_bytes bigint DEFAULT 0,
    total_audio_duration double precision DEFAULT 0
);

CREATE INDEX idx_cae_cliente_id ON clientes_audios_eventos(cliente_id);
CREATE INDEX idx_cae_status ON clientes_audios_eventos(status);
```

#### `clientes_audios` - Arquivos de Áudio Individuais

```sql
CREATE TABLE public.clientes_audios (
    id SERIAL PRIMARY KEY,
    cliente_id integer NOT NULL REFERENCES clientes(id),
    cliente_audio_evento_id uuid NOT NULL REFERENCES clientes_audios_eventos(id),
    event_sequence integer NOT NULL,
    
    -- Referência de Mídia
    media_upload_id integer NOT NULL REFERENCES media_upload(id),
    
    -- Metadados do Áudio
    waveform text, -- Array JSON
    audio_duration double precision,
    
    -- Rastreamento de Uso
    created_at timestamp with time zone NOT NULL,
    played_count integer DEFAULT 0,
    
    UNIQUE(cliente_audio_evento_id, event_sequence)
);

CREATE INDEX idx_ca_evento_id ON clientes_audios(cliente_audio_evento_id);
```

#### `media_upload` - Referências de Armazenamento de Mídia

```sql
CREATE TABLE public.media_upload (
    id SERIAL PRIMARY KEY,
    cliente_id integer NOT NULL REFERENCES clientes(id),
    
    -- Informações de Armazenamento
    s3_path text NOT NULL,
    s3_etag character varying(200),
    file_size bigint,
    file_info jsonb,
    
    -- Metadados
    intention character varying(200),
    created_at timestamp with time zone DEFAULT now()
);

CREATE INDEX idx_media_upload_cliente ON media_upload(cliente_id);
```

### Sistema de Guardiões

#### `clientes_guardioes` - Contatos de Confiança

```sql
CREATE TABLE public.clientes_guardioes (
    id SERIAL PRIMARY KEY,
    cliente_id integer NOT NULL REFERENCES clientes(id),
    
    -- Informações do Guardião
    nome character varying(200) NOT NULL,
    celular character varying(200) NOT NULL,
    celular_formatted character varying(200),
    
    -- Controle de Acesso
    token character varying(200) UNIQUE,
    status character varying(20) DEFAULT 'pending'::character varying,
    
    created_at timestamp with time zone DEFAULT now(),
    
    UNIQUE(cliente_id, celular)
);

CREATE INDEX idx_cg_cliente_id ON clientes_guardioes(cliente_id);
CREATE INDEX idx_cg_token ON clientes_guardioes(token);
```

#### `clientes_guardioes_ativacoes` - Alertas de Guardiões

```sql
CREATE TABLE public.clientes_guardioes_ativacoes (
    id SERIAL PRIMARY KEY,
    cliente_id integer NOT NULL REFERENCES clientes(id),
    
    -- Detalhes do Alerta
    alert_sent_to text, -- Array JSON
    alert_sent_to_count integer DEFAULT 0,
    
    -- Localização
    gps_lat character varying(100),
    gps_long character varying(100),
    
    created_at timestamp with time zone DEFAULT now()
);

CREATE INDEX idx_cga_cliente_id ON clientes_guardioes_ativacoes(cliente_id);
```

### Sistema de Chat

#### `chat_session` - Sessões de Chat Privado

```sql
CREATE TABLE public.chat_session (
    id SERIAL PRIMARY KEY,
    
    -- Participantes (normalizado: cliente_a_id < cliente_b_id)
    cliente_a_id integer NOT NULL REFERENCES clientes(id),
    cliente_b_id integer NOT NULL REFERENCES clientes(id),
    
    -- Informações da Última Mensagem
    last_message_at timestamp with time zone,
    last_message_by integer,
    last_message text,
    last_msg_is_media boolean DEFAULT false,
    
    -- Status de Bloqueio
    is_blocked_by_a boolean DEFAULT false,
    is_blocked_by_b boolean DEFAULT false,
    
    created_at timestamp with time zone DEFAULT now(),
    
    UNIQUE(cliente_a_id, cliente_b_id)
);

CREATE INDEX idx_chat_session_participants ON chat_session(cliente_a_id, cliente_b_id);
```

#### `chat_message` - Mensagens de Chat

```sql
CREATE TABLE public.chat_message (
    id SERIAL PRIMARY KEY,
    chat_session_id integer NOT NULL REFERENCES chat_session(id),
    
    -- Conteúdo da Mensagem
    message text,
    media_upload_id integer REFERENCES media_upload(id),
    
    -- Metadados
    created_by integer NOT NULL REFERENCES clientes(id),
    created_at timestamp with time zone DEFAULT now(),
    is_deleted boolean DEFAULT false
);

CREATE INDEX idx_chat_message_session ON chat_message(chat_session_id);
CREATE INDEX idx_chat_message_created ON chat_message(created_at);
```

#### `chat_support_message` - Chat de Suporte

```sql
CREATE TABLE public.chat_support_message (
    id SERIAL PRIMARY KEY,
    cliente_id integer NOT NULL REFERENCES clientes(id),
    
    -- Conteúdo da Mensagem
    message text NOT NULL,
    media_upload_id integer REFERENCES media_upload(id),
    
    -- Direção
    is_support_reply boolean DEFAULT false,
    
    created_at timestamp with time zone DEFAULT now()
);

CREATE INDEX idx_csm_cliente_id ON chat_support_message(cliente_id);
CREATE INDEX idx_csm_created ON chat_support_message(created_at);
```

### Quiz e Questionários

#### `questionnaires` - Configurações de Quiz

```sql
CREATE TABLE public.questionnaires (
    id SERIAL PRIMARY KEY,
    
    -- Informações Básicas
    name character varying(200),
    short_text character varying(200),
    
    -- Configuração
    condition text, -- JSON
    end_screen text, -- JSON
    penhas_start_automatically boolean DEFAULT false,
    penhas_cliente_required boolean DEFAULT false,
    
    -- Metadados
    is_test boolean DEFAULT false,
    created_on timestamp with time zone DEFAULT now(),
    modified_on timestamp with time zone DEFAULT now()
);
```

#### `quiz_config` - Configuração de Perguntas

```sql
CREATE TABLE public.quiz_config (
    id SERIAL PRIMARY KEY,
    questionnaire_id integer NOT NULL REFERENCES questionnaires(id),
    
    -- Definição da Pergunta
    code character varying(100) NOT NULL,
    question text NOT NULL,
    type character varying(100) NOT NULL,
    sort integer DEFAULT 0,
    
    -- Opções
    options jsonb DEFAULT '[]'::jsonb,
    text_validation character varying(200),
    
    -- Configuração
    yesnogroup character varying(100),
    intro text,
    relevance text,
    is_required boolean DEFAULT true,
    
    UNIQUE(questionnaire_id, code)
);

CREATE INDEX idx_quiz_config_questionnaire ON quiz_config(questionnaire_id);
```

#### `clientes_quiz_session` - Sessões de Quiz de Usuários

```sql
CREATE TABLE public.clientes_quiz_session (
    id SERIAL PRIMARY KEY,
    cliente_id integer NOT NULL REFERENCES clientes(id),
    questionnaire_id integer NOT NULL REFERENCES questionnaires(id),
    
    -- Progresso
    finished_at timestamp with time zone,
    current_question_code character varying(100),
    
    -- Metadados
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone
);

CREATE INDEX idx_cqs_cliente ON clientes_quiz_session(cliente_id);
CREATE INDEX idx_cqs_questionnaire ON clientes_quiz_session(questionnaire_id);
```

### Notícias e Conteúdo

#### `noticias` - Artigos de Notícias

```sql
CREATE TABLE public.noticias (
    id SERIAL PRIMARY KEY,
    status character varying(20) DEFAULT 'draft'::character varying,
    
    -- Conteúdo
    title character varying(800) NOT NULL,
    description text,
    fonte_titulo character varying(800),
    fonte_url character varying(800),
    
    -- Exibição
    display_created_time timestamp with time zone,
    published boolean DEFAULT false,
    
    -- Busca
    indexed_tsv tsvector,
    tags_index character varying(200),
    
    -- Metadados
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone
);

CREATE INDEX idx_noticias_tsv ON noticias USING gin(indexed_tsv);
CREATE INDEX idx_noticias_published ON noticias(published);
```

### Tabelas do Sistema

#### `minion_jobs` - Fila de Jobs em Background

```sql
CREATE TABLE public.minion_jobs (
    id BIGSERIAL PRIMARY KEY,
    args jsonb NOT NULL,
    attempts integer DEFAULT 1 NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    delayed timestamp with time zone DEFAULT now() NOT NULL,
    finished timestamp with time zone,
    priority integer DEFAULT 0 NOT NULL,
    queue text DEFAULT 'default'::text NOT NULL,
    result jsonb,
    retried timestamp with time zone,
    retries integer DEFAULT 0 NOT NULL,
    started timestamp with time zone,
    state minion_state DEFAULT 'inactive'::minion_state NOT NULL,
    task text NOT NULL,
    worker bigint
);

CREATE INDEX minion_jobs_state_priority_id_idx ON minion_jobs(state, priority DESC, id);
```

## Funções do Banco de Dados

### Funções Geoespaciais

```sql
-- Atualiza coluna geography quando lat/lng mudam
CREATE FUNCTION ft_ponto_apoio_geo_update() RETURNS trigger AS $$
BEGIN
    UPDATE ponto_apoio
    SET geog = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography
    WHERE id = NEW.id;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tgr_ponto_apoio_geo_update
AFTER INSERT OR UPDATE OF latitude, longitude ON ponto_apoio
FOR EACH ROW EXECUTE FUNCTION ft_ponto_apoio_geo_update();
```

### Funções de Auditoria

```sql
-- Rastreia atividade do usuário
CREATE FUNCTION f_tgr_clientes_app_activity_log() RETURNS trigger AS $$
BEGIN
    INSERT INTO clientes_app_activity_log (cliente_id, created_at)
    VALUES(NEW.cliente_id, COALESCE(NEW.last_activity, now()));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

## Relacionamentos Principais

1. **Usuário → Sessões**: Um-para-muitos (sessões ativas)
2. **Usuário → Guardiões**: Um-para-muitos (contatos de confiança)
3. **Usuário → Eventos de Áudio**: Um-para-muitos (gravações)
4. **Usuário → Sessões de Chat**: Muitos-para-muitos (através de chat_session)
5. **Evento de Áudio → Arquivos de Áudio**: Um-para-muitos (gravações sequenciais)
6. **Centro de Apoio → Categorias**: Muitos-para-um
7. **Usuário → Sessões de Quiz**: Um-para-muitos

## Considerações de Privacidade de Dados

1. **Proteção de PII**:
   - CPF armazenado como hash com prefixo
   - Números de telefone podem ser criptografados
   - Dados de localização opcionais

2. **Suporte à Exclusão**:
   - Soft delete com `deleted_at`
   - Exclusão agendada com `perform_delete_at`
   - Remoção completa de dados via job em background

3. **Modo Anônimo**:
   - Flag `modo_anonimo_ativo`
   - Coleta limitada de dados quando ativo
   - Tratamento especial em consultas

## Índices de Performance

### Índices Mais Importantes

1. **Geoespacial**: `idx_ponto_apoio_geog` - Para buscas por proximidade
2. **Full-text**: `idx_ponto_apoio_document` - Para buscas por palavra-chave
3. **Chaves Estrangeiras**: Todas as colunas FK são indexadas
4. **Timestamps**: Colunas created/updated para ordenação
5. **Campos de Status**: Para filtrar registros ativos