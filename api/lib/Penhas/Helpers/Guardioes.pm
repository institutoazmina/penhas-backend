package Penhas::Helpers::Guardioes;
use common::sense;
use Carp qw/confess/;
use utf8;
use JSON;
use Penhas::Logger;
use Number::Phone::Lib;
use Penhas::Utils qw/random_string_from is_test/;
use Digest::MD5 qw/md5_hex/;
use Scope::OnExit;

sub setup {
    my $self = shift;

    $self->helper('cliente_upsert_guardioes' => sub { &cliente_upsert_guardioes(@_) });
    $self->helper('cliente_delete_guardioes' => sub { &cliente_delete_guardioes(@_) });
    $self->helper('cliente_edit_guardioes'   => sub { &cliente_edit_guardioes(@_) });
    $self->helper('cliente_list_guardioes'   => sub { &cliente_list_guardioes(@_) });
    $self->helper('cliente_alert_guards'     => sub { &cliente_alert_guards(@_) });
    $self->helper('guardiao_load_by_token'   => sub { &guardiao_load_by_token(@_) });
    $self->helper('guardiao_update_by_token' => sub { &guardiao_update_by_token(@_) });

}

sub guardiao_load_by_token {
    my ($c, %opts) = @_;

    my $token = $opts{token};

    if (length($token) == 10 && $token =~ /^[ASDFGHJKLQWERTYUIOPZXCVBNM0123456789\-\.\,\*\_]{10}$/) {

        my $test_token = substr($token, 0, 7);
        my $hash       = uc(substr(md5_hex($ENV{GUARD_HASH_SALT} . $test_token), 0, 3));

        if ($token ne "$test_token$hash") {
            $c->reply_invalid_param(
                'Assinatura do código não confere.',
                'token_invalid_hash',
                'token'
            );
        }
    }
    else {
        $c->reply_invalid_param(
            'O código informado não é válido. Confira novamente o link recebido no SMS.',
            'token_invalid_format',
            'token'
        );
    }

    my $row = $c->schema2->resultset('ClientesGuardio')->search(
        {
            'me.status'     => {'in' => [qw/pending accepted refused expired_for_not_use/]},
            'me.token'      => $token,
            'me.deleted_at' => undef,
        },
        {
            prefetch => 'cliente',
        }
    )->next or $c->reply_item_not_found();

    # expira os convites que ja expiraram
    $row->cliente->clientes_guardioes_rs->expires_pending_invites;

    # desconsidera as mudanças
    $row->discard_changes({prefetch => 'cliente'});

    # confere se o status nao mudou
    if ($row->status !~ /^(pending|accepted|refused|expired_for_not_use)$/) {
        $c->reply_item_not_found();
    }

    return $row;
}

sub guardiao_update_by_token {
    my ($c, %opts) = @_;

    my $action = $opts{action};
    if ($action !~ /^(accept|refuse)$/) {
        $c->reply_invalid_param(
            'action não reconhecido',
            'action_invalid',
            'action'
        );
    }
    my $row = $c->guardiao_load_by_token(%opts);

    # se expirou, nao pode mais ser aceito
    if ($row->status eq 'expired_for_not_use') {
        $c->reply_invalid_param(
            'Este convite já expirou!',
            'guard_invite_expired',
            'token'
        );
    }

    if ($action eq 'accept' && $row->status ne 'accepted') {
        $row->update(
            {
                status        => 'accepted',
                accepted_at   => \'NOW()',
                accepted_meta => $row->accepted_meta_merge_with(
                    {
                        ip => $c->remote_addr(),
                        (
                            $row->refused_at
                            ? (
                                old_refused_at => $row->refused_at->datetime,
                              )
                            : ()
                        ),
                    }
                ),
                refused_at => undef,
            }
        );
        $row->discard_changes({prefetch => 'cliente'});
    }
    elsif ($action eq 'refuse' && $row->status ne 'refused') {
        $row->update(
            {
                status        => 'refused',
                accepted_at   => undef,
                accepted_meta => $row->accepted_meta_merge_with(
                    {
                        refused_ip => $c->remote_addr(),
                        (
                            $row->accepted_at
                            ? (
                                old_accepted_at => $row->accepted_at->datetime,
                              )
                            : ()
                        ),
                    }
                ),
                refused_at => \'NOW()',

            }
        );
        $row->discard_changes({prefetch => 'cliente'});
    }

    return $row;
}

sub cliente_upsert_guardioes {
    my ($c, %opts) = @_;

    my $user_obj = $opts{user_obj} or confess 'missing user_obj';
    my $nome     = $opts{nome}     or confess 'missing nome';
    my $celular  = $opts{celular}  or confess 'missing celular';


    my ($celular_e164, $celular_national) = &_parse_celular($c, $celular);

    my $filtered_rs = $user_obj->clientes_guardioes_rs->search_rs(
        {
            celular_e164 => $celular_e164,
        }
    );

    $filtered_rs->expires_pending_invites();

    my ($locked1, $lock_key1) = $c->kv->lock_and_wait('cliente_upsert_guardioes:pn' . $celular_e164);
    on_scope_exit { $c->kv->redis->del($lock_key1) };

    my ($locked2, $lock_key2) = $c->kv->lock_and_wait('cliente_upsert_guardioes:uid' . $user_obj->id);
    on_scope_exit { $c->kv->redis->del($lock_key2) };

    if (!$locked1 || !$locked2) {
        $c->reply_invalid_param(
            'Recurso está em uso, tente novamente',
            'already_locked'
        );
    }

    my $invites_max     = $user_obj->clientes_guardioes_rs->max_invites_count();
    my $remaing_invites = $invites_max - $user_obj->clientes_guardioes_rs->used_invites_count();
    if ($remaing_invites <= 0) {
        $c->reply_invalid_param(
            'Vocẽ não pode adicionar mais guardiões. Excluía convites recusados e expirados.',
            'max_invites_reached'
        );
    }

    my ($message, $row);

    my $already_sent_msg
      = 'O seu guardião pode aceitar o seu convite utilizando o mesmo link que foi enviado anteriormente.';
    my $exists_active = $filtered_rs->search(
        {
            status => {in => [qw/pending accepted/]},
        },
        {
            'columns' => [qw/id status/],
        }
    )->next;
    if ($exists_active) {

        $row = $exists_active;

        $message = sprintf(
            'O número %s %s',
            $celular_national,
            (
                $exists_active->status eq 'pending'
                ? "já tem um convite aguardando ativação. $already_sent_msg"
                : 'já é um guardião!'
            ),
          ),
          'open_invite_or_invited',
          'celular';
        goto RENDER;
    }

    my $recent_refused = $filtered_rs->search(
        {
            'me.status'     => {in   => ['refused', 'removed_by_user']},
            'me.refused_at' => {'>=' => \'date_sub(now(), interval 7 day)'}
        },
        {
            'columns' => [qw/id refused_at/],
        }
    )->next;
    if ($recent_refused) {
        $c->reply_invalid_param(
            sprintf(
                'O número %s recusou seu convite em %s. Você só poderá convida-lo novamente após 7 dias.',
                $celular_national,
                $recent_refused->refused_at->dmy('/'),

            ),
            'recent_refused',
            'celular'
        );
    }

    my $recent_deleted = $filtered_rs->search(
        {
            status     => 'removed_by_user',
            deleted_at => {'>=' => \'date_sub(now(), interval 1 day)'}
        },
        {
            'columns' => [qw/id deleted_at/],
        }
    )->next;
    if ($recent_deleted) {

        $recent_deleted->update(
            {
                nome       => $nome,
                status     => 'pending',
                deleted_at => undef,
            }
        );
        $row = $recent_deleted;

        $message = sprintf(
            "O convite para o número %s foi reativado! $already_sent_msg",
            $celular_national,
        );
        goto RENDER;
    }

    # se adicionar um numero expirado, remover da lista de expirados (marca como apagado)
    $filtered_rs->search(
        {
            status => 'expired_for_not_use',
        },
        {
            'columns' => [qw/id/],
        }
    )->update({deleted_at => \'NOW()'});

    # ~ 94 bilhoes de combinacoes
    my $token = random_string_from('ASDFGHJKLQWERTYUIOPZXCVBNM0123456789-.,*_', 7);
    my $hash  = substr(md5_hex($ENV{GUARD_HASH_SALT} . $token), 0, 3);

    $row = $user_obj->clientes_guardioes_rs->create(
        {
            status                        => 'pending',
            created_at                    => \'NOW()',
            celular_e164                  => $celular_e164,
            celular_formatted_as_national => $celular_national,
            nome                          => $nome,
            token                         => uc($token . $hash),
            expires_at                    => \'date_add(now(), interval 30 day)'
        }
    );

    $message = 'Enviamos um SMS com um link para que o guardião aceite o seu convite.';

    my $message_prepend = 'PenhaS: ';
    my $message_link
      = ' convidou vc ser guardiao dela. p/ aceitar e mais informações acesse '
      . ($ENV{SMS_GUARD_LINK} || 'https://sms.penhas.com.br/')
      . $row->token();

    # 130 no lugar de 140, pois o minimo reservado pro nome sao 10 chars
    my $remaining_chars = 130 - length($message_prepend . $message_link);

    # se ficou menor, nao tem jeito, vamo ser dois SMS..
    $remaining_chars += 140 if $remaining_chars < 0;

    my $message_sms = $message_prepend . substr($user_obj->nome_completo, 0, $remaining_chars) . $message_link;

    my $job_id = $c->minion->enqueue(
        'send_sms',
        [
            $celular_e164,
            $message_sms,
        ] => {
            notes    => {clientes_guardioes_id => $row->id},
            attempts => 5,
            priority => 0,
        }
    );
  RENDER:
    $row->discard_changes;
    return {
        message => $message,
        data    => &_format_guard_row($c, $user_obj, $row),
    };
}

sub cliente_delete_guardioes {
    my ($c, %opts) = @_;
    my $user_obj = $opts{user_obj} or confess 'missing user_obj';
    my $guard_id = $opts{id}       or confess 'missing id';

    my $row = $user_obj->clientes_guardioes_rs->search_rs(
        {
            'me.id' => $guard_id,
        }
    )->next or $c->reply_item_not_found();

    $row->update(
        {
            status     => 'removed_by_user',
            deleted_at => \'NOW()',
        }
    ) if $row->status ne 'removed_by_user';

    return 1;
}

sub cliente_edit_guardioes {
    my ($c, %opts) = @_;
    my $user_obj = $opts{user_obj} or confess 'missing user_obj';
    my $guard_id = $opts{id}       or confess 'missing id';
    my $nome     = $opts{nome}     or confess 'missing nome';

    my $row = $user_obj->clientes_guardioes_rs->search_rs(
        {
            'me.id'         => $guard_id,
            'me.deleted_at' => undef,
        }
    )->next or $c->reply_item_not_found();

    $row->update(
        {
            nome => $nome,
        }
    );

    return {
        message => 'Editado com sucesso!',
        data    => &_format_guard_row($c, $user_obj, $row),
    };
}

sub _parse_celular {
    my ($c, $celular) = @_;

    $celular = Number::Phone::Lib->new($celular =~ /^\+/ ? ($celular) : ('BR', $celular));
    $c->reply_invalid_param(
            'Não conseguimos decodificar o número enviado. Lembre-se de incluir o DDD para Brasil.'
          . "\nPara números internacionais inicie com +código-do-país.",
        'parser_error', 'celular'
    ) if !$celular || !$celular->is_valid();

    my $celular_national = $celular->format_using('National');

    my $is_mobile = $celular->is_mobile();
    my $code      = $celular->country_code();

    use DDP;
    p $ENV{GUARDS_ALLOWED_COUNTRY_CODES};
    $c->reply_invalid_param(
        sprintf(
            'O pais (%s %s %s) não está liberado para uso. Entre em contato com o suporte.',
            $celular->country_code,
            $celular->country  || '??',
            $celular->areaname || '??',
        ),
        'contry_not_allowed',
        'celular'
    ) if $ENV{GUARDS_ALLOWED_COUNTRY_CODES} && $ENV{GUARDS_ALLOWED_COUNTRY_CODES} !~ /,$code,/;

    # para todos os paises que eh possível verificar celular (brasil, italia, portugal,
    # incluir outros se vc souber que tem numeros de celulares padronizados
    # vou deixar passar qualquer numero que nao sejam numeros especiais
    if (!$is_mobile && $code !~ /^(55|39|351)$/) {

        $is_mobile
          = $celular->is_fixed_line()
          || $celular->is_government()
          || $celular->is_network_service()
          || $celular->is_drama()
          || $celular->is_tollfree()
          || $celular->is_pager() ? 0 : 1;
    }

    $c->reply_invalid_param(
        sprintf(
            'O número +%s %s não pode ser usado para envio de SMS. Use o número do celular do guardião.',
            $celular->country_code || '??',
            $celular_national
        ),
        'number_is_not_mobile',
        'celular'
    ) if !$is_mobile;

    my $celular_e164 = $celular->format_using('NationallyPreferredIntl');
    $celular_e164 =~ s/[^0-9\+]//g;

    if ($code ne '55') {
        $celular_national = '+' . $code . ' ' . $celular_national;
    }

    return ($celular_e164, $celular_national);
}

sub _format_guard_row {
    my ($c, $user_obj, $row) = @_;

    return {
        (map { $_ => $row->$_ } qw/id nome celular_formatted_as_national/),

        is_accepted => $row->status eq 'accepted'            ? 1 : 0,
        is_pending  => $row->status eq 'pending'             ? 1 : 0,
        is_expired  => $row->status eq 'expired_for_not_use' ? 1 : 0,

        created_at => $row->created_at->datetime(),
        expires_at => $row->expires_at->datetime(),

    };
}

sub cliente_list_guardioes {
    my ($c, %opts) = @_;

    my $user_obj = $opts{user_obj} or confess 'missing user_obj';

    $user_obj->clientes_guardioes_rs->expires_pending_invites();
    my $invites_max     = $user_obj->clientes_guardioes_rs->max_invites_count();
    my $remaing_invites = $invites_max - $user_obj->clientes_guardioes_rs->used_invites_count();

    my $filtered_rs = $user_obj->clientes_guardioes_rs->search_rs(
        {
            '-or' => [
                {'me.status'     => {in   => [qw/pending accepted expired_for_not_use/]}},
                {'me.refused_at' => {'!=' => undef}}
            ]
        },
        {order_by => [qw/me.status/, {'-desc' => 'me.created_at'}]}
    );

    my $by_status = {};
    while (my $r = $filtered_rs->next) {
        push $by_status->{$r->status()}->@*, $r;
    }

    my $config_map = {
        accepted => {
            header         => 'Guardiões',
            description    => 'Guardiões que recebem seus pedidos de socorro.',
            delete_warning => '',
            can_resend     => 0,
            layout         => 'accepted',
        },
        pending => {
            header         => 'Pendentes',
            description    => 'Guardiões que ainda não aceitaram seu convite.',
            delete_warning => '',
            can_resend     => 0,
            layout         => 'pending',
        },
        expired_for_not_use => {
            header         => 'Convites expirados',
            description    => 'Convites não podem mais serem aceitos aceitos, convite novamente',
            delete_warning => '',
            can_resend     => 1,
            layout         => 'pending',
        },
        refused => {
            header => 'Convites recusados',
            description =>
              'Convite recusado! O guardião ainda pode aceitar o convite usando o mesmo link. Use o botão 🗑️ para cancelar o convite.',
            delete_warning =>
              'Após apagar um convite recusado, você não poderá convidar este número por até 7 dias.',
            can_resend => 0,
            layout     => 'pending',
        },
    };
    my @guards;

    for my $type (qw/accepted pending expired_for_not_use refused/) {

        my $config = $config_map->{$type};

        my @rows = $by_status->{$type}->@*;

        next if @rows == 0 && $type =~ /^(expired_for_not_use|refused)$/;

        push @guards, {
            meta => $config,
            rows => [
                map {
                    +{
                        id       => $_->id(),
                        nome     => $_->nome(),
                        celular  => $_->celular_formatted_as_national(),
                        subtexto => $_->subtexto(),
                    }
                } @rows
            ],
        };


    }

    return {
        remaing_invites => $remaing_invites,
        invites_max     => $invites_max,
        guards          => \@guards

    };
}

sub cliente_alert_guards {
    my ($c, %opts) = @_;

    my $user_obj = $opts{user_obj} or confess 'missing user_obj';

    my %extra_db;
    my $regex = qr/^-?\d{1,2}(?:\.\d{1,15})?$/a;
    for my $field (qw/gps_lat gps_long/) {
        next unless defined $opts{$field};

        if ($opts{$field} !~ $regex) {
            $c->reply_invalid_param(
                "$field não passa na regexp: $regex",
                'gps_position_invalid',
                $field
            );
        }
        $extra_db{$field} = $opts{$field};
    }

    # precisa ter os dois, se nao limpa o outro.
    if (   (defined $extra_db{gps_long} && !defined $extra_db{gps_lat})
        || (defined $extra_db{gps_lat} && !defined $extra_db{gps_long}))
    {
        delete $extra_db{gps_long};
        delete $extra_db{gps_lat};
    }

    my $meta = {ip => $c->remote_addr()};

    my $alert = $user_obj->cliente_ativacoes_panicoes->create(
        {
            meta       => to_json($meta),
            created_at => \'NOW()',

            %extra_db,
        }
    );
    slog_info('New panic activation alert number %d', $alert->id);

    my $limit_per_minute = $ENV{MAX_GUARD_ALERT_PER_MINUTE} || 1;
    my $key              = 'GuardAlertsMinute:' . $user_obj->id;
    my $reqcount         = $c->kv()->local_get_count_and_inc(key => $key, expires => 60);
    if ($reqcount >= $limit_per_minute) {
        die {
            error   => 'too_many_alerts',
            message => 'Os alertas já foram enviados no último minuto!',
            status  => 400,
        };
    }

    my $limit_per_day = $ENV{MAX_GUARD_ALERT_PER_24H} || 5;
    my $key           = 'GuardAlerts24h:' . $user_obj->id;
    my $reqcount      = $c->kv()->local_get_count_and_inc(key => $key, expires => 86400);
    if ($reqcount >= $limit_per_day) {
        die {
            error   => 'too_many_alerts',
            message => 'Você atingiu o limite de alertas no período de 24h.',
            status  => 400,
        };
    }

    my @celulares = $user_obj->clientes_guardioes_rs->search_rs(
        {
            'me.status'     => 'accepted',
            'me.deleted_at' => undef,
        },
        {
            columns      => [qw/id celular_e164/],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        }
    )->all;

    my $message_prepend = 'PenhaS: ';
    my $message_link    = ' adicionou um pedido de socorro. Entre em contato. ';

    if ($alert->gps_lat && $alert->gps_long) {
        $message_link .= 'Veja sua localizaçāo no mapa: https://google.com/maps?q='
          . join(',', substr($alert->gps_lat, 0, 11), substr($alert->gps_long, 0, 11));
    }
    else {
        $message_link .= 'A localizaçāo não foi recebida.';
    }

    # 130 no lugar de 140, pois o minimo reservado pro nome sao 10 chars
    my $remaining_chars = 130 - length($message_prepend . $message_link);

    # se ficou menor, nao tem jeito, vamo ser dois SMS..
    $remaining_chars += 140 if $remaining_chars < 0;

    my $message_sms = $message_prepend . substr($user_obj->nome_completo, 0, $remaining_chars) . $message_link;

    my $sms_enviados = 0;

    foreach my $guard (@celulares) {
        my $number = $guard->{celular_e164};
        my $job_id = $c->minion->enqueue(
            'send_sms',
            [
                $number,
                $message_sms,
            ] => {
                notes    => {alert_id => $alert->id},
                attempts => 2,
                priority => 10,
            }
        );
        slog_info('send_sms %s job id: %s', $number, $job_id);
        $sms_enviados++;
    }

    $alert->update(
        {
            sms_enviados  => $sms_enviados,
            alert_sent_to => to_json({celulares => \@celulares}),
        }
    );

    return {
        message => (
              $sms_enviados > 1  ? sprintf('Alerta disparado com sucesso para %d guardiões.', $sms_enviados)
            : $sms_enviados == 1 ? 'Alerta disparado com sucesso para 1 guardião.'
            :                      'Não há guardiões cadastros! Nenhum alerta foi enviado.'
        )
    };
}

1;
