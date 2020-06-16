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

export RESTART_TYPE='all'
if [ ! "$1" = "" ]; then
    export RESTART_TYPE=$1
fi
[ "$RESTART_TYPE" == "all" ] && RESTART_TYPE="api minion";

echo "restarting services [$RESTART_TYPE]...";

[[ $RESTART_TYPE == *"api"*       ]] && echo "hypnotoad..." && LIBEV_FLAGS=4 APP_NAME=API LIBEV_FLAGS=4 MOJO_IOLOOP_DEBUG=1 hypnotoad script/penhas-api

[[ $RESTART_TYPE == *"minion"*       ]] && pgrep -f 'minion worker$' | xargs -I % sh -c '{ echo "send kill to one more minion..."; kill -INT %; sleep 6; }'