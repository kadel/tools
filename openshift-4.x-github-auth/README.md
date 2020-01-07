# openshift-4.x-github-auth

<https://docs.openshift.com/container-platform/4.2/authentication/identity_providers/configuring-github-identity-provider.html>

## deploy.sh

Enable GitHub OAuth login

- create new Oauth application on github - <https://github.com/settings/applications/new>
- `export GITHUB_AUTH_CLIENT_ID=aaaa` - OAuth application  Client ID
- `export GITHUB_AUTH_CLIENT_SECRET=bbbb` - OAuth application Client Secret
- `export GITHUB_AUTH_ORG=myorg` - members of this organization will be allowed to login to cluster
