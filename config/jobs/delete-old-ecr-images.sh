# This script DELETES X old images on the ECR for this repo, 
# and DELETES all master images except the latest Y. 
# Set the X/Y/repo/region in config.
# The script is intended to be called from a Kubernetes CronJob 
# in the Production namespace.

#                    local response=$(aws ecr batch-delete-image --region $region --repository-name $repo_name --image-ids "$1")
#                    local successes=$(echo $response | jq '.imageIds | length')
#                    local failures=$(echo $response | jq '.failures | length')
#                    echo "Successes: $successes"
#                    echo "Failures: $failures"

# exit when any command fails
set -e
set -o pipefail

# Configuration
repo=correspondence/track-a-query-ecr
total_master_images_to_keep=10
days_to_keep_non_master_images=14
region=eu-west-2
# End Configuration

function image_count() {
  local image_count=$(aws ecr list-images --region $region --repository-name $repo | jq '.imageIds | length')
  echo $image_count
}

function delete_images() {
  if [[ $# -ne 1 ]]; then echo "$0: wrong number of arguments"; return 1; fi
}

master_images_to_delete=$(aws ecr describe-images --region $region --repository-name $repo | jq "{imageDetails: [.imageDetails[] | select(.imageTags // [] | any(match(\"^.*master.*$\")) )] | sort_by(.imagePushedAt) | .[0:-$total_master_images_to_keep]}")                 
master_image_count=$(echo $master_images_to_delete | jq '.imageDetails | length')
echo "Total Master Images to delete: $master_image_count"
#echo $master_images_to_delete

#retention_time_ms=$(($days_to_keep_non_master_images*60*60*24))
#retention_cut_off_epoch=$(($(date '+%s')-$retention_time_ms))
retention_cut_off_date=$(date -d "${days_to_keep_non_master_images} days ago")
echo $retention_cut_off_date
retention_cut_off_date_formatted=$(date -d "${md}" +"%Y-%m-%d")
echo retention_cut_off_date_formatted
non_master_images_to_delete=$(aws ecr describe-images --region $region --repository-name $repo | jq "{imageDetails: [.imageDetails[] | select(.imageTags // [] | any(match(\"^.*master.*$\")) | not ) | select(.imagePushedAt<=$retention_cut_off_date_formatted)]}")
non_master_image_count=$(echo $non_master_images_to_delete | jq '.imageDetails | length')
echo "Total Non-Master Images to delete: $non_master_image_count"
echo $non_master_images_to_delete

echo "Deleting Images now..."
echo "Images before clean: $(image_count)"

if [[ ${master_image_count} -gt 0 ]]; then
  master_image_digests=$(echo $master_images_to_delete | jq '[{ imageDigest: .imageDetails[].imageDigest }]')
  delete_images "$master_image_digests"
  echo "Master Image deletion complete"
else
  echo "No master images to delete"
fi

if [[ ${non_master_image_count} -gt 0 ]]; then
  non_master_image_digests=$(echo $non_master_images_to_delete | jq '[{ imageDigest: .imageDetails[].imageDigest }]')
  delete_images "$non_master_image_digests"
  echo "Non-master images deletion complete"
else
  echo "No Non-master images to delete"
fi
echo "Images after clean: $(image_count)"
echo "Job done."
