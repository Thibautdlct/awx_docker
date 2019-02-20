#!/bin/bash
echo "restauration postgres"
now=$(date +"%d_%m_%Y")
echo "restauration des données du $now"
echo "stop machines"
for i in postgres memcached rabbitmq awx_web awx_task; do docker stop $i; done
echo "restore $now backup"
docker run --rm --volumes-from postgres -v /root/backups/volume/:/tmp postgres tar xf /tmp/postgres-$now.tar
echo "start machines"
for i in postgres memcached rabbitmq awx_web awx_task; do docker start $i; done
echo "fini"
