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

And now - when compiler needs thousands of MB, there is something wrong. And... also I have found, that various software is compiled
with hardcoded paths (for example they expect /usr/share/zoneinfo directory, although have file /etc/localtime, or they expect
shell file in /bin although SHELL variable points to other location). This is mess, big, big mess.

# Graphic drivers and SDL/framebuffer support

Preparing SDL support very fast end with installing many big projects (mesa, llvm, some X11 components.). Work is not completed, but for now (13 Oct) there are few notes:

1. debugging with strace helps in finding, what file is missed
2. 16GB RAM machine seems to be not enough for compiling LLVM, 32GB works definitive better
3. creating new packages very fast ended with using more than 1GB in the /app
4. creating libLLVM.so needs extra config options (by default it's not done)
5. compiling just basic llvm project can end with undefined symbol: _ZTIN4llvm19RTDyldMemoryManagerE
6. mesa docs give some example with info "This will install libGLESv1_CM, libGLESv2, libEGL, and one or more EGL drivers for your hardware.",
but it seems, that libGLESv2 is probably created only in Android version
7. there are old and new FB devices: [https://fedoraproject.org/wiki/Changes/ReplaceFbdevDrivers](https://fedoraproject.org/wiki/Changes/ReplaceFbdevDrivers)

Generally a lot of "fun", happily after some investigation it was found path to make things working (there are excluded some minor elements):

1. SDL has got dependiences to libraries from libglvnd (like libEGL.so, libGLESv2.so, etc.)
2. libraries from libglvnd are searching for json files describing name of libraries with EGL implementation (in my config libEGL_mesa.so.0) - see
[https://github.com/NVIDIA/libglvnd/blob/master/src/EGL/icd_enumeration.md](https://github.com/NVIDIA/libglvnd/blob/master/src/EGL/icd_enumeration.md)
3. libEGL_mesa.so.0 from mesa package is searching either for Wayland or X11 or DRM (in my case DRM, which is supported by internal driver egl_dri2 from mesa)

There are still things to do like moving these json files to system /etc, enabling full hardware acceleration, Vulkan, investigating latest mesa (it looks, it cannot work with FB anymore), etc. But for now (15 Oct):

![Alt text](2026/oct_opengl.png)

Similar path should be visible with Vulkan (we have vulkan-loader library, it's searching for json files describing Vulkan drivers/libraries and
it's loading them), unfortunately here there is an error "Couldn't create window: Installed Vulkan doesn't implement the VK_KHR_surface extension" visible.

# Creating packages - let's optimalize it

For long time I have done some development in the VDI with ca. 10-11GB RAM (I say it from memory). Some experiences with bigger projects (compiler crashes)
showed, that I need more RAM - I removed hard memory assignment from graphic card and could assign ca. 20 GB to VDI.

And now the magic question - is it possible to further decrease SSD usage?

Currently "main" compilation is done in /tmp (tmpfs), later software is saved to the /app (on the disk) and later it's optimalized (stripped, etc.).
And yes, we could change sequence to the following:

1. make compilation in /tmp
2. make link to the /app/(package)/current pointing to the /tmp
3. make "installation" in the /app/(package)/current
4. remove link from point 2
5. make optimalizations
6. make rsync between /tmp and /app

I don't know, what saves could be visible, but step by step... Additionally it's good to mention, that readme.md from packages will have
the date of last source modification (I search for last file in the root of source code packages), which allows for fast finding, if package is really
obsolete or not.

# Wayland or X11 + polishing

I don't want to join war and definitely be on one of sides - I have used X.Org for years (and I know about XLibre of course) and in some situations had
hard time with it (problems with Midnight Commander), from the other I had hard time with Wayland too (lack of gamma correction).

In 2026 I decided to look first on Hyprland, when will not work, move to XLibre.

On top of it there will be some lighter graphic environment - something with Start button, file manager, desktop wallpaper and some basic apps.

Excluding this there is ongoing work on missed things - network config, pllinux script update, adding missed command line tools, making compilers useable.
During this there is visible a lot of new things, for example first compiling "hello world" app with gcc produced this:

    /app/binutils/261017_2.47/bin/ld: error in /app/glibc/current/lib/crt1.o(.eh_frame); no .eh_frame_hdr table will be created
    /app/binutils/261017_2.47/bin/ld: warning: cannot find entry symbol _start; defaulting to 0000000000401040

The rootcause is, that ELF file doesn't have *tm_clones inside (see [What Functions Does GCC Add to Linux ELF Executables?](https://linuxvox.com/blog/what-functions-does-gcc-add-to-the-linux-elf/)).
It looks, that *.o files cannot have stripped symbols - for "hello world" app we require this rule in gcc and glibc package. Small fix and (18 Oct)
we have working gcc (at least for very simple code) - file is a little bit than in Debian, but this could be because of lack of optimalization options.

And some offtopic here: where is all help taken from? My past experience (I started personally somewhere around 1997, if I remember correctly, and was writing some software there around 1999-2000 already), searching with DuckDuckGo, analizing ready Debian/Ubuntu/Arch and other packages and pages like
[Linux From Scratch!](https://www.linuxfromscratch.org/) or even [DeepWiki](https://deepwiki.com/) (the last one is normally sloop, but... in some rare cases give some hints or keywords too)

[Prev page](file_yo_milestone11.md) [Next page](file_zz_milestone.md)
