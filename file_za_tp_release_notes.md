# Technology preview release notes

Are you tired with waiting for next release of your favourite Linux distribution? Do you want to see immediately latest and gratest versions of your applications? (are you tired, when your provider need to patch them with every release?) Do you want to be able to easy switch and check some software version without resigning from stable or working environment? Do you want to see, what is what in your disk without headache or IT studies? And do you expect security higher than ever without using too much RAM or disk?

PLLinux contains solution for this and many other things. It was started after finding various problems with existing Linux distributions and lack of dev reaction (more and more often they remove existing for years functionalities).

Technology Preview shows, in what direction could go modern operating system. This version contains already many working elements and can already give feeling, where existing systems seems to be weak and obsolete (if you like analogies, you could compare it into [Windows 95 build 58s](https://www.youtube.com/watch?v=9gKi_zYklMI&list=PLUS6aV5qyWClKFfbFT2P4Yd1RMNfxNhpM&index=2) or [Windows 95 build 73f](https://www.youtube.com/watch?v=SVL7aL7AN74&list=PLUS6aV5qyWClKFfbFT2P4Yd1RMNfxNhpM&index=3), where revolution was already visible, but not completed). Some solutions are similar to used in Android, Apple products or NixOS, but are not the same.

# Managing system

There are just two commands required:

* **app** (command line manager for managing apps)
* **pllinux** (text mode manager for managing apps and system settings)

# Filesystem

* /app - place for all apps (they're saved in separate folders, you can assign different apps or app versions from the /app to other users)
* /etc - some configuration files (much less and more readable than in typical Linux distributions, normally you can manage them with **pllinux** text mode manager
* /home - user files, with root account you see all users, with non-root users see only own home directory
* /dev, /proc, /run, /sys - pseudo-filesystems exposed by kernel
* /bin, /usr, /lib64 - contains links to the files from the /app (in the future it will be probably removed and handled other way)
* /log - visible only for root, contains temporary or permament log files
* /tmp - tmpfs
* /mnt - cd-rom, USB memories, memory cards, etc.

And this is everything.

# Starting

You need system with UEFI and without Secure Boot. Examples:

**qemu-system-x86_64 -cdrom iso.iso -m 4098 -bios /usr/share/OVMF/OVMF_CODE.fd**

Technology Preview contains three users: root (password root), user (password user) and user2 (password user2)

User files are saved in the RAM (tmpfs) and you can for example make setup using root and later login into other account.


# Known issues

# Links

* [https://sourceforge.net/projects/pllinux/](https://sourceforge.net/projects/pllinux/)
* [https://github.com/marcinwiacek/pllinux](https://github.com/marcinwiacek/pllinux)
* [https://mwiacek.com](https://mwiacek.com)

# Future

Last 2026 months, 2027 and beyond will be used for improving functionality (compiling more packages, providing more flexible and easier structure, decreasing resources usage, etc.). It includes preparing user-friendly graphic environment (something probably similar to HaikuOS or desktop existing in the Gnome 2 / Windows 95-XP era with the nice to eye look)