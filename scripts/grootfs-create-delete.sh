#!/bin/bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

sudo "$DIR/../assets/grootfs" --config "$DIR/../groot_config.yml" create docker:///busybox bob
sudo strace "$DIR/../assets/grootfs" --config "$DIR/../groot_config.yml" delete bob
