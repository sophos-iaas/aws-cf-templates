#!/bin/bash
# Requirements:
# pip install aws-amicleaner

ALL_REGIONS=$(./bin/aws_regions.sh default)
NUMBER_OF_AMIS_TO_KEEP=10

YESNO="n"

case "${1-dry}" in
  "act")
  YESNO="y"
  echo "Running act-run --- Will purge AMIs"
  ;;
  *)
  echo "Running dry-run --- Only report which AMIs to purge"
  ;;
esac

for REGION in $ALL_REGIONS ; do
  if [[ $REGION == "us-east-1" ]] ; then
    echo -e "\n[PURGE AMI]\tregion: $REGION\tSKIPPING"
    continue
  fi
  echo -e "\n[PURGE AMI]\tregion: $REGION"
  export AWS_DEFAULT_REGION="$REGION"
  yes $YESNO 2>/dev/null | amicleaner --keep-previous $NUMBER_OF_AMIS_TO_KEEP --mapping-key name --mapping-values byol mp
done
