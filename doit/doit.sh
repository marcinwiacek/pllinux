# Part of PLLINUX. Creating some binaries from the source. Tested on Lubuntu 26.04. Possible, that some deps are missed

package="bwrap";
deps=0;
cpu_num=6;

download_unpack() {
  url=$1
  localfile=${url##*/}
  package=$2
  unpackeddir=$3
  if [ ! -f "download/$localfile" ]; then wget -O download/$localfile $url; fi
  if [ ! -d "out/$package/$unpackeddir" ]; then
    mkdir out/$package || true
    cd out/$package
    tar -xvf ../../download/$localfile
    cd ../..
  fi
}

mkdir app || true
mkdir out || true
mkdir download || true
if [ "$package" == "all" ] || [ "$package" == "kernel" ]; then
  if [ "$deps" == "1" ]; then sudo apt install build-essential libncurses-dev bc libelf-dev bison; fi
  ver="7.0.12";
  download_unpack https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-$ver.tar.xz kernel linux-$ver
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
  download_unpack https://busybox.net/downloads/busybox-$ver.tar.bz2 busybox busybox-$ver
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
  download_unpack https://netfilter.org/projects/nftables/files/nftables-1.1.6.tar.xz nftables nftables-$ver
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
  download_unpack https://github.com/containers/bubblewrap/releases/download/v$ver/bubblewrap-$ver.tar.xz bwrap bubblewrap-$ver
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
if [ "$package" == "all" ] || [ "$package" == "dinit" ]; then
  ver="0.22.0";
  download_unpack https://github.com/davmac314/dinit/releases/download/v$ver/dinit-$ver.tar.xz dinit dinit-$ver
  mkdir app/dinit || true
  mkdir app/dinit/$ver || true
  mkdir app/dinit/$ver/bin || true
  cd out/dinit/dinit-$ver
  ./configure -DBINDIR=/app/dinit/current/bin -DSBINDIR=/app/dinit/current/bin
  sed -i 's/LDFLAGS_LIBCAP=-L\/usr\/lib64 -lcap/LDFLAGS_LIBCAP=-static -L\/usr\/lib64 -lcap/g' mconfig
  make all -j$cpu_num
  cp src/dinit ../../../app/dinit/$ver/bin
  cp src/dinit-check ../../../app/dinit/$ver/bin
  cp src/dinit-monitor ../../../app/dinit/$ver/bin
  cp src/dinitctl ../../../app/dinit/$ver/bin
  cp src/shutdown ../../../app/dinit/$ver/bin
fi
