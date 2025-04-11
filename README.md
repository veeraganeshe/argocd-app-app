# argocd-app-app
argocd app of app 

                                    ARGOCD DEPLOYMENT 

ARGOCD 
Argo CD is a declarative, GitOps continuous delivery tool for Kubernetes applications. It helps automate the deployment of applications to Kubernetes clusters by using Git repositories as the source of truth for defining the desired application state.

INSTALLATION OF ARGOCD
1.	Clone the d4u-argo repository in the jumpbox in which argocd needed to be installed. “https://sourcecode.jnj.com/scm/asx-jadf/d4u-argo.git”
2.	Update the domain name and hostname in argo-cd/values.
3.	The pods for running the argocd application can be installed using the command 
“helm upgrade --install d4u-argocd -f common-values-argocd.yaml argo-cd/ -n argocd”
4.	Delete if there are existing service accounts, secrets, cm's and crd's related to argocd in case if it throws error.
5.	Create Cname for the hostname.
6.	Get the login credentials by using the following command "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d”

HOW PARENT CHILD METHODOLOGY WORKS?
The parent app configuration is set up with a help of a yaml file called parent.yaml. This file corresponds to the environment in which we desire to host our application. The child app is configured with the help of another yaml file called child.yaml which corresponds to what application being hosted in respective environment specified in the parent app. 
•	The parent.yaml must be applied in the jump box in which the ARGOCD is installed. 
•	Upon applying the parent application, the parent app launches in the ARGOCD URL, and we must sync the application to launch the child application invoking the pods to get run on the respective cluster as specified in the child.yaml files of the respective applications. 
The methodology is detailed as followed.
1.	CONFIGURING THE PARENT.YAML
 

The name section corresponds to the name of the parent application(environment). The Path corresponds to the child.yaml files for launching the apps. The repoURL and target revision is set based on the requirement. Destination namespace is argocd and the server is pointed to where the argocd is getting hosted. 
We can create as many number of parent.yaml files specific to different environments like dev-for-prod, preqa etc.
2.	CONFIGURING THE CHILD.YAML FILE - It is the configuration file which sets up the specification for the child apps which are desired to be hosted on a particular destination

 

The name of the app for each child file is given accordingly as d4u-assets-api-dqo, d4u-bff-dqo, d4u-dta-api-dqo, d4u-pipeline-bff-dqo etc. The repoURL is specified and the path in which the deployment files present is given under the section “Path”. The values.yaml, dev.values.yaml are specified under the section “valueFiles”.  The destination server on which the child applications to be hosted is mentioned under the section “server” which varies according to the environment.

3.	OUR WORKING DIRECTORY STRUCTURE FOR ARGOCD 
1.	We have all our files required for argo in the repo https://sourcecode.jnj.com/scm/asx-jadf/d4u-argo.git
2.	Parent.yaml files are located in the folder /argocd_parent_files
3.	The app folder is common for all the environments which got placed in the folder /apps_cdr 
4.	The child.yaml files are located in the in different folders according to environment. For dev environment /argocd_dev_cdr and for preqa environment /argocd_preqa_cdr.
5.	The scripts and config files related to unified config is under the folder /unified-config
6.	The script for latest tag update is there in the d4u-argo folder itself as update_tag.sh
NOTE: The child and the parent yaml files must be configured according to the path given in the above directory structure. If the structure changes, then the configuration must also be changed. 

4.	GIT PUSH: Double check you are on the correct branch.  Once all the files were configured, stage all the changes done by “git add --all” , commit the changes and finally perform the “git push” to push all the changes to the repository. 

5.	APPLY PARENT.YAML: Once the git push is successful, apply the parent.yaml file in the jump box in which the ARGOCD is installed as mentioned earlier using the following command “ kubectl apply -f filename -n namespace”

6.	SYNCING THE APPLICATION IN ARGOCD: Once the kubectl is applied, the root application can be seen launched in the ARGOCD URL. The url is “d4u-argocd.jnj.com”

 

Sync the application and the respective child apps can be seen launched in ARGOCD which can be synced separately. 
Example of a child app is represented below and the sync can be done through UI 

 

Also if we click on the parent app we can see the list of child apps associated with the respective parent app.

 


7.	LOG VIEWING: The logs can be viewed for a particular pod from the event logs section through UI.

 


CRD INSTALLATION
The CRD’s required for argocd installation are as follows 
1.	applications.argoproj.io
2.	applicationsets.argoproj.io
3.	appprojects.argoproj.io
The git hub link for the above CRD’s are given below
https://github.com/argoproj/argo-cd/blob/master/manifests/crds/
The CRD’s can be installed by the following commands 
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/crds/appproject-crd.yaml
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/crds/applicationset-crd.yaml
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/crds/application-crd.yaml

The bash script is provided below 
#!/bin/bash

# Applying Argo CD CRDs

echo "Applying CRD: appproject-crd.yaml"
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/crds/appproject-crd.yaml

echo "Applying CRD: applicationset-crd.yaml"
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/crds/applicationset-crd.yaml

echo "Applying CRD: application-crd.yaml"
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/crds/application-crd.yaml

echo "All CRDs applied successfully."

                                         CLUSTER REGISTRATION
For newer environments, that particular server needs to be added in argocd cluster. Make sure that argocd CLI is installed. 
kubectl config get-contexts - apply this command in the jumpbox and get the output. Note the name of the cluster
kubectl config use-context <context-name> - This command sets the specified context as the current context in your kubeconfig file, allowing you to interact with the corresponding cluster and namespace.
Then apply the following commands for the cluster registration 
argocd login argocdtest.jnj.com --username <username> --password <password>
argocd cluster add <name of the cluster> --name <specified name>
Finally verify if the server endpoint given in the config file is visible in the argocd URL cluster page and make sure the connection status is successful. 









