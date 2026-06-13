*"...I'm doing a (free) operating system (just a hobby, won't be big and
professional like GNU) for Intel and AMD CPU clones. This has been
brewing since April..."*

Do you like Open Source software?

I love it and words above are probably the best describing this project, which was created for checking, how difficult would be creating own complete OS with full modular design and separating apps from each other (without modifying them of course).

Main rules:

  1. engineering excellence **always** in first place (completing things + no bla bla or spaghetti code)
  2. reproducible and reliable results and builds
  3. simplicity for devs and users (some people will use KISS synonym or remind classic rule "every tool should do excellent just one thing", but this point is not only about that - is about avoiding unnecessary annoying things too)
  4. consistency
  5. decreasing resources usage with correct using temp files, getting and unpacking packages and other things (related to the number of disk writes, amount of bytes sent over network, used RAM, etc.)
  6. when possible, providing real support for people with disabilities (devs today don't care today about such things like good font antialiasing, gamma support or accessibility functions)

This should evolve into system for daily usage (and maybe change something like Linux did), but won't be probably big factory for everybody and
everything, just simple to understand system for typical machines (laptops, mini pc or servers without funny exotic config). Currently
I started it with X86, in the future it will maybe include ARM. POSIX compatility is important, but not crucial in all details.
Project will NOT focus on concrete buzz words (Rust, AI, etc.) and won't use these mainstream solutions which
cannot provide added value (improved performance, security, etc.)

"This is wasting of time. NixOS has got majority of these things"

Yes, but it seems to be rather prepared for machines than humans. This is good system, BTW.

"Linux distros are far away"

Yes. But big imperia are always collapsing in some moment.

"OS needs software and nobody will be interested in this piece of crap"

Will see.

"Wasn't it enough to extend and fork something existing?"

No.

In the market you can find of course excellent Unix-like systems prepared for daily usage and concrete tasks. They're good, but many times making very unprofessional, irritating or obsolete things or implementing archaic and ancient standards (some more than 50 years old!)

Project was started because some sometimes important basics are broken and fundamental changes required. It's time to cut-off some technical debt.

"Does it mean, that the whole market is broken?"

NO, of course not... let's say it clear: current situation is maybe not good, but also not tragic (yet). And what's wrong - aggresive pushing AI, Rust, Wayland, GTK4, systemd and other things makes only problems. Many users are returning with big sympathy to old systems created around 1990-2010 because they worked many times much better (3D interface from Windows 95-XP or old Mac OS we're simply more responsible and looked visually nice, the same in the Open Source world we still see so many good voices about Gnome created with GTK2 and GTK3).

"So OK, let's assume, all this is true. Why we have problems in Open Source world?"

  1. independent devs don't have bigger vision or became old and tired and lost their mojo - they just made their projects and don't care (anymore) about many aspects like usability, security or maintability
  2. politics came into modern IT - some companies or groups of interests are realizing what is good for them or their countries
  3. we see more and more ideology instead of technical work - technology went into mainstream and some people realize sick visions
  4. many devs and managers desperately want to prove they're doing something - it includes creating horrible planning and more code (for example with AI)
  5. when something is for everything, is for nothing - some projects try to answer on all possible requests and we get Frankenstein monsters
  6. compatibility - in many places devs don't want to break it and they stay with something what should be changed many years ago (and no - GNU tools shouldn't be first candidate for Rust rewrite)

Some links:

  1. [The Lunduke Journal in Youtube](https://www.youtube.com/@Lunduke) - you don't have to agree with everything, but it shows quite good some political actions,
nonsense related with Rust and intentional making Open Source software worse
  2. [Is Gnome/GTK developed against Open-Source and Linux? (+few words about Korean/western and Chinese approach)](https://mwiacek.com/www/?q=node/629) -
things notified by Marcin Wiącek few years ago and confirmed not only by Lunduke
  3. [Mainstream Linux became next Windows and is going back instead forward](https://mwiacek.com/www/?q=node/638) - some short analysis from this year about modern "*q*uality"

And very concrete examples:

  1. Rust tools version 0.9 project mentions, that it has WORSE compatibility with tests than release 0.8, but this is
other people fault - blaming others is becoming norm today
  2. we hear like mantra "Rust will save us", but without explaining from what - this happens, when Rust is known from various problems and is generally too fresh for some environments
  3. deleting info about XLibre from various places - with clear info saying, that this is political decision

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

 1. [Milestone 1 - development environment, booting process, filesystem structure, core components, rebooting](milestone1.md)
 2. [Milestone 2 - mounting USB devices](milestone2.md)
 3. [Milestone 3 - app folder structure, network, dynamic linking and interpreters again, ](milestone3.md)
 4. [Milestone 4 - SSD writes, logging, manual pages](milestone4.md)
 5. [Milestone 5 - network, sound, CPU microcode and kernel packages](milestone5.md)
 6. Milestone 6 - dbus? AppArmor? SeLinux?
 7. Milestone 7 - easy configuration
 8. Milestone 8 - real packet manager
 9. Milestone 9 - more packages, software compiling, etc.
 10. Milestone 10 - installation
 11. Milestone 11 - graphic UI
 12. Milestone 12 - big party?

List can change, in ideal situation we will get full functional modern system.
