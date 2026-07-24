[Prev page](milestone7.md) [Next page]

# Milestone 8
# SSD writes

Over years disks were magnetic and it was possible to write data again and again without any limits.

This changed with flash memories. They have normally limited number of write cycles:

1. estimation of their minimal guaranted number / number of bytes to write in the form of TBW parameter
is normally not given for OEM disks or some classes of devices (pendrive, chips in phones, tablets, memory cards, etc.)
2. modern devices have many times lower limits than older one (for example old 1TB SSD had TBW 2400, new one 200)

Companies creating software for years didn't take care of number of disk writes - there were done thousands of
operations in the background (collecting unnecessary logs, saving telemetry/spying data, making temporary operations in disk, etc.)

PLLINUX in development and usage is trying to fight with this problem:

  1. such directories like /mnt or /tmp are always maintaned in RAM
  2. compiling software with doit.sh script can be done in RAM
  3. app package manager is downloading and unpacking to the /tmp (RAM)


  2. system boot log is not saved - in the future it will be probably optional or done during system startup fail

# Logging

# Manual pages

# Sound

# CPU microcode and kernel packages
