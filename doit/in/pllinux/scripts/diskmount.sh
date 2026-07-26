#!/app/busybox/current/bin/sh
# called by mdev from busybox package - creates mount with correct permissions
# you can check kernel device log with dmesg
#echo $ACTION $MDEV >> /x
if [ -z "$ACTION" ]; then echo "Script should be run from mdev"; exit 1; fi
case $ACTION in
  add )
    DEVICE_INFO=$(/app/busybox/current/sbin/blkid | /app/busybox/current/bin/grep /dev/$MDEV)
    for PARAM in $DEVICE_INFO
    do
      FS=${PARAM#TYPE=\"}
      FS=${FS%\"}
#      echo $DEVICE_INFO $FS >> /x
      case $FS in
        ext2|ext3|ext4|exfat|vfat)
          /app/busybox/current/bin/mkdir -p "/mnt/$MDEV" || true
          /app/util-linux/current/bin/mount -t $FS -o rw,noatime,nodiratime,nodev,noexec,nosuid,sync /dev/$MDEV /mnt/$MDEV
#        /app/busybox/current/bin/mount -t $PARAM -o noatime,nodiratime,nodev,noexec,nosuid,sync /dev/$MDEV /mnt/$MDEV
          /app/busybox/current/bin/chmod a+rwx "/mnt/$MDEV" || true
          /app/busybox/current/bin/mount -o rshared /mnt/$MDEV
#       /app/util-linux/current/bin/mount --make-rshared /mnt/$MDEV
        ;;
      iso9660)
          /app/busybox/current/bin/mkdir -p "/mnt/$MDEV" || true
          /app/util-linux/current/bin/mount -t auto -o ro,noatime,nodiratime,nodev,noexec,nosuid /dev/$MDEV /mnt/$MDEV
#        /app/busybox/current/bin/chmod a+rwx "/mnt/$MDEV" || true
          /app/busybox/current/bin/mount -o rshared /mnt/$MDEV
        ;;
      ntfs)
        # needs ntfs-3g
        ;;
      esac
    done
    ;;
  change )
    /app/busybox/current/sbin/blkid
    ;;
  remove )
    /app/busybox/current/bin/umount -f "/mnt/$MDEV" || true
    /app/busybox/current/bin/rmdir "/mnt/$MDEV" || true
    ;;
esac
