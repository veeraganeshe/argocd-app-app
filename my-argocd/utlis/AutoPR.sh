#!/bin/bash

password=$1
reviewer_password=$2

curl -X POST -u "SA-ITSUS-JADF-DEVUSR:$password" \
   -H "Content-Type: application/json" \
   -d "{
         \"title\": \"Automated PR for Marvel PreQA deployment\",
         \"description\": \"This PR is created to propose changes from the develop branch to the release GR2.2 branch.\",
         \"fromRef\": {
           \"id\": \"refs/heads/develop\"
         },
         \"toRef\": {
           \"id\": \"refs/heads/release/GR2.2\"
         }
       }" \
   "https://sourcecode.jnj.com/rest/api/1.0/projects/ASX-JADF/repos/d4u-argo/pull-requests"

# get PR id
id=$(curl -s -u SA-ITSUS-JADF-DEVUSR:"$password" -H "Content-Type: application/json" \
  "https://sourcecode.jnj.com/rest/api/1.0/projects/ASX-JADF/repos/d4u-argo/pull-requests" | \
  jq -r '.values[] | select(.title=="Automated PR for Marvel PreQA deployment") | .id')


version=$(curl -s -u SA-ITSUS-JADF-DEVUSR:"$password" \
  "https://sourcecode.jnj.com/rest/api/1.0/projects/ASX-JADF/repos/d4u-argo/pull-requests/$id" | \
  jq '.version')

# Add reviewer
curl -s -u SA-ITSUS-JADF-DEVUSR:"$password" -X PUT \
  -H "Content-Type: application/json" \
  -d "{
    \"id\": $id,
    \"version\": $version,
    \"reviewers\": [
      { \"user\": { \"name\": \"SNandhag\" } }
    ]
  }" \
  "https://sourcecode.jnj.com/rest/api/1.0/projects/ASX-JADF/repos/d4u-argo/pull-requests/$id"

# Approve PR
curl -X POST -u snandhag:"$reviewer_password" \
  -H "Content-Type: application/json" \
  "https://sourcecode.jnj.com/rest/api/1.0/projects/ASX-JADF/repos/d4u-argo/pull-requests/$id/approve"

version_merge=$(curl -s -u SA-ITSUS-JADF-DEVUSR:"$password" \
  "https://sourcecode.jnj.com/rest/api/1.0/projects/ASX-JADF/repos/d4u-argo/pull-requests/$id" | \
  jq '.version')

# Merge PR
curl -X POST -u snandhag:"$reviewer_password" \
  -H "Content-Type: application/json" \
  -d "{
        \"version\": $version_merge
      }" \
  "https://sourcecode.jnj.com/rest/api/1.0/projects/ASX-JADF/repos/d4u-argo/pull-requests/$id/merge"

