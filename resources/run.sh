#!/usr/bin/env zsh

script_dir=${0:A:h}
hostip=192.168.254.132
pubkeys=(id.pub touchstone.pub)
ca_cert="${script_dir}/"ca.crt

#
# Step: Check if inside vm
#
if ioreg -l | grep -i product-name | grep -qiv virtual; then  
    echo "This script is meant to be run on a VM!"
    kill -INT $$
fi

#
# Step: Change admin password
#
echo "Change admin password"
dscl . -passwd /Users/admin huntress admin

#
# Step: Update /etc/hosts file
#
echo "Updating Hosts File"
cat > /etc/hosts <<EOF
##
# Host Database
#
# localhost is used to configure the loopback interface
# when the system is booting.  Do not change this entry.
##
127.0.0.1       localhost
255.255.255.255 broadcasthost
::1             localhost


${hostip}    huntress.io eetee.huntress.io update.huntress.io minio.huntress.io
${hostip}    huntress.tech eetee.huntress.tech update.huntress.tech minio.huntress.tech
${hostip}    bugsnag.com notify.bugsnag.com
EOF

#
# Step: Copy SSH Keys
#

echo "Copying ssh keys"
mkdir -p /Users/admin/.ssh
mkdir -p /var/root/.ssh

for key in ${pubkeys[@]}; do
  cat $script_dir/${key} >> /Users/admin/.ssh/authorized_keys
  cat $script_dir/${key} >> /var/root/.ssh/authorized_keys
done

#
# Step: Add cert to Trusted
#
echo "Add proxy key to trust store"
security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ${ca_cert}

#
# Step: Permit Root Login
#
echo "Permit Root login"
sed -i.bak 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

echo "done"
