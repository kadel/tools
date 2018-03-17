#!/bin/bash
if [[ $# -ne 2 ]] ; then
    echo "Two args required"
    echo "NAME RAMSIZE"
    exit 1
fi
NAME=$1
RAMSIZE=$2


case $RAMSIZE in
    1)
        size="s-1vcpu-1gb"
        ;;
    2) 
        size="s-1vcpu-2gb"
        ;;
    3)
        size="s-1vcpu-3gb"
        ;;
    4) 
        size="s-2vcpu-4gb"
        ;;
    8) 
        size="s-4vcpu-8gb"
        ;;
    *)
        echo "unknown size"
        exit 1
        ;;
esac

TMPFILE=$(mktemp)

cat > $TMPFILE <<EOF
#cloud-config
write_files:
- path: /etc/nixos/host.nix
  permissions: '0644'
  content: |
    {config, pkgs, ...}:
    {
        environment.systemPackages = with pkgs; [
            vim
            mosh 
        ];
        networking.firewall = {
            enable = true;
            allowPing = true;
            allowedTCPPorts = [ 22 ];
            allowedUDPPortRanges = [ { from = 60000; to = 61000; } ];
        }
    };
    }
runcmd:
  - curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | NIXOS_IMPORT=./host.nix NIX_CHANNEL=nixos-17.03 bash 2>&1 | tee /tmp/infect.log
EOF

doctl compute droplet create $NAME \
  --size $size  \
  --image ubuntu-16-04-x64 \
  --user-data-file $TMPFILE


  rm $TMPFILE