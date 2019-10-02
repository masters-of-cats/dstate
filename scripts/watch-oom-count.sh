#!/bin/bash

while true
do
  clear
  for i in {1..20}; do
    echo -n "$i: "
    grep "oom_kill " /sys/fs/cgroup/memory/process-$i/memory.oom_control 
  done
  sleep 5
done
