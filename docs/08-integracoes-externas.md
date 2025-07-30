# Integrações Externas

## Visão Geral

O PenhaS integra-se com vários serviços externos para fornecer funcionalidades como armazenamento de arquivos, notificações, geocodificação e mensagens. Este documento detalha cada integração e sua configuração.

## Armazenamento S3

### Propósito
Armazenar conteúdo gerado pelos usuários, incluindo gravações de áudio, imagens e outros arquivos de mídia.

### Provedores Suportados
- AWS S3
- Backblaze B2
- MinIO (auto-hospedado)
- Qualquer serviço compatível com S3

### Configuração

```bash
# Variáveis de ambiente
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_DEFAULT_REGION=us-east-1
S3_MEDIA_BUCKET=penhas-media
S3_ENDPOINT_URL=https://s3.amazonaws.com  # Opcional para não-AWS
```

### Implementação

```perl
# lib/Penhas/Uploader.pm
use Paws;
use Paws::S3;

sub upload {
    my ($self, $args) = @_;
    
    my $s3 = Paws->service('S3',
        region => $ENV{AWS_DEFAULT_REGION}
    );
    
    my $result = $s3->PutObject(
        Bucket => $ENV{S3_MEDIA_BUCKET},
        Key => $args->{path},
        Body => $args->{content},
        ContentType => $args->{type},
        ACL => 'private'
    );
    
    return $result->ETag;
}
```

### Organização de Arquivos

```
penhas-media/
├── audio/
│   └── 2023/01/01/
│       └── {user_id}/
│           └── {event_id}/
│               ├── audio_1.aac
│               └── audio_2.aac
├── images/
│   └── profiles/
│       └── {user_id}/
│           └── avatar.jpg
└── uploads/
    └── {year}/{month}/
        └── {upload_id}/
            └── file.ext
```

### Segurança

#### Controle de Acesso
- Todos os arquivos armazenados com ACL privada
- Acesso apenas via URLs pré-assinadas
- Expiração de URL configurável (padrão: 1 hora)

#### Geração de URL Pré-assinada
```perl
sub generate_presigned_url {
    my ($self, $s3_path, $expires_in) = @_;
    
    $expires_in //= 3600; # 1 hora padrão
    
    my $s3 = Paws->service('S3');
    
    return $s3->GetObjectUrl(
        Bucket => $ENV{S3_MEDIA_BUCKET},
        Key => $s3_path,
        Expires => $expires_in
    );
}
```

## Amazon SNS

### Propósito
- Notificações push para dispositivos móveis
- Mensagens SMS para alertas de guardiões
- Notificações por email (opcional)

### Configuração

```bash
# Variáveis de ambiente
AWS_SNS_REGION=us-east-1
SNS_PLATFORM_APP_ARN_IOS=arn:aws:sns:...
SNS_PLATFORM_APP_ARN_ANDROID=arn:aws:sns:...
SNS_SMS_SENDER_ID=PenhaS
```

### Notificações Push

#### Registro de Dispositivo
```perl
sub register_device {
    my ($self, $platform, $device_token) = @_;
    
    my $sns = Paws->service('SNS',
        region => $ENV{AWS_SNS_REGION}
    );
    
    my $platform_arn = $platform eq 'ios' 
        ? $ENV{SNS_PLATFORM_APP_ARN_IOS}
        : $ENV{SNS_PLATFORM_APP_ARN_ANDROID};
    
    my $endpoint = $sns->CreatePlatformEndpoint(
        PlatformApplicationArn => $platform_arn,
        Token => $device_token
    );
    
    return $endpoint->EndpointArn;
}
```

#### Formatação de Mensagem
```perl
# Formato iOS APNS
{
    "APNS": {
        "aps": {
            "alert": {
                "title": "PenhaS",
                "body": "Nova mensagem",
                "loc-key": "MESSAGE_KEY",
                "loc-args": ["arg1", "arg2"]
            },
            "badge": 1,
            "sound": "default",
            "content-available": 1
        },
        "custom_data": {
            "type": "chat_message",
            "id": "123"
        }
    }
}

# Formato Android FCM
{
    "GCM": {
        "data": {
            "title": "PenhaS",
            "body": "Nova mensagem",
            "type": "chat_message",
            "id": "123"
        },
        "priority": "high",
        "time_to_live": 86400
    }
}
```

### Mensagens SMS

#### Enviando SMS
```perl
sub send_sms {
    my ($self, $phone_number, $message) = @_;
    
    my $sns = Paws->service('SNS');
    
    # Formatar número de telefone para E.164
    $phone_number = format_e164($phone_number);
    
    my $result = $sns->Publish(
        PhoneNumber => $phone_number,
        Message => $message,
        MessageAttributes => {
            'AWS.SNS.SMS.SenderID' => {
                DataType => 'String',
                StringValue => $ENV{SNS_SMS_SENDER_ID}
            },
            'AWS.SNS.SMS.SMSType' => {
                DataType => 'String',
                StringValue => 'Transactional'
            }
        }
    );
    
    return $result->MessageId;
}
```

## Serviços de Geocodificação

### Here.com (Primário)

#### Configuração
```bash
HERE_APPID=your-app-id
HERE_APPCODE=your-app-code
HERE_GEOCODE_URL=https://geocoder.api.here.com/6.2/geocode.json
HERE_REVERSE_URL=https://reverse.geocoder.api.here.com/6.2/reversegeocode.json
```

#### Geocodificação Direta
```perl
sub geocode_here {
    my ($self, $address) = @_;
    
    my $ua = Mojo::UserAgent->new;
    
    my $res = $ua->get($ENV{HERE_GEOCODE_URL} => form => {
        app_id => $ENV{HERE_APPID},
        app_code => $ENV{HERE_APPCODE},
        searchtext => $address,
        country => 'BRA',
        language => 'pt-BR'
    })->result;
    
    if ($res->is_success) {
        my $data = $res->json;
        my $location = $data->{Response}{View}[0]{Result}[0]{Location}{DisplayPosition};
        
        return {
            lat => $location->{Latitude},
            lng => $location->{Longitude}
        };
    }
    
    return undef;
}
```

#### Reverse Geocoding
```perl
sub reverse_geocode_here {
    my ($self, $lat, $lng) = @_;
    
    my $ua = Mojo::UserAgent->new;
    
    my $res = $ua->get($ENV{HERE_REVERSE_URL} => form => {
        app_id => $ENV{HERE_APPID},
        app_code => $ENV{HERE_APPCODE},
        prox => "$lat,$lng,100",
        mode => 'retrieveAddresses',
        language => 'pt-BR'
    })->result;
    
    if ($res->is_success) {
        my $data = $res->json;
        return $data->{Response}{View}[0]{Result}[0]{Location}{Address}{Label};
    }
    
    return undef;
}
```

### Google Maps (Reserva)

#### Configuração
```bash
GOOGLE_MAPS_API_KEY=your-api-key
GOOGLE_GEOCODE_URL=https://maps.googleapis.com/maps/api/geocode/json
```

#### Implementação
```perl
sub geocode_google {
    my ($self, $address) = @_;
    
    my $ua = Mojo::UserAgent->new;
    
    my $res = $ua->get($ENV{GOOGLE_GEOCODE_URL} => form => {
        address => $address,
        region => 'br',
        language => 'pt-BR',
        key => $ENV{GOOGLE_MAPS_API_KEY}
    })->result;
    
    if ($res->is_success) {
        my $data = $res->json;
        if ($data->{status} eq 'OK') {
            my $location = $data->{results}[0]{geometry}{location};
            return {
                lat => $location->{lat},
                lng => $location->{lng}
            };
        }
    }
    
    return undef;
}
```

### Estratégia de Cache

```perl
# Cache Redis para resultados de geocodificação
sub geocode_cached {
    my ($self, $address) = @_;
    
    # Gerar chave de cache
    my $cache_key = "GEO:" . md5_hex(lc($address));
    
    # Verificar cache
    my $cached = $redis->get($cache_key);
    if ($cached) {
        return decode_json($cached);
    }
    
    # Tentar serviço primário
    my $result = $self->geocode_here($address);
    
    # Usar Google como reserva
    if (!$result) {
        $result = $self->geocode_google($address);
    }
    
    # Armazenar resultado em cache
    if ($result) {
        $redis->setex($cache_key, 86400, encode_json($result)); # TTL de 24h
    }
    
    return $result;
}
```

## Serviços de Email

### Configuração SMTP

```bash
# Variáveis de ambiente
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=noreply@penhas.com.br
SMTP_PASS=your-password
SMTP_FROM="PenhaS <noreply@penhas.com.br>"
SMTP_TLS=1
```

### Envio de Email

```perl
use Email::Sender::Simple;
use Email::Sender::Transport::SMTP;
use Email::MIME;

sub send_email {
    my ($self, $args) = @_;
    
    my $transport = Email::Sender::Transport::SMTP->new({
        host => $ENV{SMTP_HOST},
        port => $ENV{SMTP_PORT},
        sasl_username => $ENV{SMTP_USER},
        sasl_password => $ENV{SMTP_PASS},
        ssl => $ENV{SMTP_TLS} ? 'starttls' : 0,
    });
    
    my $email = Email::MIME->create(
        header_str => [
            From => $ENV{SMTP_FROM},
            To => $args->{to},
            Subject => $args->{subject},
        ],
        attributes => {
            content_type => 'text/html',
            charset => 'UTF-8',
        },
        body_str => $args->{html_body},
    );
    
    Email::Sender::Simple->send($email, {
        transport => $transport
    });
}
```

### Templates de Email

Templates armazenados em `/public/email-templates/`:
- `welcome.html` - Boas-vindas ao novo usuário
- `reset-password.html` - Redefinição de senha
- `guardian-invite.html` - Convite para guardião
- `alert-sent.html` - Confirmação de alerta

## Serviços Brasileiros

### Consulta de CEP (Código Postal)

#### API Postmon (Primário)
```perl
sub lookup_cep_postmon {
    my ($self, $cep) = @_;
    
    my $ua = Mojo::UserAgent->new;
    
    my $res = $ua->get("https://api.postmon.com.br/v1/cep/$cep")->result;
    
    if ($res->is_success) {
        my $data = $res->json;
        return {
            street => $data->{logradouro},
            neighborhood => $data->{bairro},
            city => $data->{cidade},
            state => $data->{estado},
            lat => $data->{latitude},
            lng => $data->{longitude}
        };
    }
    
    return undef;
}
```

#### Scraper dos Correios (Reserva)
```perl
use WWW::Correios::CEP;

sub lookup_cep_correios {
    my ($self, $cep) = @_;
    
    my $correios = WWW::Correios::CEP->new;
    
    my $result = eval { $correios->find($cep) };
    
    if ($result && !$@) {
        return {
            street => $result->{street},
            neighborhood => $result->{neighborhood},
            city => $result->{city},
            state => $result->{state}
        };
    }
    
    return undef;
}
```

### Validação de CPF

```perl
use Business::BR::CPF;

sub validate_cpf {
    my ($self, $cpf) = @_;
    
    # Remover não-dígitos
    $cpf =~ s/\D//g;
    
    # Validar formato e dígito verificador
    return 0 unless length($cpf) == 11;
    return 0 unless Business::BR::CPF::test_cpf($cpf);
    
    # Verificações adicionais para padrões inválidos conhecidos
    return 0 if $cpf =~ /^(\d)\1{10}$/; # Todos os dígitos iguais
    
    return 1;
}
```

## Monitoramento de Integrações

### Verificações de Saúde

```perl
sub check_external_services {
    my $self = shift;
    
    my $status = {
        s3 => $self->check_s3_health(),
        sns => $self->check_sns_health(),
        geocoding => $self->check_geocoding_health(),
        email => $self->check_smtp_health(),
    };
    
    return $status;
}

sub check_s3_health {
    my $self = shift;
    
    eval {
        my $s3 = Paws->service('S3');
        $s3->HeadBucket(Bucket => $ENV{S3_MEDIA_BUCKET});
    };
    
    return $@ ? 0 : 1;
}
```

### Tratamento de Erros

```perl
# Lógica de retry para serviços externos
sub call_with_retry {
    my ($self, $service, $method, $args, $max_attempts) = @_;
    
    $max_attempts //= 3;
    my $attempt = 0;
    my $delay = 1;
    
    while ($attempt < $max_attempts) {
        $attempt++;
        
        my $result = eval { $service->$method($args) };
        
        if (!$@) {
            return $result;
        }
        
        # Registrar erro
        $self->log->error("Service call failed (attempt $attempt): $@");
        
        # Backoff exponencial
        if ($attempt < $max_attempts) {
            sleep($delay);
            $delay *= 2;
        }
    }
    
    die "Chamada de serviço falhou após $max_attempts tentativas";
}
```

## Boas Práticas

### 1. Padrão Circuit Breaker

```perl
# Prevenir falhas em cascata
my $circuit_breaker = {
    failures => 0,
    last_failure => 0,
    threshold => 5,
    timeout => 300, # 5 minutes
};

sub call_external_service {
    my ($self, $service_name, $callback) = @_;
    
    my $breaker = $self->circuit_breakers->{$service_name};
    
    # Verificar se o circuito está aberto
    if ($breaker->{failures} >= $breaker->{threshold}) {
        if (time - $breaker->{last_failure} < $breaker->{timeout}) {
            die "Circuit breaker open for $service_name";
        }
        # Resetar após timeout
        $breaker->{failures} = 0;
    }
    
    # Tentar a chamada
    my $result = eval { $callback->() };
    
    if ($@) {
        $breaker->{failures}++;
        $breaker->{last_failure} = time;
        die $@;
    }
    
    # Sucesso - resetar falhas
    $breaker->{failures} = 0;
    
    return $result;
}
```

### 2. Configuração de Timeout

```perl
# Definir timeouts apropriados
my $ua = Mojo::UserAgent->new;
$ua->connect_timeout(5);
$ua->request_timeout(30);
$ua->max_redirects(3);
```

### 3. Estratégias de Fallback

```perl
# Degradação graciosa
sub get_location {
    my ($self, $address) = @_;
    
    # Tentar serviço primário
    my $location = eval { $self->geocode_here($address) };
    
    # Usar serviço secundário como fallback
    if (!$location) {
        $location = eval { $self->geocode_google($address) };
    }
    
    # Retornar localização aproximada
    if (!$location) {
        $location = $self->get_city_center($address);
    }
    
    return $location;
}
```