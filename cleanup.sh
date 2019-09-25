#!/bin/sh

set -x

killall -9 chrome || true
killall -9 node || true
killall -9 npm || true

for i in $(seq 20)
do
  umount /var/vcap/data/dstate/store/images/image-$i/rootfs/proc
  umount /var/vcap/data/dstate/store/images/image-$i/rootfs/dev
  umount /var/vcap/data/dstate/store/images/image-$i/rootfs/sys

  /var/vcap/packages/grootfs/bin/grootfs --config groot_config.yml delete image-$i

  rmdir /sys/fs/cgroup/memory/process-$i
done
