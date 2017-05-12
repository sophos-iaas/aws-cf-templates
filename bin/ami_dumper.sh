#!/usr/bin/env bash

# This script dumps all relevant AMIs (and more..) from AWS as an input for the
# specific AMI selection performed by other tools afterwards.

owner_dev=159737981378 # team verdi build account
owner_aws=679593333241 # AWS MarketPlace account
owner_gov=219379113529 # all images in GovCloud (private and public)
owner_ubuntu=099720109477 # Ubuntu images
owner_ubuntu_gov=513442679011 # Ubuntu images in GovCloud

help() {
  echo "This tool dumps all relevant AMIs (and more..) from AWS as an input"
  echo "for the specific AMI selection performed by other tools afterwards."
  echo ""
  echo "  -r|--region <region> (mandatory)"
  echo "  -o|--out <out.file> (mandatory)"
  echo "  --public (select public AMIs)"
}

while [[ $# -ge 1 ]] ; do
	key="$1"
	case $key in
		-r|--region)
		region="$2"
		shift
		;;
		-o|--out)
		out="$2"
		shift
		;;
		--public)
		public="yes"
		;;
		*)
		help
		exit 1
		;;
	esac
	shift
done

if [[ -z $region || -z $out ]] ; then
        help
	exit 1
fi

describe_images() {
  echo "aws ec2 describe-images --profile $profile --region $region"
}

# prepare public filter
if [[ $public == "yes" ]]; then
  public_filter="Name=is-public,Values=true"
else
  public_filter="Name=is-public,Values=false"
fi

if [[ $region =~ \-gov\- ]] ; then
  profile="govcloud"
    echo "AMI dumper: region: $region public: ${public-no} > ${out}"
    # All AMIs are owned by us as there is no MarketPlace available
    $(describe_images) --owner $owner_gov --filters "$public_filter" > ${out}.1
    $(describe_images) --owner $owner_ubuntu_gov --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-*" > ${out}.2
    jq -s '{ Images: (.[0].Images + .[1].Images) }' ${out}.1 ${out}.2 | \
      jq ".Images | { Images: sort_by(.CreationDate) }" > $out
else
  profile="default"
  if [[ $public == "yes" ]]; then
    echo "AMI dumper: region: $region public: $public > $out"
    # HA/AS AMIs from MarketPlace
    $(describe_images) --owner $owner_aws --filters "$public_filter" "Name=name,Values=sophos_*" > ${out}.1
    # EGW AMIs are owned by us
    $(describe_images) --owner $owner_dev --filters "$public_filter" > ${out}.2
    $(describe_images) --owner $owner_ubuntu --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-*" > ${out}.3
    jq -s '{ Images: (.[0].Images + .[1].Images + .[2].Images) }' ${out}.1 ${out}.2 ${out}.3 | \
      jq ".Images | { Images: sort_by(.CreationDate) }" > $out
  else
    echo "AMI dumper: region: $region public: no > $out"
    # All AMIs are owned by us
    $(describe_images) --owner $owner_dev --filters "$public_filter" > ${out}.1
    $(describe_images) --owner $owner_ubuntu --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-*" > ${out}.2
    jq -s '{ Images: (.[0].Images + .[1].Images) }' ${out}.1 ${out}.2 | \
      jq ".Images | { Images: sort_by(.CreationDate) }" > $out
  fi
fi