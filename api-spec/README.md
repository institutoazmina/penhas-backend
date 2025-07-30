# PenhaS API Specification

Este diretório contém a especificação OpenAPI 3.0 para a API do PenhaS - uma plataforma de apoio e proteção para mulheres em situação de violência.

## Arquivos

- `openapi.yaml` - Especificação completa da API em formato OpenAPI 3.0

## Sobre a API

A API PenhaS é um serviço RESTful que fornece endpoints para o aplicativo móvel PenhaS. A API oferece funcionalidades para:

### Funcionalidades Principais

- **Autenticação**: Registro, login, logout e reset de senha
- **Perfil do Usuário**: Gerenciamento completo do perfil, incluindo modos anônimo e camuflado
- **Pontos de Apoio**: Localização e informações de centros de apoio próximos
- **Timeline/Feed**: Sistema de posts e interações entre usuários
- **Chat**: Mensagens privadas entre usuários
- **Áudio**: Upload e gerenciamento de gravações de áudio para evidências
- **Busca**: Localização de outros usuários por nome ou habilidades

### Autenticação

A API utiliza **JWT (JSON Web Tokens)** para autenticação. O token deve ser incluído no header `x-api-key` para endpoints que requerem autenticação.

```http
x-api-key: eyJ0eXAiOiJKV1QiLCJhbGc...
```

### Endpoints Principais

#### Públicos (sem autenticação)
- `POST /signup` - Criar nova conta
- `POST /login` - Fazer login
- `POST /reset-password/request-new` - Solicitar reset de senha
- `POST /reset-password/write-new` - Definir nova senha
- `GET /pontos-de-apoio` - Listar pontos de apoio
- `GET /pontos-de-apoio/{id}` - Detalhes de um ponto de apoio
- `GET /geocode` - Geocodificar endereços

#### Privados (requerem autenticação)
- `GET /me` - Perfil do usuário
- `PUT /me` - Atualizar perfil
- `DELETE /me` - Excluir conta
- `GET /timeline` - Feed de posts
- `POST /me/tweets` - Criar post
- `GET /me/chats` - Listar conversas
- `POST /me/chats-messages` - Enviar mensagem
- `GET /search-users` - Buscar usuários
- `POST /me/audios` - Upload de áudio

### Formatos de Resposta

#### Sucesso
```json
{
  "data": { ... },
  "status": "success"
}
```

#### Erro
```json
{
  "error": "codigo_erro",
  "message": "Mensagem de erro legível",
  "field": "campo_opcional",
  "status": 400
}
```

### Códigos de Status HTTP

- `200` - Sucesso
- `400` - Bad Request (parâmetros inválidos)
- `401` - Unauthorized (token ausente/inválido)
- `403` - Forbidden (acesso negado)
- `404` - Not Found (recurso não encontrado)
- `500` - Internal Server Error

## Usando a Especificação

### Visualização

Você pode visualizar a especificação usando ferramentas como:

- **Swagger UI**: Interface web interativa
- **Redoc**: Documentação estática elegante
- **Insomnia/Postman**: Para testes de API

### Swagger UI Local

Para visualizar com Swagger UI:

```bash
# Instalar swagger-ui-serve globalmente
npm install -g swagger-ui-serve

# Servir a especificação
swagger-ui-serve openapi.yaml
```

### Geração de Código

A especificação OpenAPI pode ser usada para gerar código cliente em várias linguagens:

```bash
# Exemplo com openapi-generator
openapi-generator generate -i openapi.yaml -g dart -o client-dart/
openapi-generator generate -i openapi.yaml -g javascript -o client-js/
```

## Desenvolvimento

### Estrutura da Especificação

A especificação está organizada nas seguintes seções:

1. **Info**: Metadados da API
2. **Servers**: URLs dos servidores (produção/desenvolvimento)
3. **Security**: Esquemas de autenticação
4. **Components**: 
   - **Schemas**: Modelos de dados reutilizáveis
   - **Responses**: Respostas padrão reutilizáveis
   - **SecuritySchemes**: Definições de autenticação
5. **Paths**: Definição de todos os endpoints
6. **Tags**: Agrupamento lógico dos endpoints

### Schemas Principais

- **UserProfile**: Perfil completo do usuário
- **SupportPoint**: Ponto de apoio/centro de atendimento
- **Tweet**: Post no timeline
- **ChatMessage**: Mensagem de chat
- **Badge**: Distintivo/conquista do usuário
- **AudioEntity**: Gravação de áudio

### Atualizações

Ao fazer alterações na API backend:

1. Atualize a especificação OpenAPI correspondente
2. Verifique se os schemas estão consistentes com os modelos de dados
3. Teste os endpoints usando a especificação
4. Atualize a versão da API se necessário

### Validação

Para validar a especificação:

```bash
# Instalar swagger-codegen-cli
npm install -g swagger-codegen-cli

# Validar especificação
swagger-codegen-cli validate -i openapi.yaml
```

## Recursos Adicionais

- [OpenAPI Specification](https://swagger.io/specification/)
- [Swagger Tools](https://swagger.io/tools/)
- [API Design Guide](https://swagger.io/resources/articles/best-practices-in-api-design/)

## Contribuição

Ao contribuir com melhorias na API:

1. Mantenha a especificação atualizada
2. Siga as convenções REST
3. Documente novos endpoints completamente
4. Inclua exemplos de request/response
5. Atualize os schemas quando necessário

## Contato

Para dúvidas sobre a API ou especificação, consulte a documentação do projeto PenhaS ou entre em contato com a equipe de desenvolvimento.