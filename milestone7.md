# Milestone 7
# Creating booting ISO




# SSD writes

Current SSD and flash memory have limited amount of writes. Because of it we:

  1. save such directories like /mnt or /tmp in RAM
  2. don't save system boot log - in the future it will be probably optional or done during system startup fail
  3. (todo) installer will download and unpack files in the RAM

