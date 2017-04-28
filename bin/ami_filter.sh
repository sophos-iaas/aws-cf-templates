#!/usr/bin/env bash

# This script filters AMIs according to specified regexes and flags

help() {
	echo "This tool filters AMIs from a JSON file according to the specified"
	echo "filters and flags."
	echo ""
	echo "  -i|--input <JSON file> (mandatory)"
	echo "  -n|--name-regex <REGEX> (mandatory)"
	echo "  --smoketest (only select AMIs with smoketest: passed tag)"
	echo "  --release (only select AMIs whose version matches release versioning)"
}

smoketest_filter="no"
regex_filter="development"

while [[ $# -ge 1 ]] ; do
	key="$1"
	case $key in
		-i|--input)
			input="$2"
			shift
		;;
		-n|--name-regex)
			regex="$2"
			shift
		;;
		--smoketest)
			smoketest_filter="yes"
		;;
		--release)
			regex_filter="release"
		;;
		--development)
			regex_filter="development"
		;;
		--wildcard)
			regex_filter="wildcard"
		;;
		*)
			help
			exit 1
		;;
	esac
	shift
done

if [[ -z $input || -z $regex ]] ; then
        help
	exit 1
fi

case $regex_filter in
	release)
	RC_FILTER="\\\d+\\\.\\\d{3}-\\\d{1,3}\\\.\\\d{1,3}"
	;;
	development)
	# 9.413-20170424.1
	RC_FILTER="\\\d+\\\.\\\d{3}-\\\d{8}\\\.\\\d{1,3}"
	;;
	wildcard)
	RC_FILTER=".*"
	;;
esac

jq -r "[.Images[]
	| select(.Name | match(\"$regex\"))
	| if \"$smoketest_filter\" == \"yes\" then
		select(.Tags != null)
		| select(.Tags
			| contains([{\"Key\":\"smoketest\",\"Value\":\"passed\"}])
		)
	  else
		.
	  end
	| select(.Name | match(\"$RC_FILTER\"))
	][-1]
	| [.ImageId, .Name]
	| @tsv" $input
