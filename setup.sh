#!/bin/sh

set -e -x

umount /var/vcap/store || true
umount /var/vcap/data/dstate/store || true
mkfs.xfs -f /dev/sdb1
mkdir -p /var/vcap/data/dstate/store
mount -o pquota,noatime -t xfs /dev/sdb1 /var/vcap/data/dstate/store

# init store
for dir in images l locks meta projectids tmp volumes; do
  mkdir -p /var/vcap/data/dstate/store/$dir
done
mkdir /var/vcap/data/dstate/store/meta/dependencies
echo '{"uid-mappings":[],"gid-mappings":[]}' > /var/vcap/data/dstate/store/meta/namespace.json

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
