# Penhas

# Configuração de infraestrutura
Abaixo instruções para uma sugestão para o deploy em Produção/Homologação:

## requisitos do mínimos de sistema

- PostgreSQL 13 ou superior com PostGis
- docker community edition 19 or maior (testado na 19.03.12)
- docker-compose 1.21 ou superior
- Nginx ou outro proxy reverso para finalização do HTTPS
- redis-server 5 ou superior
- Servidor SMTP para envio de e-mails
- S3 (compatível), pode ser AWS s3, backblaze b2 ou subir um MinIO https://min.io/
- Amazon SNS
- Here.com ou Google (https://developers.google.com/maps/documentation/geolocation e https://developers.google.com/maps/documentation/geocoding/overview)
- Recomendado 4 GB de RAM e 25GB de disco livres para as imagens dos containers.
- Metabase para relatórios (opcional)

## Componentes

<img src="https://svgshare.com/i/gTe.svg" alt="Deps">

+ um "serviço", validação do CEP utiliza a api do Postmon (https://postmon.com.br/) e se não encontrar ou estiver offline, acessa um crawler do Correios (https://metacpan.org/pod/WWW::Correios::CEP) que eu mantenho desde 2011 e as vezes para de funcionar

Para mais detalhes das integrações: [api/integracoes.md](api/integracoes.md)

## Here.com / Google

O sistema de ponto de apoio (busca)

Estou usando uma chave do here.com em produção, porem a plataforma mudou demais e quando fiz o login hj (2022/04/21) precisei criar uma nova conta, e nenhuma informação da conta anterior existe, porem as chaves continuam funcionando. Os limites do plano free que tinha era 100k/req/mês. O novo plano precisa adicionar o cartão, para ser 30k/mês, se não, a api fica limitada em 1000/dia

Podemos trocar para usar o https://developers.google.com/maps/documentation/geolocation/overview porém, eu não tenho mais contas com créditos para usar os 200 USD que o google oferece como free-tier para o geolocation

Google é 0.005/request. here.com é 0.00075/request após a free-tier

30k de requests no google sai por $155 (ainda estaria dentro dos 200usd), enquanto isso é a free-tier do here.com

## Instalação dos requisitos:

Instale o PostgreSQL, docker e docker-compose.
No Ubuntu 20.04, os comandos são os seguintes:

docker

> Consultar https://docs.docker.com/engine/install/ubuntu/

    apt-get update
    #apt-get remove docker docker-engine docker.io # remove versoes antigas/da distro
    apt-get install apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install docker-ce


docker-compose

> Consultar https://docs.docker.com/compose/install/

O docker-compose é um binário go e pode ser baixado diretamente usando wget

    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose


nginx:

    apt-get install nginx-extras


> Esta versão do nginx adiciona o suporte ao Lua, que pode ser usado para ter logs mais completos, ajudando no debug.

## Configurando PostgreSQL

> Este é apenas um exemplo, pode ser usado um host externo como RDS por exemplo


Feito com um deploy via docker-compose:

    version: '3.5'
    services:

      penhas_db_pg:
        container_name: penhas_db_pg
        image: postgis/postgis:13-3.1
        volumes:
            - ../data/penhas_db_pg:/var/lib/postgresql/data
        environment:
            POSTGRES_PASSWORD: foobar
            POSTGRES_USER: penhas
            POSTGRES_DB: penhas_db
        networks:
            - penhas_db
        logging:
          driver: "json-file"
          options:
            max-file: '100'
            max-size: 1m
        restart: unless-stopped
    networks:
        penhas_db:
            name: penhas_db_pg_network
            driver: bridge


Configurar volumes e senhas de acordo.


## Configurando redis

> Este é apenas um exemplo, pode ser usado um host externo como ElastiCache for Redis (AWS) por exemplo

Alterar o bind para `bind 127.0.0.1 172.17.0.1` em /etc/redis/redis.conf

O mesmo conceito sobre aguardar a interface docker0 se aplica aqui. Ou então usar docker-compose para subir o redis como container


### Configurando Firewall

Se houver um firewall (recomendado, mesmo se tiver com o firewall da AWS), caso os serviços como pg/redis estejam no host, precisamos ainda adicionar uma regra liberando o container a conversar com a interface bridge docker0

usando UFW firewall, você pode adicionar essa liberação utilizando o seguinte comando:

    ##  ufw allow from 172.17.0.0/24 to any port 5432 proto tcp

> 5432 é a porta do postgres, 172.17.0.0/24 são os hosts que podem conectar com ela.

O penhas também precisa do serviço redis 6379

    ##  ufw allow from 172.17.0.0/24 to any port 6379 proto tcp


## Build dos containers

> OBS: o projeto do penhas no momento precisa de um arquivo dump do banco para funcionar, não é possível fazer o bootstrap só com o git

Antes de começar, vamos criar as pastas:

    ( o usuário ubuntu precisa ja existir, e ter o id 1000)
    # cd /home/ubuntu
    # git clone ...
    # chmod 1000:1000 v2penhas -R # altera a pasta do código para o 1000:1000, pelo menos a pasta de código (/api) precisa estar com o 1000:1000


Para fazer o build, basta ir o path ./api/ e executar o `docker-compose build`

Esse processo pode levar alguns minutos na primeira vez.

Depois que o processo terminar, temos um arquivo de exemplo de como subir apenas o container da api, pode-se utilizar o docker-compose up para subir os containers

Existe um arquivo .env com as seguintes variáveis:

    PENHAS_API_LISTEN=50031
    DIRECTUS_API_LISTEN=50032

    DIRECTUS_DATABASE_HOST=penhas_db_pg
    DIRECTUS_DATABASE_PORT=5432
    DIRECTUS_DATABASE_NAME=penhas_db
    DIRECTUS_DATABASE_USERNAME=penhas
    DIRECTUS_DATABASE_PASSWORD=foobar

    # usado pelo directus
    SMTP_FROM="nao-responder.penhas@penhas.com.br"
    SMTP_HOST="email-smtp.us-east-1.amazonaws.com"
    SMTP_USER="..."
    SMTP_PASSWORD="..."

    DIRECTUS_PUBLIC_URL=https://cp.penhas.com.br
    DIRECTUS_KEY=...
    DIRECTUS_SECRET=...

    REDIS_STORAGE=../data/redis
    LOG_MAX_FILE=100
    LOG_MAX_SIZE=1m


Após configurar, execute o comando `docker-compose config` para ter um preview da configuração.

Além deste arquivo .env para o docker-compose, é necessário configurar o arquivo api/sqitch.conf

    Procure pela parte [target "docker"] e altere o 127.0.0.1 para a configuração correta como no caso acima


Para subir, basta executar `docker-compose up` e os serviços serão iniciados.

> Como pode ser visto acima, depois que um container esta rodando, para executar comandos dentro do ambiente dele, basta usar comando `docker exec`
> Para abrir um terminal: `docker exec -u app -it penhas_api /bin/bash`. Passe -u root para trocar para root.

Você pode criar o arquivo `api/envfile_local.sh` para trocar as variáveis de ambientes, por exemplo, para aumentar o número de workers da api:

    # view envfile_local.sh e adicionar
    export API_WORKERS="2"

Caso o arquivo não exista, o arquivo padrão será carregado (api/envfile.sh) que tenta manter os valores ja carregados pelo ambiente e seta o default

Depois, ajuste a permissão do arquivo `chmod +x envfile_local.sh`
Após a troca da variável, é possível recarregar o serviço da api usando `docker exec -u app penhas_api  /src/script/restart-services.sh`


Se tudo ocorreu bem, em você poderá acessar o admin da api usando

    http://172.17.0.1:64598/admin

O usuário e senha padrão (que vem no migration inicial) é `admin@sample.com` e senha `admin@sample.com`


### Configurando nginx:

A configuração do NGINX não é necessária para o ambiente de desenvolvimento, apenas para o ambiente com SSL.

A configuração do nginx ira ser diferente em cada ambiente, mas de qualquer forma, segue a base que usamos usando self-signed:

> Consultar https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-16-04

/etc/nginx/nginx.conf

    real_ip_header CF-Connecting-IP;

    log_format timed_combined_debug '$remote_addr - $remote_user [$time_iso8601] [HOST $http_host] $http_x_host '
    '"$request" $status $body_bytes_sent '
    '"$http_referer" "$http_user_agent" '
    '$request_time $upstream_response_time $pipe $request_length $upstream_addr $http_x_api_key $http_cf_connecting_ip "$request_body" "$resp_body" $http_cf_ray';
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;


/etc/nginx/sites-enabled/penhas-api

    server {
        listen 80;
        server_name penhas-api.domain.com;
        return 302 https://penhas-api.domain.com$request_uri;
    }

    server {
        listen 443 ssl;
        server_name penhas-api.domain.com;

        access_log /var/log/nginx/debug-penhas.log timed_combined_debug;


        charset utf-8;

        location / {
            proxy_read_timeout 300s;
            proxy_connect_timeout 75s;
            proxy_pass http://172.17.0.1:64598;

            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
            lua_need_request_body on;

            set $resp_body "";
            body_filter_by_lua '
                local resp_body = string.sub(ngx.arg[1], 1, 50000)

                ngx.ctx.buffered = (ngx.ctx.buffered or "") .. resp_body
                if ngx.arg[2] then
                    ngx.var.resp_body = ngx.ctx.buffered
                end
            ';
        }
    }

/etc/nginx/sites-enabled/penhas-directus

    server {
        listen 80;
        server_name penhas-directus.domain.com;
        return 302 https://penhas-directus.domain.com$request_uri;
    }

    server {
        listen 443 ssl;
        server_name penhas-directus.domain.com;

        access_log /var/log/nginx/access-penhas-directus.log;


        charset utf-8;

        location / {
            proxy_read_timeout 300s;
            proxy_connect_timeout 75s;
            proxy_pass http://172.17.0.1:64597;

            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
            lua_need_request_body on;

        }
    }


obs: nesse caso, usamos `/etc/nginx/ssl/nginx.crt` que precisa ser gerado, para servir de certificado auto-assinado antes de entregar os dados para a cloudflare, ou usar certificado da cloudflare, letsencrypt ou ainda então utilizar cloudflared via tunnel, que não precisa fazer esta configuração do nginx (de fato, se não fosse pelo log com debug, poderia inclusive rodar sem o nginx apenas com o cloudflared). Consultar https://dev.to/omarcloud20/a-free-cloudflare-tunnel-running-on-a-raspberry-pi-1jid

    ## mkdir /etc/nginx/ssl
    ## openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt

Outra alternativa é passar utilizar o letsencrypt para gerenciar os certificados.

## Configurando metabase

Assim como a API, o metabase precisa ser acessado por uma interface web para gerenciamento.

O Metabase pode ser executado de várias formas, a mais simples é com docker, salvando os dados dele em outro banco PostgreSQL:

    docker run -d -p 172.17.0.1:4757:3000 \
        --network penhas_db_pg_network \
        -e "MB_DB_TYPE=postgres" \
        -e "MB_DB_DBNAME=penhas_metabase" \
        -e "MB_DB_PORT=5432" \
        -e "MB_DB_USER=postgres" \
        -e "MB_DB_PASS=foobar" \
        -e "MB_DB_HOST=172.17.0.1" \
        --restart unless-stopped \
        --name penhas_metabase metabase/metabase:v0.39.1

Depois só configurar o nginx para fazer o proxy do vhost para 172.17.0.1:4757

O Virtual Host deve ser configurada na variável de ambiente METABASE_SECRET também ser configurado.

Atualmente o codigo ta com a url `https://analytics.penhas.com.br/` hardcoded no arquivo lib/Penhas/Controller/Admin/BigNum.pm

Para maiores detalhes, consulte https://www.metabase.com/docs/latest/operations-guide/running-metabase-on-docker.html

## Configurando o envio de e-mails:

Primeiro, configurar no banco, na tabela emaildb_config, o campo email_transporter_config, para apontar pra um server SMTP.

Por exemplo:


    -[ RECORD 1 ]------------+-------------------------------------------------------------------------------------------------------
    id                       | 1
    from                     | "Penhas" <penhas@penhas.com.br>
    template_resolver_class  | Shypper::TemplateResolvers::HTTP
    template_resolver_config | {"base_url":"http://api.penhas.com.br//email-templates/"}
    email_transporter_class  | Email::Sender::Transport::SMTP::Persistent
    email_transporter_config | {"sasl_username":"apikey","sasl_password":"key","port":"587","host":"smtp.sendgrid.net"}
    delete_after             | 25 years

Usamos outro container para o envio dos e-mails, para configurar, as instruções são semelhantes as instruções acima, e o código encontra-se no repositório publico da eokoe: https://github.com/eokoe/email-db-service

Importante manter o ID=1 que é o que o código do penhas espera

    # cd /home/ubuntu/api.penhas.com.br/
    # git clone https://github.com/eokoe/email-db-service.git
    # view run_container.sh

        #!/bin/bash

        # arquivo de exemplo para iniciar o container

        #!/bin/bash

        export SOURCE_DIR='/home/ubuntu/api.penhas.com.br/email-db/email-db-service'
        export DATA_DIR='/home/ubuntu/api.penhas.com.br/data/emaildb'

        # confira o seu ip usando ifconfig docker0|grep 'inet addr:'
        export DOCKER_LAN_IP=172.17.0.1

        mkdir -p $DATA_DIR/log
        chown 1000:1000 $DATA_DIR/log


        docker run --name penhas_emaildb \
        	-v $SOURCE_DIR:/src -v $DATA_DIR:/data \
            -e "EMAILDB_DB_HOST=penhas_db_pg"  --network penhas_db_pg_network \
            -e "EMAILDB_DB_NAME=penhas_db" -e "EMAILDB_DB_USER=penhas" -e "EMAILDB_DB_PASS=foobar" \
            -e "USE_MIME_Q_DEFAULT=1" \
            -e "USE_TXT_DEFAULT=0" \
            -e "EXIT_WORKER_AFTER=1000" \
        	--cpu-shares=512 \
        	--memory 500m -d --restart unless-stopped eokoe/emaildb


    # cd backend;
    # view envs.sh

        (altere o host do banco)

        export EMAILDB_DB_HOST=172.17.0.1
        export EMAILDB_DB_NAME=penhas_dev

    # ./run_container.sh


O campo template_resolver_config configura onde o sistema deve procurar as templates, que devem ser servidas por http ou https.

Os valores da tabela emaildb_config só são lidos durante o start do container, portanto, caso mude as configurações, é necessário reiniciar o container inteiro.

    docker restart $nome_do_container_do_emaildb

## Configurações na tabela penhas_config

    -- nome                     | valor/descrição
    ADMIN_ALLOWED_ROLE_IDS       | uuid dos roles do directus que podem logar no admin
    ANON_QUIZ_SECRET             | ... random token ...
    ASSISTANT_SUPORTE_URL        | https://api.penhas.com.br/avatar/assistant2.png
    AVATAR_ANONIMO_URL           | https://api.penhas.com.br/avatar/anonimo.svg
    AVATAR_PADRAO_URL            | https://api.penhas.com.br/avatar/padrao.svg
    AVATAR_PENHAS_URL            | https://dev-penhas-api.appcivico.com/avatar/penhas_avatar.svg
    AVATAR_SUPORTE_URL           | https://api.penhas.com.br/avatar/suporte-chat.png
    AWS_SNS_ENDPOINT             | http://sns.us-east-1.amazonaws.com
    AWS_SNS_KEY                  | key
    AWS_SNS_SECRET               | secret
    CPF_CACHE_HASH_SALT          | ... random token ...
    DEFAULT_NOTIFICATION_ICON    | https://api.penhas.com.br/i
    DELETE_PREVIOUS_SESSIONS     | 1 ou 0 para manter varias sessions ativas
    EMAIL_PONTO_APOIO_SUGESTAO   | penhasequipe@azmina.com.br
    FILTER_PONTO_APOIO_CATS      | 5,9 < deprecated após novas regras do Ponto de Apoio
    GEOCODE_HERE_APP_CODE        | key
    GEOCODE_HERE_APP_ID          | value
    GEOCODE_USE_HERE_API         | 1 ou 0 para usar google
    GOOGLE_GEOCODE_API           | apikey for google geocode/geolocation api
    GUARDS_ALLOWED_COUNTRY_CODES | ,55,39,1,34,351, # códigos de países que podem ser adicionados como guard
    IWEB_SERVICE_CHAVE           | token do CPF
    JWT_SECRET_KEY               | ... random ...
    MAINTENANCE_SECRET           | ... random ...
    MAX_CPF_ERRORS_IN_24H        | 100
    METABASE_SECRET              | (secret from metabase)
    MINION_ADMIN_PASSWORD        | ... random ...
    NOTIFICATIONS_ENABLED        | 1 ou 0 para desligar as notificações (mais usados nos testes)
    PENHAS_S3_ACCESS_KEY         | s3 access key
    PENHAS_S3_HOST               | s3.us-east-1.amazonaws.com
    PENHAS_S3_MEDIA_BUCKET       | s3 bucket
    PENHAS_S3_SECRET_KEY         | s3 secret
    PONTO_APOIO_SECRET           | ... random ... (chatbot do twitter, libera busca por lat/lng sem rate-limit)
    PUBLIC_API_URL               | https://api.penhas.com.br/
    SMS_GUARD_LINK               | https://sms.penhas.com.br/
    SUBSUBCOMENT_DISABLED        | 1 ou 0 para ativar os níveis dos sub-comments


## Crontab

Temos algumas ações que precisam rodar periodicamente no sistema, são eles:

- Adicionar na fila os jobs longos (ex: apagar conta)

Para executar tais ações, basta fazer uma chamada HTTP usando o secret do MAINTENANCE_SECRET

Os endpoints são os seguintes:

- each 1m https://api.penhas.com.br/maintenance/housekeeping?secret=$MAINTENANCE_SECRET
- each 1m https://api.penhas.com.br/maintenance/tick-notifications?secret=$MAINTENANCE_SECRET
- each 5m https://api.penhas.com.br/maintenance/tick-rss?secret=$MAINTENANCE_SECRET

Pode-se configurar para o crontab executar de 1 em 1 minuto, pois a api faz o controle de quantos jobs executar em cada request.

Também pode ser usado um serviço de monitoramento para fazer as chamadas no lugar de utilizar o crontab.


## Directus

No directus existe uma descrição para cada tabela que pode ser modificada pelos administradores.
É necessário um dump do banco para receber as tabelas do directus

# Dicas para o desenvolvimento

O sistema foi criado utilizando o framework web Mojolicious (https://mojolicious.org/).
Alem de ser um framework web, este framework contém várias ferramentas para facilitar o trabalho com html, por exemplo, o pacote Mojo::DOM. Você pode aprender mais sobre em https://docs.mojolicious.org/
Além do Mojolicious, para executar os jobs em background, foi utilizado o framework Minion https://docs.mojolicious.org/Minion que além de processar os jobs, fornece uma interface administrativa para acompanhamento dos trabalhos.

Para ORM, foi utilizado o framework DBIx::Class. Uma das vantagem de utilizar o DBIx::Class é poder utilizar o DBIx::Class::Schema::Loader para gerar automaticamente o código para uso das tabelas, e não precisar escrever praticamente nenhum SQL na mão.

## Processo para adicionar uma nova modificação no banco:

O projeto foi feito primeiramente no directus, com um banco mysql e outra parte no pg, então é necessário um dump do banco para iniciar o desenvolvimento/rodar os testes.

Para a parte em pg, nunca foi alterado o banco diretamente pela interface do directus, mas depois que juntou, isso gerou uma inconsistência com o schema esperado pela api.

Ainda falta ajustar o schema que o código consiga criar 100% do banco via sqitch, exceto as configurações do directus que são muito dinamicas.

Para novas alterações, é possível utilizar os passos abaixo:

O primeiro passo deve ser criar uma nova migration (veja: "Criando novas migrações de banco (sqitch)" abaixo) e depois rodar o comando para atualizar o código automaticamente com o novo schema.

Para isso, basta rodar o comando:

    ir para pasta api/

    $ . script/mysql.schema.dump.sh

Lembrando que o banco já deve estar configurado corretamente no arquivo `envfile_local.sh` ou `envfile.sh`

## Estrutura de pastas

Comentários sobre os arquivos mais importantes

    .
    ├── api                     # código fonte para penhas
    │   ├── build-container.sh  # constrói a imagem do container
    │   ├── deploy_db           # Migrations
    │   │   ├── deploy          # SQL de cada migration
    │   │   │   ├── 0001-db-init.sql
    |   |   |   ...
    │   │   └── sqitch.plan     # Controle de migrations
    │   ├── dist.ini            # Configuração de dependências e empacotamento do projeto
                                # este arquivo serve para gerar o Makefile.PL (que é como se fosse o package.json em node.js)
    │   ├── docker              # Arquivos para montar a imagem docker
    |   |       ...
    │   ├── envfile.sh          # arquivo de configuração de exemplo, criar envfile_local.sh
    │   ├── lib
    │   │   ├── Penhas         # Pasta base do código do penhas
    │   │   │   ├── Controller  # Pasta com as controllers
    │   │   │   │   ...
    │   │   │   ├── Controller.pm # Base da classe de controllers,
    │   │   │   ├── Helpers
        │   │   │   ...
    │   │   │   ├── Helpers.pm    # Carrega as helpers
    │   │   │   ├── Minion        # Código para executar os jobs registrados no Minion
    │   │   │   │   ├── Tasks
    │   │   │   │   │   ├── NewsIndexer.pm
    │   │   │   │   │   ├── CepUpdater.pm
    │   │   │   │   │   ├── NewNotification.pm
    │   │   │   │   │   ├── ...
    │   │   │   │   │   └── DeleteUser.pm
    │   │   │   │   └── Tasks.pm
    │   │   │   ├── Routes.pm     # Configuração de rotas do sistema (como se fosse os handlers em golang)
    │   │   │   ├── Schema e Schema2 (antes era separado mysql e pg)
    │   │   │   │   ├── Base.pm
    │   │   │   │   └── Result   # Arquivos do schema gerados automaticamente pelo schema.dump.sh
                        # ...
    │   │   │   ├── SchemaConnected.pm # Singleton para abrir conexão com o banco e iniciar as variáveis de ambiente
    │   │   │   ├── Schema.pm       # Modifica o Base class do ORM, para extender funções, eg: acessar funções do banco
    │   │   │   ├── Types.pm        # Validações de dados, ex: CPF, Nome, IntList
    │   │   │   ├── Uploader.pm     # Faz envio para S3
    │   │   │   └── Utils.pm        # "pure functions" aleatórias
    │   │   ├── Penhas.pm   # Bootstrap do sistema web
    │   │   ├── Mojolicious
    │   │   │   └── Plugin
    │   │   │       └── JWT.pm  # nao deveria ser plugin, deveria ser uma helper!
    │   ├── Makefile.PL         # arqivo com as deps "package.json"
    │   ├── Makefile            # arquivo make (não usado, mas gerado sozinho pelo dist.ini)
    │   ├── MYMETA.json         # idem
    │   ├── MYMETA.yml          # idem
    │   ├── public     # pasta com arquivos publicos, servido automaticamente pelo mojolicious quando a rota não existe
    │   │   ├── email-templates  # pasta com as templates utilizada pelo serviço de e-mail
    │   │   │   ├── account_deletion.html
    │   │   │   ├── account_reactivate.html
    │   │   │   ├── forgot_password.html
    │   │   │   └── ponto_apoio_sugestao.html
    │   │   └── web-assets  # arquivos para ser usado na interface web
        │   │   │   ... # muitos arquivos
    │   ├── sample-gracefully-reload.sh  # exemplo de script para reiniciar o docker
    │   ├── sample-run-container.sh      # exemplo de script para subir o docker sem docker-compose
    │   ├── script                       # scripts do projeto
    │   │   ├── penhas-api               # sobe a aplicação
    │   │   ├── restart-services.sh      # reinicia o serviço da api
    │   │   └── start-server.sh          # inicia o serviço da api
    │   │   ├── mysql.schema.dump.sh     # refaz o schema a partir do banco
    │   │   ├── start-minion-worker.sh   # inicia os serviços em background
    │   ├── sqitch.conf     # configuração do banco para o rodar o migration
    │   ├── t # pasta de testes do sistema
    │   │   ├── api  # testes da api
    │   │   │   ....
    │   │   ├── data # dados utilizado nos testes
    │   │   │   └── small.png
    │   │   └── lib # códigos helpers apena para os testes
    │   │       └── Penhas
    │   │           └── Test.pm
    │   ├── templates  # pasta com as templates de email para e outros HTMLs
    │   └── xt  # testes de autor (só rode se precisar)
    │       ├── 999-clear-db.t
    │       ├── 999-geocode-cached.t
    │       └── 999-geocode.t
    ├── docker-compose.yaml  # configurações do containers
    ├── lost-and-found                 # arquivos não relacionados com código
    │   ├── 2022.mapeamento.pontoapoio.csv, parse-csv.pl, etc

## Triggers

O sistema usa algumas triggers para atualizar os timestamp quando certos dados são modificados para invalidar o cache.

Você pode encontrar as triggers usando o comando:

grep -i trigger api/deploy_db/ -r

## Rodando os testes (ambiente dev) com docker

Siga os mesmos passos de instalações do pg e docker.

Depois, precisa editar o arquivo sqitch.conf. Nao precisa do arquivo envfile_local.sh

No arquivo `sqitch.conf` altere a conexão da chave "local"

Vá até o diretório base código, e execute o código:

    docker run --name penhas_backend_test --rm -v $(pwd):/src -v /tmp/:/data -it -u app azminas/penhas_api bash

    $ cd /src;
    $ . envfile_docker_test.sh # carrega as variáveis de ambiente configurado o ambiente docker
    $ yath test -j 4 -PPenhas  -Ilib t/ # inicia todos os testes, usando 4 tests em paralelo

Para o desenvolvedor, eu recomendo instalar o pg, redis, perl na máquina local, assim evita ter que subir um container inteiro toda hora que deseja rodar o teste.

Para instalar as deps, use o Dockerfile como base.

Para testar na máquina local, após instalar as dependências, execute:

    createdb -h 127.0.0.1 -U postgres penhas_dev
    sqitch deploy  -t development
    DBIC_TRACE=1 TRACE=1 yath test -j 8 -Ppenhas -Ilib t/

Os testes do Penhas podem rodar contra o banco de produção, embora não seja recomendado, mas pode ser contra um ambiente de staging, pois os testes já esperam que estejam num ambiente de banco compartilhado

TRACE=1 mostra o request/response que são executados
DBIC_TRACE=1 mostra as queries que foram executadas por dentro do ORM

## Criando novas migrações de banco (sqitch)

> instruções dadas aqui consideram que você está trabalhando na pasta "api" (e nao no root do repo)

Usamos um padrão para criar um novo arquivo sqitch:

- Cada arquivo faz "require" no último deploy
- Não usamos revert nem verify

O problema de usar o revert, é que nem toda alteração tem revert, e, quando você faz deploy de mais de uma alteração ao mesmo tempo, e uma desta falha, o sqitch roda todos os reverts (que se não existir, irá ficar em branco), dando um trabalho extra para voltar o banco em um estado estável.
Quando não existe arquivo, ele simplesmente não executa o revert, e você pode arrumar o arquivo de deploy que deu errado e executar novamente `sqitch deploy` que ele irá apenas executar os arquivos ainda não executados (ou executados com erro).

Para ajudar, uso essas funções no meu .bashrc para criar novos sqitch.

    deploydb_last_version () {
       perl -e 'my $last = [ sort { $b <=> $a } grep {/^\d{1,4}-/} @ARGV]->[0]; $last =~ s/\.sql$//; print "$last"' `ls deploy_db/deploy/`
    }

    deploydb_next_version () {
       perl -e 'my $name = shift @ARGV; my $last = [ sort { $b <=> $a } grep {/^\d{1,4}-/} @ARGV]->[0]; $last =~ s/\.sql$//; $last =~ s/^(\d+)-.+/sprintf(q{%04d}, $1+1)/e;  print "$last-$name"' $1 `ls deploy_db/deploy/`
    }

    new_deploy (){
        sqitch add `deploydb_next_version $1` --requires `deploydb_last_version` -n "${*:2}"
        ## $EDITOR deploy_db/deploy/`deploydb_last_version`.sql

        rm -rf deploy_db/revert
        rm -rf deploy_db/verify
    }


E para criar um novo deploy, simplesmente executar `new_deploy nome-do-arquivo descrição do será modificado`

Depois de criar e editar o arquivo (fica na pasta deploy_db/deploy/) você poderá executar as alterações no banco usando `sqitch deploy -t development` (-t é o target, pode ser outro)
