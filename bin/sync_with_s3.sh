#!/bin/bash

DIR="$1" ; shift
BUCKET="$1" ; shift
PROFILE="$1" ; shift
REGION="$1" ; shift
DRY="$1"

help(){
        echo "$0: LOCAL_DIR BUCKET PROFILE REGION [dry|act]"
        echo -e "\tLOCAL_DIR:\tlocal directory to upload/sync to s3"
        echo -e "\tBUCKET:\t\ts3 bucket to sync to"
        echo -e "\tPROFILE:\taws profile to use"
        echo -e "\tREGION:\t\tregion the s3 bucket is located"
        echo -e "\tact:\t\texecute changes"
        echo -e "\tdry:\t\tdry-run (only print what would be done, do not do any changes)"
}

case $DRY in
        dry)
        MORE_ARGS="--dryrun"
        ;;
        act)
        ;;
        *)
        help
        exit 1
        ;;
esac

aws s3 sync $DIR s3://$BUCKET --region $REGION --profile $PROFILE --exclude "$DIR/.git*" $MORE_ARGS
for i in `aws s3api list-objects --bucket $BUCKET --region $REGION --profile $PROFILE | jq -r '.[][].Key'` ; do
  if [ ! -f $DIR/$i ] ; then
          if [[ $DRY == "act" ]] ; then
                  echo "file not found $i. Deleting on S3"
                  aws s3api delete-object --bucket $BUCKET --region $REGION --profile $PROFILE --key $i
          else
                  echo "(dryrun) file not found $i. Deleting on S3"
          fi
  fi
done
