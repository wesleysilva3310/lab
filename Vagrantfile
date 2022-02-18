Vagrant.configure("2") do |config|
#k8sMaster
  config.ssh.insert_key = false
  config.vm.define "master" do |master|
  master.vm.box = "ubuntu/focal64"
  master.vm.network "public_network", ip: "192.168.1.16"
  master.vm.hostname = "master"
  master.vm.provision "shell", path: "setup.sh"
end
#k8sSlave1
  config.ssh.insert_key = false
  config.vm.define "slave1" do |slave1|
  slave1.vm.box = "ubuntu/focal64"
  slave1.vm.network "public_network", ip: "192.168.1.17"
  slave1.vm.hostname = "slave1"
  slave1.vm.provision "shell", path: "setup.sh"
end
#k8sSlave2
  config.ssh.insert_key = false
  config.vm.define "slave2" do |slave2|
  slave2.vm.box = "ubuntu/focal64"
  slave2.vm.network "public_network", ip: "192.168.1.18"
  slave2.vm.hostname = "slave2"
  slave2.vm.provision "shell", path: "setup.sh"
end
#Gitlab
  config.ssh.insert_key = false
  config.vm.define "gitlab" do |gitlab|
  gitlab.vm.box = "ubuntu/focal64"
  gitlab.vm.network "public_network", ip: "192.168.1.10"
  gitlab.vm.hostname = "gitlab"
  gitlab.vm.provider :virtualbox do |gitlabsetup|
  gitlabsetup.memory = 9000
  gitlabsetup.cpus = 4
end
  gitlab.vm.network "forwarded_port", guest: 80, host: 80
  gitlab.vm.network "forwarded_port", guest: 443, host: 443
  gitlab.vm.network "forwarded_port", guest: 2222, host: 2222
  gitlab.vm.provision "shell", path: "setup.sh"
  gitlab.vm.provision "shell", path: "deployGitlab.sh"
end
#Graylog
  config.ssh.insert_key = false
  config.vm.define "graylog" do |graylog|
  graylog.vm.box = "ubuntu/focal64"
  graylog.vm.network "public_network", ip: "192.168.1.11"
  graylog.vm.hostname = "graylog"
  graylog.vm.provision "shell", path: "setup.sh"
end
 #Jenkins Server
  config.ssh.insert_key = false
  config.vm.define "jenkins" do |jenkins|
  jenkins.vm.box = "ubuntu/focal64"
  jenkins.vm.network "public_network", ip: "192.168.1.12"
  jenkins.vm.hostname = "jenkins"
  jenkins.vm.provision "shell", path: "setup.sh"
  jenkins.vm.network "forwarded_port", guest: 8080, host: 8081
  jenkins.vm.network "forwarded_port", guest: 50000, host: 50000
  jenkins.vm.network "forwarded_port", guest: 443, host: 444
end
#Zabbix Server
  config.ssh.insert_key = false
  config.vm.define "zabbix" do |zabbix|
  zabbix.vm.box = "ubuntu/focal64"
  zabbix.vm.network "public_network", ip: "192.168.1.13"
  zabbix.vm.hostname = "zabbix"
  zabbix.vm.provision "shell", path: "setup.sh"
  zabbix.vm.network "forwarded_port", guest: 8080, host: 8082
  zabbix.vm.network "forwarded_port", guest: 50000, host: 50001
  zabbix.vm.network "forwarded_port", guest: 443, host: 445
end
#Rundeck
  config.ssh.insert_key = false
  config.vm.define "rundeck" do |rundeck|
  rundeck.vm.box = "wesleysilva3310/rundeck"
  rundeck.vm.network "public_network", ip: "192.168.1.15"
  rundeck.vm.hostname = "rundeck"
  rundeck.vm.provision "shell", path: "setup.sh"
  rundeck.vm.network "forwarded_port", guest: 4440, host: 4440
  rundeck.vm.provider :virtualbox do |rundecksetup|
  rundecksetup.memory = 5000
  rundecksetup.cpus = 2
end
end
end
