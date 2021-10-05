#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC1090

# Reset PATH to keep it from being clobbered in tmux
# https://github.com/dmend/dotfiles/blob/master/.bash_profile#L3-L7
if [ -x /usr/libexec/path_helper ]; then
    # shellcheck disable=SC2123
    PATH=''
    . /etc/profile
fi

# Load .bashrc
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

if type brew &>/dev/null; then
  HOMEBREW_PREFIX="$(brew --prefix)"
  # shellcheck disable=SC1090
  if [[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]; then
    source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
  else
    for COMPLETION in "${HOMEBREW_PREFIX}/etc/bash_completion.d/"*; do
      [[ -r "$COMPLETION" ]] && source "$COMPLETION"
    done
  fi
fi

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

if which plenv > /dev/null; then eval "$(plenv init -)"; fi

if [[ -d ~/.rbenv ]]; then
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/olaf/maxmind/google-cloud-sdk/path.bash.inc' ]; then . '/Users/olaf/maxmind/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/olaf/maxmind/google-cloud-sdk/completion.bash.inc' ]; then . '/Users/olaf/maxmind/google-cloud-sdk/completion.bash.inc'; fi
GPG_TTY=$(tty)
export GPG_TTY

# Make MacOS less annoying
export BASH_SILENCE_DEPRECATION_WARNING=1

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi
