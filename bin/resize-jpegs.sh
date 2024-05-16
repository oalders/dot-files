#!/usr/bin/env bash

set -eux -o pipefail

if [ "$#" -eq 0 ]; then
    # No arguments provided, find files
    mapfile -t files < <(fd . -e jpg -e jpeg)
else
    # Arguments provided, use those as file names
    files=("$@")
fi

width=600
newSuffix="-${width}.jpeg"

for file in "${files[@]}"; do
    if [[ $file == *$newSuffix ]]; then
        echo "skipping $file"
        continue
    fi
    fileNoExt="${file%.*}"
    sips -Z $width "$file" --out "${fileNoExt}${newSuffix}"
done
