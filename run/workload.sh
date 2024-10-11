#!/usr/bin/env bash

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

THREADS=4

cd ${MYDIR}/..
docker build -t crdb-pcr-demo-client .

docker run -it --rm \
--network crdb-pcr-env_default \
-e THREADS \
crdb-pcr-demo-client \
dbworkload run \
    -c ${THREADS} \
    -w /app/workload/movr.py \
    --uri 'postgresql://root@crdb-pcr-env-primary-1:26257/movr_demo?sslmode=disable'