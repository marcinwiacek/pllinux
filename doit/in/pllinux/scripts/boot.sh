#!/app/busybox/current/bin/sh
# Script for running during system start from boot service (started from init from initramfs)

if [ ! -d "/log" ]; then
  echo "Cannot be run from host"
  return
fi

export PATH=/app/busybox/current/bin:/app/busybox/current/sbin

#enable when want to see more from dynamic loader code
#export LD_PLLINUX_DEBUG=1

# check root filesystem and make it rw
KERNEL_PARAMS=$(/app/busybox/current/bin/cat /proc/cmdline $X | /app/busybox/current/bin/tr " ")
ROOT_DEVICE_ID=""
for PARAM in $KERNEL_PARAMS
do
  if [ "${PARAM:0:5}" == "root=" ]; then
     ROOT_DEVICE_ID=${PARAM#root=}
  fi
done
if [ "$ROOT_DEVICE_ID" != "" ] && [ "$ROOT_DEVICE_ID" != "rsync" ]; then
  ROOT_DEVICE_NAME=$(/app/busybox/current/sbin/blkid | /app/busybox/current/bin/grep ${ROOT_DEVICE_ID#UUID=})
  if [ -f "/forcefsck" ]; then
    /app/e2fsprogs/current/sbin/fsck.ext4 ${ROOT_DEVICE_NAME%%:*} -f
    /app/busybox/current/bin/mount -o remount $ROOT_DEVICE_ID /
    rm /forcefsck
  else
    /app/e2fsprogs/current/sbin/fsck.ext4 ${ROOT_DEVICE_NAME%%:*}
    /app/busybox/current/bin/mount -o remount $ROOT_DEVICE_ID /
  fi
fi

#setup for handling different scripts and binary files
#(when something is found in the file, we run correct app giving file as param into it)
#in the future this config will be moved to pllinux script
mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
cd /proc/sys/fs/binfmt_misc
echo ':bash:M::#!/bin/bash::/app/bash/current/bin/bash:' > register
echo ':env:M::#!/usr/bin/env::/app/pllinux/current/scripts/shebang.sh:' > register
#echo ':sh1:M::#! /bin/sh::/app/busybox/current/bin/sh:' > register # in MC binary, but don't enable, because strange things happen
echo ':sh2:M::#!/bin/sh::/app/busybox/current/bin/sh:' > register
echo ':perl1:M::#!/usr/bin/perl::/app/perl/current/bin/perl:' > register
echo ':perl2:M::#!/usr/local/bin/perl::/app/perl/current/bin/perl:' > register

# allow propagating /mnt mount into bwrap sandboxes
/app/util-linux/current/bin/mount --make-shared /mnt

#now starts few boring mounts
/app/util-linux/current/bin/mount tmpfs -t tmpfs -o rw,noatime,nosuid,noexec,mode=1777 /tmp

mkdir /dev/pts
/app/util-linux/current/bin/mount devpts -t devpts -o rw,noatime,nosuid,noexec,mode=620,gid=5 /dev/pts

mkdir /dev/shm
/app/util-linux/current/bin/mount tmpfs -t tmpfs -o rw,nosuid,nodev /dev/shm

#/app/util-linux/current/bin/mount tmpfs -t tmpfs -o rw,noatime,nosuid,noexec,mode=1777 /log/tmp
#in theory zram0 should compress everything automatically
echo lz4 > /sys/block/zram0/comp_algorithm
echo 1G > /sys/block/zram0/disksize
/app/e2fsprogs/current/sbin/mkfs.ext4 /dev/zram0 > /dev/null
/app/util-linux/current/bin/mount /dev/zram0 /log/tmp -o rw,noatime,nosuid,noexec > /dev/null

if [ ! -x /app/glibc/current/lib/ld-linux-x86-64.so.2 ]; then
  echo "/app/glibc/current/lib/ld-linux-x86-64.so.2 not executable. Fixing"
  chmod a+x /app/glibc/current/lib/ld-linux-x86-64.so.2
fi

# access to dinit for non-root users
/app/busybox/current/bin/busybox chmod a+rw /run/dinitctl

# starts and configures automatic mounting devices (USB pendrives, memory cards, etc.)
# (enable mdev on request and process already connected devices)
/app/busybox/current/bin/echo /app/busybox/current/sbin/mdev > /proc/sys/kernel/hotplug
/app/busybox/current/sbin/mdev -s

# firewall rules
/app/nftables/current/sbin/nft -f /etc/network/nftables/inet-filter.nft

# setting config from user
/app/pllinux/current/pllinux BOOT

# just permissions - need to setup it after pllinux (it can load graphic card modules)
# in near future it should be reviewed
/app/busybox/current/bin/chmod a+rw /dev/null
/app/busybox/current/bin/chmod a+rw /dev/input/*
/app/busybox/current/bin/chmod a+rw /dev/tty*
/app/busybox/current/bin/chmod a+rw /dev/fb0
/app/busybox/current/bin/chmod a+rw /dev/ptmx
/app/busybox/current/bin/chmod a+rwx /dev/dri
/app/busybox/current/bin/chmod a+rwx /dev/dri/card0

#when something crash, let's dump it into /tmp with process ID and exec name
/app/busybox/current/sbin/sysctl kernel.core_pattern=/tmp/core.%e.%p
