#!/bin/bash
## ALLOW root login & password PasswordAuthentication
sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/#PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

## CHANGE Password to root
echo "vagrant" | passwd --stdin root

## Prepare node for kubectl
mv /tmp/kubernetes.repo /etc/yum.repos.d/kubernetes.repo

## Update the Machine
yum update -y
yum upgrade -y

## Prepare partition for /var/lib/docker
echo "/dev/sdb1   /var/lib/docker   xfs   defaults   0   2" >> /etc/fstab
parted -s /dev/sdb mklabel msdos
parted -a opt /dev/sdb mkpart primary ext4 0% 100%
sleep 10
mkfs.xfs -L docker /dev/sdb1
mkdir -p /var/lib/docker
mount -a
