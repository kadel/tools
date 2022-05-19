#!/bin/sh

virt-install --connect qemu:///system \
  --name test1 \
  --virt-type kvm --memory 2048 --vcpus 2 \
  --boot hd,menu=on \
  --disk path=cloud-init.img,device=cdrom \
  --disk path=ubuntu.img,device=disk \
  --os-type Linux --os-variant ubuntu20.04 \
  --network network:default
