#!/usr/bin/env bash

set -eu -x -o pipefail

if [ "$#" -eq 0 ]; then
    # No arguments provided, find all .jpg, .jpeg, .JPG or .JPEG files
    files=$(find . -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.JPG' -o -iname '*.JPEG' \))
else
    # Arguments provided, use those as file names
    files="$@"
fi

for i in $files; do
    fileNoExt="${i%.*}"
    resizedFile="${fileNoExt}-600.jpeg"
    sips -Z 600 "$i" --out "$resizedFile"
    touch -r "$i" "$resizedFile"
done
