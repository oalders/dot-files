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
make_socket() {
    python3 -c '
import socket, sys
s = socket.socket(socket.AF_UNIX)
s.bind(sys.argv[1])
' "$1"
}

@test "ssh/rc: creates symlink when SSH_CLIENT and live forwarded socket present" {
    sock="$SOCK_DIR/agent.sock"
    make_socket "$sock"

    run env HOME="$FAKE_HOME" SSH_CLIENT="1.2.3.4 22 22" SSH_AUTH_SOCK="$sock" \
        bash "$SSH_RC"
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
        bash "$SSH_RC"
    [ "$status" -eq 0 ]

    [ "$(readlink "$FAKE_HOME/.ssh/ssh_auth_sock")" = "$new_sock" ]
}

@test "ssh/rc: no-op when SSH_CLIENT unset" {
    sock="$SOCK_DIR/agent.sock"
    make_socket "$sock"

    run env HOME="$FAKE_HOME" SSH_CLIENT="" SSH_AUTH_SOCK="$sock" \
        bash "$SSH_RC"
    [ "$status" -eq 0 ]

    [ ! -e "$FAKE_HOME/.ssh/ssh_auth_sock" ]
}

@test "ssh/rc: no-op when SSH_CLIENT and SSH_AUTH_SOCK are completely unset" {
    run env -i HOME="$FAKE_HOME" PATH="$PATH" \
        bash "$SSH_RC"
    [ "$status" -eq 0 ]

    [ ! -e "$FAKE_HOME/.ssh/ssh_auth_sock" ]
}

@test "ssh/rc: no-op when SSH_AUTH_SOCK is not a socket" {
    not_a_sock="$SOCK_DIR/regular_file"
    : >"$not_a_sock"

    run env HOME="$FAKE_HOME" SSH_CLIENT="1.2.3.4 22 22" SSH_AUTH_SOCK="$not_a_sock" \
        bash "$SSH_RC"
    [ "$status" -eq 0 ]

    [ ! -e "$FAKE_HOME/.ssh/ssh_auth_sock" ]
}

@test "bashrc: no \$SOCK references (regression for bug #1)" {
    run grep -qF '$SOCK' "$BASHRC"
    [ "$status" -ne 0 ]
}
