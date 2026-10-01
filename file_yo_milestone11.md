[Prev page](file_yp_milestone10.md) [Next page](file_zz_milestone.md)

# Milestone

# Mounting CD

Is mdev enough or should project to some kind of udev? With Linux kernel you can connect to hotplug interface (like it's done with mdev) or register events and be modern ("modern" ?). Issue with mounting CD returned, when I saw new relerase of uedev (taken from systemd but without systemd dependencies). Compilation went smoothly and package has got 11MB, but... (there must be always but) rules actually are written in 33 files and are huge. Somebody could say, that Linux is modern thx to it and can support many devices. But... then I found this:

    # enable in-kernel media-presence polling
    ACTION=="add", SUBSYSTEM=="module", KERNEL=="block", ATTR{parameters/events_dfl_poll_msecs}=="0", \
    ATTR{parameters/events_dfl_poll_msecs}="2000"

Earlier with mdev I had problem, that CD event change was not returned to mdev. I didn't know why and tried hints like

    echo 0 0 0 > /sys/class/scsi_host/host*/scan
    echo - - - > /sys/class/scsi_host/host*/scan

Nothing worked. This time I tried **mdev -d -f -S -v** and immediately found, that events actually come, but only on startup.

![Alt text](2026/sep_mdev)

Short investigation and 

**echo 2000 > /sys/block/sr0/events_poll_msecs**

actually made trick.

And now design question - should I stay with mdev with 2 lines big config (one line for all USB memories and one for CD) or migrate?

Question for the future... especially, that some questions probably will stay with udev too - what to do, when filesystem is busy, etc. etc.

# Design decisions

Let's summarize some current points:

1. installation and booting - no support for encryption yet, but the whole chain seems to work
2. ISO - OK
3. pllinux and app scripts - big part done (difficult to say, how much)
4. man - OK (in the end)
5. logging - some issues with logger & non-root users, etc. (should we change rsyslog with something else?)
6. automatic mounting devices - currently mdev (works quite ok with USB and CD)
7. network - very basic support for eth OK (with firewall)
8. tasks - cron
7. saving RAM memory - tmpfs was replaced with zram at least in one place and it requires initially more, but can give profits with bigger files ([some info](https://bbs.archlinux.org/viewtopic.php?id=243939))
8. compiling software - gcc doesn't fully work yet (it starts, just need to have correct dirs), Java and many other were not tried, perl seems to be quite OK

Basic system is around 430MB big and I'm thinking about some modern tools, for example found some possible inspirations here:

[5 Rust-Written CLI Tools That Replace Legacy Unix Commands on Linux](https://www.fosslinux.com/162085/rust-cli-tools-replace-legacy-unix-commands.htm).

And no - Rust itself is not important, important is, what functionality, stability, etc. can be provided.

Next days will be obviously connected with some next design decisions - should I first implement encryption, go into compiling software or something else? Or maybe try to achieve system size in small tiny Linux distributions?

# Shebang

In many (Unix) Linux systems scripts start with **#!path_to_the_script_interpreter** and this is interpreted by kernel and called shebang. PLLinux design should
be clean and filesystem shouldn't have links from typical known binary locations to packages inside **/app**. [The solution for this problem is called
binfmt_misc - kernel can recognize concrete byte sequences or files extensions and run interpreter](https://docs.kernel.org/admin-guide/binfmt-misc.html)

In first version setup is done in the **pllinux** package in the [boot.sh script](doit/in/pllinux/scripts/boot.sh) - we mount **/proc/sys/fm/binfmt_sys** and later for example say: when file starts wih **#!/bin/sh**, then run **/app/busybox/current/bin/sh** providing this file as parameter.

Feature will be later configurable with **readme.md** files from packages and the **pllinux** script - after disabling "standard" shebang feature
it will be possible to control precisely, which binary interpreters could be started. It's maybe not perfect, but quite OK.

[Prev page](file_yp_milestone10.md) [Next page](file_zz_milestone.md)
