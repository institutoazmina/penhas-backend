#!/bin/bash -e
cp Makefile.PL docker/Makefile_local.PL

docker build -t azminas/penhas_api docker/
