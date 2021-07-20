#!/bin/bash
sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo mkdir /tmp/puppet
sudo cd /tmp/puppet
sudo curl -JLO 'https://pm.puppet.com/cgi-bin/download.cgi?dist=el&rel=7&arch=x86_64&ver=latest'
sudo cd /tmp/puppet 
sudo tar -xf *puppet-enterprise*.tar.gz
sudo cd /tmp/puppet/puppet-ent*/ 
cat > pe.conf << EOF 
"console_admin_password": "puppet" 
EOF

export LANG=en_US.UTF-8 
export LANGUAGE=en_US.UTF-8 
export LC_ALL=en_US.UTF-8

echo -e "\n== Installing Puppet Enterprise Server...\n"
sudo /tmp/puppet/puppet-ent*/puppet-enterprise-installer -c pe.conf 

echo -e "\n== Installing bolt...\n"
sudo /opt/puppetlabs/puppet/bin/gem install bolt          