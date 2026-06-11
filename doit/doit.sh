# Part of PLLINUX. Creating some binaries from the source. Tested on Lubuntu 26.04. Possible, that some deps are missed

package="mc";
deps=0;
cpu_num=6;
prefix="$(date +"%y%m%d")_"

download_unpack() {
  url=$1
  localfile=${url##*/}
  packagename=$2
  unpackeddir=$3
  if [ ! -f "download/$localfile" ]; then wget -O download/$localfile $url; fi
  if [ ! -d "out/$packagename/$unpackeddir" ]; then
    mkdir out/$packagename || true
    cd out/$packagename
    tar -xvf ../../download/$localfile
    cd ../..
  fi
}

create_app() {
  packagename=$1
  version=$2
  mkdir app/$packagename || true
  mkdir app/$packagename/$version || true
  cp in/$packagename/readme.md app/$packagename/$version
}

strip_app() {
  packagename=$1
  find app/$packagename -type d -exec bash -c 'cd "{}" && strip *' \;
}

mkdir app || true
mkdir out || true
mkdir download || true
if [ "$package" == "all" ] || [ "$package" == "kernel" ]; then
  if [ "$deps" == "1" ]; then sudo apt install build-essential libncurses-dev bc libelf-dev bison; fi
  ver="7.0.12";
  download_unpack https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-$ver.tar.xz kernel linux-$ver
  create_app kernel $prefix$ver
  cp in/kernel/.config out/kernel/linux-$ver
  cd out/kernel/linux-$ver
  make -j$cpu_num
  cd ../../..
  # .config will be updated with new header and maybe options
  cp out/kernel/linux-$ver/.config in/kernel
  cp in/kernel/.config app/kernel/$prefix$ver
  cp out/kernel/linux-$ver/arch/x86/boot/bzImage app/kernel/$prefix$ver
  strip_app kernel
fi
if [ "$package" == "all" ] || [ "$package" == "busybox" ]; then
  ver="1.38.0";
  download_unpack https://busybox.net/downloads/busybox-$ver.tar.bz2 busybox busybox-$ver
  create_app busybox $prefix$ver
  cp in/busybox/.config out/busybox/busybox-$ver
  cd out/busybox/busybox-$ver
  make -j$cpu_num
  # .config will be updated with new header and maybe options
  cp .config ../../../in/busybox
  make CONFIG_PREFIX=$(pwd)/../../../app/busybox/$prefix$ver install
  cd ../../..
  cp in/busybox/.config app/busybox/$prefix$ver
  strip_app busybox
fi
if [ "$package" == "all" ] || [ "$package" == "nftables" ]; then
  ver="1.1.6";
  download_unpack https://netfilter.org/projects/nftables/files/nftables-1.1.6.tar.xz nftables nftables-$ver
  create_app nftables $prefix$ver
  cd out/nftables/nftables-$ver
  ./configure --prefix=$(pwd)/../../../app/nftables/$prefix$ver
  make -j$cpu_num
  make install
  cd ../../..
  cp in/nftables/nft app/nftables/$prefix$ver
  strip_app bftables
fi
if [ "$package" == "all" ] || [ "$package" == "bwrap" ]; then
  ver="0.11.2";
  download_unpack https://github.com/containers/bubblewrap/releases/download/v$ver/bubblewrap-$ver.tar.xz bwrap bubblewrap-$ver
  create_app bwrap $prefix$ver
  mkdir app/bwrap/$prefix$ver/bin || true
  cp in/bwrap/*.c out/bwrap/bubblewrap-$ver
  cd out/bwrap/bubblewrap-$ver
  meson setup -Ddefault_library=static -Ddefault_both_libraries=static -Dselinux=disabled _builddir
  meson compile -C _builddir
  sed -i 's/ LINK_ARGS = -Wl,--as-needed -Wl,--no-undefined \/usr\/lib\/x86_64-linux-gnu\/libcap.so/ LINK_ARGS = -Wl,--as-needed -Wl,--no-undefined -static \/usr\/lib\/x86_64-linux-gnu\/libcap.a/g' _builddir/build.ninja
  meson compile -C _builddir
  cp _builddir/bwrap ../../../app/bwrap/$prefix$ver/bin
  cd ../../..
  strip_app bwrap
fi
if [ "$package" == "all" ] || [ "$package" == "dinit" ]; then
  ver="0.22.0";
  download_unpack https://github.com/davmac314/dinit/releases/download/v$ver/dinit-$ver.tar.xz dinit dinit-$ver
  create_app dinit $prefix$ver
  mkdir app/dinit/$prefix$ver/bin || true
  cd out/dinit/dinit-$ver
  ./configure --bindir=/app/dinit/current/bin --sbindir=/app/dinit/current/bin
  sed -i 's/LDFLAGS_LIBCAP=-L\/usr\/lib64 -lcap/LDFLAGS_LIBCAP=-static -L\/usr\/lib64 -lcap/g' mconfig
  sed -i 's/$(CXX) -o $(SHUTDOWN_PREFIX)shutdown shutdown.o $(ALL_LDFLAGS)/$(CXX) -static -o $(SHUTDOWN_PREFIX)shutdown shutdown.o $(ALL_LDFLAGS)/g' src/Makefile
  make all -j$cpu_num
  cp src/dinit ../../../app/dinit/$prefix$ver/bin
  cp src/dinit-check ../../../app/dinit/$prefix$ver/bin
  cp src/dinit-monitor ../../../app/dinit/$prefix$ver/bin
  cp src/dinitctl ../../../app/dinit/$prefix$ver/bin
  cp src/shutdown ../../../app/dinit/$prefix$ver/bin
  cd ../../..
  cp in/dinit/poweroff app/dinit/$prefix$ver
  cp in/dinit/reboot app/dinit/$prefix$ver
  strip_app dinit
fi
if [ "$package" == "all" ] || [ "$package" == "kbd" ]; then
  if [ "$deps" == "1" ]; then sudo apt install autoconf libpam0g-dev; fi
  ver="2.10.0";
  download_unpack https://www.kernel.org/pub/linux/utils/kbd/kbd-$ver.tar.xz kbd kbd-$ver
  create_app kbd $prefix$ver
  cd out/kbd/kbd-$ver
  ./configure --prefix=$(pwd)/../../../app/kbd/$prefix$ver  --datarootdir=/app/kbd/$prefix$ver/share
  make -j$cpu_num
  make install
  cd ../../..
  strip_app kbd
fi
if [ "$package" == "all" ] || [ "$package" == "libc" ] || [ "$package" == "ldso" ]; then
  ver="2.43";
  download_unpack https://ftp.gnu.org/gnu/glibc/glibc-$ver.tar.xz libc glibc-$ver
  create_app libc $prefix$ver
  create_app ldso $prefix$ver
  cd out/libc/glibc-$ver
  mkdir compile
  cd compile
  ../configure --disable-sanity-checks
  sed -i 's/#define OPEN_TREE_CLONE    1 /#ifndef OPEN_TREE_CLONE\n#define OPEN_TREE_CLONE    1\n#endif /g' ../sysdeps/unix/sysv/linux/sys/mount.h
  make all -j$cpu_num
  cp libc.so ../../../../app/libc/$prefix$ver
  cp elf/ld.so ../../../../app/ldso/$prefix$ver
  cd ../../../..
  strip_app ldso
  strip_app libc
fi
#if [ "$package" == "all" ] || [ "$package" == "binutils" ]; then
#  ver="2.46.1";
#  download_unpack https://sourceware.org/pub/binutils/releases/binutils-2.46.1.tar.xz binutils binutils-$ver
#  create_app binutils $prefix$ver
#  cd out/binutils/binutils-$ver
#  ./configure
#  make all -j$cpu_num
#  ./configure --prefix=$(pwd)/../../../app/binutils/$prefix$ver
#  make install
#  cd ../../..
#fi
if [ "$package" == "all" ] || [ "$package" == "util-linux" ]; then
  ver="2.42";
  download_unpack https://www.kernel.org/pub/linux/utils/util-linux/v$ver/util-linux-$ver.tar.xz util-linux util-linux-$ver
  create_app util-linux $prefix$ver
  cd out/util-linux/util-linux-$ver
  ./configure --prefix=$(pwd)/../../../app/util-linux/$prefix$ver --without-systemd
  make all -j$cpu_num
  make install || true
  cd ../../..
  strip_app util-linux
fi
if [ "$package" == "all" ] || [ "$package" == "mc" ]; then
  #sudo apt-get install libglib2.0-dev libslang2-dev
  ver="4.8.33";
  download_unpack https://ftp.osuosl.org/pub/midnightcommander/mc-4.8.33.tar.xz mc mc-$ver
  create_app mc $prefix$ver
  cd out/mc/mc-$ver
  ./configure LDFLAGS=-static --disable-vfs --prefix=$(pwd)/../../../app/mc/$prefix$ver
  make all -j$cpu_num
  make install
  cd ../../..
  strip_app mc
fi
if [ "$package" == "all" ] || [ "$package" == "bash" ]; then
  #sudo apt-get install libglib2.0-dev libslang2-dev
  ver="5.3";
  download_unpack https://ftp.gnu.org/gnu/bash/bash-$ver.tar.gz bash bash-$ver
  create_app bash $prefix$ver
  cd out/bash/bash-$ver
  ./configure --prefix=$(pwd)/../../../app/bash/$prefix$ver
  make all -j$cpu_num
  make install
  cd ../../..
  strip_app bash
fi
if [ "$package" == "all" ] || [ "$package" == "e2fsprogs" ]; then
  ver="1.47.4";
  download_unpack https://git.kernel.org/pub/scm/fs/ext2/e2fsprogs.git/snapshot/e2fsprogs-1.47.4.tar.gz e2fsprogs e2fsprogs-$ver
  create_app e2fsprogs $prefix$ver
  cd out/e2fsprogs/e2fsprogs-$ver
  ./configure LDFLAGS=-static --prefix=$(pwd)/../../../app/e2fsprogs/$prefix$ver
  make all -j$cpu_num
  make install
  cd ../../..
  strip_app e2fsprogs
fi
