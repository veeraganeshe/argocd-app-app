#!/bin/bash

LOGIN_URL=$1
PASSWORD=$2

argocd login $1 --username admin --password $2 --insecure
sync_status=$(argocd app list | awk '$5 == "OutOfSync" {print $1}'  | cut -d'/' -f2)
health_status=$(argocd app list --output json | jq -r '
  .[] |
  select(
    (.status.health.status == "Suspended" or  .status.health.status == "Progressing" or .status.health.status == "Degraded" or  .status.health.status == "Missing") and .status.operationState.finishedAt != null and
    ((now - (.status.operationState.finishedAt | fromdateiso8601)) > 600)
  ) |
  .metadata.name')
if [[ -z "$sync_status" && -z "$health_status" ]]; then
   echo -e "All the Apps are in sync and healthy"
else
    if [[ -n "$sync_status" ]]; then
        echo -e "Below Applications are Out of Sync : \n\n$sync_status" | mail -s "argocd-apps-status" vganesa5@its.jnj.com achaud58@its.jnj.com mnirmal1@its.jnj.com junger2@its.jnj.com snandhag@its.jnj.com mnandach@its.jnj.com jsalame@its.jnj.com
    fi
    if [[ -n "$health_status" ]]; then
        echo -e "Below Applications are in unhealthy state for more than 10 minutes : \n\n$health_status" | mail -s "argocd-apps-health-status" vganesa5@its.jnj.com achaud58@its.jnj.com mnirmal1@its.jnj.com junger2@its.jnj.com snandhag@its.jnj.com mnandach@its.jnj.com jsalame@its.jnj.com
    fi
fi

# RUN LIKE sh /d4u-argo/utils/apps-monitoring.sh d4u-argocd-qa.jnj.com  T-bT2jDWLGJLJI42
