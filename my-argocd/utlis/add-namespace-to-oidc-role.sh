#!/bin/bash

if [[ "$NAMESPACE" == "" ]]; then
        export NAMESPACE="marvel"
fi


REGION=$1

if [[ "$REGION" == "" ]]; then
	echo "Region needs to be first argument, bailing out."
	exit 1
fi

export AWS_REGION=$REGION
export AWS_DEFAULT_REGION=$REGION

ACCOUNT=$(aws sts get-caller-identity | jq -r '.Account')
K8SNAME=$(aws eks list-clusters | jq -r '.clusters[0]')
OIDC=$(aws eks describe-cluster --name $K8SNAME | jq -r '.cluster.identity.oidc.issuer' | cut -d '/' -f 5)



FILTER=$2

for i in `kubectl get -n $NAMESPACE sa | grep -v NAME | grep -v default | cut -d ' ' -f 1`; do


	if [[ "$FILTER" != "" && "$i" != *"$FILTER"* ]]; then
		continue;
	fi

	rm /tmp/new-policy.txt
cat << EOF >> /tmp/new-policy.txt
               [ {
                        "Effect": "Allow",
                        "Principal": {
                                "Federated": "arn:aws:iam::${ACCOUNT}:oidc-provider/oidc.eks.${REGION}.amazonaws.com/id/$OIDC"
                        },
                        "Action": "sts:AssumeRoleWithWebIdentity",
                        "Condition": {
                                "StringEquals": {
                                        "oidc.eks.${REGION}.amazonaws.com/id/$OIDC:aud": "sts.amazonaws.com",
                                        "oidc.eks.${REGION}.amazonaws.com/id/$OIDC:sub": "system:serviceaccount:$NAMESPACE:$i"
                                }
                        }
                } ]
EOF


        ROLENAME="eks-pod-$i"
	NAMEMATCH=$(aws iam get-role --role-name ${ROLENAME} | jq -r '.Role.AssumeRolePolicyDocument.Statement' | grep $NAMESPACE)

	if [[ "$NAMEMATCH" == *"serviceaccount"* ]]; then
		echo "Namespace NAMESPACE appears to be specified for ${ROLENAME} already, refusing to update."
		continue;
	fi

	aws iam get-role --role-name ${ROLENAME} | jq -r '.Role.AssumeRolePolicyDocument.Statement' | jq ". + $(cat /tmp/new-policy.txt)" > /tmp/combined-policies.txt
	#aws iam get-role --role-name ${ROLENAME} | jq -r '.Role.AssumeRolePolicyDocument.Statement' | jq ". + $(cat /tmp/new-policy.txt)"
	#exit 1

        POLFILE=$(mktemp)

cat << EOF >> $POLFILE
{
        "Version": "2012-10-17",
        "Statement": 
EOF

cat /tmp/combined-policies.txt >> $POLFILE


cat << EOF >> $POLFILE
        
}
EOF
        aws iam update-assume-role-policy --role-name ${ROLENAME} --policy-document file:///$POLFILE
	#cat $POLFILE
	echo "Updated ${ROLENAME} with $NAMESPACE trust."
        rm $POLFILE
done

