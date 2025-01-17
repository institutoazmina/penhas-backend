#!/bin/bash

if ! command -v bun &> /dev/null
then
    echo "'bun' is not available. Trying to install now... if fails, check out https://bun.sh/"
    curl -fsSL https://bun.sh/install | bash
fi

bun parse.ts
