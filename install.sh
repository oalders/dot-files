#!/usr/bin/env bash

set -eu -o pipefail

./installer/ubi.sh

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh

./installer/symlinks.sh

run_installer() {
    echo "running $1"
    echo ""
    time bash "$1"
    echo ""
}

run_installers() {
    local installers=("$@")
    for installer in "${installers[@]}"; do
        run_installer "$installer"
    done
}

add_path "$HOME/local/bin"

run_mac_installers() {
    local mac_installers=(
        ./installer/xcode.sh
        # ./installer/fonts.sh
        # https://github.com/kcrawford/dockutil/issues/127
        # ./installer/dockutil.sh
        #./configure/dock.sh
        ./configure/macos.sh
        ./installer/spoon-installer.sh
        ./installer/tailscale.sh
    )

    run_installers "${mac_installers[@]}"
    # Ventura (macOS 13) is past Homebrew's bottle support, so `brew upgrade`
    # recompiles dependencies (llvm, etc.) from source and grinds the disk for
    # hours. Throttle it to roughly once a year there; daily on supported macOS.
    if is os version-codename eq ventura; then
        debounce 365 d ./installer/homebrew.sh
    else
        debounce 1 d ./installer/homebrew.sh
    fi
}

run_general_installers() {
    local installers=(
        ./installer/linux.sh
        ./installer/nix.sh
        ./installer/terraform.sh
        ./configure/lid-poweroff.sh
        ./configure/power-profile.sh
        ./configure/touchpad-dwt.sh
        ./installer/wezterm.sh
        ./configure/git.sh
        ./configure/ssh.sh
        ./installer/nvim.sh
        ./configure/vim.sh
        ./configure/tmux.sh
        ./installer/npm.sh
        ./installer/codex.sh
        ./installer/cpan.sh
        ./installer/cargo.sh
        ./installer/imgcat.sh
        ./configure/bat.sh
        ./configure/claude-settings.sh
        ./installer/oh-my-posh.sh
    )

    run_installers "${installers[@]}"
    debounce 30 days ./configure/eza.sh
    debounce 7 d ./installer/maintenance.sh

    # Seed the shared Playwright Chromium bundle only on the dev box that runs
    # browser-driven tests under nono. See nono/CLAUDE.md.
    if is cli output stdout "hostname" eq "olaf-dev"; then
        run_installer ./installer/playwright-mcp.sh
    fi
}

if is os name eq darwin; then
    run_mac_installers
    if ! is there rectangle && ! test -d /Applications/Rectangle.app; then
        brew install --cask rectangle
        defaults write com.knollsoft.Rectangle launchOnLogin -bool true
    fi
    defaults write com.knollsoft.Rectangle screenEdgeGapTop -int 0
    debounce 30 d ./configure/screenshots.sh

    # On this old Ventura (macOS 13) box, photoanalysisd grinds the disk for
    # days and never finishes; keep it disabled since an OS update can silently
    # re-enable it. print-disabled needs no sudo, so only pay the sudo prompt
    # when it has actually been re-enabled. See memory: photoanalysisd-disabled.
    if is os version --major eq 13 &&
        ! launchctl print-disabled "gui/$(id -u)" |
        grep -q '"com.apple.photoanalysisd" => disabled'; then
        sudo launchctl disable "gui/$(id -u)/com.apple.photoanalysisd"
    fi
fi

run_general_installers

exit 0
