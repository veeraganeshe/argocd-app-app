helm uninstall appdynamics -n appdynamics

kubectl delete crd clusteragents.cluster.appdynamics.com

kubectl delete crd infravizs.cluster.appdynamics.com

helm repo remove appdynamics-cloud-helmcharts

kubectl delete secrets creds-jnj-1 -n marvel

kubectl delete ns appdynamics
