package="bwrap";
deps=0;
cpu_num=6;

mkdir app || true
mkdir out || true
mkdir download || true
if [ "$package" == "all" ] || [ "$package" == "kernel" ]; then
  if [ "$deps" == "1" ]; then sudo apt install build-essential libncurses-dev bc libelf-dev bison; fi
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
if [ "$package" == "all" ] || [ "$package" == "nftables" ]; then
  ver="1.1.6";
  if [ ! -f "download/nftables-$ver.tar.xz" ]; then
    wget -O download/nftables-$ver.tar.xz https://netfilter.org/projects/nftables/files/nftables-1.1.6.tar.xz
  fi
  if [ ! -d "out/nftables/nftables-$ver" ]; then
    mkdir out/nftables || true
    cd out/nftables
    tar -xvf ../../download/nftables-$ver.tar.xz
    cd ../..
  fi
  mkdir app/nftables || true
  mkdir app/nftables/$ver || true
  cd out/nftables/nftables-$ver
  ./configure --prefix=$(pwd)/../../../app/nftables/$ver
  make -j$cpu_num
  make install
  cd ../../..
fi
if [ "$package" == "all" ] || [ "$package" == "bwrap" ]; then
  ver="0.11.2";
  if [ ! -f "download/bubblewrap-$ver.tar.xz" ]; then
    wget -O download/bubblewrap-$ver.tar.xz https://github.com/containers/bubblewrap/releases/download/v$ver/bubblewrap-$ver.tar.xz
  fi
  if [ ! -d "out/bwrap/bubblewrap-$ver" ]; then
    mkdir out/bwrap || true
    cd out/bwrap
    tar -xvf ../../download/bubblewrap-$ver.tar.xz
    cd ../..
  fi
  mkdir app/bwrap || true
  mkdir app/bwrap/$ver || true
  cp in/bwrap/*.c out/bwrap/bubblewrap-$ver
  cd out/bwrap/bubblewrap-$ver
  meson setup -Ddefault_library=static -Ddefault_both_libraries=static -Dselinux=disabled _builddir
  meson compile -C _builddir
  sed -i 's/ LINK_ARGS = -Wl,--as-needed -Wl,--no-undefined \/usr\/lib\/x86_64-linux-gnu\/libcap.so/ LINK_ARGS = -Wl,--as-needed -Wl,--no-undefined -static \/usr\/lib\/x86_64-linux-gnu\/libcap.a/g' _builddir/build.ninja
  meson compile -C _builddir
  cp _builddir/bwrap ../../../app/bwrap/$ver
fi
