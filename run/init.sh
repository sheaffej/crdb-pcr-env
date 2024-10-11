#!/usr/bin/env bash 

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Check required software is installed
cockroach &>/dev/null
if [[ $? -ne 0 ]]; then
    echo
    echo "Please install the Cockroach CLI and make sure 'cockroach sql' executes successfully"
    exit 1
fi

docker compose &>/dev/null
if [[ $? -eq 0 ]]; then
    COMPOSE_CMD="docker compose"
else
    docker-compose &>/dev/null
    if [[ $? -eq 0 ]]; then
        COMPOSE_CMD="docker-compose"
    fi
fi

if [[ -z $COMPOSE_CMD ]]; then
    echo
    echo "Please install Docker Compose, and make sure either 'docker-compose' or 'docker compose' executes successfully"
    exit 1
fi

# Bring up the docker containers
cd ${MYDIR}/..
$COMPOSE_CMD up -d --remove-orphans

# Wait for the containers to start
echo
echo -n "Waiting for nodes to be ready"
for I in `seq 1 10`; do
    sleep 1
    echo -n '.'
done
echo; echo
echo "Setting up PCR"

# Prep the Primary
cat <<EOF | docker exec -i crdb-pcr-env-standby1-1 cockroach sql --url 'postgresql://root@crdb-primary:26257/?options=-ccluster=system&sslmode=disable'
   SET CLUSTER SETTING cluster.organization = 'John Sheaffer CRL';
   SET CLUSTER SETTING enterprise.license = 'crl-0-EIDs07sGGAIiEUpvaG4gU2hlYWZmZXIgQ1JM';
   CREATE USER standby;
   GRANT ADMIN TO standby;
EOF


# Prep the Standby and start replication
cat <<EOF | docker exec -i crdb-pcr-env-standby1-1 cockroach sql --url 'postgresql://root@crdb-standby1:26257/?options=-ccluster=system&sslmode=disable'
    SET CLUSTER SETTING cluster.organization = 'John Sheaffer CRL';
    SET CLUSTER SETTING enterprise.license = 'crl-0-EIDs07sGGAIiEUpvaG4gU2hlYWZmZXIgQ1JM';
    CREATE USER standby;
    GRANT ADMIN TO standby;

    CREATE VIRTUAL CLUSTER application LIKE template
    FROM REPLICATION OF application
    ON 'postgresql://standby@crdb-primary:26257/?options=-ccluster=system&sslmode=disable';
EOF


# Show replication status
echo
cat <<EOF | docker exec -i crdb-pcr-env-standby1-1 cockroach sql --format table --url 'postgresql://root@crdb-standby1:26257/?options=-ccluster=system&sslmode=disable'
    SHOW VIRTUAL CLUSTER application WITH REPLICATION STATUS;
EOF

# Wait for replication to start
echo
echo -n "Waiting for replication to finish initialization"
for I in `seq 1 20`; do
    sleep 1
    echo -n '.'
done
echo

# Show replication status again
echo
cat <<EOF | docker exec -i crdb-pcr-env-standby1-1 cockroach sql --format table --url 'postgresql://root@crdb-standby1:26257/?options=-ccluster=system&sslmode=disable'
    SHOW VIRTUAL CLUSTER application WITH REPLICATION STATUS;
EOF

# Open DB consoles
open http://localhost:8080
open http://localhost:8081