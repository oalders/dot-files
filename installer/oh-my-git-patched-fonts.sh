#!/bin/bash

# Partly stolen from inc/oh-my-git/README.md

# Copy the awesome fonts to ~/.fonts
cd /tmp
git clone http://github.com/gabrielelana/awesome-terminal-fonts
cd awesome-terminal-fonts
git checkout patching-strategy
open /tmp/awesome-terminal-fonts/patched/SourceCodePro+Powerline+Awesome+Regular.ttf

exit 0
