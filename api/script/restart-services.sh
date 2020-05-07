#!/bin/bash -e
cd /src;
source /home/app/perl5/perlbrew/etc/bashrc;

if [ -f envfile_local.sh ]; then
    source envfile_local.sh
else
    source envfile.sh
fi

export PENHAS_API_LOG_DIR=/data/log/
export SQITCH_DEPLOY=${SQITCH_DEPLOY:=docker}

cpanm -nv . --installdeps
sqitch deploy -t $SQITCH_DEPLOY

LIBEV_FLAGS=4 APP_NAME=API LIBEV_FLAGS=4 MOJO_IOLOOP_DEBUG=1 hypnotoad script/penhas-api