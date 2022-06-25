ENV['VAGRANT_NO_PARALLEL'] = 'yes'

Vagrant.configure("2") do |config|

  # DNS Server
  config.vm.define "dnsserver" do |dns|
  
    dns.vm.box               = "generic/ubuntu2004"
    dns.vm.box_check_update  = false
    dns.vm.box_version       = "3.3.0"
    dns.vm.hostname          = "dnsserver"

    dns.vm.network "public_network", ip: "192.168.1.105"
    dns.vm.provision "shell", path: "setup.sh"
  end

  # Kubernetes Master Server
  config.vm.define "kmaster" do |node|
  
    node.vm.box               = "generic/ubuntu2004"
    node.vm.box_check_update  = false
    node.vm.box_version       = "3.3.0"
    node.vm.hostname          = "kmaster"

    node.vm.network "public_network", ip: "192.168.1.100"
  
    node.vm.provider :virtualbox do |v|
      v.name    = "kmaster"
      v.memory  = 4048
      v.cpus    =  2
    end
    node.vm.provision "shell", path: "setup.sh"
  
  end

  # Kubernetes Worker Nodes
  NodeCount = 2

  (1..NodeCount).each do |i|

    config.vm.define "kworker#{i}" do |node|

      node.vm.box               = "generic/ubuntu2004"
      node.vm.box_check_update  = false
      node.vm.box_version       = "3.3.0"
      node.vm.hostname          = "kworker#{i}"

      node.vm.network "public_network", ip: "192.168.1.10#{i}"

      node.vm.provider :virtualbox do |v|
        v.name    = "kworker#{i}"
        v.memory  = 4024
        v.cpus    = 1
      end
      node.vm.provision "shell", path: "setup.sh"
    end

  end
# Gitlab
  config.ssh.insert_key = false

  config.vm.define "gitlab" do |gitlab|

    gitlab.vm.box               = "ubuntu/focal64"
    gitlab.vm.hostname          = "gitlab"

    gitlab.vm.network "public_network", ip: "192.168.1.10"
    
    gitlab.vm.provider :virtualbox do |gitlabsetup|
        gitlabsetup.memory = 9000
        gitlabsetup.cpus = 4
        end

    gitlab.vm.network "forwarded_port", guest: 80, host: 80
    gitlab.vm.network "forwarded_port", guest: 443, host: 443
    gitlab.vm.network "forwarded_port", guest: 2224, host: 2224
    gitlab.vm.network "forwarded_port", guest: 5050, host: 5050
    gitlab.vm.provision "shell", path: "setup.sh"
end

# Graylog
  config.ssh.insert_key = false

  config.vm.define "graylog" do |graylog|

    graylog.vm.box              = "ubuntu/focal64"
    graylog.vm.hostname         = "graylog"

    graylog.vm.network "public_network", ip: "192.168.1.11"

    graylog.vm.provider :virtualbox do |graylogsetup|
      graylogsetup.memory = 3068
      graylogsetup.cpus = 4
      end

    graylog.vm.provision "shell", path: "setup.sh"
end

# Grafana / Prometheus / Alertmanager
config.ssh.insert_key = false

config.vm.define "grafana" do |grafana|

  grafana.vm.box              = "ubuntu/focal64"
  grafana.vm.hostname         = "grafana"

  grafana.vm.network "public_network", ip: "192.168.1.17"

  grafana.vm.provision "shell", path: "setup.sh"
end

# Jenkins Server
  config.ssh.insert_key = false

  config.vm.define "jenkins" do |jenkins|

    jenkins.vm.box              = "ubuntu/focal64"
    jenkins.vm.hostname         = "jenkins"

    jenkins.vm.network "public_network", ip: "192.168.1.12"

    jenkins.vm.provision "shell", path: "setup.sh"

    jenkins.vm.network "forwarded_port", guest: 8080, host: 8081
    jenkins.vm.network "forwarded_port", guest: 50000, host: 50000
    jenkins.vm.network "forwarded_port", guest: 443, host: 444
end

# Zabbix Server
  config.ssh.insert_key = false

  config.vm.define "zabbix" do |zabbix|

    zabbix.vm.box               = "wesleysilva3310/zabbix"
    zabbix.vm.hostname          = "zabbix"
    
    zabbix.vm.network "public_network", ip: "192.168.1.13"
  
    zabbix.vm.provision "shell", path: "setup.sh"

    zabbix.vm.network "forwarded_port", guest: 8080, host: 8082
    zabbix.vm.network "forwarded_port", guest: 50000, host: 50001
    zabbix.vm.network "forwarded_port", guest: 443, host: 445

  zabbix.vm.provider :virtualbox do |zabbixsetup|
    zabbixsetup.memory = 2048
  end
end
end