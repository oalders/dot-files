#!/usr/bin/env bash

set -eu -x -o pipefail

# https://apple.stackexchange.com/a/410920

# formatOptions: low, normal, high or best

find . -type f -iname '*.heic' | while read -r i; do \
  fileNoExt="${i%.*}"; \
  jpgFile="${fileNoExt}_heic_conv.jpg"; \
  sips -s format jpeg -s formatOptions high "$i" --out "$jpgFile"; \
  touch -r "$i" "$jpgFile"; \
  rm "$i"; \
done
