#!/bin/bash

IP=$(minikube ip)
NAMESPACE="kube-system"

HOST="registry.${IP}.xip.io"

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
            serviceName: registry
            servicePort: 80
EOF

echo "Creating Ingress for registry."
echo "hostname: ${HOST}"
echo ""
echo "$ingress" | kubectl apply -n ${NAMESPACE} -f -
