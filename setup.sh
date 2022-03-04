#!/bin/bash

## Atualizar o linux
sudo apt update -y && sudo apt upgrade -y

#Instalar sshpass
sudo apt-get install sshpass -y

## Instalar o docker
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt install docker docker.io -y
sudo usermod -aG docker vagrant

## Instalar o docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

## Auto-completion do docker-compose
sudo curl \
    -L https://raw.githubusercontent.com/docker/compose/1.29.2/contrib/completion/bash/docker-compose \
    -o /etc/bash_completion.d/docker-compose

##Liberar acesso ssh sem necessitar troca de chaves no vagrant, login inicial: vagrant vagrant
sudo su -
sleep 5
file=/etc/ssh/sshd_config
cp -p $file $file.old &&
while read key other
do
 case $key in
 PasswordAuthentication) other=yes;;
 PubkeyAuthentication) other=yes;;
 esac
 echo "$key $other"
done < $file.old > $file
systemctl restart sshd

#Instalar, configurar o zabbix agent e habilitar no boot
sudo wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-1+ubuntu$(lsb_release -rs)_all.deb && \
sudo dpkg -i zabbix-release_6.0-1+ubuntu$(lsb_release -rs)_all.deb && \
sudo apt update -y && sudo apt -y install zabbix-agent -y
sleep 5
cat > zabbix_agentd.conf << EOF
PidFile=/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=192.168.1.13
ServerActive=192.168.1.13
Hostname=$HOSTNAME
Include=/etc/zabbix/zabbix_agentd.d/*.conf
EOF
sudo mv zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf
sudo systemctl restart zabbix-agent.service
sudo systemctl enable zabbix-agent.service

##Instalar o ansible caso a vm seja master
if
        [ "$HOSTNAME" = master ];
then
        sudo apt install ansible -y
fi

##Instalar o gitlab caso a vm seja gitlab
if
        [ "$HOSTNAME" = gitlab ];
then
mkdir /home/vagrant/gitlab
export GITLAB_HOME=/srv/gitlab
export GITLAB_HOME=/home/vagrant/gitlab
cd $GITLAB_HOME

cat > docker-compose.yml << EOF
version: '3.5'
services:
 gitlab:
  image: 'gitlab/gitlab-ee:latest'
  restart: always
  hostname: 'gitlab.weslao.com'
  environment:
    GITLAB_OMNIBUS_CONFIG: |
      external_url 'http://gitlab.weslao.com'
      # Add any other gitlab.rb configuration here, each on its own line
  ports:
    - '80:80'
    - '443:443'
    - '2224:2224'
  volumes:
    - '$GITLAB_HOME/config:/etc/gitlab'
    - '$GITLAB_HOME/logs:/var/log/gitlab'
    - '$GITLAB_HOME/data:/var/opt/gitlab'
EOF

docker-compose up -d
#Senha inicial: docker exec -it gitlab_gitlab_1 cat /etc/gitlab/initial_root_password
fi

#Inicializar zabbix no boot senha inicial: Admin zabbix
if
        [ "$HOSTNAME" = zabbix ];
then
       cd zabbix-docker && \
       docker-compose -f docker-compose_v3_ubuntu_mysql_latest.yaml up -d
fi
