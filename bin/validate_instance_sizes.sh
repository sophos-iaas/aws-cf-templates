#!/bin/bash

# Run this from root of template repo
# it will change to tmp and validate all regions and instance sizes there

# This does not make a real difference unless it's linux
TRY_AMI="ha_byol.ami"

validate_instance(){
REGION="$1"
SIZE="$2"
AMI="$3"
CMD="../bin/_validate_instance_size.sh $REGION $SIZE $AMI"
#echo $CMD
$CMD
}

cd tmp

for i in * ; do
  if [ ! -d $i ] ; then
          continue
  fi
  validate_instance $i $(cat $i/default_instance_type.static) $(cat $i/$TRY_AMI | cut -f1)
  validate_instance $i $(cat $i/larger_instance_type.static) $(cat $i/$TRY_AMI | cut -f1)
done

cd - > /dev/null
