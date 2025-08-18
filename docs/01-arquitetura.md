# Visão Geral da Arquitetura

O backend PenhaS é uma API RESTful construída com Mojolicious (Perl) seguindo padrões de arquitetura MVC. Ele fornece serviços para o aplicativo móvel de apoio a mulheres em situação de violência.

## Arquitetura do Sistema

```
┌─────────────────┐     ┌─────────────────┐
│  Apps Móveis    │     │  Interface Web  │
│  (iOS/Android)  │     │    (Admin)      │
└────────┬────────┘     └────────┬────────┘
         │                       │
         └───────────┬───────────┘
                     │ HTTPS
              ┌──────┴──────┐
              │   Nginx     │
              │(Load Balancer)
              └──────┬──────┘
                     │
         ┌───────────┴───────────┐
         │                       │
    ┌────┴────┐            ┌────┴────┐
    │  API    │            │  API    │
    │Instância 1│   ....   │Instância N│
    └────┬────┘            └────┬────┘
         │                       │
         └───────────┬───────────┘
                     │
    ┌────────────────┴────────────────┐
    │                                 │
┌───┴───┐  ┌────────┐  ┌─────────┐  ┌┴──────┐
│ Redis │  │PostgreSQL│ │   S3    │  │Minion │
│ Cache │  │ + PostGIS│ │ Storage │  │Workers│
└───────┘  └────────┘  └─────────┘  └───────┘
```

## Componentes Principais

### Servidor API
- **Framework**: API REST baseada em Mojolicious
- **Arquitetura**: Stateless, escalável horizontalmente
- **Protocolo**: HTTPS com payloads JSON
- **Autenticação**: Tokens JWT

### Camada de Banco de Dados
- **Banco Principal**: PostgreSQL 13+ com extensão PostGIS
- **Propósito**: Dados de usuários, centros de apoio, mensagens de chat, metadados de áudio
- **Recursos**: Consultas geoespaciais, busca full-text, suporte JSONB

### Camada de Cache
- **Tecnologia**: Redis 5+
- **Propósito**: Gerenciamento de sessões, dados temporários, rate limiting
- **Estratégia de TTL**: Varia por tipo de dado (5 min para sessões, 24h para geocodificação)

### Processamento em Background
- **Sistema de Fila**: Minion (plugin Mojolicious)
- **Workers**: Processos separados para tarefas assíncronas
- **Jobs**: Exclusão de usuários, notificações, indexação, envio de SMS

### Camada de Armazenamento
- **Object Storage**: Compatível com S3 (AWS S3, Backblaze B2 ou MinIO)
- **Conteúdo**: Gravações de áudio, fotos de perfil, uploads de mídia
- **Acesso**: URLs pré-assinadas para acesso direto seguro

### Serviços Externos
- **Notificações Push**: Amazon SNS
- **Geocodificação**: Here.com (principal) ou Google Maps (fallback)
- **SMS**: Amazon SNS
- **Email**: Servidor SMTP

## Princípios de Design

### 1. Arquitetura Stateless
- Sem armazenamento de sessão no servidor
- Todo estado no banco de dados ou Redis
- Permite escalabilidade horizontal

### 2. Segurança em Primeiro Lugar
- Todos os dados criptografados em trânsito (HTTPS)
- Dados sensíveis hasheados (senhas, CPF)
- Rate limiting em múltiplos níveis
- Validação de entrada em todos os endpoints

### 3. Privacidade por Design
- Coleta mínima de dados
- Capacidade de exclusão de dados (conformidade LGPD)
- Suporte a modo anônimo
- Armazenamento criptografado de áudio

### 4. Tolerância a Falhas
- Degradação graciosa para serviços externos
- Lógica de retry para operações críticas
- Circuit breakers para APIs externas
- Mecanismos de retry para jobs em background

### 5. Otimização de Performance
- Otimização de consultas ao banco de dados
- Cache Redis para operações frequentes
- Carregamento lazy de dados relacionados
- Paginação em todos os endpoints de listagem

## Fluxo de Requisição

1. **Requisição do Cliente**
   - App móvel envia requisição HTTPS com token JWT
   - Nginx termina SSL e balanceia carga

2. **Autenticação**
   - Token JWT validado
   - Sessão verificada no cache Redis
   - Contexto do usuário carregado

3. **Processamento da Requisição**
   - Rota correspondida ao controlador
   - Validação de entrada
   - Execução da lógica de negócio
   - Consultas ao banco (com cache)

4. **Resposta**
   - Resposta JSON formatada
   - Código de status HTTP definido
   - Resposta enviada ao cliente

5. **Pós-Processamento**
   - Jobs em background enfileirados se necessário
   - Logs escritos
   - Métricas atualizadas

## Considerações de Escalabilidade

### Escalabilidade Horizontal
- Servidores API stateless podem ser adicionados/removidos dinamicamente
- Load balancer distribui requisições
- Armazenamento compartilhado via S3
- Armazenamento centralizado de sessões no Redis

### Escalabilidade do Banco de Dados
- Réplicas de leitura para relatórios
- Pool de conexões
- Otimização de consultas e indexação
- Particionamento para tabelas grandes (futuro)

### Estratégia de Cache
- Redis para dados quentes
- CDN para assets estáticos
- Cache de resultados de consultas ao banco
- Cache de valores computados

## Arquitetura de Segurança

### Segurança de Rede
- Comunicação apenas HTTPS
- Regras de firewall limitando acesso
- Rede privada para serviços internos
- Acesso VPN para administração

### Segurança da Aplicação
- Autenticação JWT
- Controle de acesso baseado em papéis
- Validação e sanitização de entrada
- Prevenção de SQL injection via ORMs

### Segurança de Dados
- Criptografia em repouso (banco de dados)
- Criptografia em trânsito (HTTPS)
- Hashing seguro de senhas
- Proteção de dados PII

## Monitoramento e Observabilidade

### Health Checks
- Endpoint `/health` para load balancer
- Verificações de conectividade do banco
- Verificações de disponibilidade do Redis
- Verificação de acessibilidade do S3

### Logging
- Logs JSON estruturados
- Agregação de logs
- Rastreamento de erros
- Trilhas de auditoria para operações sensíveis

### Métricas
- Tempos de resposta da API
- Taxas de erro por endpoint
- Performance de consultas ao banco
- Profundidade da fila de jobs em background

## Recuperação de Desastres

### Estratégia de Backup
- Backups diários do banco de dados
- Capacidade de recuperação point-in-time
- Versionamento S3 para arquivos de mídia
- Backups de configuração

### Alta Disponibilidade
- Múltiplas instâncias da API
- Replicação do banco de dados
- Persistência do Redis
- Deploy multi-AZ (cloud)

### Procedimentos de Recuperação
- Health checks automatizados
- Substituição automática de instâncias
- Procedimentos de failover do banco
- Playbooks de resposta a incidentes