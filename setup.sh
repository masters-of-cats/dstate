#!/bin/bash

set -e -x

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
STORE=/usr/var/store

"$DIR/assets/grootfs" --config "$DIR/groot_config.yml" init-store

for i in $(seq 20)
do
  mkdir -p "/sys/fs/cgroup/memory/process-$i"
  echo 250870912 > "/sys/fs/cgroup/memory/process-$i/memory.limit_in_bytes"

  "$DIR/assets/grootfs" --config "$DIR/groot_config.yml" create docker:///cfgarden/d-state-repro "image-$i"

  mount --bind /proc "$STORE/images/image-$i/rootfs/proc"
  mount --rbind /dev "$STORE/images/image-$i/rootfs/dev"
  mount --rbind /sys "$STORE/images/image-$i/rootfs/sys"

  sudo chroot "$STORE/images/image-$i/rootfs" /bin/sh -c "cd /usr/src/app && npm start >/dev/null 2>&1" &
  echo $! > "/sys/fs/cgroup/memory/process-$i/tasks"
done
