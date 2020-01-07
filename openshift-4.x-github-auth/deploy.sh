#!/bin/sh

# https://docs.openshift.com/container-platform/4.2/authentication/identity_providers/configuring-github-identity-provider.html

config_namespace="openshift-config"
github_oauth_file="github-oauth.yaml"

GITHUB_AUTH_CLIENT_SECRET_NAME="${GITHUB_AUTH_CLIENT_SECRET_NAME:-github-client-secret}"



echo "* Create Secret"
oc create secret generic $GITHUB_AUTH_CLIENT_SECRET_NAME --from-literal=clientSecret=$GITHUB_AUTH_CLIENT_SECRET -n $config_namespace

echo "* Configure OAuth"

cat $github_oauth_file \
| sed  "s/\$GITHUB_AUTH_CLIENT_ID/$GITHUB_AUTH_CLIENT_ID/" \
| sed  "s/\$GITHUB_AUTH_CLIENT_SECRET_NAME/$GITHUB_AUTH_CLIENT_SECRET_NAME/"  \
| sed  "s/\$GITHUB_AUTH_ORG/$GITHUB_AUTH_ORG/" \
| oc -n $config_namespace apply  -f -


