# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "carsten-sc/centos8-stream-core"
  config.vm.box_version = "0.0.1"
  config.vm.box_check_update = false
  config.vm.hostname = "graphite"
  config.vm.network "forwarded_port", guest: 3000, host: 80
  config.vm.network "forwarded_port", guest: 80, host: 3000
  # carbon port
  config.vm.network "forwarded_port", guest: 2003, host: 2003
  config.vm.network :private_network, ip: "192.168.3.2"
  #config.vm.network "bridged"

  config.vm.synced_folder "exchange", "/exchange"
  config.vm.synced_folder "../system", "/system"
  #config.vm.synced_folder "intern", "/intern"

  config.vm.provider "virtualbox" do |vb|
      vb.cpus = 2
      vb.memory = "2048"
      #vb.hwvirtex = "off"
  end
 
  config.vm.provision "shell", inline: <<-SHELL
      yum update -y
      cat /etc/fstab
      mount -a
      ls /system
      #chmod +x /scripts/*
      #sudo curl http://192.168.2.101:8000/graphite.sh > /root/graphite.sh
      #sudo chmod +x /root/graphite.sh
      #sudo /root/graphite.sh
      #sudo /scripts/graphite.sh
      echo done!
  SHELL

  config.ssh.private_key_path = "~/.ssh/id_rsa"
  config.ssh.forward_agent = true
  config.ssh.username = "centos"
  config.ssh.keys_only = true
  config.ssh.insert_key = false
end