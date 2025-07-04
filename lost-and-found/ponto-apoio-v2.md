# Regras para Preenchimento do CSV - Dados de Pontos de Apoio

## Definições de Colunas e Regras de Validação

### Informações Básicas
- **id_estabelecimento**: Texto livre (identificador do estabelecimento) - **OPCIONAL**
- **projeto**: **OBRIGATÓRIO** - Deve ser um dos valores:
  - `mapa_delegacia`
  - `penhas`
  - `mapa_delegacias, penhas`
- **fonte**: Texto livre (fonte dos dados) - **OPCIONAL**
- **nome**: Texto livre (nome do estabelecimento) - **OPCIONAL**
- **sigla**: Texto que será convertido para MAIÚSCULO - **OPCIONAL**
- **descricao**: Texto livre (descrição) - **OPCIONAL**

### Campos de Classificação
- **natureza**: **OBRIGATÓRIO** - Deve ser um dos valores:
  - `público`
  - `privado_coletivo`
  - `privado_ong`
  - `ong`
  - ⚠️ **ATENÇÃO**: Se colocar `tirar`, a linha inteira será ignorada na importação

- **categoria**: **OBRIGATÓRIO** - Deve ser um dos valores (não diferencia maiúscula/minúscula):
  - `casa da mulher brasileira`
  - `posto de atendimento em delegacia comum`
  - `delegacia comum`
  - `delegacia da mulher`
  - `assistência social`
  - `centro de referência da mulher`
  - `ouvidoria`
  - `saúde`
  - `segurança pública`
  - `serviço online`
  - `sociedade civil organizada`
  - `jurídico`
  - `direitos humanos`

- **abrangencia**: **OBRIGATÓRIO** - Deve ser um dos valores:
  - `Local`
  - `Regional`
  - `Regional?`
  - `Nacional`

### Informações de Endereço
- **tipo_logradouro**: **OPCIONAL** - Deve ser um dos valores:
  - `Rodovia`, `Rua`, `Avenida`, `Estrada`, `Alameda`, `Viela`, `Via`, `Travessa`, `Quadra`, `Praça`, `Área`, `Conjunto`, `Villa`, `Vila`, `Sítio`, `Área Especial`, `Trecho`, `Setor`, `Entrequadra`
- **nome_logradouro**: Texto livre (nome da rua) - **OPCIONAL**
- **numero**: Apenas números, ou deixe vazio para "s/n" (sem número) - **OPCIONAL**
- **numero_sem_numero**: Será preenchido automaticamente (não preencher manualmente)
- **complemento**: Texto livre (apartamento, sala, etc.) - **OPCIONAL**
- **bairro**: Texto livre (bairro) - **OPCIONAL**
- **municipio**: Texto livre (cidade) - **OPCIONAL**
- **cod_ibge**: Apenas números (código IBGE da cidade) - **OPCIONAL**
- **uf**: Texto que será convertido para MAIÚSCULO (código do estado) - **OPCIONAL**
- **cep**: Formato: `12345-678` ou `12345678` (CEP brasileiro) - **OPCIONAL**

### Informações de Contato
- **ddd**: Apenas números (código de área) - **OPCIONAL**
- **telefone1**: Apenas números, aceita formato `1234-5678` ou `12345678` - **OPCIONAL**
- **ramal1**: Apenas números (ramal) - **OPCIONAL**
- **telefone2**: Apenas números, aceita formato `1234-5678` ou `12345678` - **OPCIONAL**
- **ramal2**: Apenas números (ramal) - **OPCIONAL**
- **eh_whatsapp**: `sim` ou `não` (se o telefone tem WhatsApp) - **OPCIONAL**
- **email**: Formato de email válido (exemplo@dominio.com) - **OPCIONAL**

### Horário de Funcionamento
- **eh_24h**: `sim` ou `não` (funcionamento 24 horas) - **OBRIGATÓRIO**
- **horario_inicio**: Formato de hora `HH:MM` (horário de abertura) - **OPCIONAL**
- **horario_fim**: Formato de hora `HH:MM` (horário de fechamento) - **OPCIONAL**
- **dias_funcionamento**: **OPCIONAL** - Deve ser um dos valores:
  - `Dias úteis`
  - `Fim de semana`
  - `Dias úteis com plantão aos fins de semana`
  - `Todos os dias`
  - `Segunda a sábado`
  - `Segunda a quinta`
  - `Terça a quinta`
  - `Quintas-feiras`

### Tipo de Atendimento
- **eh_presencial**: `sim` ou `não` (atendimento presencial) - **OPCIONAL**
- **eh_online**: `sim` ou `não` (atendimento online) - **OPCIONAL**

### Informações sobre Pandemia
- **funcionamento_pandemia**: `sim` ou `não` (funcionou durante a pandemia) - **OPCIONAL**
- **observacao_pandemia**: Texto livre (observações sobre pandemia) - **OPCIONAL**

### Coordenadas de Localização
- **latitude**: Número decimal com vírgula como separador (ex: `-23,5505`) - **OPCIONAL**
- **longitude**: Número decimal com vírgula como separador (ex: `-46,6333`) - **OPCIONAL**

### Observações Adicionais
- **observacao**: Texto livre (observações gerais) - **OPCIONAL**

## Observações Importantes

### Formatação
1. **Maiúsculas/Minúsculas**: A maioria dos campos de lista não diferencia maiúsculas de minúsculas, mas serão convertidos para formatos específicos
2. **Campos Vazios**: Campos vazios são permitidos para a maioria das colunas
3. **Formatos Numéricos**: Use apenas dígitos para campos numéricos, vírgulas para separadores decimais
4. **Campos Booleanos**: Use `sim` (sim) ou `não` (não) para perguntas de sim/não
5. **Espaços**: Espaços no início e fim dos campos serão removidos automaticamente

### Campos Obrigatórios vs Opcionais
**OBRIGATÓRIOS:**
- `projeto`
- `natureza`
- `categoria`
- `abrangencia`
- `eh_24h`

**OPCIONAIS:**
- Todos os demais campos

### Regras Especiais
- **Regra Especial**: Se o campo `natureza` contiver `tirar`, a linha inteira será ignorada durante a importação
- **Número sem número**: O campo `numero_sem_numero` é preenchido automaticamente baseado no campo `numero`
- **WhatsApp**: O campo `eh_whatsapp` será convertido automaticamente para 0 ou 1

## Erros Comuns de Validação para Evitar

- ❌ Formato de CEP inválido (deve ter 8 dígitos com traço opcional)
- ❌ Formato de email inválido
- ❌ Formato de hora inválido (deve ser HH:MM)
- ❌ Usar valores que não estão nas listas predefinidas
- ❌ Misturar separadores decimais (use vírgula, não ponto)
- ❌ Incluir caracteres não numéricos em campos de número
- ❌ Usar `sim/não` com acentos diferentes (use exatamente `sim` ou `não`)

## Exemplo de Preenchimento Correto

```
projeto: penhas
natureza: público
categoria: delegacia da mulher
abrangencia: Local
eh_24h: não
horario_inicio: 08:00
horario_fim: 18:00
dias_funcionamento: Dias úteis
eh_whatsapp: sim
telefone1: 1133334444
cep: 01234-567
latitude: -23,5505
longitude: -46,6333
```