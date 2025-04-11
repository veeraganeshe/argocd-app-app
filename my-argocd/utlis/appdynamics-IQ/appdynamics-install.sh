#!/bin/bash

PASSWORD=$1
CLUSTER_AGENT_FILE=$2

kubectl create namespace appdynamics

kubectl create cm custom-configmap --from-file shim-for-web/shim.js -n appdynamics

kubectl create cm custom-configmap-info-logging --from-file shim-for-bff/shim.js -n appdynamics

kubectl create secret -n marvel docker-registry creds-jnj-1 --docker-server=jnj-docker.artifactrepo.jnj.com --docker-username=SA-ITSUS-JADF-DEVUSR --docker-password="$PASSWORD" --docker-email=junger2@its.jnj.com

kubectl create secret -n appdynamics docker-registry creds-jnj-1 --docker-server=jnj-docker.artifactrepo.jnj.com --docker-username=SA-ITSUS-JADF-DEVUSR --docker-password="$PASSWORD" --docker-email=junger2@its.jnj.com

helm repo add appdynamics-cloud-helmcharts https://appdynamics.jfrog.io/artifactory/appdynamics-cloud-helmcharts/

helm install -f "$CLUSTER_AGENT_FILE" "appdynamics" appdynamics-cloud-helmcharts/cluster-agent --namespace=appdynamics

#if you want to redeploy the appdynamics values file use below command:

#helm upgrade --install appdynamics appdynamics-cloud-helmcharts/cluster-agent -f "$CLUSTER_AGENT_FILE" -n appdynamics
