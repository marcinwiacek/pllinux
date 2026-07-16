#!/app/busybox/current/bin/sh
export PATH=/app/busybox/current/bin:/app/busybox/current/sbin

# check root filesystem and make it rw
KERNEL_PARAMS=$(/app/busybox/current/bin/cat /proc/cmdline $X | /app/busybox/current/bin/tr " ")
ROOT_DEVICE_ID=""
for PARAM in $KERNEL_PARAMS
do
  if [ "${PARAM:0:5}" == "root=" ]; then
     ROOT_DEVICE_ID=${PARAM#root=}
  fi
done
ROOT_DEVICE_NAME=$(/app/busybox/current/sbin/blkid | /app/busybox/current/bin/grep ${ROOT_DEVICE_ID#UUID=})
/app/e2fsprogs/current/fsck.ext4 ${ROOT_DEVICE_NAME%%:*}
/app/busybox/current/bin/mount -o remount $ROOT_DEVICE_ID /

# allow propagating /mnt mount into bwrap sandboxes
/app/util-linux/current/mount --make-shared /mnt

/app/util-linux/current/mount mount -t tmpfs -o rw,noatime,nosuid,noexec,mode=1777 /tmp

# starts and configures automatic mounting devices (USB pendrives, memory cards, etc.)
# (enable mdev on request and process already connected devices)
/app/busybox/current/bin/echo /app/busybox/current/sbin/mdev > /proc/sys/kernel/hotplug
/app/busybox/current/sbin/mdev -s

# console font
/app/kbd/current/setfont -C /dev/tty1 sun12x22.psfu.gz 2> /dev/null
/app/kbd/current/setfont -C /dev/tty2 sun12x22.psfu.gz 2> /dev/null
/app/kbd/current/setfont -C /dev/tty3 sun12x22.psfu.gz 2> /dev/null
/app/kbd/current/setfont -C /dev/tty4 sun12x22.psfu.gz 2> /dev/null

# localtime
ln -s /app/tzdb/current/usr/share/zoneinfo/Europe/Warsaw /etc/localtime

# firewall rules
/app/nftables/current/nft -f /etc/network/nftables/inet-filter.nft

# access to dinit for non-root users
/app/busybox/current/bin/busybox chmod a+rw /run/dinitctl

/app/busybox/current/bin/chmod a+rw /dev/null
