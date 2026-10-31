#!/usr/bin/env bats

load 'helpers.bash'

@test "age round-trips a message" {
    [[ $(uname) == Linux ]] || skip "installer/linux.sh installs age on Linux only"
    command -v age >/dev/null || [[ -n ${GITHUB_ACTIONS:-} ]] || skip "age not installed; run installer/linux.sh"
    key="$BATS_TEST_TMPDIR/key.txt"
    age-keygen -o "$key" 2>/dev/null
    run bash -c "echo hello | age -r \$(age-keygen -y '$key') | age -d -i '$key'"
    [ "$status" -eq 0 ]
    [ "$output" = hello ]
}
