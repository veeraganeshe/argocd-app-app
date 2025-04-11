#!/bin/bash

curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64

chmod +x argocd-linux-amd64

mv argocd-linux-amd64 /usr/local/bin/argocd

argocd version

