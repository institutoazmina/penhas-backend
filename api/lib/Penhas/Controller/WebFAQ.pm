package Penhas::Controller::WebFAQ;
use Mojo::Base 'Penhas::Controller';
use Penhas::Utils qw/is_test/;
use DateTime;

sub apply_rps {
    my $c = shift;

    # limite de requests por segundo no IP
    # no maximo 100 request por hora
    my $remote_ip = $c->remote_addr();

    # recortando o IPV6 para apenas o prefixo (18 chars)
    $c->stash(apply_rps_on => 'WEB' . substr($remote_ip, 0, 18));
    $c->apply_request_per_second_limit(100, 3600);

    $c->stash(template => 'webfaq/index');

    return 1;
}

sub webfaq_index {
    my $c    = shift;
    $c->stash(
        texto_faq_index => $c->schema2->resultset('Configuraco')->get_column('texto_faq_index')->next()
    );

    my @faqs = $c->schema2->resultset('FaqTelaSobre')->search(
        {
            'me.status'             => 'published',
            'fts_categoria.status'  => 'published',
            'fts_categoria.is_test' => is_test() ? 1 : 0,
        },
        {
            join         => 'fts_categoria',
            columns      => [qw/fts_categoria.title fts_categoria.id me.id me.title/],
            order_by     => ['fts_categoria.sort', 'me.sort'],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    )->all();
    my $faqs_by_cat = [];

    my $current_cat = {};
    my $last_cat    = '';
    foreach my $faq (@faqs) {
        my $catname = $faq->{fts_categoria}{title};
        my $catid   = $faq->{fts_categoria}{id};
        my $item    = {id => $faq->{id}, title => $faq->{title}};

        if ($last_cat ne $catname) {
            $last_cat    = $catname;
            $current_cat = {
                title => $catname,
                id    => $catid,
                rows  => [],
            };
            push $faqs_by_cat->@*, $current_cat;
        }
        push $current_cat->{rows}->@*, $item;
    }
    $c->stash(faqs_by_cat => $faqs_by_cat);

    return $c->render(html => {});
}

sub webfaq_detail {
    my $c  = shift;
    my $id = $c->param('faq_id');
    if ($id =~ /^\d+$/) {
        $c->stash(
            faq => $c->schema2->resultset('FaqTelaSobre')->search(
                {
                    'me.status' => 'published',
                    'me.id'     => $id,
                },
                {
                    columns      => [qw/me.id me.title me.content_html/],
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator'
                }
            )->next
        );
    }

    $c->stash(template => 'webfaq/detail');

    return $c->render(html => {});
}

sub webfaq_botao_contato {
    my $c = shift;

    $c->stash(template => 'webfaq/botao_contato');

    return $c->render(html => {});
}

sub web_politica_privacidade {
    my $c = shift;

    $c->stash(
        texto => $c->schema2->resultset('Configuraco')->get_column('privacidade')->next()
    );

    $c->stash(template => 'webfaq/texto');

    return $c->render(html => {});
}

sub web_termos_de_uso {
    my $c = shift;

    $c->stash(
        texto => $c->schema2->resultset('Configuraco')->get_column('termos_de_uso')->next()
    );

    $c->stash(template => 'webfaq/texto');

    return $c->render(html => {});
}


1;
