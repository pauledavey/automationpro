#!/bin/bash

set -x

systemctl stop firewalld
systemctl disable firewalld

# create user for puppet
useradd -m -p "Password123!!" "svc_puppet"
usermod -aG wheel svc_puppet

cat >  /etc/sudoers.d/svc_puppet << EOF
svc_puppet ALL = (root) NOPASSWD: /opt/puppetlabs/bin/puppet config print *
svc_puppet ALL = (root) NOPASSWD: !/opt/puppetlabs/bin/puppet config print *[[\:blank\:]]*
svc_puppet ALL = (root) NOPASSWD: /opt/puppetlabs/bin/puppet resource service puppet ensure=stopped
svc_puppet ALL = (root) NOPASSWD: /opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true
svc_puppet ALL = (root) NOPASSWD: /opt/puppetlabs/bin/facter -p puppetversion
svc_puppet ALL = (root) NOPASSWD: /opt/puppetlabs/bin/facter -p pe_server_version
svc_puppet ALL = (root) NOPASSWD: /opt/puppetlabs/bin/puppet agent -t
svc_puppet ALL = (root) NOPASSWD: /opt/puppetlabs/bin/puppet agent --test --color=false --detailed-exitcodes
svc_puppet ALL = (root) NOPASSWD: /opt/puppetlabs/bin/puppet node purge *
svc_puppet ALL = (root) NOPASSWD: !/opt/puppetlabs/bin/puppet node purge *[[\:blank\:]]*
svc_puppet ALL = (root) NOPASSWD: !/opt/puppetlabs/bin/puppet node purge <%= $trusted[certname] %>
svc_puppet ALL = (root) NOPASSWD: !/opt/puppetlabs/bin/puppet node purge pe-internal-mcollective-servers
svc_puppet ALL = (root) NOPASSWD: !/opt/puppetlabs/bin/puppet node purge pe-internal-peadmin-mcollective-client
svc_puppet ALL = (root) NOPASSWD: /bin/ls -1 /etc/puppetlabs/code/environments/
svc_puppet ALL = (root) NOPASSWD: /opt/puppetlabs/bin/puppet strings *
svc_puppet ALL = (root) NOPASSWD: /usr/bin/cat /etc/puppetlabs/client-tools/services.conf
svc_puppet ALL = (root) NOPASSWD: /usr/bin/curl *
svc_puppet ALL = (root) NOPASSWD: /opt/puppetlabs/bin/puppet-job run *
svc_puppet ALL = (root) NOPASSWD: /bin/find /etc/puppetlabs/code/environments/*
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

/tmp/puppet/puppet-enterprise-installer -c /tmp/puppet/pe.conf 
/opt/puppetlabs/puppet/bin/gem install bolt
/opt/puppetlabs/puppet/bin/puppet agent -t
/opt/puppetlabs/puppet/bin/puppet agent -t
/opt/puppetlabs/puppet/bin/puppet agent -t

cat >  /etc/issue << EOF
############################
# Puppet Enterprise Server #
############################
EOF

shutdown -r 1
