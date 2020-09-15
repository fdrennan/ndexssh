#!/bin/bash
ls -lah
apt-get update -y
git clone https://github.com/fdrennan/docker_pull_postgres.git || echo '\nDirectory already exists..\n'
# ls docker_pull_postgres
docker-compose -f docker_pull_postgres/docker-compose.yml pull
docker-compose -f docker_pull_postgres/docker-compose.yml down
docker-compose -f docker_pull_postgres/docker-compose.yml up -d
docker container ls
