#!/bin/bash

set -eux
apt-get update && apt-get install -y --no-install-recommends ca-certificates git man sudo
