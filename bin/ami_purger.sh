#!/bin/bash

public_ami(){
  AMI="$1"
  PERMS=$(aws ec2 describe-image-attribute --image-id $AMI --attribute launchPermission --region $REGION --query 'LaunchPermissions' --output text)
  PUBLIC="no"
  for PERM in $PERMS ; do
    case $PERM in
      115629891621|159737981378|490780517948) # Playground, Buildsystem, TA
      true
      ;;
      all|*)
      PUBLIC="yes"
      ;;
    esac
  done
  echo $PUBLIC
}

days_old(){
  AMI="$1"
  CREATED=$(aws ec2 describe-images --image-id $AMI  --region $REGION --query 'Images[].CreationDate' --output text)
  CREATED=$(date -d "$CREATED" +%s)
  NOW=$(date +%s)
  # 60 days, 24h, 60m, 60s
  (( DAYS_OLD = ($NOW - $CREATED) / (24 * 60 * 60) ))
  echo $DAYS_OLD
}

clean(){
  AMI="$1"
  echo "Deleting AMI $AMI"
  SNAP=$(aws ec2 describe-images --region $REGION --image-ids "$AMI" --query 'Images[*].BlockDeviceMappings[*].Ebs.SnapshotId' --output text)
  aws ec2 deregister-image --region $REGION --image-id "$AMI"
  aws ec2 delete-snapshot --region $REGION --snapshot-id "$SNAP"
}

ALL_REGIONS=$(./bin/aws_regions.sh default)

for REGION in $ALL_REGIONS ; do
  if [[ $REGION == "us-east-1" ]] ; then
    echo -e "\n[PURGE AMI]\tregion: $REGION\tSKIPPING"
    continue
  fi
  echo -e "\n[PURGE AMI]\tregion: $REGION"

  ALL_AMIS=$(aws ec2 describe-images --region $REGION --owners self --query 'Images[].ImageId' --output text)

  for AMI in $ALL_AMIS ; do
    DAYS_OLD=$(days_old $AMI)
    if [[ $DAYS_OLD -lt 60 ]] ; then
      echo "AMI $AMI $DAYS_OLD/60 days"
      continue
    fi

    PUBLIC=$(public_ami $AMI)

    # Only delete non-public amis
    if [[ $PUBLIC == "no" ]] ; then
      clean $AMI
    else
      echo "AMI $AMI is public, will not be purged"
    fi
  done
done
