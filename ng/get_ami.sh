#!/bin/bash -e
# aws ec2 describe-images --owners 159737981378 --filters "Name=name,Values=axg9400_aws*,Name=tag:smoketest,Values=passed"
# 159737981378 verdi build
# 679593333241 amazon
# 219379113529 gov-amazon

AWS_TMP="aws.tmp"

help(){
        echo "$0"
}

PUBLIC_FILTER="Name=is-public,Values=false"

if [ $# -lt 1 ] ; then
        help
        exit 1
fi

while [[ $# -ge 1 ]] ; do
        key="$1"

        case $key in
                -r|--region)
                REGION="$2"
                shift
                ;;
                -p|--profile)
                PROFILE="$2"
                shift
                ;;
                -o|--owner)
                OWNER="$2"
                shift # past argument
                ;;
                -n|--name)
                NAME="$2"
                shift # past argument
                ;;
                -s|--smoketest-passed)
                SMOKETEST="passed"
                ;;
                -t|--tag)
                TAG="$2"
                if [[ $TAG =~ ^(.*)=(.*)$ ]] ; then
                        NAME="${BASH_REMATCH[1]}"
                        VALUES="${BASH_REMATCH[2]}"
                        TAG_FILTER="Name=tag:$NAME,Values=$VALUES"
                else
                        echo "--tag must be in format \"key=value1,value2\""
                        exit 1
                fi
                shift # past argument
                ;;
                --release)
                PUBLIC_FILTER="Name=is-public,Values=true"
                ;;
                *)
                help
                exit 1
                ;;
        esac
        shift
done

if [[ -z $REGION || -z $PROFILE || -z $OWNER || -z $NAME ]] ; then
        echo "Mandatory: region, profile, owner, name"
        exit 1
fi

get_latest_ami(){
        jq -rc ".Images | sort_by(.CreationDate) | .[-1].ImageId" $1
}

#echo aws ec2 describe-images --profile $PROFILE --region $REGION --owner $OWNER --filters "Name=name,Values=$NAME,$PUBLIC_FILTER"
aws ec2 describe-images --profile $PROFILE --region $REGION --owner $OWNER --filters "Name=name,Values=$NAME" "$PUBLIC_FILTER" > $AWS_TMP
get_latest_ami $AWS_TMP
#rm $AWS_TMP
