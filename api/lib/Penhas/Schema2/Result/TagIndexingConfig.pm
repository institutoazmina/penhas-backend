#<<<
use utf8;
package Penhas::Schema2::Result::TagIndexingConfig;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("tag_indexing_config");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "tag_indexing_config_id_seq",
  },
  "created_on",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "status",
  {
    data_type => "varchar",
    default_value => "prod",
    is_nullable => 0,
    size => 20,
  },
  "tag_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "description",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 200,
  },
  "page_title_match",
  { data_type => "text", is_nullable => 1 },
  "page_title_not_match",
  { data_type => "text", is_nullable => 1 },
  "html_article_match",
  { data_type => "text", is_nullable => 1 },
  "html_article_not_match",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 200,
  },
  "page_description_match",
  { data_type => "text", is_nullable => 1 },
  "page_description_not_match",
  { data_type => "text", is_nullable => 1 },
  "url_match",
  { data_type => "text", is_nullable => 1 },
  "url_not_match",
  { data_type => "text", is_nullable => 1 },
  "rss_feed_tags_match",
  { data_type => "text", is_nullable => 1 },
  "rss_feed_tags_not_match",
  { data_type => "text", is_nullable => 1 },
  "rss_feed_content_match",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 200,
  },
  "rss_feed_content_not_match",
  { data_type => "text", is_nullable => 1 },
  "regexp",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "verified",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "error_msg",
  { data_type => "text", default_value => "", is_nullable => 1 },
  "verified_at",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "modified_on",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "owner",
  { data_type => "uuid", is_nullable => 1, size => 16 },
  "modified_by",
  { data_type => "uuid", is_nullable => 1, size => 16 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "tag",
  "Penhas::Schema2::Result::Tag",
  { id => "tag_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-24 16:42:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yxsQZfddoU01JaCBPjXTxA

# ALTER TABLE tag_indexing_config ADD FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE ON UPDATE cascade;

use Mojo::Util qw/trim/;
use Penhas::Logger;

sub compiled_regexp {
    my ($self) = @_;

    my $ret;
    my $is_regexp = $self->regexp;
    foreach my $field (
        qw/
        page_title_match
        page_title_not_match
        html_article_match
        html_article_not_match
        page_description_match
        page_description_not_match
        url_match
        url_not_match
        rss_feed_tags_match
        rss_feed_tags_not_match
        rss_feed_content_match
        rss_feed_content_not_match
        /
      )
    {
        my $value = $self->$field;
        next unless defined $value;
        $value = trim($value);
        next if $value eq '';

        my $regexp;

        if ($is_regexp) {
            log_debug("$field: testing regexp '$value'");

            my $test = eval {qr/$value/i};
            if ($@) {
                log_error("$field: regexp failed $@");
                $self->update(
                    {
                        error_msg   => "$field regexp error: $@",
                        verified    => '0',
                        modified_on => \'NOW()',
                        verified_at => \'NOW()'
                    }
                );
                return undef;
            }

            $regexp = qr/$value/iu;

        }
        else {
            my $new_regex = '(' . join('|', (map { '\b' . quotemeta(trim($_)) . '\b' } split qr{\|}, $value)) . ')';

            # evita regexp que da match pra tudo
            $new_regex =~ s{\|\|}{|}g;    # troca || por só |
            $new_regex =~ s{\|\)}{)};     # troca |) por só )
            $new_regex =~ s{\(\|}{(};     # troca (| pro só (

            $regexp = qr/$new_regex/iu;

        }

        log_debug("$field: compiled '$value' as $regexp");

        $ret->{$field} = $regexp;
    }

    if (!$self->verified) {

        # atualiza se sou a ultima versao
        $self->result_source->schema->resultset('TagIndexingConfig')->search(
            {
                id => $self->id,
                $self->get_column('modified_on')
                ? (
                    '-or' => [
                        {modified_on => undef},
                        {modified_on => {'<=' => $self->get_column('modified_on')}}
                    ],
                  )
                : ()
            }
        )->update(
            {
                error_msg   => '',
                verified    => '1',
                verified_at => \'NOW()'
            }
        );
    }

    return $ret;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
