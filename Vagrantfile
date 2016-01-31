# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrant virtual environments for nanodbc developers and users

$provision_script = <<SCRIPT
export DEBIAN_FRONTEND="noninteractive"

# For ubuntu/trusty64
sudo apt-get -qqy install software-properties-common || true

# For ubuntu/precise64:
sudo apt-get -qqy install python-software-properties || true

sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
sudo apt-get update -qqy
sudo apt-get -qqy install \
    \$(apt-cache -q search "libboost-locale1\\..*-dev" | awk '{print $1}') \
    cmake \
    doxygen \
    g++-5 \
    git \
    libmyodbc \
    libsqliteodbc \
    make \
    mysql-client \
    mysql-server \
    sqlite3 \
    unixodbc \
    unixodbc-dev \
    vim

# Might not be available, but install it if it is.
sudo apt-get -y install jekyll || true

sudo odbcinst -i -d -f /usr/share/libmyodbc/odbcinst.ini
sudo odbcinst -i -d -f /usr/share/sqliteodbc/unixodbc.ini
SCRIPT

# All Vagrant configuration is done below.
# For a configuration reference go to https://docs.vagrantup.com.
# The "2" in Vagrant.configure configures the configuration version.
# Please don't change it unless you know what you're doing.
Vagrant.configure(2) do |config|
  #######################################################################
  #################### Selection of Base Image ##########################
  #######################################################################
  ## trusty64 is more modern and easier to develop on.
  # config.vm.box = "ubuntu/trusty64"

  ## precise64 is what travis-ci tests run on.
  config.vm.box = "ubuntu/precise64"
  #######################################################################

  config.vm.box_check_update = true
  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "1024"]
  end
  config.vm.provision :shell, inline: $provision_script
end
