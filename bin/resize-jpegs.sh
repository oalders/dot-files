#!/usr/bin/env bash

set -eu -o pipefail

if [ "$#" -eq 0 ]; then
    # No arguments provided, find files
    files=$(fd . -e jpg -e jpeg)
else
    # Arguments provided, use those as file names
    files="$@"
fi

width=600
for i in $files; do
    newSuffix="-${width}.jpeg"
if [[ $i == *$newSuffix ]]; then
        continue
    fi
    fileNoExt="${i%.*}"
    resizedFile="${fileNoExt}${newSuffix}"
    sips -Z $width "$i" --out "$resizedFile"
done
