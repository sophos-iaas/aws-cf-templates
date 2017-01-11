#!/bin/bash

help(){
	echo "$0 [REGION] [SIZE] [AMI]"
}

if [[ $# -ne 3 ]] ; then
  help
  exit 1
fi

REGION=$1
SIZE=$2
AMI=$3
PROFILE=""

if [[ $REGION =~ gov ]] ; then
	PROFILE="--profile govcloud"
fi

PASS_STRING="Request would have succeeded, but DryRun flag is set."
REPORT_STRING="[INSTANCE_CHECK]\t$REGION\t$SIZE\t$AMI"

SOME_SUBNET=$(aws ec2 describe-subnets $PROFILE --region $REGION --query "Subnets[0].SubnetId" --output text)

OUT=$(aws ec2 run-instances $PROFILE --region $REGION --image-id $AMI --count 1 --instance-type $SIZE --key-name verdi-dev --subnet-id $SOME_SUBNET --dry-run 2<&1 )

if [[ $OUT =~ $PASS_STRING ]] ; then
  echo -e "$REPORT_STRING\tPASSED"
  exit 0
else
  echo -e "$REPORT_STRING\tFAILED"
  echo $OUT
  exit 1
fi
