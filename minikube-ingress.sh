#!/bin/bash


if [[ $# -ne 2 ]] ; then
    echo "Two arguments required"
    echo "SERVICE_NAME SERVICE_PORT"
    exit 1
fi

SERVICE=$1
PORT=$2

IP=$(minikube ip)
HOST="${SERVICE}.${IP}.xip.io"

read -d '' ingress << EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: registry
spec:
  rules:
  - host: ${HOST}
    http:
      paths:
        - path: /
          backend:
            serviceName: ${SERVICE}
            servicePort: ${PORT}
EOF

echo "Creating Ingress for ${SERVICE}:${PORT}."
echo "hostname: ${HOST}"
echo ""
echo "$ingress" | kubectl apply -f -
