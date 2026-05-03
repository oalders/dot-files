#!/usr/bin/env bash

set -eu -o pipefail

nono run --profile go-cgo-dev -- bash -c '
set -eu -o pipefail
d=$(mktemp -d cgo-test.XXXXXX)
trap "rm -rf \"$d\"" EXIT
cat > "$d/go.mod" <<EOF
module cgotest

go 1.21
EOF
cat > "$d/main.go" <<GO
package main

// #include <stdlib.h>
import "C"
import "fmt"

func main() {
    fmt.Println("cgo works! RAND_MAX =", C.RAND_MAX)
}
GO
cd "$d"
GOCACHE=$PWD/.cache GOMODCACHE=$PWD/.modcache CGO_ENABLED=1 go build -o hello . && ./hello
'
