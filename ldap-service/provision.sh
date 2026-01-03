#!/bin/bash
set -euo pipefail

timedatectl set-timezone Europe/Brussels
hostnamectl set-hostname sso-service.interface3.be

cat >> /etc/hosts <<'EOF'
172.28.128.117 sso-server.interface3.be
172.28.128.118 sso-service.interface3.be
172.28.128.119 sso-service.interface3.be
EOF

chmod 0600 /home/vagrant/install.txt /home/vagrant/ubuntuadmin-pass.txt || true

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -qq -y debconf-utils
debconf-set-selections < /home/vagrant/install.txt

apt-get install -qq -y sssd-ldap sssd-krb5 ldap-utils krb5-user libpam-mkhomedir

# SSSD config
mv /home/vagrant/sssd.conf /etc/sssd/sssd.conf
chmod 0600 /etc/sssd/sssd.conf
chown root:root /etc/sssd/sssd.conf
systemctl restart sssd

# Auto-create home dirs on login
pam-auth-update --enable mkhomedir || true

# Add host principal + keytab for GSSAPI SSH
printf "%s\n" "$(cat /home/vagrant/ubuntuadmin-pass.txt)" | kadmin -p ubuntu/admin -q "addprinc -randkey host/sso-service.interface3.be" || true
printf "%s\n" "$(cat /home/vagrant/ubuntuadmin-pass.txt)" | kadmin -p ubuntu/admin -q "ktadd -k /etc/krb5.keytab host/sso-service.interface3.be" || true

cat > /etc/ssh/sshd_config.d/50-gssapi.conf <<'EOF'
GSSAPIAuthentication yes
GSSAPICleanupCredentials yes
EOF
systemctl restart sshd

echo "Client joined (SSSD+Kerberos). Try: getent passwd admin ; kinit admin"
