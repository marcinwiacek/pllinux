package="busybox";
cpu_num=6;
mkdir app || true
mkdir out || true
if [ "$package" == "all" ] || [ "$package" == "kernel" ]; then
  ver="7.0.12";
  if [ ! -f "download/linux-$ver.tar.xz" ]; then
    wget -O download/linux-$ver.tar.xz https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-$ver.tar.xz
  fi
  if [ ! -d "out/kernel/linux-$ver" ]; then
    mkdir out/kernel || true
    cd out/kernel
    tar -xvf ../../download/linux-$ver.tar.xz
    cd ../..
  fi
  cp in/kernel/.config out/kernel/linux-$ver
  cd out/kernel/linux-$ver
  make -j$cpu_num
  cd ../../..
  mkdir app/kernel || true
  mkdir app/kernel/$ver || true
  # .config will be updated with new header and maybe options
  cp out/kernel/linux-$ver/.config in/kernel
  cp in/kernel/.config app/kernel/$ver
  cp out/kernel/linux-$ver/arch/x86/boot/bzImage app/kernel/$ver
fi
if [ "$package" == "all" ] || [ "$package" == "busybox" ]; then
  ver="1.38.0";
  if [ ! -f "download/busybox-$ver.tar.bz2" ]; then
    wget -O download/busybox-$ver.tar.bz2 https://busybox.net/downloads/busybox-$ver.tar.bz2
  fi
  if [ ! -d "out/busybox/busybox-$ver" ]; then
    mkdir out/busybox || true
    cd out/busybox
    tar -xvf ../../download/busybox-$ver.tar.bz2
    cd ../..
  fi
  mkdir app/busybox || true
  mkdir app/busybox/$ver || true
  cp in/busybox/.config out/busybox/busybox-$ver
  cd out/busybox/busybox-$ver
  make -j$cpu_num
  # .config will be updated with new header and maybe options
  cp .config ../../../in/busybox
  make CONFIG_PREFIX=$(pwd)/../../../app/busybox/$ver install
  cd ../../..
  cp in/busybox/.config app/busybox/$ver
fi
