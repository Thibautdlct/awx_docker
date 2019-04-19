#!/bin/bash
echo "$(cat files/ASCII.txt)"
echo -e "\033[31mInstallation des prérequis\033[0m"
setenforce 0 > /dev/null 2>&1
yum install -y epel-release > /dev/null 2>&1
echo "Installation de Ansible"
yum install -y yum-utils device-mapper-persistent-data lvm2 ansible python-devel python-pip python-docker-py vim-enhanced > /dev/null 2>&1
echo "Installation de docker"
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo > /dev/null 2>&1
yum install docker-ce -y > /dev/null 2>&1
systemctl start docker > /dev/null 2>&1
systemctl enable docker > /dev/null 2>&1

echo -e "\033[31mInstallation de AWX (~5mins)\033[0m"
cd /root/awx_docker/ && git clone https://github.com/Thibautdlct/awx.git > /dev/null 2>&1
yes | cp -rf /root/awx_docker/files/inventory /root/awx_docker/awx/installer/ > /dev/null 2>&1

cd /root/awx_docker/awx/installer && ansible-playbook -i inventory install.yml -vv > /dev/null 2>&1

echo -e "Recherche de mise à jour"
docker stop awx_task
docker rm awx_task
docker rmi ansible/awx_task

docker stop awx_web
docker rm awx_web
docker rmi ansible/aws_web
git pull
cd /root/awx_docker/awx/installer
# Review inventory
ansible-playbook -i inventory install.yml

echo "Configuration de nginx"
SERVER=$(hostname)
cat /root/awx_docker/files/nginx.conf | sed -e "s/server_name _;/server_name $SERVER;/g" > /dev/null 2>&1
docker cp /root/awx_docker/files/nginx.conf awx_web:/etc/nginx/nginx.conf > /dev/null 2>&1
docker container exec awx_web mkdir /etc/nginx/certs > /dev/null 2>&1
echo "Création d'un certificat"
cd /root/awx_docker/ > /dev/null 2>&1
openssl genrsa -out server.key 2048 > /dev/null 2>&1
openssl rsa -in server.key -out server.key > /dev/null 2>&1
openssl req -sha256 -new -key server.key -out server.csr -subj /CN=awx.local.test > /dev/null 2>&1
openssl x509 -req -sha256 -days 3650 -in server.csr -signkey server.key -out server.crt > /dev/null 2>&1
docker cp /root/awx_docker/server.csr awx_web:/etc/nginx/certs
docker cp /root/awx_docker/server.key awx_web:/etc/nginx/certs
docker cp /root/awx_docker/server.crt awx_web:/etc/nginx/certs
rm server*

echo -e "\033[31mRedémarrage des services Web (~2min)\033[0m"
docker container stop awx_web > /dev/null 2>&1
sleep 10s
docker container start awx_web > /dev/null 2>&1
sleep 100s

echo -e "\033[31mCréation de l'utilisateur Ansible\033[0m"
useradd ansible > /dev/null 2>&1

read -p "Faut-il créer une clé RSA ? (y/n)" -n 1 -r
echo #rep
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Création d'une clé RSA"
    sudo -u ansible ssh-keygen -t rsa -b 2048 -f /home/ansible/.ssh/id_rsa -q -P "" > /dev/null 2>&1
fi
echo 'ansible ALL=(ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo > /dev/null 2>&1

echo -e "\033[31mInstallation terminée\033[0m"
echo ""

ip4=$(hostname  -I | cut -f1 -d' ') > /dev/null 2>&1
echo -e "\033[32mConnectez vous à l'adresse https://$ip4/#/login\033[0m"
