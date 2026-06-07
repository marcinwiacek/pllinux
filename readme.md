Do you like Open Source software?

I love it and below is probably the best preamble for my project, which could maybe change something in the future (like Linux did):

"...I'm doing a (free) operating system (just a hobby, won't be big and
professional like GNU) for Intel and AMD CPU clones. This has been
brewing since April..."

This project was initially created for checking, how difficult would be creating own OS with
really full modular design and separating apps from each other and every user (without modifying them of course). It can eventually evolve into system for daily usage.

Main rules will be:

  1. engineering excellence ALWAYS in first place
  2. reproducible and reliable results
  3. simplicity for devs and users (some people will use KISS synonym or remind classic gold rule "every tool should do excellent just one thing", but this point is not only about that - is about avoid doing unnecessary annoying things too)
  4. consistency
  5. decreasing size and resources usage with temp files, getting and unpacking packages and other things (related to the number of disk writes, amount of bytes sent over network, used RAM, etc.)
  6. when possible, providing real support for people with disabilities (devs today don't care today about such things like good font antialiasing, gamma support or accessibility functions)

This won't be big factory for everything, rather just simple to understand system for typical machines (laptops, mini pc or servers without funny exotic config).
POSIX compatility is important, but not crucial in all details. Project will NOT focus on concrete buzz words (Rust, AI, etc.) and won't use mainstream solutions when they
can't provide added value (improved performance, security, etc.)

"This is wasting of time. NixOS has got majority of these things"

Yes, but it seems to be rather prepared for machines than humans. This is good system, BTW.

"Wasn't it enough to extend and fork something existing?"

No.

In the market you can find of course thousands of excellent Unix-like systems perfectly prepared for daily usage and concrete tasks. They're good, but many times making very unprofessional, irritating or obsolete things or implementing archaic and ancient standards (some more than 50 years old!)

Project was started because some important basics are broken and fundamental changes required. It's time to cut-off some technical debt.

"Does it mean, that the whole market is broken?"

NO, of course not... let's say it clear: current situation is maybe not tragic, but also not good. Aggresive pushing AI, Rust, Wayland, GTK4, systemd and other things makes only problems. Many users are returning with big sympathy to old systems created for example around 1990-2010 because they worked many times much better (3D interfaces from Windows 95-XP or old Mac OS we're simply more responsible and looked visually nice, the same in the Open Source world we still see so many good voices about Gnome created with GTK2 and GTK3).

"So OK, let's assume, this is true. Why we have problems in Open Source world?"

  1. independent devs don't have bigger vision or became old and tired and lost their mojo - they just made their projects and don't care (anymore) about many aspects like usability, security or maintability
  2. we have politics in modern IT - some companies or groups are just realizing what is good for them or their countries
  3. we see more and more ideology in IT instead of technical work - technology went to the mainstream and some people realize sick visions
  4. many devs and managers desperately want to proove they're doing something - it includes creating horrible planning and more code (for example with AI)
  5. when something is for everything, is for nothing - some projects try to answer on all possible requests and we get Frankenstein
  6. compatibility - in many places devs don't want to break compatibility and they stay with something what should be changed many years ago (and no - GNU tools shouldn't be first candidate for Rust rewrite)

Some links:

  1. [The Lunduke Journal in Youtube](https://www.youtube.com/@Lunduke) - you don't have to agree with everything, but it shows very good some political actions,
nonsense related with Rust and intentional making Open Source software worse
  2. [Is Gnome/GTK developed against Open-Source and Linux? (+few words about Korean/western and Chinese approach)](https://mwiacek.com/www/?q=node/629) -
things notified by Marcin Wiącek few years ago and confirmed not only by Lunduke
  3. [Mainstream Linux became next Windows and is going back instead forward](https://mwiacek.com/www/?q=node/638) - some short analysis from this year about "kuality"

And very concrete examples:

  1. Rust tools version 0.9 project mentions, that it has WORSE compatibility with tests than release 0.8, but this is
other people fault - blaming others is becoming norm today
  2. we hear like mantra "Rust will save us", but without explaining from what (and this happens, when Rust is known from various problems and is generally too fresh for some environments)
  3. deleting info about XLibre from various places with clear info saying about political issue

In PLLINUX there will be used:

  1. Linux kernel (it's monolytic and with many issues, but widely used and provides quite good hardware support)
  2. **bwrap** (it's used in projects like Flatpak)
  3. **dinit**, **busybox**, **bash**, etc.
  4. (in first place) some nice GUI with good fonts (decision not made yet)

Tools selection can change in time - we don't exclude **systemd** or **Wayland** (but they will be included only when provide really added value). Everything will be built step-by-step (which makes project very educational) - we will start from the most easy unencrypted console environment and (if possible) end with graphical GUI
and all modern stuff making using PC comfortable and funny. Enjoy.

This documention and files from this repo are provided "as is" (you could use MIT or whatever you want).

Every package in PLLINUX can have own license and we don't want to break rights or legal terms (if you see something wrong, please the best drop mail).
The most widely licenses will be probably GPL2 and GPL3 and we want to redirect to the
[Frequently Asked Questions about the GNU Licenses](https://www.gnu.org/licenses/gpl-faq.html) - with our best knowledge
it's possible for example to repackage binaries from other distros (which can improve development speed before release 1.0).

We want to say again - if some our understanding or some action somewhere is wrong, please contact us (we will treat all legal issues very seriously).

And some general plan:

 1. [Milestone 1 - development environment, booting process, filesystem structure and core components, rebooting](milestone1.md)
 2. [Milestone 2 - mounting USB devices](milestone2.md)
 3. [Milestone 3 - /app structure](milestone3.md)
 4. [Milestone 4 - SSD writes, logging, manual pages](milestone4.md)
 5. Milestone 5 - network, sound, CPU microcode and kernel packages
 6. Milestone 6 - dbus? AppArmor?  SeLinux?
 7. Milestone 7 - easy configuration
 8. Milestone 8 - graphic UI
 9. Milestone 9 - real packet manager
 10. Milestone 10 - more packages, software compiling, etc.
 11. Milestone 11 - installation
 12. Milestone 12 - big party?

List can change, in ideal situation we will get full functional modern system.
