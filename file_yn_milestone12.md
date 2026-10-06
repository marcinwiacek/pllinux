[Prev page](file_yo_milestone11.md) [Next page](file_zz_milestone.md)

# Milestone 12

# Compiling software

Everybody today say about efficiency and better, more safe programming and a lot of other things, but basic functionality normally needs more
and more disk space and RAM. But what about language efficiency?

Let's look on it from other perspective:

1. **busybox** with a lot of small tools and shell scripting - 2,3MB on disk
(I'm trying to include all normally installed files after compiling everything from the source
and of course in other implementations it can be different a little bit because of other options, platform, etc.)
2. **chezscheme** - 6MB
3. **bash** with shell scripting - 11,5MB
4. **perl** - 66MB
5. **node** with JS - 226MB (+ I've got rather bad experience after very slow compilation)
6. **cpython** - 257MB
7. **gcc** with C/C++ - 252+19MB
8. **jdk** - 1181MB

I tried to compile as well V (errors), PHP (still need to install some libraries) and FreePascal / FPC (totally different world
and although I would like to try it, need to move it into the future).

And now - when compiler needs thousands of MB, there is something wrong.

# Graphic drivers and SDL/framebuffer support

[Prev page](file_yo_milestone11.md) [Next page](file_zz_milestone.md)
