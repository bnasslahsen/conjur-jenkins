#!/bin/bash

set -a
source ".env"
set +a

#Load jenkins root policy
conjur policy update -f authn-jwt-jenkins.yml -b root
#podman exec dap evoke variable set CONJUR_AUTHENTICATORS authn,authn-k8s/dev-cluster,authn-k8s/ocp-cluster,authn-jwt/jenkins

#Verify that the Kubernetes Authenticator is configured and allowlisted
RESULT=$(curl -sSk https://"$CONJUR_MASTER_HOSTNAME":"$CONJUR_MASTER_PORT"/info  | grep "$CONJUR_AUTHENTICATOR_ID" | wc -w)

if [[ $RESULT -ne 2 ]]; then
  echo "Jenkins Authenticator not enabled!"
  exit 1
else
  echo "Jenkins Authenticator $CONJUR_AUTHENTICATOR_ID enabled!"
fi

conjur policy update -b root -f root.yml
conjur policy update -b root -f jenkins-host.yml
conjur policy update -b root -f projects.yml

conjur policy update -b root -f jenkins-secrets.yml
conjur policy update -b root -f grants.yml
conjur policy update -b root -f grants_authn.yml


conjur variable set -i ci/jenkins/secrets/github_username -v "$GIT_USER"
conjur variable set -i ci/jenkins/secrets/github_password -v "$GIT_PASS"
conjur variable set -i ci/jenkins/secrets/team1_pass -v "$TEAM1_PASS"

conjur variable set -i conjur/authn-jwt/jenkins/audience -v "$JENKINS_AUDIENCE"
conjur variable set -i conjur/authn-jwt/jenkins/identity-path -v "$JENKINS_IDENTITY"
conjur variable set -i conjur/authn-jwt/jenkins/issuer -v "$JENKINS_ISSUER"
conjur variable set -i conjur/authn-jwt/jenkins/jwks-uri -v "$JENKINS_JWKS"
conjur variable set -i conjur/authn-jwt/jenkins/token-app-property -v "$JENKINS_TOKEN_APP"
