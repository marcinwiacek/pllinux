In internet you can find a lot of solutions, including info about [autofs](https://www.kernel.org/doc/html/latest/filesystems/autofs.html) or setting up [udev](https://en.wikipedia.org/wiki/Udev)
or [UUID info in the /etc/fstab](https://linuxconfig.org/automatically-mount-usb-external-drive-with-autofs). They're working, but especially udev seems to be big factory and for our 
Milestone 2 we just need simple doing some aciton, when device is connected and disconnected.

We will use mdev from busybox. The whole functionlity is quite good described for example in:

  1. [Device Management](https://deepwiki.com/mirror/busybox/4.2-device-management)
  2. [MDEV configuration instructions under busybox](https://www.programmersought.com/article/56418701983/)
  3. [mdev Command Linux: Complete Guide to Minimal Device Manager Configuration](https://codelucky.com/mdev-command-linux/)

It basically need just few elements:

  1. telling kernel to start mdev, when action happen (in our case **/app/busybox/current/bin/echo /app/busybox/current/sbin/mdev > /proc/sys/kernel/hotplug**)
  2. running mdev with -s option to handle devices connected before starting system
  3. /etc/mdev.conf file saying, what should be done and executed in case or connecting/disconnecting
  4. our scripts making nice mount and mount and similar things

We will mount all partitions in /mnt and we have additionally steps in out bwrap execution scripts making --bind for this directory.

During tests configuration was working... almost - we had pendrive recognized by kernel as /dev/sda device (with one partition /dev/sda1) and system was creating/removing directory 
/mnt/sda1 and almost correctly mounting partition there.

Where is the problem?

Linux kernel has got different mount spaces - in theory after mounting some partitions and making next "child" space it's possible
to share some mounts with "child" (see [Shared Subtrees](https://www.kernel.org/doc/html/latest/filesystems/sharedsubtree.html)), but... it seems to be blocked by bwrap.
In this moment (24.05.2026) there is not known workaround for this and situation, that accessing memory card or pendrive needs this sequence:

  1. connecting device
  2. logging user

