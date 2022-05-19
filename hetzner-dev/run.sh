#!/bin/sh

set -x
set -e


SERVER_NAME="dev"
KEY_NAME="key1"

hcloud server create --name $SERVER_NAME --location nbg1  --ssh-key $KEY_NAME --start-after-create=false --type cx41 --image ubuntu-22.04
hcloud server enable-rescue --ssh-key $KEY_NAME $SERVER_NAME
hcloud server poweron $SERVER_NAME

SERVER_IP=$(hcloud server ip $SERVER_NAME)

sleep 20s
until ssh -o StrictHostKeyChecking=no root@"$SERVER_IP" true; do sleep 1s; done

scp -o StrictHostKeyChecking=no install.conf root@"$SERVER_IP":/root/install.conf
ssh -o StrictHostKeyChecking=no root@"$SERVER_IP" /root/.oldroot/nfs/install/installimage -a -c /root/install.conf

hcloud server reboot $SERVER_NAME

ssh-keygen -R $SERVER_IP

echo $SERVER_IP

