

export CRC_IP=$(crc ip)


sudo podman run -it -p 80:80 -p 443:443 -p 6443:6443 \
	-e CRC_IP=$CRC_IP \
    -v $PWD/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro \
    docker.io/haproxy:2.3
