#!/usr/bin/env sh

set -e 

CEPH_VERSION=octopus

# disable translate download and add proxy
cat <<EOF | sudo tee /etc/apt/apt.conf.d/20translate
Acquire::Languages "none";
EOF

# Install Kuberntes components
sudo apt-get update && sudo apt-get install -y apt-transport-https curl ca-certificates software-properties-common gnupg2 software-properties-common vim bash-completion
sudo apt-get upgrade -y

wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/ceph.list
deb https://download.ceph.com/debian-$CEPH_VERSION/ bionic main 
EOF

sudo apt-get update
sudo apt-get install -y cephadm ceph-common ceph-base
sudo apt-get clean

# Preflight
sudo mkdir /etc/ceph || true
sudo cephadm pull
sudo docker pull prom/prometheus:v2.18.1
sudo docker pull ceph/ceph-grafana:latest 
sudo docker pull prom/alertmanager:v0.20.0
sudo docker pull prom/node-exporter:v0.18.1

# Set up the Docker daemon
cat <<EOF | sudo tee /etc/docker/daemon.json 
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

# Add proxy to Docker
sudo mkdir -p /etc/systemd/system/docker.service.d
cat <<EOF | sudo tee /etc/systemd/system/docker.service.d/override.conf
[Service]
Environment="HTTP_PROXY=http://user:passowrd@proxy.example.com:3128/" "HTTPS_PROXY=http://user:password@proxy.example.com:3128/" "NO_PROXY=localhost,127.0.0.0/8,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12"
EOF

# Restart Docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# Disable swap
sudo swapoff --all
sudo sed -i '/^.*swap.*/ d' /etc/fstab

# Disable apparmor
sudo /etc/init.d/apparmor teardown
sudo systemctl disable --now apparmor

## Add shecan
#cat <<EOF | sudo tee /etc/netplan/01-netcfg.yaml
## This file describes the network interfaces available on your system
## For more information, see netplan(5).
#network:
#  version: 2
#  renderer: networkd
#  ethernets:
#    enp0s3:
#      dhcp4: no
#      dhcp6: no
#      addresses:
#        - 192.168.13.210/24
#      gateway4: 192.168.13.1
#      nameservers:
#          addresses: [8.8.8.8]
#EOF
#
#sudo netplan apply

exit 0
