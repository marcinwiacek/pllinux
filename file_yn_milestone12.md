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

[Prev page](file_yo_milestone11.md) [Next page](file_zz_milestone.md)
