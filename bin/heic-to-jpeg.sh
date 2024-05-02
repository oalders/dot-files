#!/usr/bin/env bash

set -eu -x -o pipefail

# https://apple.stackexchange.com/a/410920

# formatOptions: low, normal, high or best

if [ "$#" -eq 0 ]; then
    # No arguments provided, find all .heic or .HEIC files
    files=$(find . -type f \( -iname '*.heic' -o -iname '*.HEIC' \))
else
    # Arguments provided, use those as file names
    files="$@"
fi

for i in $files; do
    fileNoExt="${i%.*}"
    jpgFile="${fileNoExt}_heic_conv.jpg"
    sips -s format jpeg -s formatOptions high "$i" --out "$jpgFile"
    touch -r "$i" "$jpgFile"
    rm "$i"
done
