# http://superuser.com/questions/39751/add-directory-to-path-if-its-not-already-there
add_path() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="$1:$PATH"
    fi
}

HAS_GO=false
if [[ (-n "${GOPATH+set}") && ($(command -v go version)) ]]; then
    HAS_GO=true
fi

HAS_PLENV=false

# should probably also ensure that Plenv version is not the system Perl
if [[ (-n "${PLENV_SHELL+set}") ]]; then
    HAS_PLENV=true
fi

IS_DARWIN=false
LINK_FLAG=""

# https://stackoverflow.com/a/17072017/406224
if [ "$(uname)" == "Darwin" ]; then
    IS_DARWIN=true
    LINK_FLAG="-hF"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    LINK_FLAG="-T"
fi

IS_GITHUB=false

LOOKS_LIKE_GITHUB=${GITHUB_WORKSPACE:-}
if [[ ! -z $LOOKS_LIKE_GITHUB ]]; then
    IS_GITHUB=true
fi

IS_MM=false
if [ -e /usr/local/bin/mm-perl ]; then
    IS_MM=true
fi

IS_SUDOER=false
if [[ $(sudo -n true 2>&1 | grep 'password') ]]; then
    IS_SUDOER=false
else
    IS_SUDOER=true
fi

export HAS_GO
export HAS_PLENV
export IS_DARWIN
export IS_GITHUB
export IS_MM
export IS_SUDOER
export LINK_FLAG
