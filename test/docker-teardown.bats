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
esac
exit 0"
    run "$DT" "$WT" feature
    # Teardown must never block worktree removal on docker.
    [ "$status" -eq 0 ]
    [[ "$output" == *"could not reclaim"* ]]
}
