#!/bin/sh

set -e -x

if ! command -v docker > /dev/null ; then
  curl -sSL https://get.docker.com/ | sh
fi

# pull the rootfs
docker run cfgarden/d-state-repro echo "done"
docker ps -a -q | head -1 | xargs -I {}  docker export {} > /var/vcap/data/dstate/rootfs.tar
docker ps -a -q | xargs docker rm

# init store
touch /var/vcap/data/dstate/backing-file
truncate -s 266683506688 /var/vcap/data/dstate/backing-file
mkfs.xfs -f /var/vcap/data/dstate/backing-file
mkdir -p /var/vcap/data/dstate/store
mount -o loop,pquota,noatime -t xfs /var/vcap/data/dstate/backing-file /var/vcap/data/dstate/store

# unpack layer
mkdir -p /var/vcap/data/dstate/store/volumes/layer
tar -xf  /var/vcap/data/dstate/rootfs.tar -C /var/vcap/data/dstate/store/volumes/layer

for i in $(seq 20)
do
  mkdir -p /sys/fs/cgroup/memory/process-$i
  echo 250870912 > /sys/fs/cgroup/memory/process-$i/memory.limit_in_bytes
  echo 250870912 > /sys/fs/cgroup/memory/process-$i/memory.memsw.limit_in_bytes

  # mount the rootfs
  pushd /var/vcap/data/dstate/store
    mkdir -p images/image-$i/upper images/image-$i/work images/image-$i/rootfs
    mount -t overlay -o rw,upperdir=images/image-$i/upper,lowerdir=volumes/layer,workdir=images/image-$i/work overlayfs images/image-$i/rootfs
  popd

  mount --bind /proc /var/vcap/data/dstate/store/images/image-$i/rootfs/proc
  mount --rbind /dev /var/vcap/data/dstate/store/images/image-$i/rootfs/dev
  mount --rbind /sys /var/vcap/data/dstate/store/images/image-$i/rootfs/sys

  sudo chroot /var/vcap/data/dstate/store/images/image-$i/rootfs /bin/sh -c "cd /usr/src/app && npm start >/dev/null 2>&1" &
  echo $! > /sys/fs/cgroup/memory/process-$i/tasks
done
