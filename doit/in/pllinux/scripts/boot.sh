#!/app/busybox/current/bin/sh
# Script for running during system start from boot service (started from init from initramfs)

if [ ! -d "/log" ]; then
  echo "Cannot be run from host"
  return
fi

export PATH=/app/busybox/current/bin:/app/busybox/current/sbin

#export LD_PLLINUX_DEBUG=1
#export TERMINFO=/app/ncurses/current/share/terminfo

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
  /app/e2fsprogs/current/sbin/fsck.ext4 ${ROOT_DEVICE_NAME%%:*}
  /app/busybox/current/bin/mount -o remount $ROOT_DEVICE_ID /
fi

if [ ! -x /app/glibc/current/lib/ld-linux-x86-64.so.2 ]; then
  echo "/app/glibc/current/lib/ld-linux-x86-64.so.2 not executable. Fixing"
  chmod a+x /app/glibc/current/lib/ld-linux-x86-64.so.2
fi

# allow propagating /mnt mount into bwrap sandboxes
/app/util-linux/current/bin/mount --make-shared /mnt

/app/util-linux/current/bin/mount tmpfs -t tmpfs -o rw,noatime,nosuid,noexec,mode=1777 /tmp

#/app/util-linux/current/bin/mount tmpfs -t tmpfs -o rw,noatime,nosuid,noexec,mode=1777 /log/tmp
echo lz4 > /sys/block/zram0/comp_algorithm
echo 1G > /sys/block/zram0/disksize
/app/e2fsprogs/current/sbin/mkfs.ext4 /dev/zram0 > /dev/null
/app/util-linux/current/bin/mount /dev/zram0 /log/tmp -o rw,noatime,nosuid,noexec > /dev/null

# access to dinit for non-root users
/app/busybox/current/bin/busybox chmod a+rw /run/dinitctl

# starts and configures automatic mounting devices (USB pendrives, memory cards, etc.)
# (enable mdev on request and process already connected devices)
#echo > /dev/mdev.seq
#echo > /dev/mdev.log
if [ -f "/sys/block/sr0/events_poll_msecs" ]; then
  echo 2000 > /sys/block/sr0/events_poll_msecs  #CDROM needs to be polled
fi
/app/busybox/current/bin/echo /app/busybox/current/sbin/mdev > /proc/sys/kernel/hotplug
/app/busybox/current/sbin/mdev -s

# firewall rules
/app/nftables/current/sbin/nft -f /etc/network/nftables/inet-filter.nft

# just permissions
/app/busybox/current/bin/chmod a+rw /dev/null

/app/pllinux/current/pllinux BOOT
