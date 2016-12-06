#!/bin/bash

LOCAL_DIR="$1" ; shift
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

COLORIZE_AWK_COMMAND='\
      /upload/ { printf "\033[1;32m" }\
      /delete/ { printf "\033[1;31m" }\
      // { print $0 "\033[0m"; }'


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

aws s3 sync $LOCAL_DIR s3://$BUCKET --region $REGION --profile $PROFILE --exclude "*.git*" --acl public-read --delete $MORE_ARGS | awk "$COLORIZE_AWK_COMMAND"
