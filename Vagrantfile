# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "carsten-sc/centos8-stream-core"
  config.vm.box_version = "0.0.1"
  config.vm.box_check_update = true
  config.vm.hostname = "graphite"
  config.vm.network "forwarded_port", guest: 3000, host: 3000
  config.vm.network "forwarded_port", guest: 80, host: 80
  # carbon port
  config.vm.network "forwarded_port", guest: 2003, host: 2003
  config.vm.network :private_network, ip: "192.168.66.77"
  #config.vm.network "bridged"

  config.vm.synced_folder "exchange", "/exchange"
  config.vm.synced_folder "system", "/system"

  config.ssh.username = "centos"
  config.ssh.password = "centos"

  config.vm.provider "virtualbox" do |vb|
      vb.cpus = 2
      vb.memory = "2048"
  end
 
  config.vm.provision "shell", inline: <<-SHELL
      #export no_auto_import = true
      #export no_initial_import = true
      yum update -y
<<<<<<< HEAD
      ls /system
=======
>>>>>>> b441a4ac003d94da50f748c288c1eb98b250e1a1
      chmod -R +x /system/centos8/{*.py,*.sh} || true
      # change line endings to lf
      sed -i 's/\r$//' /system/centos8/{*.sh,*.py} || true
      cd /system/centos8
      ./setup-graphite.sh
      ./setup-system.sh
      ./setup-postinstall.sh
      echo done!
  SHELL

  #config.ssh.private_key_path = "~/.ssh/id_rsa"
  #config.ssh.forward_agent = true
  #config.ssh.username = "centos"
  #config.ssh.keys_only = true
  config.ssh.insert_key = false
end
