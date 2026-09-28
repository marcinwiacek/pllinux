#!/app/busybox/current/bin/sh
# Part of PLLinux
# called by mdev from busybox package - creates mount with correct permissions
# you can check kernel device log with dmesg

if [ -z "$ACTION" ]; then echo "Script should be run from mdev"; exit 1; fi

#logger -p info -t kern "Mount action: $ACTION $MDEV"
#echo "Mount action: $ACTION $MDEV" >> /tmp/mount

if [ "$ACTION" == "remove" ]; then
  /app/util-linux/current/bin/umount -f "/mnt/$MDEV" || true
  /app/busybox/current/bin/rmdir "/mnt/$MDEV" || true
elif [ "$ACTION" == "add" ] || [ "$ACTION" == "change" ]; then
  DEVICE_INFO=$(/app/busybox/current/sbin/blkid | /app/busybox/current/bin/grep /dev/$MDEV)
  if [ "$DEVICE_INFO" = "" ]; then
    # this happens with CDROM /dev/sr0
    /app/util-linux/current/bin/umount -l "/mnt/$MDEV" || true
    /app/busybox/current/bin/rmdir "/mnt/$MDEV" || true
  else
    for PARAM in $DEVICE_INFO
    do
      FS=${PARAM#TYPE=\"}
      FS=${FS%\"}
      case $FS in
        ext2|ext3|ext4|exfat|vfat)
          /app/busybox/current/bin/mkdir -p "/mnt/$MDEV" || true
          /app/util-linux/current/bin/umount -f "/mnt/$MDEV" || true
          /app/util-linux/current/bin/mount -t $FS -o rw,noatime,nodiratime,nodev,noexec,nosuid,sync /dev/$MDEV /mnt/$MDEV
          /app/busybox/current/bin/chmod a+rwx "/mnt/$MDEV" || true
          /app/util-linux/current/bin/mount --make-rshared /mnt/$MDEV
        ;;
        iso9660)
          MOUNT=$(/app/util-linux/current/bin/mount | /app/busybox/current/bin/grep /dev/$MDEV)
          if [ "$MOUNT" == "" ]; then
            /app/busybox/current/bin/mkdir -p "/mnt/$MDEV" || true
            /app/util-linux/current/bin/mount -t auto -o ro,noatime,nodiratime,nodev,noexec,nosuid /dev/$MDEV /mnt/$MDEV
          else
            #fixme - need to use remount?
            /app/util-linux/current/bin/umount -f "/mnt/$MDEV" || true
            /app/util-linux/current/bin/mount -t auto -o ro,noatime,nodiratime,nodev,noexec,nosuid /dev/$MDEV /mnt/$MDEV
          fi
          /app/busybox/current/bin/chmod a+rwx "/mnt/$MDEV" || true
          /app/util-linux/current/bin/mount --make-rshared /mnt/$MDEV
        ;;
        ntfs)
          # needs ntfs-3g
          ;;
      esac
    done
  fi
fi