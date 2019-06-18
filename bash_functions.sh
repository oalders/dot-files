self_path() {
    echo $(cd -P -- "$(dirname -- "$0")" && pwd -P)
}

# http://superuser.com/questions/39751/add-directory-to-path-if-its-not-already-there
pathadd() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="$1:$PATH"
    fi
}

IS_DARWIN=false
LINK_FLAG=""

# https://stackoverflow.com/a/17072017/406224
if [ "$(uname)" == "Darwin" ]; then
    IS_DARWIN=true
    LINK_FLAG="-hF"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    LINK_FLAG="-T"
fi

IS_MM=false
if [ -e /usr/local/bin/mm-perl ]; then
    IS_MM=true
fi

export LINK_FLAG
export IS_DARWIN
export IS_MM
