#!/bin/bash
yum --enablerepo=extras install epel-release yum-utils -y
yum update -y
yum upgrade -y

mkdir -p /etc/ansible
yum -y install sshpass python3 python3-pip ansible git vim wget
/usr/local/bin/pip3 install --upgrade pip netaddr Jinja2 idna
mv /tmp/ansible.cfg /etc/ansible
mv /tmp/ansible/ /root/kubespray_installation/
mv /tmp/kubernetes.repo /etc/yum.repos.d/kubernetes.repo
mv /tmp/postinstall.sh /opt/postinstall.sh
mv /tmp/metallb-config.yaml /opt/metallb-config.yaml
mv /tmp/metallb-install.sh /opt/metallb-install.sh
mv /tmp/nginx-svc.yaml /opt/nginx-svc.yaml

ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa

sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/#PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

for host in `cat /tmp/hostnames.txt` ; do sshpass -f /tmp/password.txt ssh-copy-id -o "StrictHostKeyChecking no" -f $host ; done

echo "/dev/sdb1   /var/lib/docker   xfs   defaults   0   2" >> /etc/fstab
parted /dev/sdb mklabel msdos
parted -a opt /dev/sdb mkpart primary ext4 0% 100%
sleep 10
mkfs.xfs -L docker /dev/sdb1
mkdir -p /var/lib/docker
mount -a
