default:
  @just --choose


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

