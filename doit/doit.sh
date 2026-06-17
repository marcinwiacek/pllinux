# Part of PLLINUX. Creating some binaries from the source. Tested on Lubuntu 26.04. Possible, that some deps are missed

output="/mnt/x";  # directory with EXT4 partition, which will be / for new system
package="busybox"; # fs to build all or "name" for concrete package
cpu_num=6; # how many CPU cores are used during compiling
prefix="$(date +"%y%m%d")_" # prefix for packages versions in /app in new system

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
  if [ -f "in/$packagename/readme.md" ]; then cp in/$packagename/readme.md $output/app/$packagename/$version; fi
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

findlib() {
  appdir=$1
  binary=$2
  mkdir -p $appdir/lib
  list="$(ldd $appdir/$binary | egrep -o '/lib.*\.[0-9]')"
  for lib in $list; do rsync -a ${lib%.so*}.so* "$appdir/lib"; done
  rm -r $appdir/lib/ld-linux-x86-64.so.2 || true
  rm -r $appdir/lib64 || true
  rm -r $appdir/lib/libc.so* || true
}

mkdir out || true
mkdir download || true
if [ "$package" == "fs" ]; then
  mkdir $output/app
  mkdir $output/bin
  mkdir $output/dev
  mkdir $output/etc
  rsync -a in/etc/ $output/etc
  mkdir $output/home
  mkdir $output/home/root
  sudo chown root $output/home/root
  sudo chgrp root $output/home/root
  sudo mkdir $output/home/root/app
  sudo chown root $output/home/root/app
  sudo chgrp root $output/home/root/app
  sudo mkdir $output/home/root/files
  sudo chown root $output/home/root/files
  sudo chgrp root $output/home/root/files
  sudo chmod u+rwx $output/home/root
  sudo chmod g-rwx $output/home/root
  sudo chmod o-rwx $output/home/root
  mkdir $output/home/user
  sudo chown 1000 $output/home/user
  sudo chgrp 1000 $output/home/user
  mkdir $output/home/user/app
  sudo chown 1000 $output/home/user/app
  sudo chgrp 1000 $output/home/user/app
  mkdir $output/home/user/files
  sudo chown 1000 $output/home/user/files
  sudo chgrp 1000 $output/home/user/files
  sudo chmod u+rwx $output/home/user
  sudo chmod g-rwx $output/home/user
  sudo chmod o-rwx $output/home/user
  sudo mkdir $output/home/user2
  sudo chown 1001 $output/home/user2
  sudo chgrp 1001 $output/home/user2
  sudo mkdir $output/home/user2/app
  sudo chown 1001 $output/home/user2/app
  sudo chgrp 1001 $output/home/user2/app
  sudo mkdir $output/home/user2/files
  sudo chown 1001 $output/home/user2/files
  sudo chgrp 1001 $output/home/user2/files
  sudo chmod u+rwx $output/home/user2
  sudo chmod g-rwx $output/home/user2
  sudo chmod o-rwx $output/home/user2
  mkdir $output/mnt
  mkdir $output/proc
  mkdir $output/run
  mkdir $output/sys
  mkdir $output/tmp
  olddir=$(pwd)
  cd $output
  if [ ! -d "etc." ]; then ln -s etc etc.; fi
  if [ ! -d "other" ]; then ln -s home/root other; fi
  cd bin
  ln -s /app/busybox/current/bin/sh sh
  cd $olddir
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
  findlib $output/app/nftables/$prefix$ver sbin/nft
  rm -r $output/app/nftables/$prefix$ver/lib/libtinfo* || true
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
  make clean
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
  olddir=$(pwd)
  cd $output/app/libc/$prefix$ver
  ln -s libc.so libc.so.6
  cd $olddir
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
if [ "$package" == "fs" ] || [ "$package" == "mc" ]; then
  if [ ! -d "/app" ]; then
    echo "MC is exception. You need link from /app to the PLLINUX /app. This will be removed in the future"
    olddir=$(pwd)
    cd /
    rm current
    sudo ln -s $output/app app
    cd $olddir
  fi
  install_deps "libglib2.0-dev libslang2-dev libgpm-dev"
  ver="4.8.33";
  download_unpack https://ftp.osuosl.org/pub/midnightcommander/mc-4.8.33.tar.xz mc mc-$ver
  create_app mc $prefix$ver
  cd out/mc/mc-$ver
    # prefix value is later put into installed and binary files, which makes installation sometimes problematic
    # there were different options tried (even changing string in all files, but... it was not possible in binaries)
#    pwdd=$(pwd)
#    pwdd=${pwdd//\//\\/}
#    newcmd="s/$pwdd\/..\/..\/..\/app\/mc\/$prefix$ver/\/app\/mc\/$prefix$ver/g"
#    find ../../../app/$packagename/$prefix$ver -name "*.sh" -exec bash -c "echo \"executing on {}\" && sed -i \"$newcmd\" {}" \;
#    find ../../../app/$packagename/$prefix$ver -name "*.csh" -exec bash -c "echo \"executing on {}\" && sed -i \"$newcmd\" {}" \;
#--exec-prefix=$(pwd)/../../../app/mc/$prefix$ver
#--prefix=$(pwd)/../../../app/mc/$prefix$ver --exec-prefix=/usr/mc
#--prefix=/usr/mc 
#--exec-prefix=/usr/mc
#--prefix=/app/mc/$prefix$ver
  ./configure --disable-vfs -with-gpm-mouse --prefix=/app/mc/current
  make all -j$cpu_num
# sandbox would be clean solution, but for now I have gcc crash
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
  rm /app/mc/current
  mkdir /app/mc/$prefix$ver
  olddir=$(pwd)
  cd /app/mc
  ln -s $prefix$ver current
  cd $olddir
  make install
  cd ../../..
  cp in/mc/mc $output/app/mc/$prefix$ver
  rm $output/app/mc/$prefix$ver/bin/mcdiff
  cp in/mc/mcdiff $output/app/mc/$prefix$ver/bin/mcdiff
  rm $output/app/mc/$prefix$ver/bin/mcview
  cp in/mc/mcview $output/app/mc/$prefix$ver/bin/mcview
  rm $output/app/mc/$prefix$ver/bin/mcedit
  cp in/mc/mcedit $output/app/mc/$prefix$ver/bin/mcedit
  olddir=$(pwd)
  cd $output/app/mc/$prefix$ver/bin
  ln -s /app/busybox/current/bin/sh sh
  cd $olddir
  mkdir $output/app/mc/$prefix$ver/usr
  mkdir $output/app/mc/$prefix$ver/usr/share
  mkdir $output/app/mc/$prefix$ver/usr/share/terminfo
  rsync -a /usr/share/terminfo/ $output/app/mc/$prefix$ver/usr/share/terminfo
  findlib $output/app/mc/$prefix$ver bin/mc
  strip_app mc
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
if [ "$package" == "fs" ] || [ "$package" == "initramfs" ]; then
  ver="0.1";
  create_app initramfs $prefix$ver
  mkdir $output/app/initramfs/$prefix$ver/x
  cp in/initramfs/init $output/app/initramfs/$prefix$ver/x
  mkdir $output/app/initramfs/$prefix$ver/x/app
  mkdir $output/app/initramfs/$prefix$ver/x/app/busybox
  rsync -a $output/app/busybox/ $output/app/initramfs/$prefix$ver/x/app/busybox
  mkdir $output/app/initramfs/$prefix$ver/x/dev
  mkdir $output/app/initramfs/$prefix$ver/x/mnt
  mkdir $output/app/initramfs/$prefix$ver/x/proc
  cp in/e2fsprogs/readme.md $output/app/e2fsprogs/$prefix$ver
  olddir=$(pwd)
  cd $output/app/initramfs/$prefix$ver/x
  find . -print0 | cpio --null --create --verbose --format=newc | gzip --best > ../initramfs.gz
  cd ..
  rm -r x
  cd $olddir
  link_app initramfs $prefix$ver
fi
if [ "$package" == "fs" ] || [ "$package" == "pllinux" ]; then
  ver="0.1";
  create_app pllinux $prefix$ver
  mkdir $output/app/pllinux/$prefix$ver
  rsync -a in/pllinux/ $output/app/pllinux/$prefix$ver
  link_app pllinux $prefix$ver
fi
if [ "$package" == "fs" ] || [ "$package" == "libtinfo" ]; then
  create_app libtinfo current
  cp /lib/x86_64-linux-gnu/libtinfo.so.6 $output/app/libtinfo/current
fi
