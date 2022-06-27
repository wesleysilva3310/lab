#!/bin/bash

# Updating linux
echo "Updating Linux"
sudo apt update -y && sudo apt upgrade -y
echo "Linux updated!"

# Install sshpass
echo "Installing sshpass"
sudo apt-get install sshpass -y
echo "Installation Complete!"

# Instalar o docker
if
        [ "$HOSTNAME" != kmaster ] && [ "$HOSTNAME" != kworker1 ] && [ "$HOSTNAME" != kworker2 ];
then
echo "Installing docker"
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt install docker docker.io -y
sudo usermod -aG docker vagrant
echo "Installation Complete!"

# Installing docker-compose
echo "Installing docker compose"
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
sudo curl \
    -L https://raw.githubusercontent.com/docker/compose/1.29.2/contrib/completion/bash/docker-compose \
    -o /etc/bash_completion.d/docker-compose
echo "Installation Complete!"
fi

# ssh access without need key pairs. initial login: vagrant vagrant
echo "Configuring ssh access"
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
echo "Configuration complete!"


# Configuring dns server
if [ "$HOSTNAME" = dnsserver ];
then
sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved
sudo unlink /etc/resolv.conf
echo nameserver 8.8.8.8 | sudo tee /etc/resolv.conf
sudo apt install dnsmasq
sudo systemctl restart dnsmasq
sudo cat >>/etc/hosts<<EOF
192.168.1.10     gitlab.weslao.com
192.168.1.10     gitlab
192.168.1.100    kmaster
192.168.1.105    dnsserver
192.168.1.101    kworker1
192.168.1.102    kworker2
192.168.1.11     graylog
192.168.1.17     grafana
192.168.1.12     jenkins
192.168.1.13     zabbix
192.168.1.15     rundeck
192.168.1.20     kafka
EOF
fi

#Adding dns server to resolv.conf
sudo cat >>/etc/resolv.conf<<EOF
nameserver 192.168.1.105
EOF

# Installing and configuring zabbix agent
echo "Installing and configuring zabbix agent"
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
sudo rm -f zabbix-release_6.0-1+ubuntu20.04_all.deb
echo "Configuration complete!"

# Installing ansible on kmaster vm
if
        [ "$HOSTNAME" = kmaster ];
then
        echo "Installing ansible on kmaster VM"
        sudo apt install ansible -y
        echo "Installation complete!"
fi

# installing helm on kmaster vm
if
        [ "$HOSTNAME" = kmaster ];
then
        echo "Installing helm on kmaster VM"
        wget https://get.helm.sh/helm-v3.9.0-linux-amd64.tar.gz
        tar -zxvf helm-v3.9.0-linux-amd64.tar.gz
        mv linux-amd64/helm /usr/local/bin/helm
        rm -Rf helm-v3.9.0-linux-amd64.tar.gz linux-amd64
        echo "Installation complete!"
fi

# Installing gitlab on gitlab vm
if
        [ "$HOSTNAME" = gitlab ];
then
echo "Installing gitlab on gitlab VM"
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
cd gitlab && docker-compose up -d
# Initial password: docker exec -it gitlab_gitlab_1 cat /etc/gitlab/initial_root_password
echo "Installation complete!"
fi

# Starting zabbix on boot, initial password: Admin zabbix
if
        [ "$HOSTNAME" = zabbix ];
then
        echo "Initialazing Zabbix"
       cd zabbix-docker && \
       docker-compose -f docker-compose_v3_ubuntu_mysql_latest.yaml up -d
       echo "Zabbix up!"
fi

#Kubernetes configuration

if 
        [ "$HOSTNAME" = kmaster ] || [ "$HOSTNAME" = kworker1 ] || [ "$HOSTNAME" = kworker2 ];
then
echo "[k8s TASK 1] Disable and turn off SWAP"
sed -i '/swap/d' /etc/fstab
swapoff -a

echo "[k8s TASK 2] Stop and Disable firewall"
systemctl disable --now ufw >/dev/null 2>&1

echo "[k8s TASK 3] Enable and Load Kernel modules"
cat >>/etc/modules-load.d/containerd.conf<<END1
overlay
br_netfilter
END1
modprobe overlay
modprobe br_netfilter

echo "[k8s TASK 4] Add Kernel settings"
cat >>/etc/sysctl.d/kubernetes.conf<<END2
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
END2
sysctl --system >/dev/null 2>&1

echo "[k8s TASK 5] Install containerd runtime"
apt update -qq >/dev/null 2>&1
apt install -qq -y containerd apt-transport-https >/dev/null 2>&1
mkdir /etc/containerd
containerd config default > /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd >/dev/null 2>&1

echo "[k8s TASK 6] Add apt repo for kubernetes"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - >/dev/null 2>&1
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main" >/dev/null 2>&1

echo "[k8s TASK 7] Install Kubernetes components (kubeadm, kubelet and kubectl)"
apt install -qq -y kubeadm=1.22.0-00 kubelet=1.22.0-00 kubectl=1.22.0-00 >/dev/null 2>&1

echo "[k8s TASK 8] Enable ssh password authentication"
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
systemctl reload sshd

echo "[k8s TASK 9] Set root password"
echo -e "kubeadmin\nkubeadmin" | passwd root >/dev/null 2>&1
echo "export TERM=xterm" >> /etc/bash.bashrc

echo "[k8s TASK 10] Update /etc/hosts file"
cat >>/etc/hosts<<END3
192.168.1.100  kmaster
192.168.1.101   kworker1
192.168.1.102  kworker2
END3

echo "K8s bootstrap configuration complete!"
fi
#Creating script to add kube dir and permissions
if
        [ "$HOSTNAME" = kmaster ];
then
echo "[k8s kmaster TASK 1] Pull required containers"
kubeadm config images pull >/dev/null 2>&1

echo "[k8s kmaster TASK 2] Initialize Kubernetes Cluster"
kubeadm init --apiserver-advertise-address=192.168.1.100 --pod-network-cidr=192.168.0.0/16 >> /root/kubeinit.log 2>/dev/null

echo "[k8s kmaster TASK 3] Deploy Calico network"
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.18/manifests/calico.yaml >/dev/null 2>&1

echo "[k8s kmaster TASK 4] Generate and save cluster join command to /joincluster.sh"
kubeadm token create --print-join-command > /joincluster.sh 2>/dev/null
sleep 30

#run ping on workers before integrate them!

cat > kubemastersetup.sh << END4
#run as vagrant user
echo "Creating kube dir and permissions"
 mkdir -p $HOME/.kube
 sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
 sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo "k8s kmaster configuration complete!"
END4
fi

#Creating script to k8s workers to be added to cluster
if 
        [ "$HOSTNAME" = kworker1 ] || [ "$HOSTNAME" = kworker2 ];
then
#run this only when creating the VM for the first time, using root user
cat > /usr/joincluster.sh << EOF
echo "Join node to Kubernetes Cluster"
apt install -qq -y sshpass >/dev/null 2>&1
sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no kmaster:/joincluster.sh /joincluster.sh 2>/dev/null
bash /joincluster.sh >/dev/null 2>&1
EOF
fi

# Install docker on k8s nodes
if
        [ "$HOSTNAME" = kmaster ];
then
echo "Installing docker"
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt install docker docker.io -y
sudo usermod -aG docker vagrant
echo "Installation Complete!"

# Installing docker-compose
echo "Installing docker compose"
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
sudo curl \
    -L https://raw.githubusercontent.com/docker/compose/1.29.2/contrib/completion/bash/docker-compose \
    -o /etc/bash_completion.d/docker-compose
echo "Installation Complete!"
fi

# Install Jenkins
if
        [ "$HOSTNAME" = jenkins ];
then

mkdir jenkins && cd jenkins
cat > docker-compose.yml << EOF
version: "3.9"

services:
  jenkins:
    image: jenkins/jenkins:lts
    container_name: jenkins-server
    privileged: true
    hostname: jenkinsserver
    user: root
    labels:
      com.example.description: "Jenkins-Server by DigitalAvenue.dev"
    ports: 
      - "8080:8080"
      - "50000:50000"
    networks:
      jenkins-net:
        aliases: 
          - jenkins-net
    volumes: 
     - jenkins-data:/var/jenkins_home
     - /var/run/docker.sock:/var/run/docker.sock
     
volumes: 
  jenkins-data:

networks:
  jenkins-net:
EOF

docker-compose up -d
fi

# Install Grafana
if
        [ "$HOSTNAME" = grafana ];
then
mkdir grafana && cd grafana
cat > docker-compose.yml << EOF
version: "3.5"

services:
  grafana:
    image: grafana/grafana:latest
    network_mode: "bridge"
    container_name: grafana
    volumes:
      - ~/grafana/data:/var/lib/grafana
    ports:
      - "3000:3000"
    restart: always
        #first login: admin:admin
EOF
docker-compose up -d && echo "Grafana up!"
sudo chown 472:472 ~/grafana/data
fi

# Install Graylog
if
        [ "$HOSTNAME" = graylog ];
then
mkdir graylog && cd graylog
cat > docker-compose.yml << EOF
version: '3'
services:
    # MongoDB: https://hub.docker.com/_/mongo/
    mongo:
      image: mongo:4.2
      networks:
        - graylog
    # Elasticsearch: https://www.elastic.co/guide/en/elasticsearch/reference/7.10/docker.html
    elasticsearch:
      image: docker.elastic.co/elasticsearch/elasticsearch-oss:7.10.2
      environment:
        - http.host=0.0.0.0
        - transport.host=localhost
        - network.host=0.0.0.0
        - "ES_JAVA_OPTS=-Dlog4j2.formatMsgNoLookups=true -Xms512m -Xmx512m"
      ulimits:
        memlock:
          soft: -1
          hard: -1
      deploy:
        resources:
          limits:
            memory: 1g
      networks:
        - graylog
    # Graylog: https://hub.docker.com/r/graylog/graylog/
    graylog:
      image: graylog/graylog:4.2
      environment:
        # CHANGE ME (must be at least 16 characters)!
        - GRAYLOG_PASSWORD_SECRET=somepasswordpepper
        # Password: admin
        - GRAYLOG_ROOT_PASSWORD_SHA2=8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918
        - GRAYLOG_HTTP_EXTERNAL_URI=http://192.168.1.11:9000/
      entrypoint: /usr/bin/tini -- wait-for-it elasticsearch:9200 --  /docker-entrypoint.sh
      networks:
        - graylog
      restart: always
      depends_on:
        - mongo
        - elasticsearch
      ports:
        # Graylog web interface and REST API
        - 9000:9000
        # Syslog TCP
        - 1514:1514
        # Syslog UDP
        - 1514:1514/udp
        # GELF TCP
        - 12201:12201
        # GELF UDP
        - 12201:12201/udp
networks:
    graylog:
      driver: bridge
EOF
docker-compose up -d && echo "graylog up!"
fi

#Adding Prometheus exporter

groupadd --system prometheus && echo "Group created."
useradd -s /sbin/nologin --system -g prometheus prometheus && echo "User created."
mkdir /var/lib/node && cd /var/lib/node/

wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz

tar xvf node_exporter-1.3.1.linux-amd64.tar.gz

cd node_exporter-1.3.1.linux-amd64

mv node_exporter ..

cat > /etc/systemd/system/node.service <<EOF
[Unit]
Description=Prometheus Node Exporter
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/var/lib/node/node_exporter

SyslogIdentifier=prometheus_node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

chown -R prometheus:prometheus /var/lib/node
chown -R prometheus:prometheus /var/lib/node/*
chmod -R 775 /var/lib/node
chmod -R 775 /var/lib/node/*
systemctl daemon-reload
systemctl enable node
systemctl start node
rm -Rf node_exporter-1.3.1.linux-amd64 node_exporter-1.3.1.linux-amd64.tar.gz
echo "Exporter installed as a service."

# Installing Vault
if
        [ "$HOSTNAME" = vault ];
then
sudo apt update && sudo apt install gpg
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vault
echo "Vault installed!"
fi