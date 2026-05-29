"...I'm doing a (free) operating system (just a hobby, won't be big and
professional like gnu) for Intel and AMD CPU clones. This has been
brewing since april..."

This is how description of this project should probably start.

In the market you can find thousands of excellent Unix-like systems perfectly prepared for daily usage and concrete tasks.
They're good, but many times making unprofessional things (IT went into mainstream and we have sloop and AI sloop and some other things) or
implementing archaic and ancient standards (some more than 50 years old!)

Why does it happen?

  1. some devs don't have bigger vision - they just made their small projects and don't care about many aspects like usability or security or maintability
  2. we have more and more politic targets in modern IT - some companies are just realizing what is good for them or their countries (it includes adding telemetry)
  3. many people just want to show they're doing something and this includes creating more code
  4. when something is everything, is for nothing (good example: Windows and some Linux distributions)

Some examples:

  1. [Is Gnome/GTK developed against Open-Source and Linux? (+few words about Korean/western and Chinese approach)](https://mwiacek.com/www/?q=node/629)
  2. [Mainstream Linux became next Windows and is going back instead forward](https://mwiacek.com/www/?q=node/638)

This project was created for checking, how difficult would be creating own distribution with
full modular design and separating apps for every user (without too much modifying them).
It can eventually evolve into system for daily usage.

There will be used:

  1. Linux kernel (it's monolytic and with many issues, but widely used and provides quite good hardware support)
  2. **bwrap** (it's used in projects like Flatpak)
  3. **dinit** (it can be potentially replaced with **systemd** or something else when it will be not enough)
  4. **busybox**, **bash**, **Wayland**, etc.

Tools selection can change in time. Main rules will be:

  1. simplicity (some people will name it KISS or will start saying about classic "every tool should do very good just one thing", but I want mention rather avoiding doing like mantra
unnecessary things like giving admin password for starting scheduled update)
  2. consistency for apps
  3. decreasing size and resources usage (number of disk writes, amount of bytes sent over
network, etc.) for example with temp files, getting and unpacking packages and other actions.

We don't build here big factory for everything, but just simple to understand system for typical machines (for example laptops or mini pc or servers without funny exotic config).
POSIX compatility is important, but not crucial. We will NOT focus on concrete buzz words (Rust, AI, etc.) and don't use all mainstream solutions when they
can't provide excellent technical solutions (better performance, security, etc.)

Everything will be built step-by-step (which makes project very educational) starting from the most easy
unencrypted console environment and (if possible) ending with graphical GUI, Wayland and all this modern stuff. Enjoy.

Every package can have own license (we will treat all legal issues very seriously and all problems must be resolved before 1.0 release),
but this documention and files from this repo are provided "as is" (you could use MIT or whatever you want).

 1. [Milestone 1 - development environment, booting process, filesystem structure and core components, rebooting](milestone1.md)
 2. [Milestone 2 - mounting USB devices](milestone2.md)
 3. [Milestone 3 - SSD writes, logging, manual pages](milestone3.md)
 4. Milestone 4 - network, sound, CPU microcode and kernel packages
 5. Milestone 5 - dbus? AppArmor?  SeLinux?
 6. Milestone 6 - easy configuration
 7. Milestone 7 - graphic UI
 8. Milestone 8 - real packet manager
 9. Milestone 9 - more packages, software compiling, etc.
 10. Milestone 10 - installation
 11. Milestone 11 - big party?

List can change, in ideal situation we will get full functional modern system.
