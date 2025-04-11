#!/bin/bash
token=$1


if [[ "$token" == "" ]]; then
  echo "token is not defined, first argument, bailing out."
  exit 1
fi

if [[ "$TAG" == "" ]]; then
  TAG="dev"
fi

if [[ "$EXCLUDE_TAG" == "" ]]; then
  EXCLUDE_TAG="exclude"
fi

if [[ "$ENVNAME" == "" ]]; then
  ENVNAME="dev3"
fi

# List of applications

APP=("d4u-admin-api" "d4u-inquiry-bff" "d4u-inquiry-api" "d4u-admin-bff"  "d4u-assets-api" "d4u-assets-bff" "d4u-auth-api" "d4u-bff" "d4u-common-api" "d4u-data-bff" "d4u-datamodel-bff" "d4u-dta-api" "d4u-pipeline-api" "d4u-pipeline-bff" "d4u-monitoring-api" "d4u-monitoring-bff" "d4u-rave-api" "d4u-study-api" "d4u-study-bff")

if [[ "$ENVNAME" == "dev3" ]]; then
  echo "Adding d4u-web-playground for dev3 environment execution."
  APP+=("d4u-web-playground");
fi

if [[ "$ENVNAME" == "preqa2" ]] || [[ "$ENVNAME" == "preqa-test" ]]; then
  echo "Adding d4u-web for preqa2/preqa-test environment execution."
  APP+=("d4u-web");
fi

declare -A appmap
declare -A vermap

appmap[d4u-admin-api]="d4u-admin-api"
appmap[d4u-admin-bff]="d4u-nx-workspace"
appmap[d4u-assets-api]="d4u-assets-api"
appmap[d4u-assets-bff]="d4u-nx-workspace"
appmap[d4u-auth-api]="d4u-auth-api"
appmap[d4u-bff]="d4u-nx-workspace"
appmap[d4u-common-api]="d4u-common-api"
appmap[d4u-data-bff]="d4u-nx-workspace"
appmap[d4u-datamodel-bff]="d4u-nx-workspace"
appmap[d4u-dta-api]="d4u-dta-api"
appmap[d4u-pipeline-api]="d4u-pipeline-api"
appmap[d4u-pipeline-bff]="d4u-nx-workspace"
appmap[d4u-monitoring-api]="d4u-monitoring-api"
appmap[d4u-monitoring-bff]="d4u-nx-workspace"
appmap[d4u-rave-api]="d4u-rave-api"
appmap[d4u-study-api]="d4u-study-api"
appmap[d4u-study-bff]="d4u-nx-workspace"
appmap[d4u-inquiry-api]="d4u-inquiry-api"
appmap[d4u-web]="d4u-nx-workspace"
appmap[d4u-web-playground]="d4u-nx-workspace"
appmap[d4u-inquiry-bff]="d4u-nx-workspace"

vermap[d4u-admin-api]="$TAG:latest"
vermap[d4u-admin-bff]="$TAG:latest"
vermap[d4u-assets-api]="$TAG:latest"
vermap[d4u-assets-bff]="$TAG:latest"
vermap[d4u-inquiry-bff]="$TAG:latest"
vermap[d4u-auth-api]="$TAG:latest"
vermap[d4u-bff]="$TAG:latest"
vermap[d4u-common-api]="$TAG:latest"
vermap[d4u-data-bff]="$TAG:latest"
vermap[d4u-datamodel-bff]="$TAG:latest"
vermap[d4u-dta-api]="$TAG:latest"
vermap[d4u-pipeline-api]="$TAG:latest"
vermap[d4u-pipeline-bff]="$TAG:latest"
vermap[d4u-monitoring-api]="$TAG:latest"
vermap[d4u-monitoring-bff]="$TAG:latest"
vermap[d4u-rave-api]="$TAG:latest"
vermap[d4u-study-api]="$TAG:latest"
vermap[d4u-study-bff]="$TAG:latest"
vermap[d4u-inquiry-api]="$TAG:latest"
vermap[d4u-web]="$TAG:latest"
vermap[d4u-web-playground]="$TAG:latest"

for app in "${APP[@]}"; do
  repo="${appmap[$app]}"
  chosen_tag="${vermap[$app]}"

  echo "Chosen tag: $chosen_tag"

  tag_filter=$(echo "$chosen_tag" | cut -d: -f1)
  if [[ "$chosen_tag" == *":latest" ]]; then
    tag_name=$(curl -s -H "Authorization: Basic $token"  "https://jadf-docker.artifactrepo.jnj.com/v2/${repo}/tags/list" \
      | jq -r ".tags[] | select(. | contains(\"$tag_filter\") and (contains(\"$EXCLUDE_TAG\") | not))" \
      | sort -V \
      | tail -n 1)

    if [[ -z "$tag_name" ]]; then
      echo "Failed to retrieve tag for $app from repository $repo"
      continue
    fi

  else
    tag_name="$chosen_tag"
  fi

  echo "$tag_name"

 values_file="../apps_cdr/${app}/$ENVNAME.values.yaml"
 existing_version=$(grep 'image:' "$values_file" -A 1 | grep 'tag:' | sed -n 's/.*tag: "\([^"]*\)".*/\1/p')
 #sed -i "s/image:\s*tag:.*/image:\n    tag: \"$tag_name\"/" "$values_file"
 if [[ "$existing_version" != "$tag_name" ]]; then
    echo "Updating $values_file for $app with new tag: ${tag_name}"
    sed -i "/image:/,/tag:/s/tag: .*/tag: \"$tag_name\"/" "$values_file"
  else
    echo "No update needed for $app, the tag is already up to date."
  fi

done
