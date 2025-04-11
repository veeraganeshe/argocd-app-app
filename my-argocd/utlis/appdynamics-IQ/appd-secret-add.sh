#!/bin/bash

cd /root/d4u-marvel-infra/eks-install

APP=(
    "marvel_inquiry_api" "marvel_rave_update_api_test" "marvel_studies_api" "marvel_task_update_api"
    "marvel_datareview_bff" "marvel_inquiry_bff" "marvel_ref_bff" "marvel_studies_bff" "marvel_user_api"
    "d4u-marvel-web" "marvel_flags_api" "marvel_inquiry_update_api" "marvel_review-requirements_api" "marvel_study_update_api" "marvel_user_bff"
    "d4u_smart_compose_bff" "marvel_flags_bff" "marvel_rave_api" "marvel_review-requirements-bff" "marvel-tasks-api" "marvel_visualization_api"
    "marvel_flags_update_api" "marvel_rave_update_api" "marvel_rr_update_api" "marvel_tasks_bff" "marvel_viz_update_api"
)

for app in "${APP[@]}"; do
    cd "$app/_scm_helm" || continue

    sed -i '/- name: creds-jnj-1/d' values.yaml

    grep -q 'name: creds-jnj-1' values.yaml || sed -i '/imagePullSecrets:/a \ \ - name: creds-jnj-1' values.yaml

    cd ../..
done
