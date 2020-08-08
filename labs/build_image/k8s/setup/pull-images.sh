#!/usr/bin/env sh

KUBE_VERSION=1.18.6
CALICO_VERSION=3.14.1

# Pull kubernetes images
sudo kubeadm --kubernetes-version $KUBE_VERSION config images pull

# Pull Calico images
sudo docker pull calico/cni:v$CALICO_VERSION
sudo docker pull calico/pod2daemon-flexvol:v$CALICO_VERSION
sudo docker pull calico/node:v$CALICO_VERSION
sudo docker pull calico/kube-controllers:v$CALICO_VERSION

# Remove proxy
sudo rm /etc/systemd/system/docker.service.d/override.conf
sudo systemctl daemon-reload
sudo systemctl restart docker

exit 0
