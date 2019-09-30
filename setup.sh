#!/bin/bash

set -e -x

if ! command -v docker > /dev/null ; then
  curl -sSL https://get.docker.com/ | sh

  mkdir -p /var/vcap/data/docker-root
  sed -i '/ExecStart/c\ExecStart=/usr/bin/dockerd --data-root /var/vcap/data/docker-root/ -H fd:// $DOCKER_OPTS' /lib/systemd/system/docker.service
  systemctl daemon-reload
  service docker restart
fi

# pull the rootfs
docker run cfgarden/d-state-repro echo "done"
docker ps -a -q | head -1 | xargs -I {}  docker export {} > /var/vcap/data/dstate/rootfs.tar
docker ps -a -q | xargs docker rm

# init store
touch /var/vcap/data/dstate/backing-file
chmod 600 /var/vcap/data/dstate/backing-file
truncate -s 266683506688 /var/vcap/data/dstate/backing-file
mkfs.xfs -f /var/vcap/data/dstate/backing-file
mkdir -p /var/vcap/data/dstate/store
mount -o loop,pquota,noatime -t xfs /var/vcap/data/dstate/backing-file /var/vcap/data/dstate/store
mkdir -p /var/vcap/data/dstate/store/meta
echo '{"uid-mappings":[],"gid-mappings":[]}' > /var/vcap/data/dstate/store/meta/namespace.json
chown root:root /var/vcap/data/dstate/store
chmod 700 /var/vcap/data/dstate/store

# create store directories
for dir in images locks meta projectids tmp volumes l projectids; do
  mkdir -p /var/vcap/data/dstate/store/$dir
  chmod 755 /var/vcap/data/dstate/store/$dir
  chown root:root /var/vcap/data/dstate/store/$dir
done

mkdir -p /var/vcap/data/dstate/store/meta/dependencies
chmod 755 /var/vcap/data/dstate/store/meta/dependencies
chown root:root /var/vcap/data/dstate/store/meta/dependencies

mknod -m 0 /var/vcap/data/dstate/store/whiteout_dev c 0 0
chown root:root /var/vcap/data/dstate/store/whiteout_dev


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
