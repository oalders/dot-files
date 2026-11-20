#!/usr/bin/env bats

# Every tracked script must be picked up by the precious commands for its
# language. A script is found by extension or, for extensionless files, by
# shebang. Languages with no linter installed here (python, osascript) are
# not checked.

load 'helpers.bash'

required_commands() {
    case "$1" in
        shell) echo "shellcheck shfmt" ;;
        perl) echo "perltidy perlcritic perlimports" ;;
        lua) echo "stylua" ;;
    esac
}

language_of() {
    local f="$1" first
    case "$f" in
        *.sh | *.bash | *.bats)
            echo shell
            return
            ;;
        *.pl | *.pm | *.t)
            echo perl
            return
            ;;
        *.lua)
            echo lua
            return
            ;;
    esac
    IFS= read -r first <"$f" || true
    case "$first" in
        '#!'*bash* | '#!'*/sh | '#!'*/sh\ *) echo shell ;;
        '#!'*perl*) echo perl ;;
    esac
}

@test "every tracked script is covered by its language's precious commands" {
    cd "$SCRIPT_DIR"
    # Only the include lists matter here, so every linter is a no-op stub.
    # One job, because parallel jobs interleave the debug lines parsed below.
    setup_sandbox
    for cmd in shfmt shellcheck stylua perltidy perlcritic perlimports; do
        stub_command "$cmd" "exit 0"
    done
    included=$(precious --jobs 1 lint --all --debug --no-color 2>&1 |
        sed -nE 's/.*File (.+) is included for the ([^ ]+) command.*/\1 \2/p' | sort -u)

    missing=()
    while IFS= read -r -d '' f; do
        [[ -f $f && ! -L $f ]] || continue
        lang=$(language_of "$f")
        [[ -n $lang ]] || continue
        for cmd in $(required_commands "$lang"); do
            grep -Fxq "$f $cmd" <<<"$included" || missing+=("$f ($lang): $cmd")
        done
    done < <(git ls-files -z)

    if ((${#missing[@]})); then
        printf 'not covered by precious.toml:\n'
        printf '  %s\n' "${missing[@]}"
        false
    fi
}
