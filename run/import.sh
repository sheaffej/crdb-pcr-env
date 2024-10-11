#!/usr/bin/env bash

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Create the schema on the primary
cockroach sql --url 'postgres://root@localhost:26257/defaultdb?sslmode=disable' -f ${MYDIR}/../workload/import.sql