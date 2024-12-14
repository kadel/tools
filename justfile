default:
  @just --list


# template-file-example argument:
#     #!/usr/bin/env sh
#     cat <<EOF > test
#     ahoj {{argument}}
#     EOF
#     cat test


# expose crc api server (localhost:6443) on 0.0.0.0:16443
crc-expose-api:
    # crc needs to run with usermode networking
    socat TCP-LISTEN:16443,fork TCP:localhost:6443


# generates k8s deployment
generate-deployment name image port:
    kubectl create deployment {{name}} --image={{image}} --port={{port}} --dry-run=client -o yaml

# run bash in image
bashin-x86 image:
  podman run --platform linux/amd64 -it --rm --entrypoint /bin/bash {{image}}

# run sh in image
shin-x86 image:
  podman run --platform linux/amd64 -it --rm --entrypoint /bin/sh {{image}}


# run bash in image
bashin image:
  podman run -it --rm --entrypoint /bin/bash {{image}}

# run sh in image
shin image:
  podman run -it --rm --entrypoint /bin/sh {{image}}


# build and push container image
build-push image *args=".":
  podman build --platform linux/amd64 -t {{image}} {{args}}
  podman push {{image}}

# compile butane file
butane infile outfile:
  podman run --interactive --rm --security-opt label=disable \
    --volume ${PWD}:/pwd --workdir /pwd quay.io/coreos/butane:release \
    --pretty --strict {{infile}} > {{outfile}}

# extract first layer from image into outfile using oras cli
extract-first-layer image tag outfile:
  #!/bin/sh
  DIGEST=$(oras manifest fetch  --pretty {{image}}:{{tag}} | jq -r ".layers[0].digest") && \
  echo $DIGEST && \
  oras blob fetch {{image}}@$DIGEST --output {{outfile}}

# start HA proxy container for CRC
crc-ha-proxy:
  #!/usr/bin/env sh
  export CRC_IP=$(crc ip)
  sed "s/\$CRC_IP/$CRC_IP/g" {{justfile_directory()}}/containers/crc-ha-proxy/config/haproxy.cfg.template > {{justfile_directory()}}/containers/crc-ha-proxy/config/haproxy.cfg
  podman run --replace -it --name crc-ha-proxy -v {{justfile_directory()}}/containers/crc-ha-proxy/config:/usr/local/etc/haproxy:Z --sysctl net.ipv4.ip_unprivileged_port_start=0 docker.io/library/haproxy:latest
  rm {{justfile_directory()}}/containers/crc-ha-proxy/config/haproxy.cfg

# smaller pdf ()
pdf-small infile outfile:
  gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile={{outfile}} {{infile}}


# remove all volumes, tool is podman or docker
cleanup-volumes tool:
  {{tool}} volume rm $({{tool}} volume ls -q)

# remove all images, tool is podman or docker
cleanup-images tool:
  {{tool}} rmi $({{tool}} images -q)

# remove all containers, tool is podman or docker
cleanup-containers tool:
  {{tool}} rm $({{tool}} ps -a -q)


# quickly start a test vm
start-test-vm vmName="test":
  #!/usr/bin/env bash
  connect="qemu:///system"

  vmName={{vmName}}
  orgImage="//var/lib/libvirt/boot/Fedora-Cloud-Base-Generic.x86_64-40.qcow2"
  vmImage="/var/lib/libvirt/images/${vmName}.qcow2"
  cloudInitFile="/var/lib/libvirt/images/${vmName}-cloud-init.yaml"

  read -r -d '' CLOUDINIT <<-EOF
  #cloud-config
  hostname: test
  fqdn: test.home.tomaskral.eu
  preserve_hostname: false
  users:
    - name: user
      hashed_passwd: "$6$rounds=500000$3/0LfJPUdqDe3VK/$MzRg/g1o.8iENQJRCjQnh6QHMGe/stx7EG9iZrO.8BbLqU0i9x8YTb4Jy.c.WYXpXsAmgP5SmCxroxsXwUzKl."
      sudo: ALL=(ALL) NOPASSWD:ALL
      ssh_authorized_keys:
        - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNkcC8+8183dmGtM27t9G9fUxWogsquXzOrNn3x56Pm test@localhost
  EOF

  echo "${CLOUDINIT}" | sudo tee ${cloudInitFile}
  sudo chown libvirt-qemu:libvirt-qemu ${cloudInitFile}

  sudo cp ${orgImage} ${vmImage}
  sudo chown libvirt-qemu:libvirt-qemu ${vmImage}
  sudo qemu-img resize ${vmImage} 20G
  virt-install --connect ${connect} --name ${vmName} \
    --memory 4096 --cpu host --vcpus 2 --graphics none \
    --os-variant fedora40 \
    --import --disk ${vmImage},format=qcow2,bus=virtio \
    --cloud-init user-data="${cloudInitFile}" \
    --network bridge=br0,model=virtio
  
destroy-test-vm vmName="test":
  #!/usr/bin/env bash
  vmName=test
  connect="qemu:///system"
  virsh --connect ${connect} destroy test
  virsh --connect ${connect} undefine test
  sudo rm /var/lib/libvirt/images/${vmName}.qcow2
  sudo rm /var/lib/libvirt/images/${vmName}-cloud-init.yaml

import 'bluefin-tools.just'
import 'private.just'