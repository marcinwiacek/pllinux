# Technology preview release notes

Are you tired with waiting for next release of your favourite Linux distribution? 
Do you want to see immediately latest and gratest versions of your applications?
Are you tired, when your provider need to patch them with every release? 
Do you want to be able to easy switch and check some software version without resigning from stable or working environment? 
Do you want to see, what is what in your disk without headache or IT studies?
Are you tired with learning command line tools and searching in the internet for the solution for problems known in Linux for years?
And finally: do you expect security higher than ever without using too much RAM or disk?

PLLinux contains solution for this and many other things. It was started after finding various problems with existing Linux distributions 
and lack of dev reaction (more and more often they also remove existing for years functionalities or promoting code, which was not tested).

This PLLinux Technology Preview release shows, in what direction could go modern operating system. 
This version contains already many working elements and can already give feeling, where existing systems seems to be obsolete 
(if you like analogies, you could compare it into 
[Windows 95 build 58s](https://www.youtube.com/watch?v=9gKi_zYklMI&list=PLUS6aV5qyWClKFfbFT2P4Yd1RMNfxNhpM&index=2) or 
[Windows 95 build 73f](https://www.youtube.com/watch?v=SVL7aL7AN74&list=PLUS6aV5qyWClKFfbFT2P4Yd1RMNfxNhpM&index=3), where revolution was already visible, 
but not completed). Some solutions are similar to used in Android, Apple products or NixOS, but are not the same.

# Architecture

System is based on long-supported code and tools with known reputation:

1. [Linux kernel](https://kernel.org) (there were other considered too, but for now let's hope, that this code won't be damaged by AI and other things)
2. [busybox](https://busybox.net/), when possible (when it's good enough) and other tools (like [util-linux](https://github.com/util-linux/util-linux)) extending busybox, when it has got known issues or limits
3. [bwrap or bubblewrap](https://github.com/containers/bubblewrap) (used for example in Flatpak) - in PLLinux giving extra security and separation layers in various situations
4. [dinit](https://davmac.org/projects/dinit/) (taken because of simplicity) - decision about lack of systemd could be reconsidered in the future

We avoid changing existing software (two exceptions: [dynamic loader in "libc"](https://github.com/marcinwiacek/pllinux/blob/main/file_yt_milestone6.md) and some permission details in "bwrap") and
(excluding permissions and other directories) system in many cases can run without any problems unmodified Linux binaries, which simply work... after
giving list of dependencies in readme.md files described in further part of these notes
(this is totally different approach from NixOS, where binaries normally need to be patched)

There are just few services started:

1. tty1-tty3 for starting terminals
2. boot used for system boot actions
3. recovery started when something fails during boot
4. crond for tasks started with schedule in background
5. sysctld for saving logs in the disk

Other actions (starting and stopping network, synchronizing time using NTP, mounting USB drives, etc.) is done on mainly event occurence - you can wait some miliseconds and it doesn't hurt.

DHCP is not done with services now.

Note: used architecture (especially bwrap) can make some scenarios potentially more difficult and normally
root actions are done from the terminal with logged root (honestly speaking you don't need to do them every second with good framework).

# Managing system

There are just two commands required:

* **app** (command line manager for managing apps)
* **pllinux** (text mode manager for managing apps and system settings)

They're created using shell scripts - can be easy modified even by medium experienced person.

Note: we know, that shell script is not the best way of writing code in the world (from the other hand: it really makes work and you don't need anything more for apps used from time to time)

# Filesystem

* /app - place for all apps (they're saved in separate folders, you can assign different apps or app versions from the /app to other users)
* /etc - some configuration files (much less and more readable than in typical Linux distributions, normally you can manage them 
with **pllinux** text mode manager
* /home - user files, with root account you see all users, with non-root users see only own home directory
* /other
* /dev, /proc, /run, /sys - pseudo-filesystems exposed by kernel
* /bin, /usr, /lib64 - links to the files from the /app to satisfy first lines in scripts/shebangs (in the future all of them will be probably removed and functionality will be handled other way)
* /log - visible only for root, contains temporary or permament log files
* /tmp - tmpfs
* /mnt - cd-rom, USB memories, memory cards, etc.

And this is everything. Every package inside /app has got own directory. Inside you have:

1. scripts directory (package manager can start file from them during installation, etc.)
2. dynamic directory (scripts can put here whatever required)
3. readme.md with package description
4. other files and directories (structure is not defined, but normally you see such directories like in "normal" Linux)

Readme.md is semi-text file with some elements, for example:

    **License**
    GPL3+ with GCC Runtime Library Exception

    **PATH**
    bin:sbin

    **PATH_First**
    bin:sbin

    **SHELL**
    bin/bash

    **Deps**
    glibc current
    zstd current

    **Description**
    Core part of PLLINUX (libraries) + compiler.

    **Project**
    https://gcc.gnu.org

    **Man**
    share/man/man1:share/man/man7

    **Install**
    install.sh

    **Services**
    boot
    recovery

# Freedom

With PLLinux you decide, if you want to use compiled packages or whether you want to create them from source. You have also full freedom
in modifying system to your needs. This is pure technical heaven and return to the GNU ideas in the best shape.

Note: some packages are not available from the box not because they're written in concrete language - everything is estimated from technical
excellence perspective only (maturity, number of bugs, resources usage, etc.)

# Starting

You need system with UEFI and without Secure Boot. Examples:

**qemu-system-x86_64 -cdrom iso.iso -m 4098 -bios /usr/share/OVMF/OVMF_CODE.fd**

Technology Preview contains three users: root (password root), user (password user) and user2 (password user2)

User files are saved in the RAM (tmpfs) and you can for example make setup using root and later login into other account.

# Known issues

**Some keyboard layouts are not complete (kbd package problem)**

This is typical in Open Source - various packages are used and mentioned everywhere, but not updated even after years. Here we have probably
situation, that "kbd" package won't be completed, because GUI have done it much better.

**No man pages with util-linux (groff package problem)**

"Encountered end of file while defining macro LR" - no solution known yet

**"grotty:<standard input>: fatal error: output error" sometimes with man pages (groff package problem?)**

Seems to be cosmetic (no known side effects excluding error message).

# Links

* [https://sourceforge.net/projects/pllinux/](https://sourceforge.net/projects/pllinux/)
* [https://github.com/marcinwiacek/pllinux](https://github.com/marcinwiacek/pllinux)
* [https://mwiacek.com](https://mwiacek.com)

# How can you help?

  1. proposing new ideas - it's never too late for them
  2. showing this project to other people - good party must be big & nothing helps more than testers, users and developers
  3. submitting bugs - project is very early stage, but don't be shy, when have something to say
  4. further updates for existing dynamic loader or making other development - always welcome (mainly C or Bash shell scripting now)
  5. packaging software - always welcome (mainly Bash shell scripting now)

#Contact

Use for example GitHub or marcin ( at ) mwiacek ( dot ) com. I'm not answering very fast, but in the end it always happens.

#FAQ

**Why not extend existing project?**

They have technology dept and cannot change it because of users. There is required fresh air in this mess (let's say this word clear).

**Why opening opened doors?**

Few years ago many people were thinking only about Intel and AMD in their PC, Apple went and created something different... and we have today very good Macbook Air, Pro or Mini.
World simply needs different solutions and staying in 1980 year with OS design is probably bad idea.

**Why not Rust or systemd or other project x?**

They will be used, when provide really added value. Starting project desciptions with "written in Rust" instead of advantages list is anti-advertisement (additionally please look, that we don't have Servo completed till today, Rust coreutils have many baby problems and systemd became big thing staying far away from initial goals)

**But systemd has got clear names for network interfaces**

Yes, it has got many good and many bad elements.

Note: stable network interfaces names will be implemented in the future.

**Why console and not GUI?**

GUI is of course planned. And creating good system roots and base is more important in this stage.

Note: yes, text mode has got many disadvantages. It was used for now just because of simplicity.

**Projects like Vinix or Redox are better**

Concurrence is always good. Future will show, what will be used more widely in the future. And result cannot be sometimes predicted (see situation with OS/2 and Windows 95)

**It's another boring Linux distribution**

It doesn't have at least only other branding.

**Does it have sense to make new OS by people in AI time?**

New products and ideas are always moving people forward.

# Schedule and future

This project was started in April 2026 and already went into quite useable shape and form.

Last 2026 months, year 2027 and beyond will be used for improving functionality (compiling more packages, 
providing more flexible and easier structure, decreasing resources usage, etc.). It includes especially preparing user-friendly
graphic environment (something probably similar to HaikuOS or desktop existing in the Gnome 2 / Windows 95-XP era with the nice to eye graphic elements
and elements concentrated on real productivity)

There are of course many things in the queue (for example firewall rules for every app or updates with downloading incremental part of packages), just
some single more funny elements (which require more development and code changes) will be probably moved into further future. 
Example: deleting to the trash.
