#!/usr/bin/env bats

load 'helpers.bash'

# Test::Spelling skips pod-spell.t unless `hunspell -l` works with a dictionary.
@test "hunspell flags misspelled English words" {
    [[ $(uname) == Linux ]] || skip "installer/linux.sh installs hunspell on Linux only"
    command -v hunspell >/dev/null || [[ -n ${GITHUB_ACTIONS:-} ]] || skip "hunspell not installed; run installer/linux.sh"
    run bash -c "echo 'helo wrold' | hunspell -l"
    [ "$status" -eq 0 ]
    [ "$output" = $'helo\nwrold' ]
}
