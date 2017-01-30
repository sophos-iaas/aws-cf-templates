#!/bin/bash

TRANSFORM="$1"
FILE="$2"

jq -r "$TRANSFORM" $FILE > $FILE.transform
mv $FILE.transform $FILE
