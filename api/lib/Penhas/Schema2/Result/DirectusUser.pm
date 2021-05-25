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

use feature 'state';
use Crypt::Passphrase::Argon2;

sub check_password {
    my ($self, $password) = @_;

    state $passphrase = Crypt::Passphrase::Argon2->new();

    return $passphrase->verify_password($password, $self->get_column('password'));
}

1;
