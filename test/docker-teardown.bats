#!/usr/bin/env bats

load 'helpers.bash'

# A `docker` stub that emulates just the queries docker-teardown makes, driven
# by env vars the tests set:
#   DOCKER_DAEMON_OK      "1" (default) => `docker ps -q` succeeds; else fails.
#   DOCKER_COMPOSE_ROWS   file of "<id><TAB><working_dir>" lines returned for
#                         the compose label query.
#   DOCKER_DEV_ID         id returned for the `--filter name=...` (bin/dev)
#                         query; empty => no dev container.
#   DOCKER_RM_LOG         file the stub appends `rm` arguments to, so a test
#                         can assert exactly which ids were removed.
#   DOCKER_IMAGE_LOCAL    "1" (default) => `docker image inspect` succeeds, so
#                         the reclaim step finds a local image.
#   DOCKER_RUN_LOG        file the stub appends `run` arguments to, so a test
#                         can assert how the ownership-reclaim container ran.
#   DOCKER_NETWORK_ROWS   file of "<project><TAB><id><TAB><name>" lines; the
#                         `network ls` query emits the id/name of rows whose
#                         project matches the requested label filter.
#   DOCKER_NETWORK_ATTACHED file of "<id><TAB><count>" lines giving the
#                         attached-container count `network inspect` reports for
#                         a network; a network absent from the file counts 0.
#   DOCKER_NETRM_LOG      file the stub appends `network rm` arguments to, so a
#                         test can assert which networks were removed.
docker_stub_body='
case "${1:-}" in
ps)
    shift
    if [ "${1:-}" = "-q" ] && [ "$#" -eq 1 ]; then
        [ "${DOCKER_DAEMON_OK:-1}" = "1" ] && exit 0 || exit 1
    fi
    label_filter=""; name_filter=""; id_filter=""
    while [ "$#" -gt 0 ]; do
        case "$1" in
        --filter)
            shift
            case "$1" in
            label=*) label_filter="${1#label=}" ;;
            name=*) name_filter="${1#name=}" ;;
            id=*) id_filter="${1#id=}" ;;
            esac
            ;;
        --format) shift ;;
        esac
        shift
    done
    if [ -n "$name_filter" ]; then
        [ -n "${DOCKER_DEV_ID:-}" ] && echo "$DOCKER_DEV_ID"
        exit 0
    fi
    if [ -n "$id_filter" ]; then
        echo "  $id_filter  name-$id_filter  Up"
        exit 0
    fi
    if [ -n "$label_filter" ]; then
        [ -f "${DOCKER_COMPOSE_ROWS:-/nonexistent}" ] && cat "$DOCKER_COMPOSE_ROWS"
        exit 0
    fi
    exit 0
    ;;
rm)
    shift
    printf "%s\n" "$*" >>"${DOCKER_RM_LOG:?}"
    exit 0
    ;;
image)
    [ "${DOCKER_IMAGE_LOCAL:-1}" = "1" ] && exit 0 || exit 1
    ;;
run)
    shift
    printf "%s\n" "$*" >>"${DOCKER_RUN_LOG:?}"
    exit 0
    ;;
network)
    shift
    case "${1:-}" in
    ls)
        shift
        proj=""
        while [ "$#" -gt 0 ]; do
            case "$1" in
            --filter)
                shift
                case "$1" in
                label=com.docker.compose.project=*)
                    proj="${1#label=com.docker.compose.project=}"
                    ;;
                esac
                ;;
            --format) shift ;;
            esac
            shift
        done
        if [ -f "${DOCKER_NETWORK_ROWS:-/nonexistent}" ]; then
            while IFS="$(printf "\t")" read -r p id name; do
                [ "$p" = "$proj" ] && printf "%s\t%s\n" "$id" "$name"
            done <"$DOCKER_NETWORK_ROWS"
        fi
        exit 0
        ;;
    inspect)
        shift
        net="$1"
        count=0
        if [ -f "${DOCKER_NETWORK_ATTACHED:-/nonexistent}" ]; then
            while IFS="$(printf "\t")" read -r n c; do
                [ "$n" = "$net" ] && count="$c"
            done <"$DOCKER_NETWORK_ATTACHED"
        fi
        echo "$count"
        exit 0
        ;;
    rm)
        shift
        printf "%s\n" "$*" >>"${DOCKER_NETRM_LOG:?}"
        exit 0
        ;;
    esac
    exit 0
    ;;
esac
exit 0
'

setup() {
    setup_sandbox
    DT="$BIN_DIR/docker-teardown"
    # A path we never create, so docker-teardown skips symlink resolution and
    # uses it verbatim — keeps label fixtures deterministic.
    WT="$BATS_TEST_TMPDIR/wt"
    RM_LOG="$BATS_TEST_TMPDIR/rm.log"
    : >"$RM_LOG"
    export DOCKER_RM_LOG="$RM_LOG"
    RUN_LOG="$BATS_TEST_TMPDIR/run.log"
    : >"$RUN_LOG"
    export DOCKER_RUN_LOG="$RUN_LOG"
    NETRM_LOG="$BATS_TEST_TMPDIR/netrm.log"
    : >"$NETRM_LOG"
    export DOCKER_NETRM_LOG="$NETRM_LOG"
    stub_command docker "$docker_stub_body"
}

# A worktree-shaped directory whose contents are all ours. Sets WT to it,
# replacing the never-created default so the ownership-reclaim step runs.
make_real_worktree() {
    WT="$BATS_TEST_TMPDIR/real-wt"
    mkdir -p "$WT/live-mysql-data"
    echo x >"$WT/live-mysql-data/ibdata"
}

@test "docker-teardown prints usage and exits 2 with no args" {
    run "$DT"
    [ "$status" -eq 2 ]
    [[ "$output" == *"Usage: docker-teardown"* ]]
}

@test "docker-teardown -h exits 0" {
    run "$DT" -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: docker-teardown"* ]]
}

@test "docker-teardown rejects unknown option with exit 2" {
    run "$DT" --bogus "$WT"
    [ "$status" -eq 2 ]
    [[ "$output" == *"unknown option"* ]]
}

@test "docker-teardown exits 0 and removes nothing when the daemon is unreachable" {
    DOCKER_DAEMON_OK=0 run "$DT" "$WT" feature
    [ "$status" -eq 0 ]
    [[ "$output" == *"daemon unreachable"* ]]
    [ ! -s "$RM_LOG" ]
}

@test "docker-teardown reports no owned containers when nothing matches" {
    run "$DT" "$WT" feature
    [ "$status" -eq 0 ]
    [[ "$output" == *"no worktree-owned containers"* ]]
    [ ! -s "$RM_LOG" ]
}

@test "docker-teardown removes only compose containers under the worktree" {
    rows="$BATS_TEST_TMPDIR/rows"
    # One container at the worktree, one under a subdir (both owned), and one
    # at an unrelated path (must be left alone).
    printf 'aaa111\t%s\n' "$WT" >"$rows"
    printf 'bbb222\t%s/subdir\n' "$WT" >>"$rows"
    printf 'ccc333\t%s\n' "$BATS_TEST_TMPDIR/other" >>"$rows"
    export DOCKER_COMPOSE_ROWS="$rows"

    run "$DT" "$WT"
    [ "$status" -eq 0 ]

    removed="$(cat "$RM_LOG")"
    [[ "$removed" == *aaa111* ]]
    [[ "$removed" == *bbb222* ]]
    [[ "$removed" != *ccc333* ]]
}

@test "docker-teardown removes the bin/dev container for the worktree+branch" {
    export DOCKER_DEV_ID=abc123
    run "$DT" "$WT" feature
    [ "$status" -eq 0 ]
    [[ "$(cat "$RM_LOG")" == *abc123* ]]
}

@test "docker-teardown dry-run lists targets but removes nothing" {
    export DOCKER_DEV_ID=abc123
    run "$DT" --dry-run "$WT" feature
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY RUN"* ]]
    [[ "$output" == *abc123* ]]
    [ ! -s "$RM_LOG" ]
}

# --- ownership reclaim ---------------------------------------------------
#
# The reclaim step exists because a compose service that bind-mounts a
# worktree directory writes it as root, and `git worktree remove --force`
# then dies with "Permission denied" *after* unregistering the worktree.
# Creating a genuinely root-owned file in a test would need sudo, so these
# tests stub `find` to report one instead — the stub PATH shadows it for
# docker-teardown just as it does `docker`.

@test "reclaim: no container is started when every path is already ours" {
    make_real_worktree
    run "$DT" "$WT" feature
    [ "$status" -eq 0 ]
    [[ "$output" != *"reclaiming"* ]]
    [ ! -s "$RUN_LOG" ]
}

@test "reclaim: a root-owned path triggers a chown container over the worktree" {
    make_real_worktree
    stub_command find "printf '%s\n' \"\$2/live-mysql-data\""
    run "$DT" "$WT" feature
    [ "$status" -eq 0 ]
    [[ "$output" == *"reclaiming"* ]]
    started="$(cat "$RUN_LOG")"
    # Mounts exactly the worktree, and chowns to the invoking user.
    [[ "$started" == *"-v $WT:/wt"* ]]
    [[ "$started" == *"chown -h $(id -u):$(id -g)"* ]]
    # Never reaches the network, and never touches .git.
    [[ "$started" == *"--network none"* ]]
    [[ "$started" == *"-name .git -prune"* ]]
}

@test "reclaim: dry-run reports the root-owned paths but starts no container" {
    make_real_worktree
    stub_command find "printf '%s\n' \"\$2/live-mysql-data\""
    run "$DT" --dry-run "$WT" feature
    [ "$status" -eq 0 ]
    [[ "$output" == *"would chown"* ]]
    [[ "$output" == *"live-mysql-data"* ]]
    [ ! -s "$RUN_LOG" ]
}

@test "reclaim: a failed chown container warns but still exits 0" {
    make_real_worktree
    stub_command find "printf '%s\n' \"\$2/live-mysql-data\""
    # Re-stub docker so only `run` fails. No containers match in this test, so
    # the trimmed `ps` handling is enough.
    stub_command docker "case \"\${1:-}\" in
ps) exit 0 ;;
image) exit 0 ;;
run) exit 1 ;;
network) exit 0 ;;
esac
exit 0"
    run "$DT" "$WT" feature
    # Teardown must never block worktree removal on docker.
    [ "$status" -eq 0 ]
    [[ "$output" == *"could not reclaim"* ]]
}

# --- compose network sweep -----------------------------------------------
#
# The real leak: containers are gone but a `<basename>_default` network with
# zero attachments survives. The sweep infers the compose project name from the
# worktree basename ("wt" here) and removes the empty network. Guard: a network
# with an attached container is left alone. It also honours project names
# derived from matched containers, mirrors the container dry-run style, and is a
# no-op when nothing matches.

@test "network sweep removes a stale empty network for the worktree basename" {
    nets="$BATS_TEST_TMPDIR/nets"
    # basename of WT is "wt"; compose's default project would be "wt".
    printf 'wt\taaa111\twt_default\n' >"$nets"
    export DOCKER_NETWORK_ROWS="$nets"

    run "$DT" "$WT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"removing 1 network(s)"* ]]
    [[ "$(cat "$NETRM_LOG")" == *aaa111* ]]
}

@test "network sweep leaves a network that still has attached containers" {
    nets="$BATS_TEST_TMPDIR/nets"
    printf 'wt\taaa111\twt_default\n' >"$nets"
    export DOCKER_NETWORK_ROWS="$nets"
    attached="$BATS_TEST_TMPDIR/attached"
    printf 'aaa111\t2\n' >"$attached"
    export DOCKER_NETWORK_ATTACHED="$attached"

    run "$DT" "$WT"
    [ "$status" -eq 0 ]
    [ ! -s "$NETRM_LOG" ]
}

@test "network sweep removes a network derived from a matched container's project" {
    rows="$BATS_TEST_TMPDIR/rows"
    # A matched container carrying a compose project label whose value differs
    # from the worktree basename.
    printf 'aaa111\t%s\tmyproj\n' "$WT" >"$rows"
    export DOCKER_COMPOSE_ROWS="$rows"
    nets="$BATS_TEST_TMPDIR/nets"
    printf 'myproj\tbbb222\tmyproj_default\n' >"$nets"
    export DOCKER_NETWORK_ROWS="$nets"

    run "$DT" "$WT"
    [ "$status" -eq 0 ]
    [[ "$(cat "$NETRM_LOG")" == *bbb222* ]]
}

@test "network sweep dry-run lists the network but removes nothing" {
    nets="$BATS_TEST_TMPDIR/nets"
    printf 'wt\taaa111\twt_default\n' >"$nets"
    export DOCKER_NETWORK_ROWS="$nets"

    run "$DT" --dry-run "$WT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY RUN - would remove 1 network(s)"* ]]
    [[ "$output" == *"aaa111  wt_default"* ]]
    [ ! -s "$NETRM_LOG" ]
}

@test "network sweep is a no-op when no networks match" {
    run "$DT" "$WT"
    [ "$status" -eq 0 ]
    [ ! -s "$NETRM_LOG" ]
}

@test "network sweep removes multiple networks in a single run" {
    rows="$BATS_TEST_TMPDIR/rows"
    # A matched container contributes a second project, so two distinct
    # projects each own one empty network.
    printf 'aaa111\t%s\tmyproj\n' "$WT" >"$rows"
    export DOCKER_COMPOSE_ROWS="$rows"
    nets="$BATS_TEST_TMPDIR/nets"
    printf 'wt\taaa111\twt_default\n' >"$nets"
    printf 'myproj\tbbb222\tmyproj_default\n' >>"$nets"
    export DOCKER_NETWORK_ROWS="$nets"

    run "$DT" "$WT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"removing 2 network(s)"* ]]
    removed="$(cat "$NETRM_LOG")"
    [[ "$removed" == *aaa111* ]]
    [[ "$removed" == *bbb222* ]]
}

@test "network sweep: a failed network rm warns but still exits 0" {
    nets="$BATS_TEST_TMPDIR/nets"
    printf 'wt\taaa111\twt_default\n' >"$nets"
    export DOCKER_NETWORK_ROWS="$nets"
    # Re-stub docker so only `network rm` fails; the network ls/inspect queries
    # still succeed so a target is found and removal is attempted.
    stub_command docker "case \"\${1:-}\" in
ps) exit 0 ;;
image) exit 0 ;;
run) exit 0 ;;
network)
    case \"\${2:-}\" in
    ls) printf 'aaa111\twt_default\n'; exit 0 ;;
    inspect) echo 0; exit 0 ;;
    rm) exit 1 ;;
    esac
    exit 0
    ;;
esac
exit 0"
    run "$DT" "$WT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"one or more networks could not be removed"* ]]
}
