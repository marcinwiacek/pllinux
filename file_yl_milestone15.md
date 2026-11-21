[Prev page](file_ym_milestone14.md) [Next page](file_zz_milestone.md)

# Milestone 15

# One step back, two forward

Creating OS looks very hard, right?

Let's look on some issues (I don't name them problems, because these are things, which CAN be resolved).

**Programmer crap**

First of all - are all typical users programmers or just people, who want to run app? Why we see always so many include and other dev files? What disk profits
we will get when remove some of files?

Some candidates:

* a files (static libraries)
* documentation including man3 files
* some package related files like 

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

And now time for some conclusion - many years ago in other reality very technical people made some decisions and
later their (sometimes bad) decicions were multiplied and without big cleanup like in PLLinux it's sometimes even
difficult to understand what are some dependencies.

**Cascade linking for libraries?**

[Prev page](file_ym_milestone14.md) [Next page](file_zz_milestone.md)
