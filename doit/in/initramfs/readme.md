**Description**
Init filesystem for kernel:
  * unpacking: gunzip initramfs.gz && cpio -ivF initramfs
  * packing: find . -print0 | cpio --null --create --verbose --format=newc | gzip --best > ../app/kernel/current/initramfs.gz

Inside:
  * busybox 1.38
  * own init script

**Project**
[GitHub](https://github.com/marcinwiacek/pllinux)

**License**
  * busybox - GPL2
  * init - I don't care
