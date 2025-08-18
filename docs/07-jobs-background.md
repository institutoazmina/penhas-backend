# Jobs em Background

## Visão Geral

O PenhaS usa o Minion, um plugin do Mojolicious, para processamento de jobs em background. Isso permite que tarefas demoradas ou que consomem muitos recursos sejam processadas de forma assíncrona sem bloquear a API principal.

## Arquitetura do Minion

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   API       │────▶│  PostgreSQL  │◀────│   Minion    │
│  Process    │     │  Fila de Jobs│     │   Workers   │
└─────────────┘     └──────────────┘     └─────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │ minion_jobs  │
                    │    tabela    │
                    └──────────────┘
```

## Configuração de Jobs

### Inicialização de Workers

```bash
# Iniciar um worker Minion
./script/penhas-api minion worker

# Iniciar múltiplos workers
./script/penhas-api minion worker -j 4

# Iniciar worker para filas específicas
./script/penhas-api minion worker -q critical -q default
```

### Registro de Jobs

Jobs são registrados em `lib/Penhas/Minion/Tasks.pm`:

```perl
sub setup {
    my $c = shift;
    
    my $minion = $c->app->minion;
    
    # Registrar todas as tarefas
    $minion->add_task(delete_user => \&delete_user);
    $minion->add_task(new_notification => \&new_notification);
    $minion->add_task(news_indexer => \&news_indexer);
    $minion->add_task(cep_updater => \&cep_updater);
    $minion->add_task(send_sms => \&send_sms);
    $minion->add_task(delete_audio => \&delete_audio);
}
```

## Tipos de Jobs

### 1. DeleteUser

Exclusão completa de dados do usuário para conformidade LGPD.

**Arquivo:** `lib/Penhas/Minion/Tasks/DeleteUser.pm`

**Propósito:** Excluir permanentemente todos os dados do usuário quando solicitado.

**Processo:**
```perl
sub delete_user {
    my ($job, $user_id) = @_;
    
    # 1. Excluir arquivos de áudio do S3
    # 2. Excluir mensagens de chat
    # 3. Excluir relacionamentos de guardiões
    # 4. Excluir sessões de quiz
    # 5. Excluir uploads de mídia
    # 6. Excluir registro do usuário
    # 7. Registrar conclusão
}
```

**Enfileiramento:**
```perl
$minion->enqueue(
    'delete_user',
    [$user_id],
    {
        attempts => 5,
        delay => 60,  # Aguardar 60 segundos
        priority => 5
    }
);
```

### 2. NewNotification

Enviar notificações push via Amazon SNS.

**Arquivo:** `lib/Penhas/Minion/Tasks/NewNotification.pm`

**Propósito:** Enviar notificações push para dispositivos móveis.

**Recursos:**
- Processamento em lote para eficiência
- Formatação específica por plataforma (iOS/Android)
- Rastreamento de entrega
- Retry automático em caso de falha

**Processo:**
```perl
sub new_notification {
    my ($job, $notification_id) = @_;
    
    # 1. Carregar detalhes da notificação
    # 2. Obter tokens de dispositivo dos destinatários
    # 3. Formatar mensagem por plataforma
    # 4. Enviar via SNS
    # 5. Rastrear status de entrega
}
```

**Formato da Mensagem:**
```perl
# iOS
{
    "aps": {
        "alert": {
            "title": "PenhaS",
            "body": "Você tem uma nova mensagem"
        },
        "badge": 1,
        "sound": "default"
    },
    "custom_data": { ... }
}

# Android
{
    "data": {
        "title": "PenhaS",
        "body": "Você tem uma nova mensagem",
        "custom_data": { ... }
    }
}
```

### 3. NewsIndexer

Atualizar índices de busca full-text para artigos de notícias.

**Arquivo:** `lib/Penhas/Minion/Tasks/NewsIndexer.pm`

**Propósito:** Processar e indexar conteúdo de notícias para busca.

**Processo:**
```perl
sub news_indexer {
    my ($job, $news_id) = @_;
    
    # 1. Carregar artigo de notícia
    # 2. Extrair conteúdo de texto
    # 3. Remover tags HTML
    # 4. Normalizar texto
    # 5. Gerar TSVector
    # 6. Atualizar índice de busca
    # 7. Atualizar índice de tags
}
```

**Processamento de Texto:**
```perl
# Remoção de HTML
$text =~ s/<[^>]+>//g;

# Normalizar espaços
$text =~ s/\s+/ /g;

# Gerar documento de busca
$tsv = to_tsvector('portuguese', $text);
```

### 4. CepUpdater

Atualizar dados de localização do usuário a partir de códigos postais.

**Arquivo:** `lib/Penhas/Minion/Tasks/CepUpdater.pm`

**Propósito:** Geocodificar códigos postais brasileiros (CEP) para coordenadas.

**Processo:**
```perl
sub cep_updater {
    my ($job, $user_id) = @_;
    
    # 1. Obter CEP do usuário
    # 2. Verificar cache
    # 3. Consultar API Postmon
    # 4. Fallback para Correios
    # 5. Atualizar localização do usuário
    # 6. Cachear resultado
}
```

**Integração com API:**
```perl
# Primário: Postmon
GET https://api.postmon.com.br/v1/cep/01310100

# Fallback: Scraper Correios
WWW::Correios::CEP->new->find($cep);
```

### 5. SendSMS

Enviar mensagens SMS para alertas de guardiões.

**Arquivo:** `lib/Penhas/Minion/Tasks/SendSMS.pm`

**Propósito:** Enviar alertas SMS para guardiões.

**Processo:**
```perl
sub send_sms {
    my ($job, $args) = @_;
    
    my $phone = $args->{phone};
    my $message = $args->{message};
    
    # 1. Formatar número de telefone
    # 2. Validar número
    # 3. Enviar via SNS
    # 4. Rastrear entrega
    # 5. Tratar erros
}
```

**Template de Mensagem:**
```perl
"[PenhaS] $user_name está em perigo! 
Localização: $location_url
Enviado às: $time"
```

### 6. DeleteAudio

Remover arquivos de áudio do armazenamento S3.

**Arquivo:** `lib/Penhas/Minion/Tasks/DeleteAudio.pm`

**Propósito:** Limpar arquivos de áudio quando eventos são excluídos.

**Processo:**
```perl
sub delete_audio {
    my ($job, $audio_event_id) = @_;
    
    # 1. Obter todos os arquivos de áudio do evento
    # 2. Excluir do S3
    # 3. Excluir registros do banco
    # 4. Atualizar estatísticas do evento
}
```

### 7. NewsDisplayIndexer

Processar notícias para otimização de exibição.

**Arquivo:** `lib/Penhas/Minion/Tasks/NewsDisplayIndexer.pm`

**Propósito:** Pré-processar conteúdo de notícias para exibição eficiente.

**Processo:**
- Gerar resumos
- Processar imagens
- Criar miniaturas
- Cachear conteúdo renderizado

## Gerenciamento de Jobs

### Enfileirando Jobs

```perl
# Enfileiramento básico
my $job_id = $minion->enqueue('task_name', [@args]);

# Com opções
my $job_id = $minion->enqueue(
    'task_name',
    [@args],
    {
        attempts => 3,      # Máximo de tentativas
        delay => 60,        # Atraso em segundos
        priority => 5,      # Maior = mais importante
        queue => 'critical' # Fila customizada
    }
);
```

### Opções de Jobs

| Opção | Descrição | Padrão |
|-------|-----------|---------|
| `attempts` | Máximo de tentativas de retry | 1 |
| `delay` | Segundos a aguardar antes de processar | 0 |
| `priority` | Prioridade do job (0-10) | 0 |
| `queue` | Nome da fila | 'default' |
| `expire` | Segundos antes do job expirar | 172800 (2 dias) |

### Estados de Jobs

```perl
# Estados de jobs em minion_jobs.state
'inactive'  # Aguardando processamento
'active'    # Sendo processado
'finished'  # Concluído com sucesso
'failed'    # Falhou após todas as tentativas
```

### Monitorando Jobs

```bash
# Monitoramento via linha de comando
./script/penhas-api minion job -s        # Estatísticas
./script/penhas-api minion job -l 10     # Listar 10 jobs
./script/penhas-api minion job -f        # Listar jobs falhados
./script/penhas-api minion job -R        # Retentar jobs falhados

# Remover jobs antigos
./script/penhas-api minion job -r        # Remover jobs finalizados
```

### Interface Admin do Minion

Acesse a interface web em `/minion` (requer autenticação):

```perl
# Configuração de rotas
my $minion_admin = $r->under('/minion')->to(
    cb => sub {
        my $c = shift;
        return 1 if $c->req->url->to_abs->password eq $ENV{MINION_ADMIN_SECRET};
        $c->render(text => 'Unauthorized', status => 401);
        return 0;
    }
);
$minion_admin->minion;
```

## Tratamento de Erros

### Lógica de Retry

```perl
sub task_with_retry {
    my ($job, @args) = @_;
    
    eval {
        # Lógica da tarefa aqui
    };
    
    if ($@) {
        if ($job->info->{attempts} < 3) {
            # Retry com backoff exponencial
            return $job->retry({delay => 2 ** $job->info->{attempts}});
        }
        # Falha final
        $job->fail($@);
    }
}
```

### Notificações de Erro

```perl
# Registrar erros
$job->app->log->error("Tarefa falhou: $error");

# Enviar alerta para falhas críticas
if ($job->info->{queue} eq 'critical') {
    send_admin_alert($error);
}
```

## Otimização de Performance

### Processamento em Lote

```perl
# Processar múltiplos itens em um job
sub batch_processor {
    my ($job, $item_ids) = @_;
    
    my $batch_size = 100;
    
    while (my @batch = splice @$item_ids, 0, $batch_size) {
        process_batch(\@batch);
        
        # Atualizar progresso
        $job->note(
            processed => $job->info->{notes}{processed} + @batch
        );
    }
}
```

### Gerenciamento de Recursos

```perl
# Processamento eficiente de memória
sub process_large_dataset {
    my ($job, $query_params) = @_;
    
    my $rs = $schema->resultset('LargeTable')->search(
        $query_params,
        { rows => 1000 }  # Processar em chunks
    );
    
    while (my @chunk = $rs->next) {
        process_chunk(\@chunk);
        
        # Liberar memória
        undef @chunk;
    }
}
```

## Jobs Agendados

### Agendamento Tipo Cron

```perl
# Na inicialização da aplicação
$app->minion->add_task(hourly_cleanup => sub {
    my ($job) = @_;
    # Lógica de limpeza
});

# Agendar job recorrente
$app->minion->enqueue(
    'hourly_cleanup',
    [],
    {
        delay => 3600,  # 1 hora
        attempts => 1
    }
);
```

### Tarefas Agendadas Comuns

1. **Por Hora**
   - Limpar sessões expiradas
   - Processar notificações pendentes
   - Atualizar índices de busca

2. **Diariamente**
   - Gerar relatórios
   - Limpar logs antigos
   - Atualizar dados de localização

3. **Semanalmente**
   - Reindexação completa de busca
   - Manutenção do banco de dados
   - Verificação de backups

## Melhores Práticas

### 1. Idempotência

Tornar jobs idempotentes - seguros para retentar:

```perl
sub idempotent_task {
    my ($job, $user_id) = @_;
    
    # Verificar se já foi processado
    return if already_processed($user_id);
    
    # Processar
    process_user($user_id);
    
    # Marcar como processado
    mark_processed($user_id);
}
```

### 2. Rastreamento de Progresso

```perl
sub long_running_task {
    my ($job, $total_items) = @_;
    
    for (my $i = 0; $i < $total_items; $i++) {
        process_item($i);
        
        # Atualizar progresso
        $job->note(
            progress => int(($i / $total_items) * 100)
        );
    }
}
```

### 3. Limpeza de Recursos

```perl
sub task_with_cleanup {
    my ($job, @args) = @_;
    
    # Criar recursos temporários
    my $temp_file = create_temp_file();
    
    # Garantir limpeza
    scope_guard {
        unlink $temp_file;
    };
    
    # Processar
    process_with_file($temp_file);
}
```

## Solução de Problemas

### Problemas Comuns

1. **Jobs travados no estado 'active'**
   - Worker travou
   - Job demorando demais
   - Solução: Definir timeout do job

2. **Alto uso de memória**
   - Conjuntos de resultados grandes
   - Vazamentos de memória
   - Solução: Processar em lotes

3. **Jobs não processando**
   - Sem workers rodando
   - Incompatibilidade de fila
   - Solução: Verificar status do worker

### Comandos de Debug

```bash
# Verificar status do worker
ps aux | grep "minion worker"

# Ver detalhes do job
./script/penhas-api minion job -v <job_id>

# Execução manual de job
./script/penhas-api minion job -f <job_id>
```