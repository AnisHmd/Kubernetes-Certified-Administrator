# Build Image with Packer

## Install packer
Download packer file and copy to bin folder  
```
wget https://releases.hashicorp.com/packer/1.6.0/packer_1.6.0_linux_amd64.zip
unzip packer_1.6.0_linux_amd64.zip
mv packer /usr/local/bin/
```

## Build ova image for virtulabox
Just run  
```
packer build template.json
```

# Setup Single Node Ceph Storage with cephadm
### Prepare VM
Configure static ip for VM  
```
$ sudo vi /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: no
      dhcp6: no
      addresses:
        - 192.168.13.211/24
      gateway4: 192.168.13.1
      nameservers:
          addresses: [8.8.8.8]
```

```
$ sudo netplan apply
```

Chnage hostname  
```
echo -n "ceph-mon-01" > /etc/hostname
```

```
vi /etc/hosts
192.168.13.211	ceph-mon-01
```

```
sudo hostname -F /etc/hostname
```
Then logout and login again.  


### Bootstrap Ceph 
Config chooseleaf default bucket type to osd.  

```
cat <<EOF >ceph.conf
[global]
osd crush chooseleaf type = 0
EOF
```

Start bootstrapping with cephadm
```
cephadm bootstrap \
  --mon-ip 192.168.13.211 \
  --initial-dashboard-user admin \
  --initial-dashboard-password password \
  --config ceph.conf
```

### Add OSD's
Poweroff machine and add three 10GB virtual HDD. Then add them as OSD.  
```
ceph orch daemon add osd ceph-mon-01:/dev/sdb
ceph orch daemon add osd ceph-mon-01:/dev/sdc
ceph orch daemon add osd ceph-mon-01:/dev/sdd
```

Check cluster status. pgs must be active+clean.  
```
# ceph -s
  cluster:
    id:     4ceb98fe-d9a6-11ea-be2d-0800279bfb4e
    health: HEALTH_OK
 
  services:
    mon: 1 daemons, quorum ceph-mon-01 (age 87s)
    mgr: ceph-mon-01.pylgmv(active, since 77s)
    osd: 3 osds: 3 up (since 38s), 3 in (since 38s)
 
  data:
    pools:   1 pools, 1 pgs
    objects: 1 objects, 0 B
    usage:   3.0 GiB used, 27 GiB / 30 GiB avail
    pgs:     1 active+clean
```

Create pool to start.  
```
ceph osd pool create cka 32
```

and check status again.  
```
# ceph -s
  cluster:
    id:     4ceb98fe-d9a6-11ea-be2d-0800279bfb4e
    health: HEALTH_OK
 
  services:
    mon: 1 daemons, quorum ceph-mon-01 (age 22m)
    mgr: ceph-mon-01.pylgmv(active, since 21m)
    osd: 3 osds: 3 up (since 21m), 3 in (since 21m)
 
  data:
    pools:   2 pools, 33 pgs
    objects: 1 objects, 0 B
    usage:   3.0 GiB used, 27 GiB / 30 GiB avail
    pgs:     33 active+clean
```

Its ready to use :-)
