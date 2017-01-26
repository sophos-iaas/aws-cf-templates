#!/bin/bash

ALL_REGIONS=$(./bin/aws_regions.sh default)
NUMBER_OF_AMIS_TO_KEEP=10
DRYRUN=${1-dry}

case "$DRYRUN" in
  "act")
  echo "ACT"
  DRYRUN="y"
  ;;
  *)
  echo "DRY"
  DRYRUN="n"
  ;;
esac

export AWS_PROFILE="copyimage"

for REGION in $ALL_REGIONS ; do
  if [[ $REGION == "us-east-1" ]] ; then
    echo -e "\n[PURGE AMI]\tregion: $REGION\tSKIPPING"
    continue
  fi
  echo -e "\n[PURGE AMI]\tregion: $REGION"
  export AWS_DEFAULT_REGION="$REGION"
  yes $DRYRUN | amicleaner --keep-previous $NUMBER_OF_AMIS_TO_KEEP --mapping-key name --mapping-values byol mp
done
