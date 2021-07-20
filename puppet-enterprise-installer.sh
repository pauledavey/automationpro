#!/bin/bash

systemctl stop firewalld
systemctl disable firewalld

# create user for puppet
useradd -m -p "Password123!!" "svc_puppet"
usermod -aG wheel svc_puppet

cat >  /etc/sudoers.d/svc_puppet << EOF
svc_puppet ALL = (root) NOPASSWD: /opt/puppetlabs/bin/puppet node purge *
svc_puppet ALL = (root) NOPASSWD: !/opt/puppetlabs/bin/puppet node purge *[[\:blank\:]]*
svc_puppet ALL = (root) NOPASSWD: /opt/puppetlabs/bin/puppet config print *
svc_puppet ALL = (root) NOPASSWD: !/opt/puppetlabs/bin/puppet config print *[[\:blank\:]]*
svc_puppet ALL = (root) NOPASSWD: /opt/puppetlabs/bin/facter -p puppetversion
svc_puppet ALL = (root) NOPASSWD: /opt/puppetlabs/bin/facter -p pe_server_version
svc_puppet ALL = (root) NOPASSWD: /opt/puppetlabs/bin/puppet agent -t
svc_puppet ALL = (root) NOPASSWD: /opt/puppetlabs/bin/puppet agent â€“test â€“color\=false â€“detailed-exitcodes
svc_puppet ALL = (root) NOPASSWD: /bin/kill -HUP *
svc_puppet ALL = (root) NOPASSWD: !/bin/kill -HUP *[[\:blank\:]]*
svc_puppet ALL = (root) NOPASSWD: !/opt/puppetlabs/bin/puppet node purge pe-201734-master.puppetdebug.vlan
svc_puppet ALL = (root) NOPASSWD: !/opt/puppetlabs/bin/puppet node purge pe-internal-mcollective-servers
svc_puppet ALL = (root) NOPASSWD: !/opt/puppetlabs/bin/puppet node purge pe-internal-peadmin-mcollective-client
svc_puppet ALL = (root) NOPASSWD: /opt/puppetlabs/bin/puppet resource service puppet ensure\=stopped
svc_puppet ALL = (root) NOPASSWD: /opt/puppetlabs/bin/puppet resource service puppet ensure\=running enable\=true
svc_puppet ALL = (root) NOPASSWD: /bin/cp /etc/puppetlabs/puppet/ssl/ca/ca_crl.pem /etc/puppetlabs/puppet/ssl/crl.pem
EOF

mkdir -p /tmp/puppet

wget 'https://pm.puppet.com/cgi-bin/download.cgi?dist=el&rel=7&arch=x86_64&ver=latest' -O /tmp/puppet/puppet-enterprise-installer.tar.gz
tar -zvxf /tmp/puppet/puppet-enterprise-installer.tar.gz -C /tmp/puppet --strip-components=1
cat > /tmp/puppet/pe.conf << EOF 
"console_admin_password": "Password123!!"
"puppet_enterprise::puppet_master_host": "%{::trusted.certname}"
EOF

export LANG=en_US.UTF-8 
export LANGUAGE=en_US.UTF-8 
export LC_ALL=en_US.UTF-8

echo -e "\n== Installing Puppet Enterprise Server...\n"
/tmp/puppet/puppet-enterprise-installer -c /tmp/puppet/pe.conf 

echo -e "\n== Run Puppet Agent -t...\n"
puppet agent -t

echo -e "\n== Run Puppet Agent -t...\n"
puppet agent -t

echo -e "\n== Installing bolt...\n"
sudo /opt/puppetlabs/puppet/bin/gem install bolt          
