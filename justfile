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


quick-bash image:
  podman run --platform linux/amd64 -it --rm --entrypoint /bin/bash {{image}}

quick-sh image:
  podman run --platform linux/amd64 -it --rm --entrypoint /bin/sh {{image}}


build-push image *args=".":
  podman build --platform linux/amd64 -t {{image}} {{args}}
  podman push {{image}}


butane infile outfile:
  podman run --interactive --rm --security-opt label=disable \
       --volume ${PWD}:/pwd --workdir /pwd quay.io/coreos/butane:release \
       --pretty --strict {{infile}} > {{outfile}}


extract-first-layer image tag outfile:
  #!/bin/sh
  DIGEST=$(oras manifest fetch  --pretty {{image}}:{{tag}} | jq -r ".layers[0].digest") && \
  echo $DIGEST && \
  oras blob fetch {{image}}@$DIGEST --output {{outfile}}