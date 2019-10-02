#!/bin/bash

set -ex

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
STORE=/usr/var/store

killall -9 chrome || true
killall -9 node || true
killall -9 npm || true

for i in $(seq 20)
do
  if grep -q "images/image-$i/rootfs/proc" /proc/self/mountinfo; then umount "$STORE/images/image-$i/rootfs/proc"; fi
  if grep -q "images/image-$i/rootfs/dev" /proc/self/mountinfo; then umount "$STORE/images/image-$i/rootfs/dev"; fi
  if grep -q "images/image-$i/rootfs/sys" /proc/self/mountinfo; then umount "$STORE/images/image-$i/rootfs/sys"; fi

  "$DIR/assets/grootfs" --config "$DIR/groot_config.yml" delete "image-$i"

  if [ -d "/sys/fs/cgroup/memory/process-$i" ]; then rmdir "/sys/fs/cgroup/memory/process-$i"; fi
done
