[Prev page](file_yp_milestone10.md) [Next page](file_zz_milestone.md)

# Milestone

# Design decisions

Let's summarize some current points:

1. installation and booting - no support for encryption yet, but the whole chain seems to work
2. ISO - OK
3. pllinux and app scripts - big part done (difficult to say, how much - probably 70 or 80%)
4. man - OK (in the end)
5. logging - some issues with logger, non-root users, etc. (should we change rsyslog with something else?)
6. automatic mounting devices - currently mdev using old "hotplug" interface, but it seems to have problem with CD-ROM (they're handled with SCSI and
commands like echo 0 0 0 > /sys/class/scsi_host/host*/scan or echo - - - > /sys/class/scsi_host/host*/scan don't help) and it's required to migrate to udev
7. saving RAM memory - tmpfs was replaced with zram at least in one place and it requires initially more, but can give profits with bigger files ([some info](https://bbs.archlinux.org/viewtopic.php?id=243939))
8. compiling software - gcc doesn't work yet, Java and many other were not tried

With point 6 I wanted to avoid pooling devices, unfortunately in eudev files (taken from systemd) it's written quite clear:

  # enable in-kernel media-presence polling
  ACTION=="add", SUBSYSTEM=="module", KERNEL=="block", ATTR{parameters/events_dfl_poll_msecs}=="0", \
    ATTR{parameters/events_dfl_poll_msecs}="2000"

[5 Rust-Written CLI Tools That Replace Legacy Unix Commands on Linux](https://www.fosslinux.com/162085/rust-cli-tools-replace-legacy-unix-commands.htm)

[Prev page](file_yp_milestone10.md) [Next page](file_zz_milestone.md)
