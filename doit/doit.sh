# Part of PLLINUX. Creating some binaries from the source. Tested on Lubuntu 26.04. Possible, that some deps are missed

output="/mnt/x";
package="kernel";
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
  mkdir $output/app/$packagename || true
  mkdir $output/app/$packagename/$version || true
  cp in/$packagename/readme.md $output/app/$packagename/$version
}

strip_app() {
  packagename=$1
  find $output/app/$packagename -type d -exec bash -c 'cd "{}" && strip *' \;
}

link_app() {
  packagename=$1
  version=$2
  olddir=$(pwd)
  cd $output/app/$1
  rm current
  ln -s $version current
  cd $olddir
}

install_deps() {
  for dep in $1; do
    if dpkg -s $dep > /dev/null 2>&1; then
      echo $dep installed
    else
      sudo apt install $dep;
    fi
  done
}

#mkdir out || true
#mkdir download || true
if [ "$package" == "fs" ]; then
  mkdir $output/app
  mkdir $output/bin
  mkdir $output/dev
  mkdir $output/etc
  mkdir $output/home
  mkdir $output/home/root
  mkdir $output/home/user
  mkdir $output/home/user2
  mkdir $output/mnt
  mkdir $output/proc
  mkdir $output/run
  mkdir $output/sys
  mkdir $output/tmp
fi
if [ "$package" == "fs" ] || [ "$package" == "kernel" ]; then
  install_deps "build-essential libncurses-dev bc libelf-dev bison"
  ver="7.1";
  download_unpack https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-$ver.tar.xz kernel linux-$ver
  create_app kernel $prefix$ver
  cp in/kernel/.config out/kernel/linux-$ver
  cd out/kernel/linux-$ver
  make -j$cpu_num
  cd ../../..
  # .config will be updated with new header and maybe options
  cp out/kernel/linux-$ver/.config in/kernel
  cp in/kernel/.config $output/app/kernel/$prefix$ver
  cp out/kernel/linux-$ver/arch/x86/boot/bzImage $output/app/kernel/$prefix$ver
  strip_app kernel
  link_app kernel $prefix$ver
fi
if [ "$package" == "fs" ] || [ "$package" == "busybox" ]; then
  ver="1.38.0";
  download_unpack https://busybox.net/downloads/busybox-$ver.tar.bz2 busybox busybox-$ver
  create_app busybox $prefix$ver
  cp in/busybox/.config out/busybox/busybox-$ver
  cd out/busybox/busybox-$ver
  make -j$cpu_num
  # .config will be updated with new header and maybe options
  cp .config ../../../in/busybox
  make CONFIG_PREFIX=$output/app/busybox/$prefix$ver install
  cd ../../..
  cp in/busybox/* $output/app/busybox/$prefix$ver
  strip_app busybox
  link_app busybox $prefix$ver
fi
if [ "$package" == "fs" ] || [ "$package" == "nftables" ]; then
  ver="1.1.6";
  download_unpack https://netfilter.org/projects/nftables/files/nftables-1.1.6.tar.xz nftables nftables-$ver
  create_app nftables $prefix$ver
  cd out/nftables/nftables-$ver
  ./configure --prefix=$output/app/nftables/$prefix$ver
  make -j$cpu_num
  make install
  cd ../../..
  cp in/nftables/nft $output/app/nftables/$prefix$ver
  strip_app nftables
  link_app nftables $prefix$ver
fi
if [ "$package" == "fs" ] || [ "$package" == "bwrap" ]; then
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
  mkdir $output/app/bwrap/$prefix$ver/bin
  cp _builddir/bwrap $output/app/bwrap/$prefix$ver/bin
  cd ../../..
  strip_app bwrap
  link_app bwrap $prefix$ver
fi
if [ "$package" == "fs" ] || [ "$package" == "dinit" ]; then
  ver="0.22.0";
  download_unpack https://github.com/davmac314/dinit/releases/download/v$ver/dinit-$ver.tar.xz dinit dinit-$ver
  create_app dinit $prefix$ver
  mkdir app/dinit/$prefix$ver/bin || true
  cd out/dinit/dinit-$ver
  ./configure --bindir=/app/dinit/current/bin --sbindir=/app/dinit/current/bin
  sed -i 's/LDFLAGS_LIBCAP=-L\/usr\/lib64 -lcap/LDFLAGS_LIBCAP=-static -L\/usr\/lib64 -lcap/g' mconfig
  sed -i 's/$(CXX) -o $(SHUTDOWN_PREFIX)shutdown shutdown.o $(ALL_LDFLAGS)/$(CXX) -static -o $(SHUTDOWN_PREFIX)shutdown shutdown.o $(ALL_LDFLAGS)/g' src/Makefile
  make all -j$cpu_num
  mkdir $output/app/dinit/$prefix$ver/bin
  cp src/dinit $output/app/dinit/$prefix$ver/bin
  cp src/dinit-check $output/app/dinit/$prefix$ver/bin
  cp src/dinit-monitor $output/app/dinit/$prefix$ver/bin
  cp src/dinitctl $output/app/dinit/$prefix$ver/bin
  cp src/shutdown $output/app/dinit/$prefix$ver/bin
  cd ../../..
  cp in/dinit/poweroff $output/app/dinit/$prefix$ver
  cp in/dinit/reboot $output/app/dinit/$prefix$ver
  strip_app dinit
  link_app dinit $prefix$ver
fi
if [ "$package" == "fs" ] || [ "$package" == "kbd" ]; then
  install_deps "autoconf libpam0g-dev"
  ver="2.10.0";
  download_unpack https://www.kernel.org/pub/linux/utils/kbd/kbd-$ver.tar.xz kbd kbd-$ver
  create_app kbd $prefix$ver
  cd out/kbd/kbd-$ver
  ./configure --prefix=$output/app/kbd/$prefix$ver  --datarootdir=/app/kbd/$prefix$ver/share
  make -j$cpu_num
  make install
  cd ../../..
  cp in/kbd/* $output/app/kbd/$prefix$ver
  strip_app kbd
  link_app kbd $prefix$ver
fi
if [ "$package" == "fs" ] || [ "$package" == "libc" ] || [ "$package" == "ldso" ]; then
  ver="2.43";
  download_unpack https://ftp.gnu.org/gnu/glibc/glibc-$ver.tar.xz libc glibc-$ver
  create_app libc $prefix$ver
  create_app ldso $prefix$ver
  cd out/libc/glibc-$ver
  mkdir compile
  cd compile
  ../configure --disable-sanity-checks --prefix=$output/app/libc/$prefix$ver --disable-static-c++-tests --disable-static-c++-link-check
  sed -i 's/#define OPEN_TREE_CLONE    1 /#ifndef OPEN_TREE_CLONE\n#define OPEN_TREE_CLONE    1\n#endif /g' ../sysdeps/unix/sysv/linux/sys/mount.h
  make all -j$cpu_num
#  make install -test
  cp libc.so $output/app/libc/$prefix$ver
  cp elf/ld.so $output/app/ldso/$prefix$ver
  cd ../../../..
  strip_app ldso
  link_app ldso $prefix$ver
  strip_app libc
  link_app libc $prefix$ver
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
if [ "$package" == "fs" ] || [ "$package" == "util-linux" ]; then
  ver="2.42";
  download_unpack https://www.kernel.org/pub/linux/utils/util-linux/v$ver/util-linux-$ver.tar.xz util-linux util-linux-$ver
  create_app util-linux $prefix$ver
  cd out/util-linux/util-linux-$ver
  ./configure --prefix=$output/app/util-linux/$prefix$ver --without-systemd
  make all -j$cpu_num
  make install || true
  cd ../../..
  cp in/util-linux/* $output/app/util-linux/$prefix$ver
  strip_app util-linux
  link_app util-linux $prefix$ver
fi
if [ "$package" == "fsddd" ] || [ "$package" == "mc" ]; then
  if [ ! -d "/app/mc" ]; then
    echo "MC is exception. You need link from /app to the PLLINUX /app"
  else
    install_deps "libglib2.0-dev libslang2-dev libgpm-dev"
    ver="4.8.33";
    download_unpack https://ftp.osuosl.org/pub/midnightcommander/mc-4.8.33.tar.xz mc mc-$ver
    create_app mc $prefix$ver
    cd out/mc/mc-$ver
    # prefix value is later put into installed files, which makes installation useless
    ./configure --disable-vfs -with-gpm-mouse --prefix=/app/mc/current
#--exec-prefix=$(pwd)/../../../app/mc/$prefix$ver
#--prefix=$(pwd)/../../../app/mc/$prefix$ver --exec-prefix=/usr/mc
#--prefix=/usr/mc 
#--exec-prefix=/usr/mc
#--prefix=/app/mc/$prefix$ver
    make all -j$cpu_num
#    mkdir $(pwd)/../../../app/mc/$prefix$ver/bin
#    mkdir $(pwd)/../../../app/mc/$prefix$ver/sbin
#    mkdir $(pwd)/../../../app/mc/$prefix$ver/etc
#    mkdir $(pwd)/../../../app/mc/$prefix$ver/usr
#    bwrap --ro-bind /bin bin \
#          --ro-bind /sbin sbin \
#          --dev /dev \
#          --bind $(pwd)/../../../app/mc/$prefix$ver/etc etc \
#          --bind $(pwd)/../../../app/mc/$prefix$ver/usr usr/mc \
#          --ro-bind /usr/lib usr/lib \
#          --ro-bind /usr/bin usr/bin \
#          --ro-bind /usr/sbin usr/sbin \
#          --ro-bind /lib lib \
#          --ro-bind /lib64 lib64 \
#          --bind . src \
#          --chdir /src \
#          --tmpfs /tmp \
#          /usr/bin/make install
#    pwdd=$(pwd)
#    pwdd=${pwdd//\//\\/}
#    newcmd="s/$pwdd\/..\/..\/..\/app\/mc\/$prefix$ver/\/app\/mc\/$prefix$ver/g"
#    find ../../../app/$packagename/$prefix$ver -name "*.sh" -exec bash -c "echo \"executing on {}\" && sed -i \"$newcmd\" {}" \;
#    find ../../../app/$packagename/$prefix$ver -name "*.csh" -exec bash -c "echo \"executing on {}\" && sed -i \"$newcmd\" {}" \;
    rm /app/mc/current
    mkdir /app/mc/$prefix$ver
    olddir=$(pwd)
    cd /app/mc
    ln -s $prefix$ver current
    cd $olddir
    make install
    cd ../../..
    strip_app mc
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "bash" ]; then
  ver="5.3";
  download_unpack https://ftp.gnu.org/gnu/bash/bash-$ver.tar.gz bash bash-$ver
  create_app bash $prefix$ver
  cd out/bash/bash-$ver
  ./configure --prefix=$output/app/bash/$prefix$ver
  make all -j$cpu_num
  make install
  cd ../../..
  cp in/bash/* $output/app/bash/$prefix$ver
  strip_app bash
  link_app bash $prefix$ver
fi
if [ "$package" == "fs" ] || [ "$package" == "e2fsprogs" ]; then
  ver="1.47.4";
  download_unpack https://git.kernel.org/pub/scm/fs/ext2/e2fsprogs.git/snapshot/e2fsprogs-1.47.4.tar.gz e2fsprogs e2fsprogs-$ver
  create_app e2fsprogs $prefix$ver
  cd out/e2fsprogs/e2fsprogs-$ver
  ./configure LDFLAGS=-static --enable-symlink-install  --enable-relative-symlinks --prefix=$output/app/e2fsprogs/$prefix$ver
  make all -j$cpu_num
  make install
  cd ../../..
  cp in/e2fsprogs/* $output/app/e2fsprogs/$prefix$ver
  strip_app e2fsprogs
  link_app e2fsprogs $prefix$ver
fi
