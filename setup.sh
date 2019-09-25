#!/bin/sh

set -e -x

/var/vcap/packages/grootfs/bin/grootfs --config groot_config.yml init-store

for i in $(seq 20)
do
  mkdir -p /sys/fs/cgroup/memory/process-$i
  echo 250870912 > /sys/fs/cgroup/memory/process-$i/memory.limit_in_bytes
  echo 250870912 > /sys/fs/cgroup/memory/process-$i/memory.memsw.limit_in_bytes

  /var/vcap/packages/grootfs/bin/grootfs --config groot_config.yml create docker:///cfgarden/d-state-repro image-$i

  mount --bind /proc /var/vcap/data/dstate/store/images/image-$i/rootfs/proc
  mount --rbind /dev /var/vcap/data/dstate/store/images/image-$i/rootfs/dev
  mount --rbind /sys /var/vcap/data/dstate/store/images/image-$i/rootfs/sys

  sudo chroot /var/vcap/data/dstate/store/images/image-$i/rootfs /bin/sh -c "cd /usr/src/app && npm start >/dev/null 2>&1" &
  echo $! > /sys/fs/cgroup/memory/process-$i/tasks
done
