# Technology preview release notes

  * Do you want just use your PC and have allergy for Windows and Mac?
  * Are you annoyed with checking AI sloop, which looks good, but many times doesn't have real support?
  * Is resolving problems without end making your crazy?
  * Do you want to see new features immediately?
  * Are you annoyed with command line tools?
  * Is waiting for next release of your Linux distribution boring?
  * Do you want to be able to play with some new software without resigning from stable and working environment?
  * And finally: do you want to pay less for CPU, RAM and disk and control what is used for?

Hi, my name is Marcin, I'm using PCs around 36 years and I love beauty and simplicity, additionally I'm tired with politics
in IT and words "nothing can be done". And I'm building system, which could resolve many existing problems.

I know, that you heard it many times. The thing is, that PLLinux:

* is created using existing software (it equals maturity in many cases) and
* prepared from scratch (it allows for avoiding many problems visible
in typical Linux distributions and gives good knowledge about internals and occasion for cutting off obsolete parts),

additionally I'm doing it with long technical experience (I'm certified engineer working in the past for such companies like Google,
on top of it I'm very lazy and preffer doing something once, but good).

The biggest key points for release 1.0:

  1. the less is more - for example:
    * one script for configuring everything named **pllinux** (it calls command line tools including script for managing apps called **app**)
    * one script for building distro named **doit**
    * no dev elements when user doesn't want do development (no header files, compilers, etc.)
    * no all world localization files when user needs just English
    * all system scripts built in one language and put in one place
    * decreasing code size from release to release for saving power, CPU and expensive RAM and SSD usage (no duplicated files, big logs, binary indexes, telemetry, etc.)
  2. no obsolete solutions known from many other distro - it's time to grow up and go beyond 1980 year (there is used mature software, but
connected without iritating problems)
  3. very easy adding existing (Linux) apps - they can be always actual (no more weeks or months of waiting)
  4. good separating apps from each other - much better even than in NixOS (you can easy check version, size, files, etc. and
control permissions and dependencies)
  5. good separating users and their files - extra security layers
  6. doing what is setup and nothing else - reliable, repeatable and expected results and
no hidden actions / changing settings without user knowledge
  7. continuous implementing best technical options
  8. showing reality "as is" - no hiding problems (for example obsolete code)

In other words: operating system should allow for runnings apps with minimal resources in secure and comfortable way and should do
whatever user want and expect.

This Technology Preview is not created for production use. It was prepared to show main architecture elements - you can see how could look
and work basic elements of the modern OS. Current version contains many components and is very good presenting, what could be wrong with existing
systems (you could compare it to the
[Windows 95 build 58s](https://www.youtube.com/watch?v=9gKi_zYklMI&list=PLUS6aV5qyWClKFfbFT2P4Yd1RMNfxNhpM&index=2) or
[Windows 95 build 73f](https://www.youtube.com/watch?v=SVL7aL7AN74&list=PLUS6aV5qyWClKFfbFT2P4Yd1RMNfxNhpM&index=3), where revolution
was started and somehow visible, but not completed and fully ready yet).

Some solutions are similar to used in Android, Apple products or NixOS, but not the same - they will change even to better before beta or first final release
(like it was in Windows 95, see [The Early Windows 95 Builds Microsoft DIDN'T Want Us To See](https://www.youtube.com/watch?v=cgq7LcvRFA4))

Note: project was started after finding various problems with existing Linux distributions and lack of dev reaction
(more and more often they also remove existing for years functionalities or promote code, which was not tested).

# Filesystem

* /app - place for all apps normally with read-only permission (they're saved in separate folders, you can assign different apps or app versions from the /app to other users, excluding package updates everything inside /app
cannot be modified)
* /etc - some configuration files (much less files and more readable than in typical Linux distributions, normally you can manage them with **pllinux** manager)
* /home - user files (with root account you see all users, with non-root users see only own home directory; we setup HOME into app directory inside we try to put all apps config and stuff there).
* /lib64 - link to the dynamic loader
* /log - visible only for root (contains temporary or permament log files written for example by **syslogd**)
* /lost+found - ext4 folder
* /mnt - CD-ROM, USB memories, memory cards, etc.
* /tmp - tmpfs for temporary files (maybe it will later replaced with zram)
* /dev, /proc, /run, /sys - pseudo-filesystems exposed by kernel

Sometime you can see /bin or /usr too (they have links to existing files from /app). The goal is to eliminate them totally, currently we're using activly kernel options for this (binfmt_misc).

And this is everything. /cache, /boot, /cdrom, /lib32, /libx32, /media, /root, /sbin, /snap, /srv, /var and many other are elimininated. And the biggest magic starts in /app:

Every package inside /app has got own directory. Inside you have:

1. readme.md with package description
2. other files and directories provided "as is" by software (structure is not defined, but normally you see such directories like in "normal" Linux)

Some packages will need maybe dynamic content, but... it can be modified only by **app** manager in controlled sandbox (this part is still considered). This part will probably look this way:

1. scripts directory (package manager can start file from them during installation, etc.)
2. dynamic directory (scripts can put here whatever required)

Some of directories inside /app/(app_name) are just symlinks. And we have:

1. current - always the latest or gratest version selected by default
2. (version number)- - link to highest version lower than specified (for example for 4.0.0- we normally select latest 3.x.x)
3. (version number)+ - link to highest version higher than specified

Links are normally changed by package manager during installing or updating dependencies. Currently packages are (mainly) compiled with config with
"current" link inside - it could potentially sometimes make issue, when you have "non-current" package binary or script (and it tries to reach some
other elements). It could be reconsidered in the future and we could use "version" link (in that situation for normal users we will need to
link "current" and "version" app versions).

Now imagine, that you want to assign to user for example concrete bash or latest bash + some other tools. This is possible. The same you can make
upgrades in background and in the last step just change "current" links (no need for having separate installation partition). And of course very
similar situation is, when you want to build your source code with concrete set of tools - no need of building separate docker or something (just
point what you want and use it).

Names of the packages are normally the same to the project names - you should be able to find them in most cases by putting package name in search
engine (DuckDuck, Google, etc.)

Readme.md is semi-text file with some elements, for example:

    **Project**
    https://gcc.gnu.org

    **Description**
    Core part of PLLINUX (libraries) + compiler.

    **License**
    GPL3+ with GCC Runtime Library Exception

    **AI**
    https://docs.kernel.org/process/coding-assistants.html

    **PATH**
    bin:sbin

    **PATH_First**
    bin:sbin

    **SHELL**
    bin/bash

    **Man**
    share/man/man1:share/man/man7

    **Install**
    install.sh

    **Services**
    boot
    recovery

    **Include**
    include

    **Modules**
    modules

    **Links**
    bin/sh /bin/sh

    **Fonts**
    share/consolefonts

    **Last**
    20260505

    **X11-modules**
    lib/xorg/modules/xlibre-25.orig

    **X11-conf**
    etc/X11/xorg.conf.d.orig

    **X11-fonts**
    .

    **Vulkan-modules**
    share/vulkan.orig

    **Deps**
    glibc current
    zstd current

This is text file and order is technically not important (but I try to have project, description and license on the beginning and deps on the end).

We have here different elements:

1. descriptive (for example description is shown by **pllinux** manager, **Last** contains info about last modification of files
inside source package in main dir)
2. used by some software during work (for example **man** command is looking for all readme.md and searching for "Man" elements to find
directory with source files)
3. used for creating files in /etc during package installation (it includes for example X11-modules, X11-conf, X11-fonts or services)
4. used for starting binaries (deps is showing, which packages can be availables for the binary - which libraries can be linked into it, when it's asked)
5. setting up user environment (when user is logging, we create for example PATH from readme.md)

Very interesting is point 4 - PLLinux by default doesn't give access to all *.so files, they need to be whitelisted with Deps element.

But what in situation when package is downloaded and readme.md needs to be updated?

There will be added some package with updates, details will be implemented after Technical Preview. Additionally, to save SSD space for release 1.0 
there is planned to prepare three packages for the software:

1. main able to start software with English locale (for example "mc")
2. development with header files and a libraries ("mc-dev")
3. locale with different languages ("mc-locale")

It all should greatly decrease disk writes.

# Architecture

System is based on long-supported code and tools with known reputation, for example:

1. [Linux kernel](https://kernel.org) (there were other considered too, but for now let's hope, that this code won't be damaged by AI and other things)
2. [busybox](https://busybox.net/), when possible (when it's good enough) or other tools (like [util-linux](https://github.com/util-linux/util-linux)), when
busybox has got known issues or limits
3. [bwrap](https://github.com/containers/bubblewrap) (used for example in Flatpak) - in PLLinux giving extra security and separation layers in various situations
4. [dinit](https://davmac.org/projects/dinit/) (taken because of simplicity) - decision about lack of systemd could be reconsidered in the future

We avoid changing existing software code and there are only few exceptions:

1. [dynamic loader in "libc"](https://github.com/marcinwiacek/pllinux/blob/main/file_yt_milestone6.md)
2. some permission details in "bwrap"
3. changing some /bin/sh references to /app/busybox/current/bin/sh

Excluding permissions and other directories names PLLinux in many cases can run without any problems unmodified Linux binaries. 
This simply works... just after giving list of dependencies in readme.md manifest files described below (this is totally different
from NixOS, where binaries normally need to be patched).

There are just few services started:

1. **tty1-tty3** for starting terminals
2. **boot** and **bootsh** used for system boot actions
3. **recovery** started when something fails during boot process
4. **crond** for tasks started with schedule in background
5. **syslogd** for saving logs in the disk

Other actions (starting and stopping network, synchronizing time using NTP, mounting USB drives, etc.) are done mainly on event - you can wait some
miliseconds and it doesn't hurt.

DHCP is not done with services now.

**bwrap** sandboxing is used for:

1. user sessions (they don't see real filesystem)
2. running package manager (it doesn't see user files)
3. running compilation/installation script from packages (generally all changes in main filesystem are done by package manager)

Big pressure is put into limiting disk writes or memory usage. This is very important with current SSD/RAM prices.

Note: used architecture (especially **bwrap**) can make some scenarios potentially more difficult and
root actions are normally done from the terminal with logged root (honestly speaking you don't need to do them every second with good work framework).

What about configurations?

Some packages in the /app contain link to the directory in the /etc, where we put for example links to all drivers. This is happening for example
with x11 drivers or vulkan and these /etc directories and updated ONLY by **app** package manager.

# Full freedom

With PLLinux you decide, if you want to use compiled packages or whether you want to create them from source. 
You have also full freedom in modifying system to your needs. This is pure technical heaven and return to the GNU ideas in the best shape.

Note: some software is not available from the box because it's written in concrete language - 
everything is estimated from technical perspective only (maturity, number of bugs, resources usage, etc.) and added after carefull consideration.

# Starting ISO

You need system with UEFI with disabled Secure Boot.

The best results could be visible with VirtualBox (ICH9, VMSVGA, NVME, etc.). You can try QEMU too:

**qemu-system-x86_64 -cdrom iso.iso -m 4098 -bios /usr/share/OVMF/OVMF_CODE.fd**

Technology Preview contains three users: root (password root), user (password user) and user2 (password user2). You can use configurator (**pllinux**) or start X11 available with console number 11 (**win** command). User files are saved in the RAM (tmpfs) and it's possible for example make setup using root and later login into other account. Additionally system is ready for partitioning and cloning/installing to the separate partition.

If you want to play with development and extra packages, just unpack them to the /app, logout and login again. Done.

During all checks please remember: this is technology preview, not production ready setup.

# Managing system

To work with PLLinux normally you just need one command **pllinux** (text mode manager for managing apps and system settings, reinstalling, cloning, fixing boot issues, etc.).

In some edge cases you can be maybe interested in two more:

1. **app** (command line manager for managing apps normally called from **pllinux**)
2. **doit** (running from host, not included in ISO file, available [in GitHub](https://github.com/marcinwiacek/pllinux) and used for making all distribution files
and packages from the source)

They're all created using shell scripting. It's clear, that this is NOT the best way of writing code, from the other hand it really makes work and 
you don't need anything more for apps used from time to time, additionally code can be easy modified and audited even by medium experienced people.

Simplicity at all!

# Building ISO, PLLinux partition or packages from sources

Follow [instructions from the GitHub](https://github.com/marcinwiacek/pllinux). Steps include installing host system (the best Debian 13.7), creating separate ext4 partition and running script compiling PLLinux software named **doit** (it's doing practically everything) and in the end setting up GRUB start menu options with few easy steps.

# Known issues

**Some keyboard layouts are not complete (kbd package problem)**

This is typical in Open Source - various packages are used and mentioned everywhere, but not updated even after years. Here we have
probably situation, that "kbd" package won't be completed, because GUI have done it much better.

**There is saved a lot of printf garbabe in Midnight Commander history log**

Old thing, see [https://github.com/MidnightCommander/mc/issues/2104](https://github.com/MidnightCommander/mc/issues/2104).

Solution: you need to avoid sh and use for example Bash with your user (it's done with default ISO config)

**Non-admin users logging info is not saved in logs**

Solution unknown. Will be investigated.

**Problems with crond and non-root users**

Solution unknown. Will be investigated.

**Long waiting for opening partition with GRUB**

Known GRUB issue. The only one solution is decreasing security, in the future GRUB maybe will be replaced with something else.

**Password need to be given two times with encrypted partition**

Known GRUB/Linux architecture issue. Some distributions are mitigating it with putting decryption key on the disk and we don't want
probably to do it.

**Midnight Commander shows strange .[1m or similar things with man files in viewer**
[mcviewer: add syntax highlighting via external command - #5065](https://github.com/MidnightCommander/mc/pull/5065)

**Midnight Commander and "Broken Pipe" error**
When you see this after pressing F3 or F4 - add link from /bin/sh to the /app/busybox/current/bin/sh

**Software needs /bin/sh or /usr/share/terminfo or other "standard" location**

Indeed, /bin/sh is hardcoded in many binaries and I still search for method for fully elimininating it (MC and F3/F4 "Broken pipe" is example).
With scripts it's already done - there is used kernel mechanism for this.

With /usr/share/terminfo - we use TERMINFO variable, XTERM is provided with option setting it up (by default it's removing it)

With zone info directory - we use TZDIR and happily it works like should

# Links

* [https://sourceforge.net/projects/pllinux/](https://sourceforge.net/projects/pllinux/)
* [https://github.com/marcinwiacek/pllinux](https://github.com/marcinwiacek/pllinux)
* [https://mwiacek.com](https://mwiacek.com)

# How can you help?

  1. proposing new ideas - it's never too late for them
  2. showing this project to other people - good party must be big & nothing helps more than testers, users and developers
  3. submitting bugs - project is very early stage, but don't be shy, when have something to say
  4. further updates for existing dynamic loader or making other development - always welcome (mainly C or Bash shell scripting required now)
  5. packaging software - always welcome (needs mainly Bash shell scripting now)

# Contact

Use for example GitHub or marcin ( at ) mwiacek ( dot ) com. I'm not answering very fast, but in the end it always happens.

# FAQ

**AI will be build more beautiful system in one day**

Go there... with all advantages and disadvantages.

**Why not extend existing project?**

They have technology dept and many times don't want to change because of users or politics. There is required fresh air in this situation.

**Why opening opened doors?**

Few years ago many people were thinking about Intel and AMD only. Apple created something different... and we have today very
good Macbook Air, Pro or Mini (with ARM CPU).

In other words: world simply needs different solutions and staying in 1980 with OS design is bad idea.

**Why not Rust or systemd or other project?**

They will be used, when provide really added value. Starting and ending project info with "written in Rust" words,
covering everything with it and pushing it like AI sloop instead of real technical discussion is anti-advertisement
and no-go for me (additionally we don't have complete Servo till today, Rust core-utils have many baby-age problems and 
main problems during preparing Technical Release was... surprise... surprise with Rust related packages).

Systemd has got advantages, but in the same time became big & fat & in my opinion is staying far away from initial goals.

**But systemd has got clear names for network interfaces and many cool things**

Yes, it has got many good and many bad elements.

Note: stable network interfaces names will be implemented in the future.

**PLLInux is not memory safe and contains very bad code**

Saying this like mantra will not improve situation. Propose better code if you can. You're highly invited. Show working tested
solution and it will be included, when... (this is important) when it will be better than existing one.

**Why limited console and not GUI?**

Creating good system base is the most important in this stage. And GUI is of course planned.

Note: yes, text mode has got many disadvantages. And some advantages too.

**Projects like Vinix, Redox, Haiku, NixOS or even ReactOS or Omarchy are better**

Concurrence is always good. Future will show, what will be used in the future. And results cannot be sometimes predicted
(see situation with OS/2 and Windows 95)

**This will be always few steps after Omarchy, Ubuntu, Debian, etc.**

Never say never.

**It's another boring Linux distribution**

It doesn't have at least just other wallpaper or branding.

**Does it have sense to make new OS by people in AI age?**

New products and ideas are always moving people forward. And making things by human (not AI) is extending their skills + it's known, what we have inside.

**It's shipped with slow, obsolete and abandomed GNU apps. Why not use musl or other?**

Number of people critizing something is always much bigger than number of people doing something. Propose updates if there is
better alternative.

**This is just small project written by one person and it will be abandomed soon**

Take my beer - I had very long successfull projects in the past.

Note: Linux kernel started this way too.

**What about sudo?**

Currently user sessions are sandboxed and the main idea is, that user is making admin tasks from unsanboxed root session
(and don't use increasing privileges). This can partially change in the future and will be reviewed many times after
Technology Preview (note: some actions like giving password to encrypted partitions will be handled without need of giving
admin password)

**All PLLinux goals can be achieved by docker or virtualization**

Yes. But we don't have distributions in mainstream doing this nicely. And PLLinux is trying to make it with small amount of resources.

**It will be never compatible with all dev tools or serious apps like Steam, VirtualBox, Firefox, etc.**

Never say never.

**It needs host system to build**

Rome was not built in one day. Technical Preview was created for showing potential of the technology and next releases will achieve
in some day full independence.

**It's much bigger than Puppy Linux, Tiny Core Linux and other small distributions**

One of first goals for PLLinux is building desktop class system with all features. Technical Preview is bigger, but next versions have in goals
removing unnecessary things and debug code.

**The whole idea doesn't have sence - searching for libraries is slow now**

My first implementation is "as is", in the future of course there will be many updates. In real life few ms is nothing, when you look
on profits from separating all apps like it's done in PLLinux.

**Some commands like man are sometimes slow**

Normally there is used mandb and here it was not used - if problem will be visible for more users, decision could be reconsidered.

# Schedule and future

This project was started in April 2026 and already went into quite useable shape and form.

Time in the 2026/2027 and beyond will be used for improving functionality (compiling more packages,
providing more flexible and easier structure, decreasing resources usage, etc.). It includes preparing user-friendly
graphic environment (something similar probably to HaikuOS or desktops in the Gnome 2 / Windows 95-XP era with the nice to eye rich graphic elements
and GUI concentrated on real productivity)

There are of course many things in the queue (for example firewall rules for every app or updates with downloading incremental packages parts), just
some single more funny elements (which require more development and code changes) will be probably moved into further future
(example: deleting to the trash)
