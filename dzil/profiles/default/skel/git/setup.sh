#!/usr/bin/env bash

chmod +x git/hooks/pre-commit
cd .git/hooks || exit
ln -s ../../git/hooks/pre-commit .
