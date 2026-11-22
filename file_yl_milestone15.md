[Prev page](file_ym_milestone14.md) [Next page](file_zz_milestone.md)

# Milestone 15

# One step back, two forward

Creating OS looks very hard, right?

Let's look on some issues (I don't name them problems, because these are things, which CAN be resolved and WILL be resolved). They're not mentioned to show, how difficult things are.
This is rather Postmortem documention done after some tries and finding some conclusions (which is natural part of the process)

**Programmer crap**

First of all - are typical users programmers or just people, who want to run apps? Why we see quite always so many include and other dev files in Linux? What disk profits
we will get when remove some of files?

Some candidates to deleting:

* all a files (static libraries)
* documentation including man3 files
* some package related files like cmake info or pc files

Static libraries could be used in rare cases and PLLinux will probably deliver them only for packages used for static compiling basic binaries (main rule is, that shared files will
be used everywhere). The other mentioned things are many times (not always) small and creating separate directories with them can need actually MORE place on disk than saving them
with "main" package.

Some statistics: /app directory in my PLLinux needs 2 224 128 kB, in the same time directories with majority of "dev" packages 110 280 kB.

It's not too much, additionally splitting files will need extra work and can make some complications in the future. This topic needs to be still further analysed. Possible options:

1. delivering all packages in "main+dev" or "main" form
2. delivering separate "dev" packages only, when they're bigger for example than 40KB
3. delivering all packages in "main+dev" form only

And how should look these "dev" packages? Should we link all files from "main" to "dev"?

![Alt text](2026/nov_links_to_dev.jpg)

It doesn't look ellegant and easy and suggests some problems, when "dev" package is not installed as well.

Should we have dev files in separate files? The profit is, that admin will see immediately, what is installed and what not (but in the same time it's not clearly visible, if we have all "main" and all "dev" in the same version)

![Alt text](2026/nov_separate_dev.jpg)

Maybe in that case we should give everything with same package name and just add "-dev" to the version?

![Alt text](2026/nov_separate_dev_version.jpg)

This gives profit, that removing app is deleting everything at once... but admin needs to enter package directory to see everything.

Like I written, this thing will be still investigated. Probably option with "main+dev" or "dev" version is the best. But we will see in the future.

**Current and non-current versions**

The goal in PLLinux is, that you can assign to some users "current" version of apps and they can be replaced on fly (user will just need to restart app). This could work, when... app files don't have hardcoded real paths. In current build it doesn't always happend and readme.md for such apps contains new element:

    **Current**
    yes

Needs to be improved with future releases. The goal is to have all system config in /etc and user config in /home/app

**Stupid problems which need a lot of time**

**Crappy and obsolete code**

/bin/sh

**Users with and without sandboxing**


**Cascade linking for libraries?**

And now time for some conclusion - many years ago in other reality very technical people made some decisions and
later their (sometimes bad) decicions were multiplied and without big cleanup like in PLLinux it's sometimes even
difficult to understand what are some dependencies.

[Prev page](file_ym_milestone14.md) [Next page](file_zz_milestone.md)
