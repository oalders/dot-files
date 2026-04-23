#!/usr/bin/env bash

# Install font for oh-my-posh on Linux
# source: https://gist.github.com/matthewjberger/7dd7e079f282f8138a9dc3b045ebefa0?permalink_comment_id=4179773#gistcomment-4179773

declare -a fonts=(
    # BitstreamVeraSansMono
    # CodeNewRoman
    # DroidSansMono
    # FiraCode
    # FiraMono
    # Go-Mono
    # Hack
    # Hermit
    JetBrainsMono
    # Meslo
    # Noto
    # Overpass
    # ProggyClean
    # RobotoMono
    # SourceCodePro
    # SpaceMono
    # Ubuntu
    # UbuntuMono
)

version='2.2.2'
fonts_dir="${HOME}/.local/share/fonts"

if [[ ! -d $fonts_dir ]]; then
    mkdir -p "$fonts_dir"
fi

base_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}"

# Download the SHA-256 checksums file
curl --fail --location -O "$base_url/SHA-256.txt"

for font in "${fonts[@]}"; do
    zip_file="${font}.zip"
    echo "Downloading $base_url/$zip_file"
    curl --fail --location -O "$base_url/$zip_file"
    grep "$zip_file" SHA-256.txt | sha256sum --check --strict
    unzip "$zip_file" -d "$fonts_dir"
    rm "$zip_file"
done

rm -f SHA-256.txt

find "$fonts_dir" -name '*Windows Compatible*' -delete

fc-cache -fv
