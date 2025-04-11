#!/bin/bash

kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/crds/appproject-crd.yaml

kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/crds/applicationset-crd.yaml

kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/crds/application-crd.yaml

