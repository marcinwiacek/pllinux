# Technology preview release notes

Are you tired with waiting for next release of your favourite Linux distribution? Do you want to see immediately latest and gratest versions
of your applications? Do you want to be able to easy switch and check some software version without resigning from stable or working environment? Do you want to see, what is what in your disk without headache or IT studies? And do you expect security higher than ever
without using too much RAM or disk?

PLLinux contains solution for this and many other things. It was started after seeing problems with existing Linux distributions and lack of dev reaction for it (or after seeing decreasing product functionalities).

Technology Preview shows, in what direction should go modern operating system. This version contains already many elements
and can already give feeling, where many existing systems are weak and obsolete (if you like analogies,
you could compare it into [Windows 95 build 58s](https://www.youtube.com/watch?v=9gKi_zYklMI&list=PLUS6aV5qyWClKFfbFT2P4Yd1RMNfxNhpM&index=2) or [Windows 95 build 73f](https://www.youtube.com/watch?v=SVL7aL7AN74&list=PLUS6aV5qyWClKFfbFT2P4Yd1RMNfxNhpM&index=3), where revolution was already visible, but not completed). Some solutions are similar to used in Android or Apple products or
even NixOS, but are not the same.

# Filesystem
All applications are saved in separate folders inside /app, filesystem contains additionally /etc folder with some configuration files, /home with user files and few folders created by kernel or created to satisfy some scripts (they contains just links to the /app).

And this is everything.

You can assign different apps or app versions from the /app to other users.

# Starting

You need system with UEFI and without Secure Boot. Examples:

**qemu-system-x86_64 -cdrom iso.iso -m 4098 -bios /usr/share/OVMF/OVMF_CODE.fd**

Technology Preview contains three users: root (password root), user (password user) and user2 (password user2)

User files are saved in the RAM (tmpfs) and you can for example make setup using root and later login into other account.

# Known issues

# Future

Next months and 2027 will be used for improving functionality (compiling more packages, providing more flexible
and easier structure, decreasing resources usage, etc.) and preparing graphic environment.