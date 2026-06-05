#!/usr/bin/env bats

load 'helpers.bash'

setup() {
    setup_sandbox
    SSH_RC="$SCRIPT_DIR/ssh/rc"
    BASHRC="$SCRIPT_DIR/bashrc"

    command -v python3 >/dev/null || skip "python3 required to fabricate AF_UNIX socket files"

    FAKE_HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$FAKE_HOME/.ssh"

    SOCK_DIR="$BATS_TEST_TMPDIR/sockets"
    mkdir -p "$SOCK_DIR"
}

# Bind a unix-domain socket at $1. The bind survives the python exit
# (the socket inode persists until explicit unlink), giving us a real
# AF_UNIX socket file for the [ -S ] tests in ssh/rc.
#
# Bind via a path relative to the socket's directory: the string passed to
# bind() must fit in struct sockaddr_un.sun_path (108 bytes on Linux, 104 on
# macOS), and $BATS_TEST_TMPDIR nests under $TMPDIR, which the nono sandbox
# points at a deep worktree path that overflows the limit (issue #946).
# chdir-ing first keeps the bound name short ("agent.sock") while the socket
# file still lands at the intended absolute path. The [ -S ] / readlink checks
# in ssh/rc stat that absolute path (no length limit) rather than connect(),
# so this is safe.
make_socket() {
    python3 -c '
import os, socket, sys
directory, name = os.path.split(sys.argv[1])
if directory:
    os.chdir(directory)
s = socket.socket(socket.AF_UNIX)
s.bind(name)
' "$1"
}

@test "ssh/rc: creates symlink when SSH_CLIENT and live forwarded socket present" {
    sock="$SOCK_DIR/agent.sock"
    make_socket "$sock"

    run env HOME="$FAKE_HOME" SSH_CLIENT="1.2.3.4 22 22" SSH_AUTH_SOCK="$sock" \
        sh "$SSH_RC"
    [ "$status" -eq 0 ]

    [ -L "$FAKE_HOME/.ssh/ssh_auth_sock" ]
    [ "$(readlink "$FAKE_HOME/.ssh/ssh_auth_sock")" = "$sock" ]
}

@test "ssh/rc: replaces stale symlink on re-login (regression for bug #2)" {
    old_sock="$SOCK_DIR/old.sock"
    new_sock="$SOCK_DIR/new.sock"
    make_socket "$old_sock"
    make_socket "$new_sock"

    ln -s "$old_sock" "$FAKE_HOME/.ssh/ssh_auth_sock"

    run env HOME="$FAKE_HOME" SSH_CLIENT="1.2.3.4 22 22" SSH_AUTH_SOCK="$new_sock" \
        sh "$SSH_RC"
    [ "$status" -eq 0 ]

    [ "$(readlink "$FAKE_HOME/.ssh/ssh_auth_sock")" = "$new_sock" ]
}

@test "ssh/rc: no-op when SSH_CLIENT unset" {
    sock="$SOCK_DIR/agent.sock"
    make_socket "$sock"

    run env HOME="$FAKE_HOME" SSH_CLIENT="" SSH_AUTH_SOCK="$sock" \
        sh "$SSH_RC"
    [ "$status" -eq 0 ]

    [ ! -e "$FAKE_HOME/.ssh/ssh_auth_sock" ]
}

@test "ssh/rc: no-op when SSH_CLIENT and SSH_AUTH_SOCK are completely unset" {
    run env -i HOME="$FAKE_HOME" PATH="$PATH" \
        sh "$SSH_RC"
    [ "$status" -eq 0 ]

    [ ! -e "$FAKE_HOME/.ssh/ssh_auth_sock" ]
}

@test "ssh/rc: no-op when SSH_AUTH_SOCK is not a socket" {
    not_a_sock="$SOCK_DIR/regular_file"
    : >"$not_a_sock"

    run env HOME="$FAKE_HOME" SSH_CLIENT="1.2.3.4 22 22" SSH_AUTH_SOCK="$not_a_sock" \
        sh "$SSH_RC"
    [ "$status" -eq 0 ]

    [ ! -e "$FAKE_HOME/.ssh/ssh_auth_sock" ]
}

@test "bashrc: no \$SOCK references (regression for bug #1)" {
    run grep -qF '$SOCK' "$BASHRC"
    [ "$status" -ne 0 ]
}
