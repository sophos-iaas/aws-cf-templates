#!/usr/bin/env bash

VERSION="${1:-.*}"

if [[ $VERSION =~ ^([0-9])\.([0-9])$ ]]; then
	major=${BASH_REMATCH[1]}
	minor=${BASH_REMATCH[2]}
	lesser_minor=$(($minor-1))
	VERSION="$major.${lesser_minor}[7-9]|$major.${minor}[0-6]"
fi

echo $VERSION
