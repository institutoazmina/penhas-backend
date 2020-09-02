#<<<
use utf8;
package Penhas::Schema2::Result::DirectusUser;

# Criado manualmente, pois só precisamos dessa tabela e só de alguams colunas

use strict;
use warnings;
__PACKAGE__->load_components("PassphraseColumn");

use base 'Penhas::Schema::Base';
__PACKAGE__->table("directus_users");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "status",
  {
    data_type => "varchar",
    default_value => "draft",
    is_nullable => 0,
    size => 16,
  },
  "role",
  { data_type => "integer", is_nullable => 1 },
  "first_name",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "last_name",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "password",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("idx_users_email", ["email"]);
#>>>

__PACKAGE__->load_components("PassphraseColumn");
__PACKAGE__->remove_column("password");
__PACKAGE__->add_column(
    password => {
        data_type               => "text",
        passphrase              => 'crypt',
        passphrase_class        => "BlowfishCrypt",
        passphrase_args         => {cost => 8, salt_random => 1,},
        passphrase_check_method => "check_password",
        is_nullable             => 0,
    },
);

sub get_column {
    my ($self, $col, @other) = @_;

    return $self->SUPER::get_column($col, @other) if $col ne 'password';

    my $text = $self->SUPER::get_column($col, @other);
    $text =~ s{\$2y\$}{\$2a\$};
    return $text;
}


1;
