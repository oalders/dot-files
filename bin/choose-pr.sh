#!/usr/bin/env bash

gh pr list --author "app/dependabot" --json headRefName,title

