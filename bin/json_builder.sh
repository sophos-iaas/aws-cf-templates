#!/usr/bin/env bash

# Creats valid json output from /region/*.ami folder structure and file contents

KEY="$1"
FILENAME="$2"

for i in tmp/* ; do
  test -d $i || continue
  echo "{\"${i#*/}\":{\"$KEY\":\"$(cat $i/$FILENAME)\"}}"
done | jq -s add
