"...I'm doing a (free) operating system (just a hobby, won't be big and
professional like GNU) for Intel and AMD CPU clones. This has been
brewing since April..."

This is probably good desciption for the project, which could maybe change something (like Linux kernel).

It was initially created for checking, how difficult would be creating own distribution with
full modular design and separating apps for every user (without modifying them, if possible).
It can eventually evolve into system for daily usage.

Wasn't it enough to extend and fork something existing?

In the market you can find thousands of excellent Unix-like systems perfectly prepared for daily usage and concrete tasks.
They're good, but many times making very unprofessional things or implementing archaic and ancient standards (some more than 50 years old!)

But why?

  1. some devs don't have bigger vision or became old and tired and lost their mojo - they just made their projects and don't care (anymore) about many aspects like usability, security or maintability
  2. we have more and more politics in modern IT - some companies are realizing what is good for them or their countries
  3. we have more and more ideology in IT instead of technical work - technology went in the mainstream and more and more often people realize sick visions
  4. many devs and managers just want to show they're doing something - unfortunately this includes creating wrong plans and more code (for example using AI)
  5. when something is everything, is for nothing - some projects try to answer on all possible requests and we get Frankenstein
  6. compatibility - in many systems devs don't want to break compatibility

Some links:

  1. [The Lunduke Journal in Youtube](https://www.youtube.com/@Lunduke) - you don't have to agree with everything, but it shows very good some political moves,
nonsense related with Rust and intentional making Open Source software worse
  2. [Is Gnome/GTK developed against Open-Source and Linux? (+few words about Korean/western and Chinese approach)](https://mwiacek.com/www/?q=node/629) -
things notified by Marcin Wiącek few years ago and confirmed not only by Lunduke
  3. [Mainstream Linux became next Windows and is going back instead forward](https://mwiacek.com/www/?q=node/638) - some short analysis from this year about "kuality"

Project was started, because some important basics are broken (for example with Rust tools version 0.9 project mentions, that it has WORSE compatibility with tests than release 0.8, but this is
other people fault - blaming others we hear more and more again and in the same time we hear "Rust will save us", but without explaining from what).

Situation is maybe not very bad, but also not very good. Aggresive pushing AI, RUST, Wayland, GTK4, systemd and other software gives opposite results.
Many users are returning with big sympathy to the old systems created for example between 1990-2010 because they worked
in some aspects much better (3D interfaces from Windows 95-XP or old Mac OS we're simply more responsible and looked better, in the Open Source world
we still see so many good voices about Gnome created with GTK2 and GTK3).

In PLLINUX there will be used:

  1. Linux kernel (it's monolytic and with many issues, but widely used and provides quite good hardware support)
  2. **bwrap** (it's used in projects like Flatpak)
  3. **dinit**, **busybox**, **bash**, etc.

Tools selection can change in time - we don't exclude **systemd** or **Wayland**, but they will be included only when provide really added value.

Main rules will be:

  1. simplicity (some people will name it KISS or will start saying about classic rule "every tool should do excellent just one thing", but we want mention rather avoiding doing unnecessary things like giving admin password for starting scheduled updates
  2. consistency for apps
  3. decreasing size and resources usage (number of disk writes, amount of bytes sent over
network, etc.) for example with temp files, getting and unpacking packages and other actions

We don't want to build big factory for everything, but just simple to understand system for typical machines (for example laptops or mini pc or servers without funny exotic config).
POSIX compatility is important, but not crucial in all details. We will NOT focus on concrete buzz words (Rust, AI, etc.) and don't use all mainstream solutions when they
can't provide excellent technical solutions (better performance, security, etc.)

Everything will be built step-by-step (which makes project very educational) - we will start from the most easy
unencrypted console environment and (if possible) end with graphical GUI and all modern stuff making using PC comfortable and funny. Enjoy.

This documention and files from this repo are provided "as is" (you could use MIT or whatever you want).

Every package in PLLINUX can have own license and we don't want to break rights or legal terms (if you see something wrong, please the best drop mail).
The most widely licenses will be probably GPL2 and GPL3 and we want to redirect to the
[Frequently Asked Questions about the GNU Licenses](https://www.gnu.org/licenses/gpl-faq.html) - with our best knowledge
it's possible for example to repackage binaries from other distros (which can improve development speed before release 1.0).

We want to say again - if some our understanding or action somewhere is wrong, please contact us (we will treat all legal issues very seriously).

And some general plan:

 1. [Milestone 1 - development environment, booting process, filesystem structure and core components, rebooting](milestone1.md)
 2. [Milestone 2 - mounting USB devices](milestone2.md)
 3. [Milestone 3 - app structure](milestone3.md)
 3. Milestone 3 - SSD writes, logging, manual pages
 4. Milestone 4 - network, sound, CPU microcode and kernel packages
 5. Milestone 5 - dbus? AppArmor?  SeLinux?
 6. Milestone 6 - easy configuration
 7. Milestone 7 - graphic UI
 8. Milestone 8 - real packet manager
 9. Milestone 9 - more packages, software compiling, etc.
 10. Milestone 10 - installation
 11. Milestone 11 - big party?

List can change, in ideal situation we will get full functional modern system.
