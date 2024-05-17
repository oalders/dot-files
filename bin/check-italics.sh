#!/usr/bin/env bash

set -euo pipefail

echo -e '\e[1mBold\e[22m'
echo -e '\e[2mDimmed\e[22m'
echo -e '\e[3mItalic\e[23m'
echo -e '\e[4mUnderlined\e[24m'
echo -e '\e[4:3mCurly Underlined\e[4:0m'
echo -e '\e[4:3m\e[58;2;240;143;104mColored Curly Underlined\e[59m\e[4:0m'

printf "\x1b[58:2::255:0:0m\x1b[4:1msingle\x1b[4:2mdouble\x1b[4:3mcurly\x1b[4:4mdotted\x1b[4:5mdashed\x1b[0m\n"
