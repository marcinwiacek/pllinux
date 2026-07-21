# Milestone 7
# Creating booting drive

In many descriptions creating boot drive working with UEFI is using Grub. Currently development is done in Debian "Trixy" and there are two options:

1. creating booting ISO file (which could be written to USB as well)
2. creating image for USB with one or two partitions (FAT32+EXT4 or FAT32 with ISO file inside) - see for example

Option 1 seems to be easier:

1. download xorriso (**sudo apt-get install xorriso**) and eventually some Grub packages (**sudo apt-get install grub-pc-bin**)
2. prepare initramfs with [other init file (it's opening shell for check)](2026/init)
3. create iso directory
4. put [grub.cfg](2026/grub.cfg) inside iso\boot\grub
5. put kernel and initramfs packages into iso\app
6. make **grub-mkrescue -o iso.iso iso/ --disable-shim-lock**

Try to boot... for example with Qemu.

**qemu-system-x86_64 -cdrom iso.iso -m 4098**

Doesn't work after selecting menu option in Grub.

![Alt text](2026/jul_magic.png)

Try to replace initramfs with other (old) format and you will see funny info "qemu: linux kernel too old to load a ram disk".

Replace kernel with some other (from Debian for example). And it works - we need only to resolve access to the /app and some other things
(why does it require 386 Grub version?), but... it looks, that standard PLLINUX kernel needs some updates.

# SSD writes

Current SSD and flash memory have limited amount of writes. Because of it we:

  1. save such directories like /mnt or /tmp in RAM
  2. don't save system boot log - in the future it will be probably optional or done during system startup fail
  3. (todo) installer will download and unpack files in the RAM

