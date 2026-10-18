#!/usr/bin/env bats

load 'helpers.bash'

setup() {
    setup_sandbox
    GIT_ORIGIN="$BIN_DIR/git-origin"
    setup_git_repo
    stub_command is 'exit 0'
    stub_command gh 'echo "$@" >>"$BATS_TEST_TMPDIR/gh.log"'
}

# Route every form of the test URL to a local bare repo so ssh/https can run
# their default-branch sync without the network.
setup_fake_github() {
    UPSTREAM_DIR="$BATS_TEST_TMPDIR/upstream.git"
    git init --bare -q -b main "$UPSTREAM_DIR"
    git push -q "$UPSTREAM_DIR" main
    local form
    for form in https://github.com/oalders/dot-files.git \
        git@github.com:oalders/dot-files.git \
        https://codeberg.org/oalders/dot-files.git; do
        git config --add "url.$UPSTREAM_DIR.insteadOf" "$form"
    done
}

@test "git-origin ssh converts an https origin" {
    setup_fake_github
    git remote add origin https://github.com/oalders/dot-files.git
    run "$GIT_ORIGIN" ssh
    [ "$status" -eq 0 ]
    [ "$(git config --get remote.origin.url)" = "git@github.com:oalders/dot-files.git" ]
    grep -qx 'config set -h github.com git_protocol ssh' "$BATS_TEST_TMPDIR/gh.log"
}

@test "git-origin https converts an scp-style origin and syncs the default branch" {
    setup_fake_github
    git remote add origin git@github.com:oalders/dot-files.git
    run "$GIT_ORIGIN" https
    [ "$status" -eq 0 ]
    [ "$(git config --get remote.origin.url)" = "https://github.com/oalders/dot-files.git" ]
    grep -qx 'config set -h github.com git_protocol https' "$BATS_TEST_TMPDIR/gh.log"
    [ "$(git rev-parse --abbrev-ref main@{u})" = "origin/main" ]
    [ "$(git symbolic-ref --short refs/remotes/origin/HEAD)" = "origin/main" ]
}

@test "git-origin https converts a non-GitHub ssh:// origin without touching gh" {
    setup_fake_github
    git remote add origin ssh://git@codeberg.org/oalders/dot-files
    run "$GIT_ORIGIN" https
    [ "$status" -eq 0 ]
    [ "$(git config --get remote.origin.url)" = "https://codeberg.org/oalders/dot-files.git" ]
    [ ! -e "$BATS_TEST_TMPDIR/gh.log" ]
}

@test "git-origin keeps branch upstream config" {
    setup_fake_github
    git remote add origin https://github.com/oalders/dot-files.git
    git fetch -q origin
    git branch -q -u origin/main
    run "$GIT_ORIGIN" ssh
    [ "$status" -eq 0 ]
    [ "$(git config branch.main.remote)" = "origin" ]
}

@test "git-origin default-branch renames local master to main" {
    git branch -m main master
    UPSTREAM_DIR="$BATS_TEST_TMPDIR/upstream.git"
    git init --bare -q -b main "$UPSTREAM_DIR"
    git remote add origin "$UPSTREAM_DIR"
    git push -q origin master:main

    run "$GIT_ORIGIN" default-branch
    [ "$status" -eq 0 ]
    [ "$(git branch --show-current)" = "main" ]
    [ "$(git rev-parse --abbrev-ref main@{u})" = "origin/main" ]
    [ "$(git symbolic-ref --short refs/remotes/origin/HEAD)" = "origin/main" ]
}

@test "git-origin default-branch fails for a missing remote branch" {
    setup_upstream
    run "$GIT_ORIGIN" default-branch master
    [ "$status" -ne 0 ]
    [[ "$output" == *"origin/master does not exist"* ]]
}

@test "git-origin refuses a URL without owner/repo" {
    git remote add origin git@github.com:.git
    run "$GIT_ORIGIN" https
    [ "$status" -ne 0 ]
    [ "$(git config --get remote.origin.url)" = "git@github.com:.git" ]
}

@test "git-origin ssh strips a trailing slash" {
    setup_fake_github
    git remote add origin https://github.com/oalders/dot-files/
    run "$GIT_ORIGIN" ssh
    [ "$status" -eq 0 ]
    [ "$(git config --get remote.origin.url)" = "git@github.com:oalders/dot-files.git" ]
}

@test "git-origin reports a missing origin remote" {
    run "$GIT_ORIGIN" https
    [ "$status" -ne 0 ]
    [[ "$output" == *"No origin remote configured"* ]]
}

@test "git-origin still syncs the default branch when gh config fails" {
    setup_fake_github
    stub_command gh 'exit 1'
    git remote add origin git@github.com:oalders/dot-files.git
    run "$GIT_ORIGIN" https
    [ "$status" -eq 0 ]
    [[ "$output" == *"warning: could not set gh git_protocol"* ]]
    [ "$(git symbolic-ref --short refs/remotes/origin/HEAD)" = "origin/main" ]
}

@test "git-origin rejects extra arguments" {
    git remote add origin git@github.com:oalders/dot-files.git
    run "$GIT_ORIGIN" https extra
    [ "$status" -ne 0 ]
    [ "$(git config --get remote.origin.url)" = "git@github.com:oalders/dot-files.git" ]
}
