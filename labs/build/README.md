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

## Build multi stage
Build ova file with kubernetes packages. Remove pull-image.sh provisioner stage from template.json.  
```
    {
       "type":"shell",
       "script":"setup/pull-images.sh"
    }
```

Run build  
```
packer build template.json
```

build ultimate packet from first ova  
```
packer build template-ova.json
```
