[Prev page](milestone7.md) [Next page]

# Milestone 8
# SSD writes

Over years disks were magnetic and it was possible to write data again and again without any limits.

This changed with flash memories. They have limited number of write cycles and there are few problems visible:

1. estimation of number of bytes to write in the form of TBW parameter
is normally not given for OEM disks or some classes of devices (pendrives, chips in phones, tablets, memory cards, etc.) - you don't know,
when they can fail
2. diagnostic is not provided for some classes of devices - again: you don't know, if they're failing
3. modern devices many times cost more, but have lower limits than older one (for example old 1TB SSD could have TBW 2400, new one 200) - nice progress, isn't it 
(and no: it's more greed of some companies instead of real crysis)
4. companies creating software for years didn't take care of number of disk writes - there are done thousands of
operations in the background although you don't make any action
(it includes collecting unnecessary logs, saving telemetry/spying data, making temporary operations in disk, etc.)

PLLINUX during development and usage is trying to fight with problem of high usage of disk:

  1. such directories like /mnt or /tmp are always maintaned in RAM
  2. compiling software with doit.sh script can be done in RAM
  3. app package manager is downloading and unpacking to the /tmp (RAM)
  4. packages are or will be cleaned from useless content (in plan adding option just for installing selected locales)

  2. system boot log is not saved - in the future it will be probably optional or done during system startup fail

# Logging

# Manual pages

# Sound

# CPU microcode and kernel packages
