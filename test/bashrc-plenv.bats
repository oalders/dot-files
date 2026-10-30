#!/usr/bin/env bats

load 'helpers.bash'

@test "bashrc clears inherited local::lib vars when plenv is installed" {
    FAKE_HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$FAKE_HOME/.plenv"
    ln -s "$SCRIPT_DIR" "$FAKE_HOME/dot-files"
    # Real oh-my-posh writes a cache file that test/shellcheck.bats then lints.
    setup_sandbox
    stub_command oh-my-posh ''

    run env -i HOME="$FAKE_HOME" PATH="$PATH" \
        PERL5LIB=x PERL_MM_OPT=x PERL_MB_OPT=x \
        PERL_LOCAL_LIB_ROOT=x PERL_CPANM_OPT=x \
        bash --norc --noprofile -c '
            . ~/dot-files/bashrc >/dev/null 2>&1
            for v in PERL5LIB PERL_MM_OPT PERL_MB_OPT PERL_LOCAL_LIB_ROOT PERL_CPANM_OPT; do
                [[ -v $v ]] && echo "$v still set"
            done
            true'
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}
