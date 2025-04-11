dest_dir=$1
env_name=$2
env=$3
eks_cluster=$4 
targetbranch=$5

mkdir -p "$dest_dir"

cp -r argocd_dev-test_marvel/* "$dest_dir"

for FILE in "$dest_dir"/*; do
    if [[ -f "$FILE" ]]; then
        filename=$(basename "$FILE")
        base_name="${filename%-test-cer.yaml}"
        new_filename="${base_name}-${env_name}.yaml"
        mv "$FILE" "$dest_dir/$new_filename"
	env_file="$dest_dir/$new_filename"
	sed -i "s/\<dev\>/$env/g" "$env_file"
	sed -i "s/test-cer/"$env_name"/g" "$env_file"
	sed -i "s#develop#$targetbranch#g" "$env_file"
	sed -i "s|https://39236AB00F617DB990DB59EEA78ADE08.gr7.us-east-1.eks.amazonaws.com|$eks_cluster|g" "$env_file"
    fi
 done
