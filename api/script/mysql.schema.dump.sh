#!/bin/bash -e
GIT_DIR=$(git rev-parse --show-toplevel)
CWD=$(pwd)
if [ -f envfile_local.sh ]; then
    source envfile_local.sh
else
    source envfile.sh
fi

if ! command -v dbicdump &> /dev/null
then
    echo "dbicdump could not be found, run cpanm -n DBIx::Class::Schema::Loader "
    exit
fi

cd $GIT_DIR/api/

dbicdump -o dump_directory=./lib \
             -Ilib \
             -o use_moose=0 \
             -o 'overwrite_modifications'=1 \
             -o 'generate_pod'=0 \
             -o result_base_class='Penhas::Schema::Base' \
             -o db_schema=public \
             -o exclude='qr/^(directus|_?antigo_)/i' \
             -o filter_generated_code='sub {my ( $type, $class, $text ) = @_; return "#<<<\n$text#>>>"; }' \
             Penhas::Schema2 \
             "dbi:Pg:dbname=${POSTGRESQL_DBNAME};host=${POSTGRESQL_HOST};port=${POSTGRESQL_PORT}" $POSTGRESQL_USER $POSTGRESQL_PASSWORD



cd $CWD
