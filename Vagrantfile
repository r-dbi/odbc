# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrant virtual environments for nanodbc developers and users

$provision_script = <<SCRIPT
export DEBIAN_FRONTEND="noninteractive"
sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
sudo apt-get update -y -q
sudo apt-get -y -q install \
    cmake \
    g++-5 \
    git \
    libboost-locale1.55-dev \
    libboost-test1.55-dev \
    libmyodbc \
    libsqliteodbc \
    mysql-client \
    mysql-server \
    unixodbc \
    unixodbc-dev

sudo odbcinst -i -d -f /usr/share/libmyodbc/odbcinst.ini
sudo odbcinst -i -d -f /usr/share/sqliteodbc/unixodbc.ini
SCRIPT

# All Vagrant configuration is done below.
# For a configuration reference go to https://docs.vagrantup.com.
# The "2" in Vagrant.configure configures the configuration version.
# Please don't change it unless you know what you're doing.
Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.box_check_update = true
  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "1024"]
  end
  config.vm.provision :shell, inline: $provision_script
end
