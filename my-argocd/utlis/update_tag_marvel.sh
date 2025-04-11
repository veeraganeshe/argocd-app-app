#!/bin/bash
token=$1


if [[ "$token" == "" ]]; then
  echo "token is not defined, first argument, bailing out."
  exit 1
fi

# "2.1.4" for dev-for-prod or "2.2.0" for dev/dev-sandbox/preqa
if [[ "$VERSION" == ""  ]]; then
  VERSION="2.2.0"
fi

# "dev" for dev/dev-sandbox or "rel" for dev-for-prod/preqa
if [[ "$TAG" == "" ]]; then
  TAG="dev"
fi

# "dev" or "dev-sandbox" or "dev-for-prod" or "preqa"
if [[ "$ENVNAME" == "" ]]; then
  ENVNAME="dev"
fi

# List of applications
APP=("d4u-marvel-web" "d4u_smart_compose_bff" "marvel_datareview_bff" "marvel_flags_api" "marvel_flags_bff" "marvel_flags_update_api" "marvel_inquiry_api" "marvel_inquiry_bff" "marvel_inquiry_update_api" "marvel_rave_api" "marvel_rave_update_api" "marvel_ref_bff" "marvel_review-requirements_api" "marvel_review-requirements-bff" "marvel_rr_update_api" "marvel_studies_api" "marvel_studies_bff" "marvel_study_update_api" "marvel-tasks-api" "marvel_tasks_bff" "marvel_task_update_api" "marvel_user_api" "marvel_user_bff" "marvel_visualization_api" "marvel_viz_update_api")

declare -A appmap
declare -A vermap


appmap[d4u-marvel-web]=d4u-marvel-web
appmap[d4u_smart_compose_bff]=d4u-smart-compose-bff
appmap[marvel_datareview_bff]=marvel_datareview_bff
appmap[marvel_flags_api]=marvel_flags_api
appmap[marvel_flags_bff]=marvel_flags_bff
appmap[marvel_flags_update_api]=marvel_flags_update_api
appmap[marvel_inquiry_api]=marvel-inquiry-api
appmap[marvel_inquiry_bff]=marvel_inquiry_bff
appmap[marvel_inquiry_update_api]=marvel_inquiry_update_api
appmap[marvel_rave_api]=marvel_rave_api
appmap[marvel_rave_update_api]=marvel_rave_update_api
appmap[marvel_ref_bff]=marvel-ref-bff
appmap[marvel_review-requirements_api]=marvel_review_requirement_api
appmap[marvel_review-requirements-bff]=marvel_review_requirements_bff
appmap[marvel_rr_update_api]=marvel_rr_update_api
appmap[marvel_studies_api]=marvel_studies_api
appmap[marvel_studies_bff]=marvel-studies-bff
appmap[marvel_study_update_api]=marvel_study_update_api
appmap[marvel-tasks-api]=marvel_tasks_api
appmap[marvel_tasks_bff]=marvel-tasks-bff
appmap[marvel_task_update_api]=marvel_task_update_api
appmap[marvel_user_api]=marvel_user_api
appmap[marvel_user_bff]=marvel-user-bff
appmap[marvel_visualization_api]=marvel_visualization_api
appmap[marvel_viz_update_api]=marvel_viz_update_api


vermap[d4u-marvel-web]="$TAG:latest"
vermap[d4u_smart_compose_bff]="$TAG:latest"
vermap[marvel_datareview_bff]="$TAG:latest"
vermap[marvel_flags_api]="$TAG:latest"
vermap[marvel_flags_bff]="$TAG:latest"
vermap[marvel_flags_update_api]="$TAG:latest"
vermap[marvel_inquiry_api]="$TAG:latest"
vermap[marvel_inquiry_bff]="$TAG:latest"
vermap[marvel_inquiry_update_api]="$TAG:latest"
vermap[marvel_rave_api]="$TAG:latest"
vermap[marvel_rave_update_api]="$TAG:latest"
vermap[marvel_ref_bff]="$TAG:latest"
vermap[marvel_review-requirements_api]="$TAG:latest"
vermap[marvel_review-requirements-bff]="$TAG:latest"
vermap[marvel_rr_update_api]="$TAG:latest"
vermap[marvel_studies_api]="$TAG:latest"
vermap[marvel_studies_bff]="$TAG:latest"
vermap[marvel_study_update_api]="$TAG:latest"
vermap[marvel-tasks-api]="$TAG:latest"
vermap[marvel_tasks_bff]="$TAG:latest"
vermap[marvel_task_update_api]="$TAG:latest"
vermap[marvel_user_api]="$TAG:latest"
vermap[marvel_user_bff]="$TAG:latest"
vermap[marvel_visualization_api]="$TAG:latest"
vermap[marvel_viz_update_api]="$TAG:latest"


for app in "${APP[@]}"; do
  repo="${appmap[$app]}"
  chosen_tag="${vermap[$app]}"

  echo "Chosen version: $VERSION | Chosen tag: $chosen_tag"

  tag_filter=$(echo "$chosen_tag" | cut -d: -f1)
  if [[ "$chosen_tag" == *":latest" ]]; then
    #echo curl -s -H "Authorization: Basic $token"  "https://jadf-docker.artifactrepo.jnj.com/v2/${repo}/tags/list" 
    tag_name=$(curl -s -H "Authorization: Basic $token"  "https://jadf-docker.artifactrepo.jnj.com/v2/${repo}/tags/list" \
      | jq -r ".tags[] | select(. | contains(\"${VERSION}-${tag_filter}-\"))" \
      | awk -F '-' '{print $NF, $0}' \
      | sort -n -k1 \
      | awk '{print $2}' \
      | tail -n 1 )

    if [[ -z "$tag_name" ]]; then
      echo "Failed to retrieve tag for $app from repository $repo"
      continue
    fi

  else
    tag_name="$chosen_tag"
  fi

  echo "$tag_name"

  values_file="../apps_marvel/${app}/$ENVNAME.values.yaml"
  existing_version=$(grep 'image:' "$values_file" -A 1 | grep 'tag:' | sed -n 's/.*tag: "\([^"]*\)".*/\1/p')
  #sed -i "s/image:\s*tag:.*/image:\n    tag: \"$tag_name\"/" "$values_file"
  if [[ "$existing_version" != "$tag_name" ]]; then
    echo "Updating $values_file with new tag: ${tag_name}"
    sed -i "/image:/,/tag:/s/tag: .*/tag: \"$tag_name\"/" "$values_file"
  else
    echo "No update needed for $app, the tag is already up to date."
  fi

done
