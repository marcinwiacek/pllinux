*"...I'm doing a (free) operating system (just a hobby, won't be big and
professional like GNU) for Intel and AMD CPU clones. This has been
brewing since April..."*

This is project with operating system built around Linux kernel and Bubblewrap (bwrap) with extra separating apps in the main filesystem (something like in NixOS, but done differently).

**Some important points**

  1. splitting apps and users in different way than in various Linux distributions, which gives you much more security and flexibility
(you can provide and show other apps to other users, build package scripts can run in the sanbdbox, upgrades and rollbacks are much easier, etc.)
  2. reproducible and reliable results (dependiences among apps must be always defined and thing running in one installation will work on the other)
  3. simplicity for devs and users
  4. consistency
  5. decreasing resources usage (using tmpfs, etc.)
  6. when possible, providing real support for people with disabilities

When you think, that this is just utopia, look on screens below - is it possible in your Linux?

![Memory](2026/jun_mc_root.png)

![Memory](2026/jun_mc_user.png)

![Memory](2026/jun_memory.png)

**Plans**

Currently in early alpha. Some things are done and some todo:

 0. [Milestone 0 - more initial info](milestone0.md)
 1. [Milestone 1 - development environment, booting process, filesystem structure, core components, rebooting](milestone1.md)
 2. [Milestone 2 - mounting USB devices](milestone2.md)
 3. [Milestone 3 - app folder structure, network, dynamic linking and interpreters (again), packages, system in this moment](milestone3.md)
 4. [Milestone 4 - SSD writes, logging, manual pages]
 5. [Milestone 5 - sound, CPU microcode and kernel packages]
 6. Milestone 6 - dbus? AppArmor? SeLinux?
 7. Milestone 7 - easy configuration
 8. Milestone 8 - real packet manager
 9. Milestone 9 - more packages, software compiling, etc.
 10. Milestone 10 - installation
 11. Milestone 11 - graphic UI
 12. Milestone 12 - big party?

This can change without earlier notice.

**Important dates**

  1. 16 April 2026 - start
  2. June 2026 - releasing GitHub repo to public (with script for building)

**Building and starting**

  1. install Lubuntu 26.04 (build script is created inside it; probably any Ubuntu distribution should work without changes)
  2. create and mount new EXT4 partition
  3. point this partition in the [build script doit.sh](doit/doit.sh)
  4. run [build script doit.sh](doit/doit.sh) (it can ask sometimes for sudo for dependiences)
  5. add PLLINUX to the GRUB (create [file /etc/grub.d/40_custom](2026/40_custom) with correct UUID for new filesystem get with **sudo blkid**)
  6. restart and have fun.

In the future there will be of course created ISO and installer. Secure Boot needs probably to disabled now. UEFI "rather" required.

**How can you help?**

  1. proposing new ideas - it's never too late for them
  2. showing this project to other people - good party must be big & nothing more helps like new testers, users and developers
  3. submitting bugs - project is very early stage, but don't be shy, when you want already to say something
  4. updating existing dynamic loader or making other development - always welcome
  5. packaging software - always welcome

**Contact**

Use for example GitHub or marcin ( at ) mwiacek ( dot ) com. I'm not answering very fast, but in the end it always happens.
