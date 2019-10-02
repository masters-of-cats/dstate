#!/bin/bash

sudo watch "ps -eLo pid,tid,ppid,user:11,comm,state,wchan,lstart,etime | grep 'D '"
