#!/usr/bin/env bash

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd ${MYDIR}/..

docker compose &>/dev/null
if [[ $? -eq 0 ]]; then
    COMPOSE_CMD="docker compose"
else
    docker-compose &>/dev/null
    if [[ $? -eq 0 ]]; then
        COMPOSE_CMD="docker-compose"
    fi
fi

$COMPOSE_CMD down -v