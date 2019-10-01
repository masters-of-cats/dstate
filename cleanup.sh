#!/bin/bash

set -x

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
STORE=/usr/var/store

killall -9 chrome || true
killall -9 node || true
killall -9 npm || true

for i in $(seq 20)
do
  umount "$STORE/images/image-$i/rootfs/proc"
  umount "$STORE/images/image-$i/rootfs/dev"
  umount "$STORE/images/image-$i/rootfs/sys"

  "$DIR/assets/grootfs" --config "$DIR/groot_config.yml" delete "image-$i"

  rmdir "/sys/fs/cgroup/memory/process-$i"
done
