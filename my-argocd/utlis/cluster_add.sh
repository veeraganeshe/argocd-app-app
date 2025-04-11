#!/bin/bash

password=$1
cluster_name=$2
context=$(kubectl config current-context)
kubectl config use-context "$context"
argocd login d4u-argocd.jnj.com --username admin --password $password --insecure
argocd cluster add "$context"

