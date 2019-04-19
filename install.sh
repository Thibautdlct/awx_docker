#!/bin/bash
echo "$(cat files/ASCII.txt)"
echo -e "\033[31mInstallation des prérequis\033[0m"
setenforce 0
yum install -y epel-release
echo "Installation de Ansible"
yum install -y yum-utils device-mapper-persistent-data lvm2 ansible python-devel python-pip python-docker-py vim-enhanced
echo "Installation de docker"
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce -y
systemctl start docker
systemctl enable docker
pip install docker-compose
pip uninstall docker docker-py -y
pip install docker-compose
echo -e "\033[31mInstallation de AWX (~5mins)\033[0m"
cd /root/awx_docker/ && git clone https://github.com/ansible/awx.git
yes | cp -rf /root/awx_docker/files/inventory /root/awx_docker/awx/installer/

cd /root/awx_docker/awx/installer && ansible-playbook -i inventory install.yml -vv
echo "Configuration de nginx"
SERVER=$(hostname)
cat /root/awx_docker/files/nginx.conf | sed -e "s/server_name _;/server_name $SERVER;/g"
docker cp /root/awx_docker/files/nginx.conf awx_web:/etc/nginx/nginx.conf
docker container exec awx_web mkdir /etc/nginx/certs
echo "Création d'un certificat"
cd /root/awx_docker/
openssl genrsa -out server.key 2048
openssl rsa -in server.key -out server.key
openssl req -sha256 -new -key server.key -out server.csr -subj /CN=awx.local.test
openssl x509 -req -sha256 -days 3650 -in server.csr -signkey server.key -out server.crt
docker cp /root/awx_docker/server.csr awx_web:/etc/nginx/certs
docker cp /root/awx_docker/server.key awx_web:/etc/nginx/certs
docker cp /root/awx_docker/server.crt awx_web:/etc/nginx/certs
rm server*

echo -e "\033[31mRedémarrage des services Web (~2min)\033[0m"
docker container stop awx_web
sleep 10s
docker container start awx_web
sleep 100s

echo -e "\033[31mCréation de l'utilisateur Ansible\033[0m"
useradd ansible

read -p "Faut-il créer une clé RSA ? (y/n)" -n 1 -r
echo #rep
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Création d'une clé RSA"
    sudo -u ansible ssh-keygen -t rsa -b 2048 -f /home/ansible/.ssh/id_rsa -q -P ""
fi
echo 'ansible ALL=(ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo

echo -e "\033[31mInstallation terminée\033[0m"
echo ""

ip4=$(hostname  -I | cut -f1 -d' ')
echo -e "\033[32mConnectez vous à l'adresse https://$ip4/#/login\033[0m"
