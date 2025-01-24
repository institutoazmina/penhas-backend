## Integrações Externas

Este documento descreve as integrações externas utilizadas na API do PenhaS,
as variáveis de ambiente necessárias para seu funcionamento e os endpoints que as utilizam.

**1. Google Maps Geocoding API**

* **Objetivo:** Utilizada para geocodificação (endereço para latitude/longitude) e
geocodificação reversa (latitude/longitude para endereço).
* **Variáveis de Ambiente:**
    * `GOOGLE_GEOCODE_API`: Sua chave da API do Google Maps Geocoding.
* **Endpoints:**
    * `/geocode`: Endpoint público, acessível a qualquer pessoa.
    * `/me/geocode`: Endpoint privado, acessível a usuários logados.

> Não é obrigatória, caso configure a HERE Maps

**2. HERE Maps Geocoding API**

* **Objetivo:** Utilizada para geocodificação (endereço para latitude/longitude) e
geocodificação reversa (latitude/longitude para endereço).
* **Variáveis de Ambiente:**
    * `GEOCODE_USE_HERE_API`: Define qual API de geocodificação será utilizada (1 para HERE Maps,
caso contrário, Google Maps).
    * `GEOCODE_HERE_APP_ID`: Seu ID de aplicativo do HERE Maps.
    * `GEOCODE_HERE_APP_CODE`: Seu código de aplicativo do HERE Maps.
* **Endpoints:**
    * `/geocode`: Endpoint público, acessível a qualquer pessoa.
    * `/me/geocode`: Endpoint privado, acessível a usuários logados.

**3. iWebService**

* **Objetivo:** Utilizada para consultar e validar CPFs.
* **Variáveis de Ambiente:**
    * `IWEB_SERVICE_CHAVE`: Sua chave da API do iWebService.
* **Endpoints:**
    * `/signup`: Endpoint público, utilizado durante o processo de cadastro do usuário.

**4. Amazon SNS**

* **Objetivo:**  Utilizada para enviar notificações por SMS.
* **Variáveis de Ambiente:**
    * `AWS_SNS_KEY`:  Seu ID de chave de acesso do AWS SNS.
    * `AWS_SNS_SECRET`: Sua chave de acesso secreta do AWS SNS.
    * `AWS_SNS_ENDPOINT`: (Opcional) O endpoint da sua região do SNS (padrão: 'http://sns.sa-east-1.amazonaws.com').
* **Endpoints:**
    * Não é acessado diretamente por nenhum endpoint, mas é utilizado pela tarefa `send_sms`
disparada por outras ações, como enviar convites de guardiões ou alertas de pânico.

**5. APIs Brasileiras de CEP**

* **Objetivo:**  Esses módulos implementam integrações com APIs brasileiras de CEP (Código Postal) para
buscar informações de localização com base no CEP.
* **Módulos:**
    * `Penhas::CEP::Postmon`: Utiliza a API do Postmon (https://postmon.com.br/).
    * `Penhas::CEP::Correios`: Utiliza a API dos Correios (Serviço Postal Brasileiro).
    * `Penhas::CEP::ViaCep`:  Utiliza a API do ViaCep (https://viacep.com.br/).
* **Variáveis de Ambiente:**  Esses módulos não exigem variáveis de ambiente específicas.
Eles se baseiam nas APIs públicas dos respectivos serviços.
* **Endpoints:**
    * `/signup`: Endpoint público, utilizado para validar o CEP do usuário durante o cadastro.
    * `/me/sugerir-pontos-de-apoio`: Endpoint privado, usado para validar o CEP ao sugerir
um novo ponto de apoio.
    * `/admin/analisar-sugestao-ponto-apoio`:  Endpoint de administração, utilizado para buscar
informações de endereço com base no CEP.
    * `/maintenance/cliente_update_cep`: Tarefa interna, utilizada para atualizar os dados do usuário
com base no CEP.

**Observações:**

* O código prioriza a API do Postmon, em seguida tenta a API dos Correios e, por último, a API
do ViaCep, caso necessário, visando encontrar as informações de endereço mais completas possíveis.
* O sistema armazena em cache os resultados dessas APIs para reduzir solicitações desnecessárias
e melhorar o desempenho.
