dest_dir=$1
env_name=$2
env=$3
eks_cluster=$4 

mkdir -p "$dest_dir"

cp -r argocd_dev_cdr/* "$dest_dir"

for FILE in "$dest_dir"/*; do
    if [[ -f "$FILE" ]]; then
        filename=$(basename "$FILE")
        base_name="${filename%-dqq.yaml}"
        new_filename="${base_name}-${env_name}.yaml"
        mv "$FILE" "$dest_dir/$new_filename"
	env_file="$dest_dir/$new_filename"
	sed -i "s/\<dev\>/$env/g" "$env_file"
	sed -i "s/dqq/"$env_name"/g" "$env_file"
	sed -i "s|https://kubernetes.default.svc|$eks_cluster|g" "$env_file"
    fi
 done
