#!/usr/bin/env bash

set -eu -o pipefail

# gems useful for development
# rubocop for linting
# yard for viewing documentation

# yard server --reload
# open http://0.0.0.0:8808/

gem install rubocop yard
