#!/bin/bash
clear
echo ""
echo "----------------------------------------------------"
echo "  Setup Ansible for vRA8 Integration Helper Script  " | tee -a ansible_setup_helper_log
echo "----------------------------------------------------  "  | tee -a ansible_setup_helper_log
echo ""
echo "- Ansible Account Username & Password"
read -p 'Please enter the username of the new ansible account to create (i.e. ansible): ' uservar
read -sp 'Please enter the password for the new ansible account: ' passvar
echo ""
read -sp 'Please re-enter the password for the new ansible account (for confirmation): ' passvarconfirm
echo "*Username is $uservar"
echo "*Password not logged for security"

if [ -z "$uservar" ]; then
    echo "ERROR!! Entered username for new ansible account to create is blank. This is not permitted. Script will exit"  | tee -a ansible_setup_helper_log
    exit 1;
fi

if [ "$passvar" == "$passvarconfirm" ]; then
    echo "*Entered password matches entered confirmation password. Script will proceed..."  | tee -a ansible_setup_helper_log
else
    echo "ERROR!! Entered password does not match entered confirmation password. Script will exit"  | tee -a ansible_setup_helper_log
    exit 1;
fi

echo "*Adding new ansible user and setting password" | tee -a ansible_setup_helper_log
useradd -m -p $(openssl passwd -crypt $passvar) $uservar | tee -a ansible_setup_helper_log

echo "*Ensure new ansible user can SUDO successfully" | tee -a ansible_setup_helper_log
touch /etc/sudoers.d/$uservar 
cat > /etc/sudoers.d/$uservar << EOF
$uservar ALL=(ALL) NOPASSWD: ALL
EOF

echo ""
echo "- Install Ansible Open Source"
echo "*Adding the EPEL repository so we can download and install Ansible" | tee -a ansible_setup_helper_log
dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y | tee -a ansible_setup_helper_log

echo "*Install Ansible (open source)" | tee -a ansible_setup_helper_log
dnf install ansible -y | tee -a ansible_setup_helper_log

echo ""
echo "-Configure Ansible Installation"
echo "*Ensure that permissions are correctly set for the new ansible user" | tee -a ansible_setup_helper_log
setfacl -R -m u:$uservar:rwx /etc/ansible | tee -a ansible_setup_helper_log

echo "*Edit the /etc/ansible/ansible.cfg file" | tee -a ansible_setup_helper_log
echo "*Enable entry: host_key_checking = False" | tee -a ansible_setup_helper_log
sed -i 's/#host_key_checking/host_key_checking/' /etc/ansible/ansible.cfg | tee -a ansible_setup_helper_log

echo "*Amend entry: vault_password_file = /home/ansible/vault_password_file" | tee -a ansible_setup_helper_log
sed -i '/#vault_password_file/c\vault_password_file = /home/ansible/vault_password_file' /etc/ansible/ansible.cfg | tee -a ansible_setup_helper_log

echo "*Enable entry: record_host_keys = False" | tee -a ansible_setup_helper_log
sed -i 's/#record_host_keys/record_host_keys/' /etc/ansible/ansible.cfg | tee -a ansible_setup_helper_log

echo "*Amend entry: ssh_args = -o UserKnownHostsFile=/dev/null" | tee -a ansible_setup_helper_log
sed -i '/#ssh_args/c\ssh_args = -o UserKnownHostsFile=/dev/null' /etc/ansible/ansible.cfg | tee -a ansible_setup_helper_log

echo ""
echo "Configure VAULT"
echo "*Set password in vault_password_file" | tee -a ansible_setup_helper_log
touch /home/$uservar/vault_password_file
cat > /home/$uservar/vault_password_file << EOF
$passvar
EOF

echo "*Perform setup actions as the new ansible user" | tee -a ansible_setup_helper_log
echo "*Generate ssh keys (public & private)" | tee -a ansible_setup_helper_log
#sudo -i -u ansible bash -c "ssh-keygen -t rsa -f ~/.ssh/id_rsa -N 'fds8h734bjdsavf87'" | tee -a ansible_setup_helper_log
sudo -i -u ansible bash -c "ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ''" | tee -a ansible_setup_helper_log

echo ""
echo "- Finalise"
echo "*Installation and configuration complete" | tee -a ansible_setup_helper_log
echo "*Log file is available in current working path named 'ansible_setup_helper_log'"
exit 0
