#!/bin/bash

# The AMI can be queried from the templates like:
# cat templates/utm/autoscaling.template  | jq -r '.Mappings.RegionMap."us-gov-west-1".BYOL'

help(){
  echo "$0: AMI [dry|act]"
}

get_ami_public(){
  aws ec2 describe-images --profile govcloud --image-ids $1 --query 'Images[0].Public'
}

set_ami_public(){
  aws ec2 modify-image-attribute --profile govcloud --image-id $1 --launch-permission "{\"Add\": [{\"Group\":\"all\"}]}"
}

AMI="$1"
DRY="$2"

[[ "$DRY" == "act" ]] && set_ami_public $AMI

RESULT=$(get_ami_public $AMI 2>&1)
if [[ "$RESULT" == "true" ]] ; then
  echo -e "AMI $AMI is \033[0;32mPUBLIC\033[0m"
else
  echo -e "AMI $AMI is \033[0;31mPRIVATE\033[0m"
  echo "RESULT: $RESULT"
  exit 1
fi
