#!/bin/bash

set -eux

FILE=Brewfile
rm $FILE
brew bundle dump
sort -o $FILE $FILE
