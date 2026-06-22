# Part of PLLINUX. Creating some binaries from the source and installing in the system. Tested on Debian.

output="/mnt/x";  # directory with EXT4 partition, which will be / for new system
package="util-linux"; # "fs" to build all or concrete name for concrete package (busybox, nftables, etc.)
cpu_num=6; # how many CPU cores are used during compiling
dont_process_the_same_ver=0; # 1 - on; 0 - off; don't compile and install app, when the same version (even from other day) available

# Check if makes sense to build the whole package
should_make() {
  packagename=$1
  packagever=$2

  if [ $dont_process_the_same_ver == "1" ]; then
    if [ ! -d "out/$packagename" ]; then
      return 0; // true
    fi
    dirlist=$(ls "$output/app/$packagename")
    for singledir in $dirlist; do
      if [ "${singledir:7}" == "$packagever" ]; then return 1; fi
    done
    return 0; //true
  fi
  return 0; //true
}

# Download and unpack package
# todo: checking checksum and package authentity
download_unpack_source() {
  url=$1
  localfile=${url##*/}
  packagename=$2
  unpackeddir=$3

  if [ ! -f "download/$localfile" ]; then
    wget -O /tmp/$localfile.tmp $url;
    if [ $? -eq 0 ]; then
      mv /tmp/$localfile.tmp download/$localfile
    else
      exit 1
    fi
  fi
  if [ ! -d "out/$packagename/$unpackeddir" ]; then
    mkdir out/$packagename || true
    cd out/$packagename
    tar -xvf ../../download/$localfile
    cd ../..
  fi
}

#creating directory with the app
create_app() {
  packagename=$1
  version=$2

  mkdir $output/app/$packagename || true
  mkdir $output/app/$packagename/$version || true
  if [ -f "in/$packagename/readme.md" ]; then cp in/$packagename/readme.md $output/app/$packagename/$version; fi
}

#strip all binaries and libraries (remove debug symbols)
strip_app() {
  packagename=$1
  version=$2

  find $output/app/$packagename/$version* -type d -exec bash -c 'cd "{}" && strip * 2> /dev/null ' \;
}

#set "current" directory to the new installed app
set_current_app() {
  packagename=$1
  version=$2

  olddir=$(pwd)
  cd $output/app/$1
  rm current || true
  mv $version.tmp $version || true
  ln -s $version current
  cd $olddir
}

#install host system dependiencies, when required
install_host_deps() {
  for dep in $1; do
    if dpkg -s $dep > /dev/null 2>&1; then
      echo $dep installed
    else
      echo Need to install $dep package
      sudo apt install $dep;
    fi
  done
}

#find libraries in the specified binary
#we should maybe use ... tool for this
find_binary_lib() {
  appdir=$1
  binary=$2
  mkdir -p $appdir/lib
  list="$(ldd $appdir/$binary | egrep -o '/lib.*\.[0-9]')"
  for lib in $list; do rsync -a ${lib%.so*}.so* "$appdir/lib"; done
  rm -r $appdir/lib/ld-linux-x86-64.so.2 || true
  rm -r $appdir/lib64 || true
  rm -r $appdir/lib/libc.so* || true
}

prefix="$(date +"%y%m%d")_" # prefix for packages versions in /app in new system

install_host_deps "rsync"
#install_host_deps "mc retext git gitk gedit"
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
  ver="7.1.1";
  if should_make kernel $ver; then
    install_host_deps "build-essential libncurses-dev bc libelf-dev bison flex libdwarf-dev libelf-dev libdw-dev libssl-dev gawk"
    download_unpack_source https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-$ver.tar.xz kernel linux-$ver
    cp in/kernel/.config out/kernel/linux-$ver
    cd out/kernel/linux-$ver
    make -j$cpu_num
    cd ../../..
    cp out/kernel/linux-$ver/.config in/kernel # .config will be updated with new header and maybe options
    create_app kernel $prefix$ver.tmp
    cp in/kernel/.config $output/app/kernel/$prefix$ver.tmp
    cp out/kernel/linux-$ver/arch/x86/boot/bzImage $output/app/kernel/$prefix$ver.tmp
    strip_app kernel $prefix$ver
    set_current_app kernel $prefix$ver
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "busybox" ]; then
  ver="1.38.0";
  if should_make busybox $ver; then
    download_unpack_source https://busybox.net/downloads/busybox-$ver.tar.bz2 busybox busybox-$ver
    cp in/busybox/.config out/busybox/busybox-$ver
    cd out/busybox/busybox-$ver
    make -j$cpu_num
    create_app busybox $prefix$ver.tmp
    cp .config ../../../in/busybox # .config will be updated with new header and maybe options
    make CONFIG_PREFIX=$output/app/busybox/$prefix$ver.tmp install
    cd ../../..
    cp in/busybox/* $output/app/busybox/$prefix$ver.tmp
    strip_app busybox $prefix$ver
    set_current_app busybox $prefix$ver
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "nftables" ]; then
  ver="1.1.6";
  if should_make nftables $ver; then
    install_host_deps "libgmp3-dev libnftnl-dev libmnl-dev"
    download_unpack_source https://netfilter.org/projects/nftables/files/nftables-$ver.tar.xz nftables nftables-$ver
    create_app nftables $prefix$ver.tmp
    cd out/nftables/nftables-$ver
    ./configure --prefix=$output/app/nftables/$prefix$ver.tmp
    make -j$cpu_num
    make install
    cd ../../..
    cp in/nftables/nft $output/app/nftables/$prefix$ver.tmp
    strip_app nftables
    find_binary_lib $output/app/nftables/$prefix$ver.tmp sbin/nft
    rm -r $output/app/nftables/$prefix$ver.tmp/lib/libtinfo* || true
    set_current_app nftables $prefix$ver
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "bwrap" ]; then
  ver="0.11.2";
  if should_make bwrap $ver; then
    install_host_deps "meson libcap-dev"
    download_unpack_source https://github.com/containers/bubblewrap/releases/download/v$ver/bubblewrap-$ver.tar.xz bwrap bubblewrap-$ver
    create_app bwrap $prefix$ver.tmp
    mkdir app/bwrap/$prefix$ver.tmp/bin || true
    cp in/bwrap/*.c out/bwrap/bubblewrap-$ver
    cd out/bwrap/bubblewrap-$ver
    meson setup -Ddefault_library=static -Ddefault_both_libraries=static -Dselinux=disabled _builddir
    meson compile -C _builddir
    sed -i 's/ LINK_ARGS = -Wl,--as-needed -Wl,--no-undefined \/usr\/lib\/x86_64-linux-gnu\/libcap.so/ LINK_ARGS = -Wl,--as-needed -Wl,--no-undefined -static \/usr\/lib\/x86_64-linux-gnu\/libcap.a/g' _builddir/build.ninja
    meson compile -C _builddir
    mkdir $output/app/bwrap/$prefix$ver.tmp/bin
    cp _builddir/bwrap $output/app/bwrap/$prefix$ver.tmp/bin
    cd ../../..
    strip_app bwrap
    set_current_app bwrap $prefix$ver
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "dinit" ]; then
  ver="0.22.0";
  if should_make dinit $ver; then
    download_unpack_source https://github.com/davmac314/dinit/releases/download/v$ver/dinit-$ver.tar.xz dinit dinit-$ver
    create_app dinit $prefix$ver.tmp
    mkdir app/dinit/$prefix$ver.tmp/bin || true
    cd out/dinit/dinit-$ver
    ./configure --bindir=/app/dinit/current/bin --sbindir=/app/dinit/current/bin
    sed -i 's/LDFLAGS_LIBCAP=-L\/usr\/lib64 -lcap/LDFLAGS_LIBCAP=-static -L\/usr\/lib64 -lcap/g' mconfig
    sed -i 's/$(CXX) -o $(SHUTDOWN_PREFIX)shutdown shutdown.o $(ALL_LDFLAGS)/$(CXX) -static -o $(SHUTDOWN_PREFIX)shutdown shutdown.o $(ALL_LDFLAGS)/g' src/Makefile
    make all -j$cpu_num
    mkdir $output/app/dinit/$prefix$ver.tmp/bin
    cp src/dinit $output/app/dinit/$prefix$ver.tmp/bin
    cp src/dinit-check $output/app/dinit/$prefix$ver.tmp/bin
    cp src/dinit-monitor $output/app/dinit/$prefix$ver.tmp/bin
    cp src/dinitctl $output/app/dinit/$prefix$ver.tmp/bin
    cp src/shutdown $output/app/dinit/$prefix$ver.tmp/bin
    cd ../../..
    cp in/dinit/poweroff $output/app/dinit/$prefix$ver.tmp
    cp in/dinit/reboot $output/app/dinit/$prefix$ver.tmp
    strip_app dinit
    set_current_app dinit $prefix$ver
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "kbd" ]; then
  ver="2.10.0";
  if should_make kbd $ver; then
    if [ ! -d "/app" ]; then
      echo "KBD is exception. You need link from /app to the PLLINUX /app. This will be removed in the future"
      olddir=$(pwd)
      cd /
      rm current
      sudo ln -s $output/app app
      cd $olddir
    fi
    install_host_deps "autoconf libpam0g-dev"
    download_unpack_source https://www.kernel.org/pub/linux/utils/kbd/kbd-$ver.tar.xz kbd kbd-$ver
    create_app kbd $prefix$ver
    cd out/kbd/kbd-$ver
    make clean
    ./configure --prefix=$output/app/kbd/$prefix$ver  --datarootdir=/app/kbd/$prefix$ver/share
    make -j$cpu_num
    make install
    cd ../../..
    cp in/kbd/* $output/app/kbd/$prefix$ver
    strip_app kbd
    set_current_app kbd $prefix$ver
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libc" ] || [ "$package" == "ldso" ]; then
  ver="2.43";
  if should_make libc $ver; then
    download_unpack_source https://ftp.gnu.org/gnu/glibc/glibc-$ver.tar.xz libc glibc-$ver
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
    set_current_app ldso $prefix$ver
    strip_app libc
    set_current_app libc $prefix$ver
  fi
fi
#if [ "$package" == "all" ] || [ "$package" == "binutils" ]; then
#  ver="2.46.1";
#  download_unpack_source https://sourceware.org/pub/binutils/releases/binutils-2.46.1.tar.xz binutils binutils-$ver
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
  if should_make util-linux $ver; then
    download_unpack_source https://www.kernel.org/pub/linux/utils/util-linux/v$ver/util-linux-$ver.tar.xz util-linux util-linux-$ver
    create_app util-linux $prefix$ver
    cd out/util-linux/util-linux-$ver
    ./configure --prefix=$output/app/util-linux/$prefix$ver --without-systemd --disable-lsfd --disable-enosys
    make all -j$cpu_num
    make install || true
    cd ../../..
    cp in/util-linux/* $output/app/util-linux/$prefix$ver
    strip_app util-linux
    set_current_app util-linux $prefix$ver
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "mc" ]; then
  ver="4.8.33";
  if should_make mc $ver; then
    if [ ! -d "/app" ]; then
      echo "MC is exception. You need link from /app to the PLLINUX /app. This will be removed in the future"
      olddir=$(pwd)
      cd /
      rm current
      sudo ln -s $output/app app
      cd $olddir
    fi
    install_host_deps "libglib2.0-dev libslang2-dev libgpm-dev"
    download_unpack_source https://ftp.osuosl.org/pub/midnightcommander/mc-$ver.tar.xz mc mc-$ver
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
    find_binary_lib $output/app/mc/$prefix$ver bin/mc
    strip_app mc
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "bash" ]; then
  ver="5.3";
  if should_make bash $ver; then
    download_unpack_source https://ftp.gnu.org/gnu/bash/bash-$ver.tar.gz bash bash-$ver
    create_app bash $prefix$ver
    cd out/bash/bash-$ver
    ./configure --prefix=$output/app/bash/$prefix$ver
    make all -j$cpu_num
    make install
    cd ../../..
    cp in/bash/* $output/app/bash/$prefix$ver
    strip_app bash
    set_current_app bash $prefix$ver
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "e2fsprogs" ]; then
  ver="1.47.4";
  if should_make bash $ver; then
    download_unpack_source https://git.kernel.org/pub/scm/fs/ext2/e2fsprogs.git/snapshot/e2fsprogs-$ver.tar.gz e2fsprogs e2fsprogs-$ver
    create_app e2fsprogs $prefix$ver
    cd out/e2fsprogs/e2fsprogs-$ver
    ./configure LDFLAGS=-static --enable-symlink-install  --enable-relative-symlinks --prefix=$output/app/e2fsprogs/$prefix$ver
    make all -j$cpu_num
    make install
    cd ../../..
    cp in/e2fsprogs/* $output/app/e2fsprogs/$prefix$ver
    strip_app e2fsprogs
    set_current_app e2fsprogs $prefix$ver
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "initramfs" ]; then
  ver="0.1";
  if should_make initramfs $ver; then
    create_app initramfs $prefix$ver
    mkdir /tmp/initramfs
    cp in/initramfs/init /tmp/initramfs
    mkdir /tmp/initramfs/app
    mkdir /tmp/initramfs/app/busybox
    rsync -a $output/app/busybox/ /tmp/initramfs/app/busybox
    mkdir /tmp/initramfs/dev
    mkdir /tmp/initramfs/mnt
    mkdir /tmp/initramfs/proc
#    cp in/e2fsprogs/readme.md $output/app/e2fsprogs/$prefix$ver
    olddir=$(pwd)
    cd /tmp/initramfs
    find . -print0 | cpio --null --create --verbose --format=newc | gzip --best > $output/app/initramfs/$prefix$ver/initramfs.gz
    rm -r /tmp/initramfs
    cd $olddir
    set_current_app initramfs $prefix$ver
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "pllinux" ]; then
  ver="0.1";
  create_app pllinux $prefix$ver
  mkdir $output/app/pllinux/$prefix$ver
  rsync -a in/pllinux/ $output/app/pllinux/$prefix$ver
  set_current_app pllinux $prefix$ver
fi
if [ "$package" == "fs" ] || [ "$package" == "libtinfo" ]; then
  create_app libtinfo current
  cp /lib/x86_64-linux-gnu/libtinfo.so.6 $output/app/libtinfo/current
fi
if [ "$package" == "git" ]; then
  ver="2.54.0";
  if should_make git $ver; then
    install_host_deps "gettext"
    download_unpack_source https://www.kernel.org/pub/software/scm/git/git-$ver.tar.xz git git-$ver
    create_app git $prefix$ver
    cd out/git/git-$ver
    ./configure
#  ./configure LDFLAGS=-static --enable-symlink-install  --enable-relative-symlinks --prefix=$output/app/e2fsprogs/$prefix$ver
    make all -j$cpu_num
#  make install
    mkdir $output/app/git/$prefix$ver/bin
    cp git $output/app/git/$prefix$ver/bin
    cd ../../..
    strip_app git
    set_current_app git $prefix$ver
    find_binary_lib $output/app/git/$prefix$ver bin/git
    cp in/git/git $output/app/git/$prefix$ver
    cp in/git/readme.md $output/app/git/$prefix$ver
  fi
fi
