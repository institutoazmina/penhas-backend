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
             -o exclude='qr/directus/i' \ # -o constraint='qr/^(?:Table1|Table2)/i' \
             -o filter_generated_code='sub {my ( $type, $class, $text ) = @_; return "#<<<\n$text#>>>"; }' \
             Penhas::Schema2 \
             "dbi:mysql:dbname=${MYSQL_DBNAME};host=${MYSQL_HOST};port=${MYSQL_PORT}" $MYSQL_USER $MYSQL_PASSWORD



cd $CWD
