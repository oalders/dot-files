# shellcheck shell=bash

# path handling
# http://superuser.com/questions/39751/add-directory-to-path-if-its-not-already-there
add_path() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="$1:$PATH"
        export PATH
    fi
}

remove_path() {
    PATH=$(tr : '\n' <<<"$PATH" | grep -v "^$1$" | paste -sd ':' -)
    export PATH
}

echo_path() {
    echo "path..."
    tr : '\n' <<<"$PATH"
}

clean_path() {
    # shellcheck disable=SC1001
    tr : '\n' <<<"$PATH" | awk '!x[$0]++' | grep \/ | grep -v game | paste -sd ":" -
}

reset_path() {
    PATH=$(clean_path)
    export PATH
}
