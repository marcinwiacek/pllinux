# Part of PLLINUX. Version from 23 July 2026. Creating binaries (from the source) and installing them in the PLLINUX partition. Tested on Debian "Trixie".

output="/mnt/x";  # directory with EXT4 partition, which will be / for new system
package="xorriso"; # "fs" to build all or concrete name for concrete package (busybox, nftables, etc.) or iso to build iso file
cpu_num=6; # how many CPU cores are used during compilation
dont_process_the_same_ver=0; # 1 - on; 0 - off; don't compile and install app, when the same version (even from other day) available
use_tmpfs=1; # 1 - some compilations will be done in RAM disk (currently excluded: kernel and gcc part); 0 - save all to disk
isofile="/mnt/host/iso.iso" # boot iso created with package iso

# options below shouldn't be probably changed
out="out"
if [ "$use_tmpfs" = "1" ]; then
  out="/tmp/doit" # in Debian this is tmpfs
  mkdir $out 2> /dev/null
fi
curdir=$(pwd)
prefix="$(date +"%y%m%d")_" # prefix for packages versions in /app in new system

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
  canbetmp=$4

  if [ ! -f "download/$localfile" ]; then
    echo $url
    wget -O /tmp/$localfile.tmp $url;
    if [ $? -eq 0 ]; then
      mv /tmp/$localfile.tmp download/$localfile
    else
      exit 1
    fi
  fi

  if [ "$canbetmp" = "1" ]; then
    if [ ! -d "$out/$packagename/$unpackeddir" ]; then
      mkdir $out/$packagename || true
      cd $out/$packagename
      tar -xvf $curdir/download/$localfile
      cd $unpackeddir
    else
      cd $out/$packagename/$unpackeddir
    fi
  else
    if [ ! -d "out/$packagename/$unpackeddir" ]; then
      mkdir out/$packagename || true
      cd out/$packagename
      tar -xvf $curdir/download/$localfile
      cd $unpackeddir
    else
      cd out/$packagename/$unpackeddir
    fi
  fi
}

#creating directory with the app
create_app() {
  packagename=$1
  version=$2

  mkdir $output/app/$packagename || true
  mkdir $output/app/$packagename/$version || true
  if [ -f "$curdir/in/$packagename/readme.md" ]; then cp $curdir/in/$packagename/readme.md $output/app/$packagename/$version; fi
}

set_current_app_clean_strip_cd() {
  packagename=$1
  version=$2
  stripapp=$3

  #set "current" directory to the new installed app
  cd $output/app/$1
  rm current || true
  ln -s $version current

  if [ -d "$output/app/$packagename/$version/lib" ]; then
    chmod a-x $output/app/$packagename/$version/lib/*.so*
    chmod a-x $output/app/$packagename/$version/lib/*.la*
  fi

  if [ "$stripapp" = "1" ]; then
    #strip all binaries and libraries (remove debug symbols)
    find $output/app/$packagename/$version* -type d -exec bash -c 'cd "{}" && strip * 2> /dev/null ' \;
  fi

  if [ "$use_tmpfs" = "1" ]; then
    rm -r -f $out
    mkdir $out 2> /dev/null
  fi

  cd $curdir
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

#blind code now
create_readme() {
  CONTENT=""
  if [ $1 != "" ]; then
    CONTENT="$CONTENT**Deps**"
  fi
}

remove_duplicates_cd() {
  cd $1
  while true; do
    DOITAGAIN="0"
    for fname in $(find . -maxdepth 1 -type f); do
      CHECKSUM=($(md5sum $fname))
      for fname2 in $(find . -maxdepth 1 -type f); do
        CHECKSUM2=($(md5sum $fname2))
        if [ "$fname" != "$fname2" ] && [ "$CHECKSUM" = "$CHECKSUM2" ]; then
            rm $fname2
            ln -s $fname $fname2
            DOITAGAIN="1"
        fi
      done
      if [ "$DOITAGAIN" = "1" ]; then
        break
      fi
    done
    if [ "$DOITAGAIN" = "0" ]; then
      break
    fi
  done
  cd $curdir
}

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
  mkdir $output/lib64
  olddir=$(pwd)
  cd $output
  if [ ! -d "etc." ]; then ln -s etc etc.; fi
  if [ ! -d "other" ]; then ln -s home/root other; fi
  cd bin
  ln -s /app/busybox/current/bin/sh sh
  ln -s /app/bash/current/bin/bash bash
  cd ..
  cd lib64
  ln -s /app/glibc/current/lib/ld-linux-x86-64.so.2 ld-linux-x86-64.so.2
  chmod a+x ld-linux-x86-64.so.2
  cd $olddir
fi
if [ "$package" == "fs" ] || [ "$package" == "kernel" ]; then
  ver="7.1.3";
  if should_make kernel $ver; then
    install_host_deps "build-essential libncurses-dev bc libelf-dev bison flex libdwarf-dev libelf-dev libdw-dev libssl-dev gawk"
    download_unpack_source https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-$ver.tar.xz kernel linux-$ver 0
    cp $curdir/in/kernel/.config $out/kernel/linux-$ver
    make -j$cpu_num
    cp $out/kernel/linux-$ver/.config $curdir/in/kernel # .config will be updated with new header and maybe options
    create_app kernel $prefix$ver
    cp $in/kernel/.config $output/app/kernel/$prefix$ver
    cp $out/kernel/linux-$ver/arch/x86/boot/bzImage $output/app/kernel/$prefix$ver
    set_current_app_clean_strip_cd kernel $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "busybox" ]; then
  ver="1.38.0";
  if should_make busybox $ver; then
    download_unpack_source https://busybox.net/downloads/busybox-$ver.tar.bz2 busybox busybox-$ver 1
    cp $curdir/in/busybox/.config $out/busybox/busybox-$ver
    make -j$cpu_num
    create_app busybox $prefix$ver
    cp .config $curdir/in/busybox # .config will be updated with new header and maybe options
    make CONFIG_PREFIX=$output/app/busybox/$prefix$ver install
    cp $curdir/in/busybox/* $output/app/busybox/$prefix$ver
    rm $output/app/busybox/$prefix$ver/linuxrc
    set_current_app_clean_strip_cd busybox $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "nftables" ]; then
  ver="1.1.6";
  if should_make nftables $ver; then
    install_host_deps "libgmp3-dev libmnl-dev libedit-dev"
    #Trixy has got older version of libnftnl-dev
    if [ ! -f "download/libnftnl11_1.3.1-1_amd64.deb" ]; then
      wget -O download/libnftnl11_1.3.1-1_amd64.deb http://mirrors.kernel.org/ubuntu/pool/main/libn/libnftnl/libnftnl11_1.3.1-1_amd64.deb
      sudo apt-get install download/libnftnl11_1.3.1-1_amd64.deb
    fi
    download_unpack_source https://netfilter.org/projects/nftables/files/nftables-$ver.tar.xz nftables nftables-$ver 1
    ./configure --prefix=$output/app/nftables/$prefix$ver
    make -j$cpu_num
    create_app nftables $prefix$ver
    make install
    find_binary_lib $output/app/nftables/$prefix$ver sbin/nft
    rm -r $output/app/nftables/$prefix$ver/lib/libtinfo* || true
    set_current_app_clean_strip_cd nftables $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "bwrap" ]; then
  ver="0.11.2";
  if should_make bwrap $ver; then
    install_host_deps "meson libcap-dev"
    download_unpack_source https://github.com/containers/bubblewrap/releases/download/v$ver/bubblewrap-$ver.tar.xz bwrap bubblewrap-$ver 1
    cp $curdir/in/bwrap/*.c $out/bwrap/bubblewrap-$ver
    meson setup -Ddefault_library=static -Ddefault_both_libraries=static -Dselinux=disabled _builddir
    meson compile -C _builddir
    sed -i 's/ LINK_ARGS = -Wl,--as-needed -Wl,--no-undefined \/usr\/lib\/x86_64-linux-gnu\/libcap.so/ LINK_ARGS = -Wl,--as-needed -Wl,--no-undefined -static \/usr\/lib\/x86_64-linux-gnu\/libcap.a/g' _builddir/build.ninja
    meson compile -C _builddir
    create_app bwrap $prefix$ver
    mkdir $output/app/bwrap/$prefix$ver/bin
    cp _builddir/bwrap $output/app/bwrap/$prefix$ver/bin
    cp $curdir/in/bwrap/diff $output/app/bwrap/$prefix$ver
    cp $curdir/in/bwrap/diff2 $output/app/bwrap/$prefix$ver
    set_current_app_clean_strip_cd bwrap $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "dinit" ]; then
  ver="0.22.0";
  if should_make dinit $ver; then
    download_unpack_source https://github.com/davmac314/dinit/releases/download/v$ver/dinit-$ver.tar.xz dinit dinit-$ver 1
    ./configure --bindir=/app/dinit/current/bin --sbindir=/app/dinit/current/bin
    sed -i 's/LDFLAGS_LIBCAP=-L\/usr\/lib64 -lcap/LDFLAGS_LIBCAP=-static -L\/usr\/lib64 -lcap/g' mconfig
    sed -i 's/$(CXX) -o $(SHUTDOWN_PREFIX)shutdown shutdown.o $(ALL_LDFLAGS)/$(CXX) -static -o $(SHUTDOWN_PREFIX)shutdown shutdown.o $(ALL_LDFLAGS)/g' src/Makefile
    make all -j$cpu_num
    create_app dinit $prefix$ver
    mkdir $output/app/dinit/$prefix$ver/bin
    cp src/dinit $output/app/dinit/$prefix$ver/bin
    cp src/dinit-check $output/app/dinit/$prefix$ver/bin
    cp src/dinit-monitor $output/app/dinit/$prefix$ver/bin
    cp src/dinitctl $output/app/dinit/$prefix$ver/bin
    cp src/shutdown $output/app/dinit/$prefix$ver/bin
    cp $curdir/in/dinit/poweroff $output/app/dinit/$prefix$ver
    cp $curdir/in/dinit/reboot $output/app/dinit/$prefix$ver
    set_current_app_clean_strip_cd dinit $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "kbd" ]; then
  ver="2.10.0";
  if should_make kbd $ver; then
    if [ ! -d "/app" ]; then
      echo "KBD is exception. You need link from /app to the PLLINUX /app. This will be removed in the future"
      cd /
      sudo ln -s $output/app app
      cd $curdir
    fi
    install_host_deps "autoconf libpam0g-dev"
    download_unpack_source https://www.kernel.org/pub/linux/utils/kbd/kbd-$ver.tar.xz kbd kbd-$ver 1
    make clean
    ./configure --prefix=$output/app/kbd/$prefix$ver --datarootdir=/app/kbd/$prefix$ver/share
    make -j$cpu_num
    create_app kbd $prefix$ver
    make install
    cp $curdir/in/kbd/* $output/app/kbd/$prefix$ver
    set_current_app_clean_strip_cd kbd $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "glibc" ]; then
  # GNU C Library, not glib (gtk, gnome)
  ver="2.43";
  if should_make glibc $ver; then
    download_unpack_source https://ftp.gnu.org/gnu/glibc/glibc-$ver.tar.xz glibc glibc-$ver 1
    mkdir $out/glibc/glibc-$ver-build
    cd $out/glibc/glibc-$ver-build
    ../glibc-$ver/configure --prefix=$output/app/glibc/$prefix$ver
    cp $curdir/in/glibc/2_43_rtld.c ../glibc-$ver/elf/rtld.c
    make all -j$cpu_num
    create_app glibc $prefix$ver
    make install
    chmod a-x $output/app/glibc/$prefix$ver/lib/audit/*so*
    chmod a-x $output/app/glibc/$prefix$ver/lib/gconv/*so*
    cp $curdir/in/glibc/2_43_patch_ver6.txt $output/app/glibc/$prefix$ver
    set_current_app_clean_strip_cd glibc $prefix$ver 1
    chmod a+x $output/app/glibc/$prefix$ver/lib/ld-linux-x86-64.so.2
  fi
fi
#if [ "$package" == "all" ] || [ "$package" == "binutils" ]; then
#  ver="2.46.1";
#  download_unpack_source https://sourceware.org/pub/binutils/releases/binutils-2.46.1.tar.xz binutils binutils-$ver 0
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
    download_unpack_source https://www.kernel.org/pub/linux/utils/util-linux/v$ver/util-linux-$ver.tar.xz util-linux util-linux-$ver 1
    ./configure --prefix=$output/app/util-linux/$prefix$ver --without-systemd --disable-lsfd --disable-enosys
    make all -j$cpu_num
    create_app util-linux $prefix$ver
    make install || true
    cp $curdir/in/util-linux/* $output/app/util-linux/$prefix$ver
    set_current_app_clean_strip_cd util-linux $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "mc" ]; then
  ver="4.8.33";
  if should_make mc $ver; then
    if [ ! -d "/app" ]; then
      echo "MC is exception. You need link from /app to the PLLINUX /app. This will be removed in the future"
      cd /
      sudo ln -s $output/app app
      cd $curdir
    fi
    install_host_deps "libglib2.0-dev libslang2-dev libgpm-dev"
    download_unpack_source https://ftp.osuosl.org/pub/midnightcommander/mc-$ver.tar.xz mc mc-$ver 1
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
    ./configure --disable-vfs -without-gpm-mouse --prefix=/app/mc/current
    make all -j$cpu_num
    # need to install to /app/mc/current
    create_app mc $prefix$ver
    cd /app/mc
    rm current
    ln -s $prefix$ver current
    cd $out/mc/mc-$ver
    make install
    cd $output/app/mc/$prefix$ver/bin
    ln -s /app/busybox/current/bin/sh sh
    cd $output/app/mc/$prefix$ver
    mkdir usr
    cd usr
    mkdir share
    cd share
    ln -s /app/ncurses/current/share/terminfo terminfo
    cp $curdir/in/mc/mc $output/app/mc/$prefix$ver
    set_current_app_clean_strip_cd mc $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "bash" ]; then
  ver="5.3";
  if should_make bash $ver; then
    download_unpack_source https://ftp.gnu.org/gnu/bash/bash-$ver.tar.gz bash bash-$ver 1
    ./configure --prefix=$output/app/bash/$prefix$ver
    make all -j$cpu_num
    create_app bash $prefix$ver
    make install
    cp $curdir/in/bash/* $output/app/bash/$prefix$ver
    set_current_app_clean_strip_cd bash $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "e2fsprogs" ]; then
  ver="1.47.4";
  if should_make bash $ver; then
    download_unpack_source https://git.kernel.org/pub/scm/fs/ext2/e2fsprogs.git/snapshot/e2fsprogs-$ver.tar.gz e2fsprogs e2fsprogs-$ver 1
    ./configure LDFLAGS=-static --enable-symlink-install  --enable-relative-symlinks --prefix=$output/app/e2fsprogs/$prefix$ver
    make all -j$cpu_num
    create_app e2fsprogs $prefix$ver
    make install
    cp $curdir/in/e2fsprogs/* $output/app/e2fsprogs/$prefix$ver
    set_current_app_clean_strip_cd e2fsprogs $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "initramfs" ]; then
  ver="0.1";
  if should_make initramfs $ver; then
    create_app initramfs $prefix$ver

    mkdir $out/initramfs
    cp in/initramfs/init $out/initramfs
    mkdir $out/initramfs/app
    for app in busybox; do mkdir $out/initramfs/app/$app; rsync -a $output/app/$app/ $out/initramfs/app/$app; done
    mkdir $out/initramfs/dev
    mkdir $out/initramfs/proc
    mkdir $out/initramfs/mnt
    mkdir $out/initramfs/run
    mkdir $out/initramfs/sys
    mkdir $out/initramfs/etc
    mkdir $out/initramfs/lib64

    cd $out/initramfs/lib64
    ln -s /app/glibc/current/lib/ld-linux-x86-64.so.2 ld-linux-x86-64.so.2
    chmod a+x ld-linux-x86-64.so.2

    cd $out/initramfs
    find . -print0 | cpio --null --create --verbose --format=newc | gzip --best > $output/app/initramfs/$prefix$ver/initramfs.gz

    set_current_app_clean_strip_cd initramfs $prefix$ver 0
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "pllinux" ]; then
  ver="0.1";
  create_app pllinux $prefix$ver
  mkdir $output/app/pllinux/$prefix$ver
  rsync -a $curdir/in/pllinux/ $output/app/pllinux/$prefix$ver
  set_current_app_clean_strip_cd pllinux $prefix$ver 0
fi
if [ "$package" == "fs" ] || [ "$package" == "git" ]; then
  ver="2.55.0";
  if should_make git $ver; then
    install_host_deps "gettext"
    download_unpack_source https://www.kernel.org/pub/software/scm/git/git-$ver.tar.xz git git-$ver 1
    ./configure
    make all -j$cpu_num NO_RUST=1
    create_app git $prefix$ver
#  fixme:make install
    mkdir $output/app/git/$prefix$ver/bin
    cp git $output/app/git/$prefix$ver/bin
    set_current_app_clean_strip_cd git $prefix$ver 1
  fi
fi
# PGP
if [ "$package" == "libgpg-error" ]; then
  ver="1.61";
  if should_make libgpg-error $ver; then
    download_unpack_source https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-${ver}.tar.bz2 libgpg-error libgpg-error-$ver 1
    ./configure --prefix=$output/app/libgpg-error/$prefix$ver --enable-install-gpg-error-config
    make all -j$cpu_num
    create_app libgpg-error $prefix$ver
    make install
    set_current_app_clean_strip_cd libgpg-error $prefix$ver 1
  fi
fi
# PGP
if [ "$package" == "libgcrypt" ]; then
  ver="1.12.2";
  if should_make libgcrypt $ver; then
    download_unpack_source https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-${ver}.tar.bz2 libgcrypt libgcrypt-$ver 1
    ./configure --prefix=$output/app/libgcrypt/$prefix$ver --with-libgpg-error-prefix=$output/app/libgpg-error/current
    make all -j$cpu_num
    create_app libgcrypt $prefix$ver
    make install
    set_current_app_clean_strip_cd libgcrypt $prefix$ver 1
  fi
fi
# PGP
if [ "$package" == "libassuan" ]; then
  ver="3.0.2";
  if should_make libassuan $ver; then
    download_unpack_source https://gnupg.org/ftp/gcrypt/libassuan/libassuan-${ver}.tar.bz2 libassuan libassuan-$ver 1
    ./configure --prefix=$output/app/libassuan/$prefix$ver --with-libgpg-error-prefix=$output/app/libgpg-error/current
    make all -j$cpu_num
    create_app libassuan $prefix$ver
    make install
    set_current_app_clean_strip_cd libassuan $prefix$ver 1
  fi
fi
# PGP
if [ "$package" == "libksba" ]; then
  ver="1.8.0";
  if should_make libksba $ver; then
    download_unpack_source https://gnupg.org/ftp/gcrypt/libksba/libksba-${ver}.tar.bz2 libksba libksba-$ver 1
    ./configure --prefix=$output/app/libksba/$prefix$ver --with-libgpg-error-prefix=$output/app/libgpg-error/current
    make all -j$cpu_num
    create_app libksba $prefix$ver
    make install
    set_current_app_clean_strip_cd libksba $prefix$ver 1
  fi
fi
# PGP
if [ "$package" == "npth" ]; then
  ver="1.8";
  if should_make npth $ver; then
    download_unpack_source https://gnupg.org/ftp/gcrypt/npth/npth-${ver}.tar.bz2 npth npth-$ver 1
    ./configure --prefix=$output/app/npth/$prefix$ver --enable-install-npth-config
    make all -j$cpu_num
    create_app npth $prefix$ver
    make install
    set_current_app_clean_strip_cd npth $prefix$ver 1
  fi
fi
# PGP
if [ "$package" == "gnupg" ]; then
  ver="2.5.21";
  if should_make gnupg $ver; then
    download_unpack_source https://gnupg.org/ftp/gcrypt/gnupg/gnupg-${ver}.tar.bz2 gnupg gnupg-$ver 1
    ./configure --with-libgpg-error-prefix=$output/app/libgpg-error/current \
      --with-libgcrypt-prefix=$output/app/libgcrypt/current \
      --with-libassuan-prefix=$output/app/libassuan/current \
      --with-ksba-prefix=$output/app/libksba/current \
      --with-npth-prefix=$output/app/npth/current \
      --prefix=$output/app/gnupg/$prefix$ver
    make all -j$cpu_num
    create_app gnupg $prefix$ver
    make install
    #fixme: some errors
    set_current_app_clean_strip_cd gnupg $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "openssl" ]; then
  for ver in 3.6.3 4.0.1; do 
    if should_make openssl $ver; then
      download_unpack_source https://github.com/openssl/openssl/releases/download/openssl-$ver/openssl-$ver.tar.gz openssl openssl-$ver 1
      ./Configure
      make all -j$cpu_num
      create_app openssl $prefix$ver
      mkdir $output/app/openssl/$prefix$ver/bin
      cp apps/openssl $output/app/openssl/$prefix$ver/bin
      mkdir $output/app/openssl/$prefix$ver/lib
      rsync -a *.so* $output/app/openssl/$prefix$ver/lib
      rsync -a $curdir/in/openssl/ $output/app/openssl/$prefix$ver
      set_current_app_clean_strip_cd openssl $prefix$ver 1
    fi
  done
fi
if [ "$package" == "fs" ] || [ "$package" == "wget2" ]; then
  ver="2.2.1";
  if should_make wget2 $ver; then
    install_host_deps "lzip"
    download_unpack_source https://ftp.gnu.org/gnu/wget/wget2-$ver.tar.lz wget2 wget2-$ver 1
    ./configure
    make all -j$cpu_num
    create_app wget2 $prefix$ver
    mkdir $output/app/wget2/$prefix$ver/bin
    mkdir $output/app/wget2/$prefix$ver/lib
    mkdir $output/app/wget2/$prefix$ver/ssl
    cp src/wget2_noinstall $output/app/wget2/$prefix$ver/bin/wget
    rsync -a libwget/.libs/*.so* $output/app/wget2/$prefix$ver/lib
    rsync -a $curdir/in/wget2/ $output/app/wget2/$prefix$ver

    #fixme
    cd /etc/ssl/certs
    rsync -a -L . $output/app/wget2/$prefix$ver/ssl

    set_current_app_clean_strip_cd wget2 $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "rsync" ]; then
  ver="3.4.4";
  if should_make rsync $ver; then
    download_unpack_source https://download.samba.org/pub/rsync/src/rsync-$ver.tar.gz rsync rsync-$ver 1
    ./configure --disable-xxhash --disable-lz4
    make all -j$cpu_num
    create_app rsync $prefix$ver
    mkdir $output/app/rsync/$prefix$ver/bin
    cp rsync $output/app/rsync/$prefix$ver/bin
    rsync -a $curdir/in/rsync/ $output/app/rsync/$prefix$ver
    set_current_app_clean_strip_cd rsync $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "zstd" ]; then
  ver="1.5.7";
  if should_make zstd $ver; then
    download_unpack_source https://github.com/facebook/zstd/releases/download/v$ver/zstd-$ver.tar.gz zstd zstd-$ver 1
    make all -j$cpu_num
    create_app zstd $prefix$ver
    cp LICENSE $output/app/zstd/$prefix$ver
    rsync -a $curdir/in/zstd/ $output/app/zstd/$prefix$ver
    mkdir $output/app/zstd/$prefix$ver/bin
    cp programs/zstd $output/app/zstd/$prefix$ver/bin
    cp programs/zstd-compress $output/app/zstd/$prefix$ver/bin
    cp programs/zstd-decompress $output/app/zstd/$prefix$ver/bin
    cp programs/zstd-small $output/app/zstd/$prefix$ver/bin
    cp programs/zstdgrep $output/app/zstd/$prefix$ver/bin
    cp programs/zstdsmall $output/app/zstd/$prefix$ver/bin
    mkdir $output/app/zstd/$prefix$ver/lib
    rsync -a lib/lib* $output/app/zstd/$prefix$ver/lib
    cd $output/app/zstd/$prefix$ver/lib
    rm libzstd.so
    ln -s libzstd.so.$ver libzstd.so
    rm libzstd.so.1
    ln -s libzstd.so.$ver libzstd.so.1
    set_current_app_clean_strip_cd zstd $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "zlib" ]; then
  ver="1.3.2";
  if should_make zlib $ver; then
    download_unpack_source https://zlib.net/zlib-$ver.tar.xz zlib zlib-$ver 1
    ./configure
    make all -j$cpu_num
    create_app zlib $prefix$ver
    cp LICENSE $output/app/zlib/$prefix$ver
    rsync -a $curdir/in/zlib/ $output/app/zlib/$prefix$ver
    mkdir $output/app/zlib/$prefix$ver/lib
    rsync -a libz* $output/app/zlib/$prefix$ver/lib
    set_current_app_clean_strip_cd zlib $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "pcre2" ]; then
  ver="10.47";
  if should_make pcre2 $ver; then
    download_unpack_source https://github.com/PCRE2Project/pcre2/releases/download/pcre2-$ver/pcre2-$ver.tar.gz pcre2 pcre2-$ver 1
    ./configure --prefix=$output/app/pcre2/$prefix$ver
    make all -j$cpu_num
    create_app pcre2 $prefix$ver
    make install
    cp $out/pcre2/pcre2-$ver/LICENCE.md $output/app/pcre2/$prefix$ver
    rsync -a $curdir/in/pcre2/ $output/app/pcre2/$prefix$ver
    set_current_app_clean_strip_cd pcre2 $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "ncurses" ]; then
  ver="6.6";
  if should_make ncurses $ver; then
    download_unpack_source https://invisible-island.net/archives/ncurses/ncurses-$ver.tar.gz ncurses ncurses-$ver 1
    ./configure --prefix=$output/app/ncurses/$prefix$ver --with-shared  --with-termlib  --with-ticlib --disable-widec --with-develop --with-cxx-shared --with-trace --with-versioned-syms
    make all -j$cpu_num
    create_app ncurses $prefix$ver
    make install
    rsync -a $curdir/in/ncurses/ $output/app/ncurses/$prefix$ver
    cp $out/ncurses/ncurses-$ver/COPYING $output/app/ncurses/$prefix$ver
    set_current_app_clean_strip_cd ncurses $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "gcc" ]; then
#  ver="16.1.0";
  ver="14.4.0";
  if should_make gcc $ver; then
    # we unpack and download prerequisities to the normal disk (to allow compilation offline)
    # compilation can be done in tmpfs (ca. 4,3 GB)
    download_unpack_source https://ftp.gnu.org/gnu/gcc/gcc-$ver/gcc-$ver.tar.xz gcc gcc-$ver 0
    contrib/download_prerequisites
    cd $out
    mkdir gcc-$ver-build
    cd gcc-$ver-build
    $curdir/out/gcc/gcc-$ver/configure --enable-shared --disable-multilib --prefix= --disable-bootstrap --enable-languages=c,c++
    make all -j$cpu_num
    create_app gcc $prefix$ver
    make DESTDIR=$output/app/gcc/$prefix$ver install-strip
    rsync -a $output/app/gcc/$prefix$ver/lib64/* $output/app/gcc/$prefix$ver/lib
    rm -r $output/app/gcc/$prefix$ver/lib64
    rsync -a $curdir/in/gcc/ $output/app/gcc/$prefix$ver
    remove_duplicates_cd $output/app/gcc/$prefix$ver/bin
    set_current_app_clean_strip_cd gcc $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "slang" ]; then
  ver="2.3.3";
  if should_make slang $ver; then
    download_unpack_source https://www.jedsoft.org/releases/slang/slang-$ver.tar.bz2 slang slang-$ver 1
    ./configure --prefix=$output/app/slang/$prefix$ver
    make all -j$cpu_num
    create_app slang $prefix$ver
    make install
    chmod a-x $output/app/slang/$prefix$ver/lib/slang/v2/modules/*.so
    set_current_app_clean_strip_cd slang $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "glib" ]; then
  #glib (GTK, gnome), not GNU C library
  ver="2.89.1";
  if should_make glib $ver; then
    #downloading to disk because of dependencies
    download_unpack_source https://github.com/GNOME/glib/archive/refs/tags/$ver.tar.gz glib glib-$ver 0
    if [ -d "subprojects/packagefiles" ]; then
      cd subprojects
      meson subprojects download --sourcedir ..
      rm -r gvdb
      rm -r packagecache
      rm -r packagefiles
      cd ..
    fi
    mkdir $out/glib/$prefix$ver-compile
    ln -s $out/glib/$prefix$ver-compile _build
    meson setup -Dprefix=$output/app/glib/$prefix$ver --buildtype minsize _build
    meson compile -C _build
    create_app glib $prefix$ver
    meson install -C _build
    chmod a+x $output/app/glib/$prefix$ver/lib/x86_64-linux-gnu/
    chmod a-x $output/app/glib/$prefix$ver/lib/x86_64-linux-gnu/*so*
    rsync -a $output/app/glib/$prefix$ver/lib/x86_64-linux-gnu/* $output/app/glib/$prefix$ver/lib
    rm -r $output/app/glib/$prefix$ver/lib/x86_64-linux-gnu/
    rsync -a $curdir/in/glib/ $output/app/glib/$prefix$ver
    set_current_app_clean_strip_cd glib $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "autoconf" ]; then
  ver="2.73";
  if should_make autoconf $ver; then
    download_unpack_source https://ftp.gnu.org/gnu/autoconf/autoconf-2.73.tar.xz autoconf autoconf-$ver 1
    mkdir $out/autoconf/autoconf-$ver-build
    cd $out/autoconf/autoconf-$ver-build
    ../autoconf-$ver/configure --prefix=$output/app/autoconf/$prefix$ver
    make all -j$cpu_num
    create_app autoconf $prefix$ver
    make install
    set_current_app_clean_strip_cd autoconf $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "automake" ]; then
  ver="1.18";
  if should_make automake $ver; then
    download_unpack_source https://ftp.gnu.org/gnu/automake/automake-$ver.tar.xz automake automake-$ver 1
    mkdir $out/automake/automake-$ver-build
    cd $out/automake/automake-$ver-build
    ../automake-$ver/configure --prefix=$output/app/automake/$prefix$ver
    make all -j$cpu_num
    create_app automake $prefix$ver
    make install
    remove_duplicates_cd $output/app/automake/$prefix$ver/bin
    set_current_app_clean_strip_cd automake $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "xorriso" ]; then
  ver="1.5.8";
  if should_make xorriso $ver; then
    download_unpack_source https://www.gnu.org/software/xorriso/xorriso-$ver.pl02.tar.gz xorriso xorriso-$ver 1
    mkdir $out/xorriso/xorriso-$ver-build
    cd $out/xorriso/xorisso-$ver-build
    ../xorriso-$ver/configure --prefix=$output/app/xorriso/$prefix$ver
    make -j$cpu_num
    create_app xorriso $prefix$ver
    make install
    set_current_app_clean_strip_cd xorriso $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "tzdb" ]; then
  ver="2026c";
  if should_make tzdata $ver; then
    download_unpack_source https://data.iana.org/time-zones/releases/tzdb-$ver.tar.lz tzdb tzdb-$ver 1
    create_app tzdb $prefix$ver
    make TOPDIR="$output/app/tzdb/$prefix$ver" install
    set_current_app_clean_strip_cd tzdb $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "jdk" ]; then
  # >1GB during installation
  ver="25-ga";
  rel="25-ga";
  if should_make jdk $ver; then
    install_host_deps "autopoint openjdk-25-jdk libasound2-dev libcups2-dev libfontconfig1-dev libx11-dev libxext-dev libxrender-dev libxrandr-dev libxtst-dev libxt-dev"
    download_unpack_source https://github.com/openjdk/jdk/archive/refs/tags/jdk-$rel.tar.gz jdk jdk-jdk-$ver 1
    chmod a+x configure
    ./configure
    make clean
    make JOBS=$cpu_num images
    create_app jdk $prefix$ver
    rsync -a build/linux-x86_64-server-release/images/jdk/* $output/app/jdk/$prefix$ver
    set_current_app_clean_strip_cd jdk $prefix$ver 0
  fi
fi
if [ "$package" == "iso" ]; then
  mkdir $output/boot
  mkdir $output/boot/grub
  cp $curdir/in/boot/* $output/boot/grub
  sudo grub-mkrescue -o $isofile $output/ --disable-shim-lock
fi
#if [ "$package" == "gpm" ]; then
#  code seems to be obsolete
#  ver="1.20.7";
#  if should_make gpm $ver; then
#    install_host_deps "libtool"
#    download_unpack_source https://github.com/telmich/gpm/archive/refs/tags/$ver.tar.gz gpm gpm-$ver 0
#    create_app gpm $prefix$ver
#    cd out/gpm/gpm-$ver
#    ./autogen.sh
#    autoupdate
#    ./autogen.sh
#    ./configure --prefix=$output/app/gpm/$prefix$ver
#    make all -j$cpu_num
#    make install
#    chmod a-x $output/app/slang/$prefix$ver/lib/*
#    cd ../../..
#    set_current_app_clean_strip_cd slang $prefix$ver
#  fi
#fi
#if [ "$package" == "groff" ]; then
  # work in progress
  # for displaying man pages
#  ver="1.24.1";
#  if should_make groff $ver; then
#    download_unpack_source https://ftp.gnu.org/gnu/groff/groff-$ver.tar.gz groff groff-$ver 0
#    create_app groff $prefix$ver
#    cd out/groff/groff-$ver
#    ./configure --prefix=$output/app/groff/$prefix$ver
#    make all -j$cpu_num
#    make install
#  fi
#fi
if [ "$package" == "fs" ] || [ "$package" == "man-db" ]; then
  #work in progress
  ver="2.13.1";
  if should_make man-db $ver; then
    install_host_deps "autopoint libpipeline-dev"
    download_unpack_source https://gitlab.com/man-db/man-db/-/archive/$ver/man-db-$ver.tar.bz2 man-db man-db-$ver 1
    ./bootstrap
    ./configure --prefix=$output/app/man-db/$prefix$ver
    make -j$cpu_num
    create_app man-db $prefix$ver
    make install
    set_current_app_clean_strip_cd man-db $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "smartmontools" ]; then
  #work in progress
  rel="7_5";
  ver="7.5";
  if should_make smartmontools $ver; then
    download_unpack_source https://github.com/smartmontools/smartmontools/releases/download/RELEASE_$rel/smartmontools-$ver.tar.gz smartmontools smartmontools-$ver 1
    ./configure --prefix=$output/app/smartmontools/$prefix$ver
    make -j$cpu_num
    create_app smartmontools $prefix$ver
    make install
    set_current_app_clean_strip_cd smartmontools $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "grub" ]; then
  #work in progress
  ver="2.14";
  if should_make grub $ver; then
    install_host_deps "autoconf-archive"
    download_unpack_source https://gitlab.freedesktop.org/gnu-grub/grub/-/archive/grub-$ver/grub-grub-$ver.tar.gz?ref_type=tags grub grub-gub-$ver 0
    create_app grub $prefix$ver
    cd out/grub
    mkdir grub-grub-$ver-build
    cd grub-grub-$ver
    autoconf
    cd grub-grub-$ver-build
    ../grub-grub-$ver/configure --prefix=$output/app/grub/$prefix$ver
    make all -j$cpu_num
    make install
    cd ../../..
    set_current_app_clean_strip_cd grub $prefix$ver
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "perl" ]; then
  # work in progress
  ver="5.42.2";
  if should_make perl $ver; then
    download_unpack_source https://www.cpan.org/src/5.0/perl-$ver.tar.gz perl perl-$ver 1
    ./Configure -d
    make -j$cpu_num
    create_app perl $prefix$ver
    make install
    set_current_app_clean_strip_cd perl $prefix$ver 1
  fi
fi
