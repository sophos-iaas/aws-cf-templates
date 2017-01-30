#!/usr/bin/env bash

# Optional arguments: AWS profile list, default: default govcloud
# Returns all regions accessible by the provided AWS profiles

aws_profiles=""

aws_regions() {
  regions=$(aws ec2 describe-regions --profile $1)
  if [ ! $? -eq 0 ]; then
    echo "profile in question: $1" >&2
  fi
  echo $(echo $regions | jq -r ".Regions[].RegionName")
}

if [[ -z "$@" ]]; then
  aws_profiles="default govcloud"
else
  aws_profiles=$@
fi

all_regions=""
for profile in $aws_profiles; do
  all_regions+="$(aws_regions $profile) "
done
echo $all_regions
