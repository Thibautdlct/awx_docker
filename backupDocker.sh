#!/bin/bash
echo "backup volume postgres"
now=$(date +"%d_%m_%Y")
echo $now
docker run --rm --volumes-from postgres -v /root/backups/volume:/backup postgres tar cf /backup/postgres-$now.tar /var
docker start postgres
echo "copie vers backup"
scp /root/backups/volume/postgres-$now.tar root@172.20.10.5:/root/backups/volume/
scp /home/ansible/.ssh/id_rsa root@172.20.10.5:/home/ansible/.ssh/id_rsa
scp /home/ansible/.ssh/id_rsa.pub root@172.20.10.5:/home/ansible/.ssh/id_rsa.pub
scp /home/ansible/.ssh/known_hosts root@172.20.10.5:/home/ansible/.ssh/known_hosts
echo "Fini"
