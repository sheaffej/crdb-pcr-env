# crdb-pcr-env

This respository contains scripts to demo CockroachDB Physical Cluster Replication (PCR) using a local Docker environment.

These scripts are writen in bash, for use on a MacOS or Linux system. These scripts have not been tested on other operating systems, but could easily be modifed to work on any environment since all the import parts work within Docker containers.

## Prerequisites
To run this demo, you need to have installed locally on your system:
- A Docker engine (Docker Desktop, Colima, Podman, etc)
- Docker Compose (either `docker-compose` or `docker compose`)
- The `cockroach` binary for command-line use (i.e. `cockroach sql ...`)

## Installation
Clone this repository
```
git clone https://github.com/sheaffej/crdb-fetch-demo.git
cd crdb-fetch-demo
```


Then there are 4 bash scripts to execute the demo.
```
# Build the PCR environment
run/init.sh

# Import the movr sampld data into the primary cluster node
run/import.sh

# Run a continous workload on the primary cluster node using `dbworkload`
run/workload.sh

# Destroy the environment and release all resources
run/destroy.sh
```