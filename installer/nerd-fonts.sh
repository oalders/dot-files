#!/bin/bash

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

if [[ ! -d "$fonts_dir" ]]; then
    mkdir -p "$fonts_dir"
fi

for font in "${fonts[@]}"; do
    zip_file="${font}.zip"
    download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/${zip_file}"
    echo "Downloading $download_url"
    wget "$download_url"
    unzip "$zip_file" -d "$fonts_dir"
    rm "$zip_file"
done

find "$fonts_dir" -name '*Windows Compatible*' -delete

fc-cache -fv
