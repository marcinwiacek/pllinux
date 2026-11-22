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

Some statistics: /app directory in my PLLinux needs 2224128 MB, in the same time directories with majority of "dev" packages 110280MB.

It's not too much, additionally splitting files will need extra work and can make some complications in the future. This topic needs to be still further analysed. Possible options:

1. delivering all packages in "main+dev" or "main" form (should "main+dev" have name with the "-dev" in the end?)
2. delivering "dev" packages only, when they're bigger for example than 40KB
3. delivering all packages in "main+dev" form only

And how should look these "dev" packages?



**Current and non-current versions**

The goal in PLLinux is, that you can assign to some users "current" version of apps and they can be replaced on fly. This could work, when... app
files don't have hardcoded real paths. But

readme.md

    **Current**
    yes

**Stupid problems which need a lot of time**

**Crappy and obsolete code**

/bin/sh

**Users with and without sandboxing**


**Cascade linking for libraries?**

And now time for some conclusion - many years ago in other reality very technical people made some decisions and
later their (sometimes bad) decicions were multiplied and without big cleanup like in PLLinux it's sometimes even
difficult to understand what are some dependencies.

[Prev page](file_ym_milestone14.md) [Next page](file_zz_milestone.md)
