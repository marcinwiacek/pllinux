# Part of PLLINUX. Version from 26 Oct 2026. Creating binaries (from the source) and installing them in the PLLINUX partition. Tested on Debian "Trixie".

output="/mnt/x";  # directory with EXT4 partition, which will be / for new system. In other scripts equal to DIR variable
package="libidn2"; # "fs" to build all, "fsmin" to build minimalistic working system, "iso" to build iso file or concrete name for package (busybox, nftables, etc.)
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

IFSORIG=$IFS

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

  case $localfile in
    *$packagename* ) ;;
    * ) localfile=${packagename}-${localfile}
  esac

  if [ ! -f "download/$localfile" ]; then
    echo $url
    wget -O /tmp/$localfile.tmp $url;
    if [ $? -eq 0 ]; then
      mv /tmp/$localfile.tmp download/$localfile
    else
      exit 1
    fi
  fi

echo directory1 is $(pwd)
  if [ "$canbetmp" = "1" ]; then
    if [ ! -d "$out/$packagename/$unpackeddir" ]; then
      mkdir $out/$packagename || true
      cd $out/$packagename
      case $localfile in
        ccadb* ) cp $curdir/download/$localfile $out/$packagename/ccadb ;;
        *.rpm* ) install_host_deps "rpm"
                 rpm2cpio $curdir/download/$localfile | cpio -idmv ;;
        *.zip* ) unzip $curdir/download/$localfile -d .
                 cd $unpackeddir ;;
        * )      tar -xvf $curdir/download/$localfile
                 cd $unpackeddir
      esac
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
echo directory2 is $(pwd)
  TODAY_DATE="$(date +%Y%m%d)"
  IFS=" "
  while read -r LATEST_FILE; do
    if [ -f "$LATEST_FILE" ]; then
      LATEST_FILE_UPDATE="$(date -r $LATEST_FILE +%Y%m%d)"
      if [ "$LATEST_FILE_UPDATE" != "$TODAY_DATE" ]; then
        break
      fi
    fi
  done <<< "$(ls -t)"
  IFS=$IFSORIG
}

#obsolete
#creating directory with the app
create_app() {
  packagename=$1
  version=$2

  [ -d $output/app/$packagename ] || mkdir $output/app/$packagename
  [ -d $output/app/$packagename/$version ] || mkdir $output/app/$packagename/$version
  if [ -f "$curdir/in/$packagename/readme.md" ]; then 
    cp $curdir/in/$packagename/readme.md $output/app/$packagename/$version;
    echo "" >> $output/app/$packagename/$version/readme.md
  else
    if [ -f $output/app/$packagename/$version/readme.md ]; then
      rm $output/app/$packagename/$version/readme.md
    fi
  fi
  echo "**Last**" >> $output/app/$packagename/$version/readme.md
  echo "$LATEST_FILE_UPDATE" >> $output/app/$packagename/$version/readme.md
}

#obsolete
set_current_app() {
  packagename=$1
  version=$2
  stripapp=$3

  curdir2=$(pwd)

  #set "current" directory to the new installed app
  cd $output/app/$1
  if [ -d "current" ]; then rm -r current; fi
  ln -s $version current

  cd $curdir2
}

#creating directory with the app in /tmp and link to /app/(package)/current
create_app_in_tmp_and_link_it() {
  packagename=$1
  version=$2

  rm -r -f /tmp/installit 2> /dev/null
  mkdir /tmp/installit
  rm $output/app/$packagename/current 2> /dev/null
  [ -d $output/app/$packagename ] || mkdir $output/app/$packagename
  ln -s /tmp/installit $output/app/$packagename/current
}

set_current_app_clean_strip_cd() {
  packagename=$1
  version=$2
  stripapp=$3

  if [ -d "/tmp/installit" ]; then
    pathtoapp="/tmp/installit"
  else
    pathtoapp="$output/app/$packagename/$version"
  fi

  if [ -d "$pathtoapp/lib" ]; then
    chmod a-x $pathtoapp/lib/*.so* 2> /dev/null
    chmod a-x $pathtoapp/lib/*.la* 2> /dev/null
    chmod a-x $pathtoapp/lib/*.a 2> /dev/null
  fi

  if [ "$stripapp" = "1" ]; then
    #strip binaries and libraries (remove debug symbols). Exclude *.o, *.a or (for Grub) lib directory
    case $packagename in
    *grub*) find $pathtoapp* \
        -not -name 'lib' \
        -type d -exec bash -c 'cd "{}" && strip * 2> /dev/null ' \; ;;
    *) find $pathtoapp* \
        -not -name '*.o' \
        -not -name '*.a' \
        -type f -exec bash -c 'strip "{}" 2> /dev/null ' \; 
    esac
  fi

  if [ -f "$curdir/in/$packagename/readme.md" ]; then 
    cp $curdir/in/$packagename/readme.md $pathtoapp
    echo "" >> $pathtoapp/readme.md
  else
    rm $pathtoapp/readme.md 2> /dev/null
  fi
  echo "**Last**" >> $pathtoapp/readme.md
  echo "$LATEST_FILE_UPDATE" >> $pathtoapp/readme.md

  if [ -d "/tmp/installit" ]; then
    [ -d $output/app/$packagename ] || mkdir $output/app/$packagename
    if [ -d $output/app/$packagename/$version ]; then rm -r -f $output/app/$packagename/$version 2> /dev/null; fi
    mkdir $output/app/$packagename/$version || true
  fi

  #set "current" directory to the new installed app
  cd $output/app/$packagename
  if [ -d "current" ]; then rm -r current; fi
  ln -s $version current

  if [ -d "/tmp/installit" ]; then
    rsync -a /tmp/installit/ $output/app/$packagename/$version
    rm -r -f /tmp/installit
  fi

  if [ "$use_tmpfs" = "1" ]; then
    rm -r -f $out
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
#find_binary_lib() {
#  appdir=$1
#  binary=$2
#  mkdir -p $appdir/lib
#  list="$(ldd $appdir/$binary | egrep -o '/lib.*\.[0-9]')"
#  for lib in $list; do 
#    rsync -a ${lib%.so*}.so* "$appdir/lib";
#  done
#  rm -r $appdir/lib/ld-linux-x86-64.so.2 || true
#  rm -r $appdir/lib64 || true
#  rm -r $appdir/lib/libc.so* || true
#}

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
            chmod a+w $fname2
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

# function copied "as is" from app.sh script
# getting app dependencies from app readme.md
find_app_deps() {
  local DIR=$1
  local SECTION=$2
  local GET_CURRENT=$3
  if [ -e "$DIR/readme.md" ]; then
     sectionDeps=0
     while read -r line; do
       if [ "$line" = "**$SECTION**" ]; then
         sectionDeps=1
       elif [ "$line" = "" ]; then
         sectionDeps=0;
       elif [ "$sectionDeps" = 1 ]; then
         case $DEPS in
           *$line* )
              ;;
           * )
              SAVE=1
              case $line in
                *current* )
                    SAVE=$GET_CURRENT
                    ;;
              esac
              if [ "$SAVE" == "1" ]; then
                complete=0
                if [ "$DEPS" != "" ]; then
                  DEPS="$DEPS:"
                fi
                DEPS="$DEPS$line"
              fi
              ;;
         esac
       fi
     done < $DIR/readme.md
  fi
}

if [ ! -d "$output" ]; then
  echo "output folder $output does not exist."
  exit
fi

    if [ ! -d "/app" ]; then
      echo "You need link from /app to the PLLINUX /app"
      cd /
      sudo ln -s $output/app app
      cd $curdir
    fi

install_host_deps "rsync"
#install_host_deps "mc retext git gitk gedit"
#[ -d out ] || mkdir out
[ -d download ] || mkdir download
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ]; then

  #don't forget about sync with pllinux and initramfs

  for folderentry in app bin dev etc home mnt proc run sys tmp lib64 log log/tmp usr usr/share usr/bin; do mkdir $output/$folderentry; done

  rsync -a in/pllinux.etc/ $output/etc

  for userentry in root user user2; do 
    case $userentry in
      root) GRP=root ;;
      user) GRP=1000 ;;
      user2) GRP=1001 ;;
    esac

    for direntry in $output/home/$userentry $output/home/$userentry/app $output/home/$userentry/files; do
      sudo mkdir $direntry
      sudo chown $GRP $direntry
      sudo chgrp $GRP $direntry
    done

    sudo chmod u+rwx $output/home/$userentry
    sudo chmod g-rwx $output/home/$userentry
    sudo chmod o-rwx $output/home/$userentry
  done

  cd $output
  if [ ! -d "etc." ]; then ln -s etc etc.; fi
  if [ ! -d "other" ]; then ln -s home/root other; fi
#  cd bin
#  ln -s /app/busybox/current/bin/sh sh
#  ln -s /app/bash/current/bin/bash bash
#  cd ..
  cd lib64
  ln -s /app/glibc/current/lib/ld-linux-x86-64.so.2 ld-linux-x86-64.so.2
  chmod a+x ld-linux-x86-64.so.2
  cd ..
  cd usr/share
  ln -s /app/tzdb/current/usr/share/zoneinfo zoneinfo
  cd ..
  cd ..
  cd etc
  cd vulkan
  ln -s /app/mesa/current/share/vulkan/icd.d implicit_layer.d
  cd ..
  cd ..
  cd usr
  cd bin
  ln -s /app/xkbcomp/current/bin/xkbcomp xkbcomp

  #don't forget about sync with pllinux and initramfs

  cd $curdir
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "kernel" ]; then
  ver="6.18.57";
#  ver="7.2.11";
#  ver="7.2.6";
  if should_make kernel $ver; then
    install_host_deps "build-essential libncurses-dev bc libelf-dev bison flex libdwarf-dev libelf-dev libdw-dev libssl-dev gawk"
    download_unpack_source https://cdn.kernel.org/pub/linux/kernel/v${ver:0:1}.x/linux-$ver.tar.xz kernel linux-$ver 1
    cp $curdir/in/kernel/.config_$ver ./.config
    make -j$cpu_num
    cp .config $curdir/in/kernel/.config_$ver # .config will be updated with new header and maybe options
    create_app kernel $prefix$ver
    for fileentry in .config arch/x86/boot/bzImage; do
      cp $fileentry $output/app/kernel/$prefix$ver
    done
#    make modules -j$cpu_num
#    make headers_install INSTALL_HDR_PATH=$output/app/kernel/$prefix$ver -j$cpu_num
#    make vdso_install INSTALL_MOD_PATH=/tmp/x -j$cpu_num
    make modules_install INSTALL_MOD_PATH=/tmp/x -j$cpu_num
    cd /tmp/x/lib/modules
    cd $(ls)
    rm build
    rsync -a . $output/app/kernel/$prefix$ver/modules
    cd /tmp
    rm -r /tmp/x
    set_current_app_clean_strip_cd kernel $prefix$ver 0 # not stripping of kernel modules!
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "busybox" ]; then
  ver="1.38.0";
  if should_make busybox $ver; then
    download_unpack_source https://busybox.net/downloads/busybox-$ver.tar.bz2 busybox busybox-$ver 1
    cp $curdir/in/busybox/.config .
    make -j$cpu_num
    create_app_in_tmp_and_link_it busybox $prefix$ver
    cp .config $curdir/in/busybox # .config will be updated with new header and maybe options
    make CONFIG_PREFIX=/app/busybox/current install
    cp $curdir/in/busybox/* /tmp/installit
    rm /tmp/installit/linuxrc
    set_current_app_clean_strip_cd busybox $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libmnl" ]; then
  ver="1.0.5";
  if should_make libmnl $ver; then
    download_unpack_source https://netfilter.org/projects/libmnl/files/libmnl-$ver.tar.bz2 libmnl libmnl-$ver 1
    ./configure --prefix=/app/libmnl/current
    make -j$cpu_num
    create_app_in_tmp_and_link_it libmnl $prefix$ver
    make install
    set_current_app_clean_strip_cd libmnl $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libnftnl" ]; then
  ver="1.3.2";
  if should_make libnftnl $ver; then
    download_unpack_source https://netfilter.org/projects/libnftnl/files/libnftnl-1.3.2.tar.xz libnftnl libnftnl-$ver 1
    ./configure --prefix=/app/libnftnl/current
    make -j$cpu_num
    create_app libnftnl $prefix$ver
    set_current_app libnftnl $prefix$ver 1
    make install
    set_current_app_clean_strip_cd libnftnl $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "nftables" ]; then
  ver="1.1.6";
  if should_make nftables $ver; then
    install_host_deps "libgmp3-dev libmnl-dev libedit-dev"
    #Trixy has got older version of libnftnl-dev
    if [ ! -f "download/libnftnl11_1.3.1-1_amd64.deb" ]; then
      wget -O download/libnftnl11_1.3.1-1_amd64.deb http://mirrors.kernel.org/ubuntu/pool/main/libn/libnftnl/libnftnl11_1.3.1-1_amd64.deb
      sudo apt-get install download/libnftnl11_1.3.1-1_amd64.deb
    fi
    download_unpack_source https://netfilter.org/projects/nftables/files/nftables-$ver.tar.xz nftables nftables-$ver 1
    ./configure --prefix=/app/nftables/current
    make -j$cpu_num
    create_app nftables $prefix$ver
    set_current_app nftables $prefix$ver 1
    make install
    set_current_app_clean_strip_cd nftables $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "bwrap" ]; then
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
    mkdir $output/app/bwrap/$prefix$ver/man
    cp _builddir/bwrap.1 $output/app/bwrap/$prefix$ver/man
    mkdir $output/app/bwrap/$prefix$ver/completion
    mkdir $output/app/bwrap/$prefix$ver/completion/bash
    cp completions/bash/bwrap $output/app/bwrap/$prefix$ver/completion/bash
    mkdir $output/app/bwrap/$prefix$ver/completion/zsh
    cp completions/zsh/_bwrap $output/app/bwrap/$prefix$ver/completion/zsh
    set_current_app_clean_strip_cd bwrap $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "dinit" ]; then
  ver="0.22.0";
  if should_make dinit $ver; then
    download_unpack_source https://github.com/davmac314/dinit/releases/download/v$ver/dinit-$ver.tar.xz dinit dinit-$ver 1
    ./configure --bindir=/app/dinit/current/bin --sbindir=/app/dinit/current/bin
    sed -i 's/LDFLAGS_LIBCAP=-L\/usr\/lib64 -lcap/LDFLAGS_LIBCAP=-static -L\/usr\/lib64 -lcap/g' mconfig
    sed -i 's/$(CXX) -o $(SHUTDOWN_PREFIX)shutdown shutdown.o $(ALL_LDFLAGS)/$(CXX) -static -o $(SHUTDOWN_PREFIX)shutdown shutdown.o $(ALL_LDFLAGS)/g' src/Makefile
    make all -j$cpu_num
    create_app dinit $prefix$ver
    mkdir $output/app/dinit/$prefix$ver/bin
    for binentry in dinit dinit-check dinit-monitor dinitctl shutdown; do
      cp src/$binentry $output/app/dinit/$prefix$ver/bin
    done
    for binentry in poweroff reboot; do
      cp $curdir/in/dinit/$binentry $output/app/dinit/$prefix$ver
    done
    mkdir $output/app/dinit/$prefix$ver/man
    for manentry in 5 8; do
      mkdir $output/app/dinit/$prefix$ver/man/man.$manentry
      cp doc/manpages/*.$manentry $output/app/dinit/$prefix$ver/man/man.$manentry
    done
    set_current_app_clean_strip_cd dinit $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "kbd" ]; then
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
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "glibc" ]; then
  # GNU C Library, not glib (gtk, gnome)
  ver="2.44";
  if should_make glibc $ver; then
    download_unpack_source https://ftp.gnu.org/gnu/glibc/glibc-$ver.tar.xz glibc glibc-$ver 1
    mkdir $out/glibc/glibc-$ver-build
    cd $out/glibc/glibc-$ver-build
    ../glibc-$ver/configure --prefix=/app/glibc/current
    cp $curdir/in/glibc/2_44_rtld.c ../glibc-$ver/elf/rtld.c
    make all -j$cpu_num
    create_app_in_tmp_and_link_it glibc $prefix$ver
    make install
    chmod a-x /app/glibc/current/lib/audit/*so*
    chmod a-x /app/glibc/current/lib/gconv/*so*
    cd /app/glibc/current/share
    ln -s /app/tzdb/current/usr/share/zoneinfo zoneinfo
    cd /app/glibc # to silence some error in set_current_app...
    cp $curdir/in/glibc/2_43_patch_ver6.txt /app/glibc/current
    set_current_app_clean_strip_cd glibc $prefix$ver 1
    chmod a+x $output/app/glibc/$prefix$ver/lib/ld-linux-x86-64.so.2
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "util-linux" ]; then
  ver1="2.42";
  ver="2.42.4";
  if should_make util-linux $ver; then
    download_unpack_source https://www.kernel.org/pub/linux/utils/util-linux/v$ver1/util-linux-$ver.tar.xz util-linux util-linux-$ver 1
    #without --disable-makeinstall... tries to remove files from /usr/share... doesn't respect --prefix
    #without --disable-bash-compiletion similar story
    ./configure --prefix=/app/util-linux/current --without-systemd --disable-lsfd --disable-enosys \
        --disable-bash-completion --disable-makeinstall-chown  --disable-makeinstall-setuid  --disable-makeinstall-tty-setgid
    make all -j$cpu_num
    create_app util-linux $prefix$ver
    set_current_app util-linux $prefix$ver 1
    make install || true
    cp $curdir/in/util-linux/* $output/app/util-linux/$prefix$ver
    echo "" >> /app/util-linux/current/readme.md
    echo "**Last**" >> /app/util-linux/current/readme.md
    echo "$LATEST_FILE_UPDATE" >> /app/util-linux/current/readme.md
    set_current_app_clean_strip_cd util-linux $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "mc" ]; then
  ver="4.8.33";
  if should_make mc $ver; then
    install_host_deps "libglib2.0-dev libslang2-dev libgpm-dev"
    download_unpack_source https://ftp.osuosl.org/pub/midnightcommander/mc-$ver.tar.xz mc mc-$ver 1
    #--with-screen=ncurses  <- this seems to make MC hanging after pressing key
    ./configure --disable-vfs -without-gpm-mouse --prefix=/app/mc/current --exec-prefix=/app/mc/current
    make all -j$cpu_num
    create_app_in_tmp_and_link_it mc $prefix$ver
    make install
    cd /app/mc/current/bin
    ln -s /app/busybox/current/bin/sh sh
    cp $curdir/in/mc/mc /app/mc/current
    set_current_app_clean_strip_cd mc $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "bash" ]; then
  ver="5.3";
  if should_make bash $ver; then
    download_unpack_source https://ftp.gnu.org/gnu/bash/bash-$ver.tar.gz bash bash-$ver 1
    ./configure --prefix=/app/bash/current
    make all -j$cpu_num
    create_app bash $prefix$ver
    set_current_app bash $prefix$ver 1
    make install
    cp $curdir/in/bash/* $output/app/bash/$prefix$ver
    echo "" >> /app/bash/current/readme.md
    echo "**Last**" >> /app/bash/current/readme.md
    echo "$LATEST_FILE_UPDATE" >> /app/bash/current/readme.md
    set_current_app_clean_strip_cd bash $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "e2fsprogs" ]; then
  ver="1.47.4";
  if should_make bash $ver; then
    download_unpack_source https://git.kernel.org/pub/scm/fs/ext2/e2fsprogs.git/snapshot/e2fsprogs-$ver.tar.gz e2fsprogs e2fsprogs-$ver 1
    ./configure LDFLAGS=-static --enable-symlink-install  --enable-relative-symlinks --prefix=/app/e2fsprogs/current
    make all -j$cpu_num
    create_app e2fsprogs $prefix$ver
    set_current_app e2fsprogs $prefix$ver 1
    make install
    cp $curdir/in/e2fsprogs/* $output/app/e2fsprogs/$prefix$ver
    echo "" >> /app/e2fsprogs/current/readme.md
    echo "**Last**" >> /app/e2fsprogs/current/readme.md
    echo "$LATEST_FILE_UPDATE" >> /app/e2fsprogs/current/readme.md
    set_current_app_clean_strip_cd e2fsprogs $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "gnutls" ]; then
#libunistring-dev
  ver="3.7.11";
  if should_make gnutls $ver; then
    download_unpack_source https://www.gnupg.org/ftp/gcrypt/gnutls/v3.7/gnutls-3.7.11.tar.xz gnutls gnutls-$ver 1
    ./configure --prefix=/app/gnutls/current
    make all -j$cpu_num
    create_app_in_tmp_and_link_it gnutls $prefix$ver
    make install
    cp LICENSE /app/gnutls/current
    set_current_app_clean_strip_cd gnutls $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "curl" ]; then
  ver="8.23.0";
  ver2="8_23_0";
  if should_make curl $ver; then
    download_unpack_source https://github.com/curl/curl/archive/refs/tags/curl-8_23_0.tar.gz curl curl-curl-$ver2 1
#CURL_CA_PATH
    cmake -DCMAKE_BUILD_TYPE:STRING=Release  -B build \
      -D CMAKE_PREFIX_PATH="/app/gnutls/current" \
      -DCURL_USE_GNUTLS=on -DCURL_USE_OPENSSL=on -DCURL_LIBCURL_VERSIONED_SYMBOLS=on -DBUILD_SHARED_LIBS=on \
      -DCMAKE_INSTALL_PREFIX:PATH=/app/curl/current 
    cmake --build build  --config Release --target all -j$cpu_num
    create_app_in_tmp_and_link_it curl $prefix$ver
    cmake --install build
    cp COPYING /app/curl/current
    set_current_app_clean_strip_cd curl $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "kmod" ]; then
  ver="34";
  if should_make kmod $ver; then
    install_host_deps "scdoc"
    download_unpack_source https://github.com/kmod-project/kmod/archive/refs/tags/v$ver.tar.gz kmod kmod-$ver 1
    meson setup -Dprefix=/app/kmod/current --buildtype release _build
    meson compile -C _build
    create_app kmod $prefix$ver
    set_current_app kmod $prefix$ver 1
    meson install -C _build
    rsync -a $output/app/kmod/$prefix$ver/lib/x86_64-linux-gnu/* $output/app/kmod/$prefix$ver/lib
    rm -r $output/app/kmod/$prefix$ver/lib/x86_64-linux-gnu/
    set_current_app_clean_strip_cd kmod $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "initramfs" ]; then
  ver="0.1";
  if should_make initramfs $ver; then
    create_app initramfs $prefix$ver

    mkdir $out/initramfs
    cp $curdir/in/initramfs/init $out/initramfs

    for folderentry in app dev lib64 proc mnt run sys etc; do mkdir $out/initramfs/$folderentry; done

    for app in busybox; do mkdir $out/initramfs/app/$app; rsync -a $output/app/$app/ $out/initramfs/app/$app; done

    # we should have cryptsetup command compiled static with minimum size
    # instead of this we copy a lot of libraries and unnecessary dependencies
    # current solution is temporary, in the future:
    # 1. we need to decrease amount of copied elements OR
    # 2. compile cryptsetup static (this is much better)

#    ver2="2.8.8";
#    install_host_deps "asciidoctor libpopt-dev libjson-c-dev libssh-dev"
#    install_host_deps "make autoconf automake autopoint pkg-config libtool gettext libssl-dev libdevmapper-dev libpopt-dev uuid-dev libsepol-dev libjson-c-dev libssh-dev libblkid-dev tar asciidoctor"
#    download_unpack_source https://cdn.kernel.org/pub/linux/utils/cryptsetup/v2.8/cryptsetup-$ver2.tar.xz cryptsetup cryptsetup-$ver2 1
#    meson setup -Dprefix=$output/app/cryptsetup/$prefix$ver -Dstatic-cryptsetup=true -Dudev=false -Dveritysetup=false  _build
#    meson compile -C _build
#    create_app glib $prefix$ver
#    meson install -C _build
#    ./configure --prefix=$output/app/cryptsetup/$prefix$ver \
#--enable-static-cryptsetup --enable-static --disable-udev \
#LIBS="-L/app/lvm2/current/usr/lib "
#DEVMAPPER_CFLAGS="-I/app/lvm2/current/usr/include" \
#         LDFLAGS=-L/app/lvm2/current/usr/lib \
#      --disable-udev --disable-selinux --disable-veritysetup --disable-integritysetup
#    make -j$cpu_num

    mkdir $out/initramfs/app/cryptsetup
    mkdir $out/initramfs/app/cryptsetup/current
    mkdir $out/initramfs/app/cryptsetup/current/sbin
    cp $output/app/cryptsetup/current/sbin/cryptsetup $out/initramfs/app/cryptsetup/current/sbin
    cp $output/app/cryptsetup/current/readme.md $out/initramfs/app/cryptsetup/current

    DEPS="glibc current:cryptsetup current:openssl 260725_3.6.3"
    while true; do
      IFS=":"
      for DEP in $DEPS; do
        IFS=" " read -r APP_NAME APP_VER << EOF
$DEP
EOF
        find_app_deps $output/app/$APP_NAME/$APP_VER "Deps" 1
      done
      break
    done

    for DEP in $DEPS; do
      IFS=" " read -r APP_NAME3 APP_VER3 << EOF
$DEP
EOF
      mkdir $out/initramfs/app/$APP_NAME3
      mkdir $out/initramfs/app/$APP_NAME3/$APP_VER3
      rsync -a $output/app/$APP_NAME3/$APP_VER3/lib $out/initramfs/app/$APP_NAME3/$APP_VER3
      cp $output/app/$APP_NAME3/$APP_VER3/readme.md $out/initramfs/app/$APP_NAME3/$APP_VER3
    done

    cd $out/initramfs/lib64
    ln -s /app/glibc/current/lib/ld-linux-x86-64.so.2 ld-linux-x86-64.so.2
    chmod a+x ld-linux-x86-64.so.2

    cd $out/initramfs
    find . -print0 | cpio --null --create --verbose --format=newc | gzip --best > $output/app/initramfs/$prefix$ver/initramfs.gz

    set_current_app_clean_strip_cd initramfs $prefix$ver 0
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "pllinux" ]; then
  ver="0.1";
  create_app pllinux $prefix$ver
  mkdir $output/app/pllinux/$prefix$ver
  rsync -a $curdir/in/pllinux/ $output/app/pllinux/$prefix$ver
  set_current_app_clean_strip_cd pllinux $prefix$ver 0
fi
if [ "$package" == "fs" ] || [ "$package" == "git" ]; then
  ver="2.55.0";
  if should_make git $ver; then
    install_host_deps "gettext asciidoc docbook2x"
    download_unpack_source https://www.kernel.org/pub/software/scm/git/git-$ver.tar.xz git git-$ver 1
    ./configure
    make -j$cpu_num all doc info NO_RUST=1
    create_app git $prefix$ver
    set_current_app git $prefix$ver 1
    make prefix=/app/git/current install install-doc install-html install-info NO_RUST=1
    set_current_app_clean_strip_cd git $prefix$ver 1
    remove_duplicates_cd $output/app/git/$prefix$ver/bin
    remove_duplicates_cd $output/app/git/$prefix$ver/libexec/git-core
  fi
fi
# PGP
if [ "$package" == "fs" ] || [ "$package" == "libgpg-error" ]; then
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
if [ "$package" == "fs" ] || [ "$package" == "libgcrypt" ]; then
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
if [ "$package" == "fs" ] || [ "$package" == "libassuan" ]; then
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
if [ "$package" == "fs" ] || [ "$package" == "libksba" ]; then
  ver="1.8.0";
  if should_make libksba $ver; then
    download_unpack_source https://gnupg.org/ftp/gcrypt/libksba/libksba-${ver}.tar.bz2 libksba libksba-$ver 1
    ./configure --prefix=$output/app/libksba/$prefix$ver --with-libgpg-error-prefix=$output/app/libgpg-error/current
    make all -j$cpu_num
    create_app libksba $prefix$ver
    make install
    cp COPYING $output/app/libksba/$prefix$ver
    set_current_app_clean_strip_cd libksba $prefix$ver 1
  fi
fi
# PGP
if [ "$package" == "fs" ] || [ "$package" == "npth" ]; then
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
if [ "$package" == "fs" ] || [ "$package" == "gnupg" ]; then
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
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "openssl" ]; then
#3.5.9 LTS
  for ver in 3.5.9 4.1.0; do 
    if should_make openssl $ver; then
      download_unpack_source https://github.com/openssl/openssl/releases/download/openssl-$ver/openssl-$ver.tar.gz openssl openssl-$ver 1
      ./Configure --prefix=/app/openssl/$prefix$ver #--openssldir=/app/ccadb/current
      make all -j$cpu_num
      create_app openssl $prefix$ver
      make install
      mv /app/openssl/$prefix$ver/lib64 /app/openssl/$prefix$ver/lib
      set_current_app_clean_strip_cd openssl $prefix$ver 1
      mkdir "/tmp/doit"
    fi
  done
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "wget2" ]; then
  ver="2.2.1";
  if should_make wget2 $ver; then
    install_host_deps "lzip"
    download_unpack_source https://ftp.gnu.org/gnu/wget/wget2-$ver.tar.lz wget2 wget2-$ver 1
    ./configure --prefix=/app/wget2/current
    make all -j$cpu_num
    create_app_in_tmp_and_link_it wget2 $prefix$ver
    make install
    rm bin/wget2_noinstall
    cp $curdir/in/$package/wget /app/$packagename/current
    set_current_app_clean_strip_cd wget2 $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libidn2" ]; then
#gengetopt
#gtk-doc*
#  ver="2.3.8"; #compilation error?

  ver="2.3.7";
  if should_make libidn2 $ver; then
    download_unpack_source https://ftp.gnu.org/gnu/libidn/libidn2-$ver.tar.gz libidn2 libidn2-$ver 1
    ./configure --prefix=/app/libidn2/current
    make all -j$cpu_num
    create_app_in_tmp_and_link_it libidn2 $prefix$ver
    make install
    set_current_app_clean_strip_cd libidn2 $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "popt" ]; then
  ver="1.19";
  if should_make popt $ver; then
    download_unpack_source https://github.com/rpm-software-management/popt/archive/refs/tags/popt-$ver-release.tar.gz popt popt-popt-$ver-release 1
    ./autogen.sh
    ./configure --prefix=/app/popt/$prefix$ver
    make all -j$cpu_num
    create_app popt $prefix$ver
    make install
    set_current_app_clean_strip_cd popt $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libbsd" ]; then
  ver="0.12.2";
  if should_make libbsd $ver; then
    download_unpack_source https://libbsd.freedesktop.org/releases/libbsd-$ver.tar.xz libbsd libbsd-$ver 1
    install_host_deps "automake autogen libtool"
#    echo $ver > .dist-version
    ./autogen
    ./configure --prefix=/app/libbsd/$prefix$ver
    make all -j$cpu_num
    create_app libbsd $prefix$ver
    make install
    set_current_app_clean_strip_cd libbsd $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libedit" ]; then
  ver="20260512-3.1";
  if should_make libedit $ver; then
    download_unpack_source https://www.thrysoee.dk/editline/libedit-$ver.tar.gz libedit libedit-$ver 1
    ./configure --prefix=/app/libedit/$prefix$ver
    make all -j$cpu_num
    create_app libedit $prefix$ver
    make install
    cd /app/libedit/current/lib
    ln -s libedit.so libedit.so.2 # debian has other versioning than package?
    set_current_app_clean_strip_cd libedit $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "gmp" ]; then
  ver="6.3.0";
  if should_make gmp $ver; then
    download_unpack_source https://gmplib.org/download/gmp/gmp-6.3.0.tar.xz gmp gmp-$ver 1
    ./configure --prefix=/app/gmp/$prefix$ver
    make all -j$cpu_num
    create_app gmp $prefix$ver
    make install
    set_current_app_clean_strip_cd gmp $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libmd" ]; then
  ver="1.3.0";
  if should_make libmd $ver; then
    download_unpack_source https://libbsd.freedesktop.org/releases/libmd-$ver.tar.xz libmd libmd-$ver 1
#    install_host_deps "automake autogen libtool"
#    echo $ver > .dist-version
    ./autogen
    ./configure --prefix=/app/libmd/$prefix$ver
    make all -j$cpu_num
    create_app libmd $prefix$ver
    make install
    set_current_app_clean_strip_cd libmd $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "mtdev" ]; then
  ver="1.1.7";
  if should_make mtdev $ver; then
    download_unpack_source https://bitmath.org/code/mtdev/mtdev-$ver.tar.bz2 mtdev mtdev-$ver 1
    ./configure --prefix=/app/mtdev/current
    make all -j$cpu_num
    create_app_in_tmp_and_link_it mtdev $prefix$ver
    make install
    set_current_app_clean_strip_cd mtdev $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libevdev" ]; then
  ver="1.14.0";
  if should_make libevdev $ver; then
    download_unpack_source https://gitlab.freedesktop.org/libevdev/libevdev/-/archive/libevdev-1.14.0/libevdev-libevdev-1.14.0.tar.bz2?ref_type=tags libevdev libevdev-libevdev-$ver 1
    meson setup -Dprefix=/app/libevdev/current -Dlibdir=lib -Ddocumentation=disabled builddir
    ninja -C builddir
    create_app_in_tmp_and_link_it libevdev $prefix$ver
    ninja -C builddir install
    set_current_app_clean_strip_cd libevdev $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libwacom" ]; then
#python-pytest*
#python-libevdev*
#python3-pyudev
#pytest
#libevdev
  ver="2.20.0";
  if should_make libwacom $ver; then
    download_unpack_source https://github.com/linuxwacom/libwacom/archive/refs/tags/libwacom-$ver.tar.gz libwacom libwacom-libwacom-$ver 1
    meson setup -Dprefix=/app/libwacom/current -Dlibdir=lib builddir
    ninja -C builddir
    create_app_in_tmp_and_link_it libwacom $prefix$ver
    ninja -C builddir install
    set_current_app_clean_strip_cd libwacom $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libgudev" ]; then
  ver="238";
  if should_make libgudev $ver; then
    download_unpack_source https://github.com/GNOME/libgudev/archive/refs/tags/238.tar.gz libgudev libgudev-$ver 1
    meson setup -Dprefix=/app/libgudev/current -Dlibdir=lib builddir
    ninja -C builddir
    create_app_in_tmp_and_link_it libgudev $prefix$ver
    ninja -C builddir install
    set_current_app_clean_strip_cd libgudev $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libliftoff" ]; then
  ver="0.5.0";
  if should_make libliftoff $ver; then
    download_unpack_source https://gitlab.freedesktop.org/emersion/libliftoff/-/releases/v0.5.0/downloads/libliftoff-0.5.0.tar.gz libliftoff libliftoff-$ver 1
    meson setup -Dprefix=/app/libliftoff/current -Dlibdir=lib builddir
    ninja -C builddir
    create_app_in_tmp_and_link_it libliftoff $prefix$ver
    ninja -C builddir install
    set_current_app_clean_strip_cd libliftoff $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "wlroots" ]; then
  if should_make wlroots $ver; then

#        --force-fallback-for=wayland-server \
#       --force-fallback-for=wayland-protocols \
#    PKG_CONFIG_PATH=/app/libdrm/current/lib/pkgconfig:/app/libxkbcommon/current/lib/pkgconfig:/app/pixman/current/lib/pkgconfig \
  ver="0.20.2";
#  ver="0.19.3";
    download_unpack_source https://gitlab.freedesktop.org/wlroots/wlroots/-/releases/$ver/downloads/wlroots-$ver.tar.gz wlroots wlroots-$ver 1
    PKG_CONFIG_PATH=/app/wayland/current/lib/pkgconfig:/app/libdrm/current/lib/pkgconfig:/app/libxkbcommon/current/lib/pkgconfig:/app/pixman/current/lib/pkgconfig \
        meson setup -Dprefix=/app/wlroots/current --buildtype release  \
       --force-fallback-for=wayland-protocols \
-Dxwayland=disabled -Dbackends=drm,libinput \
        --wrap-mode=default \
       -Dlibdir=lib build
    ninja -C build
    create_app_in_tmp_and_link_it wlroots $prefix$ver
    ninja -C build install
    set_current_app_clean_strip_cd wlroots $prefix$ver 1
#  ver="0.18.2";
#    download_unpack_source https://gitlab.freedesktop.org/wlroots/wlroots/-/releases/$ver/downloads/wlroots-$ver.tar.gz wlroots wlroots-$ver 1
#    PKG_CONFIG_PATH=/app/libdrm/current/lib/pkgconfig:/app/libxkbcommon/current/lib/pkgconfig:/app/pixman/current/lib/pkgconfig \
#        meson setup -Dprefix=/app/wlroots/current --buildtype release  \
#        --wrap-mode=default \
#       -Dlibdir=lib build
#    ninja -C build
#    create_app_in_tmp_and_link_it wlroots $prefix$ver
#    ninja -C build install
#    set_current_app_clean_strip_cd wlroots $prefix$ver 1
  fi
fi
#wayland
if [ "$package" == "fs" ] || [ "$package" == "woodland" ]; then
#libstb-dev
#libwlroots-0.18-dev
  ver="2.1.1";
  if should_make woodland $ver; then
    download_unpack_source https://github.com/DiogenesN/woodland/archive/refs/tags/v2.1.1.tar.gz woodland woodland-$ver 1
    chmod +x ./configure
    PREFIX=/app/woodland/current ./configure
    make -j$cpu_num
    create_app_in_tmp_and_link_it woodland $prefix$ver
    make install PREFIX=/app/woodland/current
    set_current_app_clean_strip_cd woodland $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "labwc" ]; then
  ver="0.20.2";
  if should_make labwc $ver; then
    download_unpack_source https://github.com/labwc/labwc/archive/refs/tags/0.20.2.tar.gz labwc labwc-$ver 1
    PKG_CONFIG_PATH=/app/pixman/current/lib/pkgconfig \
        meson setup -Dprefix=/app/labwc/current --buildtype release \
            -Dlibdir=lib build
    ninja -C build
    create_app_in_tmp_and_link_it labwc $prefix$ver
    ninja -C build install
    set_current_app_clean_strip_cd labwc $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "wayfire" ]; then
#libglm-dev
#libyyjson-dev
#doctest
  ver="0.11.0";
  if should_make wayfire $ver; then
    download_unpack_source https://github.com/WayfireWM/wayfire/archive/refs/tags/v0.11.0.tar.gz wayfire wayfire-$ver 1
    cd subprojects
    for DIRNAME in wf-config wf-json wf-touch wf-utils wlroots wlroots-vkfx; do
        if [ ! -f "$DIRNAME/meson.build" ]; then      rm -r $DIRNAME; fi
    done
    git clone https://github.com/WayfireWM/wf-config.git
    git clone https://github.com/WayfireWM/wf-json.git
    git clone https://github.com/WayfireWM/wf-touch.git
    git clone https://github.com/WayfireWM/wf-utils.git
#    git clone https://gitlab.freedesktop.org/wlroots/wlroots.git
#    git clone https://gitlab.freedesktop.org/ammen99/wlroots
    cd ..
    PKG_CONFIG_PATH=/app/libxml2/current/lib/pkgconfig:/app/wlroots/current/lib/pkgconfig:/app/wayland/current/lib/pkgconfig:/app/libdrm/current/lib/pkgconfig:/app/libxkbcommon/current/lib/pkgconfig:/app/pixman/current/lib/pkgconfig:/app/wayland-protocols/current/share/pkgconfig \
        meson setup -Dprefix=/app/wayfire/current --buildtype release -Dtests=disabled -Dxwayland=disabled -Dvulkan_effects=false \
       -Dlibdir=lib -Duse_system_wfconfig=disabled build
#-Duse_system_wlroots=enabled build
    ninja -C build
    create_app_in_tmp_and_link_it wayfire $prefix$ver
    ninja -C build install
    set_current_app_clean_strip_cd wayfire $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "hyprland" ]; then
#work in progress
#  ver="0.56.2";
  ver="0.55.0";
  if should_make hyprland $ver; then
#udis86*
#glslang-dev
#libeis*
#mupraser*
#libre2*
#lcms2*
#libxcb-errors*
#libxcb-icccm4-dev
    download_unpack_source https://github.com/hyprwm/Hyprland/archive/refs/tags/v$ver.tar.gz hyprland Hyprland-$ver 1
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DNO_SYSTEMD:STRING=true  -B build \
      -D CMAKE_PREFIX_PATH="/app/lua/current;/app/libxcb/current;/app/hyprwayland-scanner/current;/app/aquamarine/current;/app/hyprlang/current;/app/hyprcursor/current;/app/hyprutils/current;/app/hyprgraphics/current;/app/xkbcommon/current;/app/wayland-protocols/current;/app/libinput/current;/app/hyprwire/current"

sed -i "s/\+ filename/\+ std::string\(filename\)/" hyprctl/src/main.cpp


    PATH=$PATH:/app/hyprwire/current/bin:/app/hyprwayland-scanner/current/bin  &&   cmake --build build  --config Release --target all -j$cpu_num
    create_app_in_tmp_and_link_it hyprland $prefix$ver
#    make install PREFIX=/app/bzip2/$prefix$ver
#    set_current_app_clean_strip_cd hyprland $prefix$ver 1
  fi
fi
#end of wayland
if [ "$package" == "fs" ] || [ "$package" == "hyprwire" ]; then
#  ver="0.3.1";
#cannot be compiled ?https://github.com/hyprwm/hyprwire/issues/20
#append_range with insert like in Debian?
# todo: add files from in : https://en.cppreference.com/cpp/container/vector/append_range
#some ideas from https://github.com/ironexperiment/Hyprland-on-debian-trixie/blob/main/patches/hyprwire-append_range-gcc14-compat.patch
  ver="0.3.0";
  if should_make hyprwire $ver; then
    download_unpack_source https://github.com/hyprwm/hyprwire/archive/refs/tags/v$ver.tar.gz hyprwire hyprwire-$ver 1
    cmake   -B build      -D CMAKE_PREFIX_PATH="/app/hyprutils/current" -DCMAKE_INSTALL_PREFIX:PATH=/app/hyprwire/current -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF
#fixme - change sed -r with sed -i
    find * \
        -name '*.cpp' \
        -type f -exec bash -c 'echo "{}" && cat "{}" | sed -r "s/(.*).append_range\((.*)\)(.*)/{auto\&\& _r = \2; \1\.insert(\1\.end\(\), _r\.begin\(\), _r\.end\(\)); }/" > "{}.2" && rm {} && mv {}.2 {} ' \;
    cmake --build build  -j$cpu_num
    create_app_in_tmp_and_link_it hyprwire $prefix$ver
    cmake --install build
    set_current_app_clean_strip_cd hyprwire $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "cairo" ]; then
  ver="1.18.6";
  if should_make cairo $ver; then
    download_unpack_source https://www.cairographics.org/releases/cairo-1.18.6.tar.xz cairo cairo-$ver 1
    meson setup -Dprefix=/app/cairo/current --buildtype release -Dlibdir=lib build
    ninja -C build
    create_app_in_tmp_and_link_it cairo $prefix$ver
    ninja -C build install
    set_current_app_clean_strip_cd cairo $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "yyjson" ]; then
  ver="0.13.0";
  if should_make yyjson $ver; then
    download_unpack_source https://github.com/ibireme/yyjson/archive/refs/tags/0.13.0.tar.gz yyjson yyjson-$ver 1
    cmake -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/app/yyjson/current \
      -DBUILD_SHARED_LIBS=true -S . -B ./build 
    create_app_in_tmp_and_link_it yyjson $prefix$ver
    cmake --build ./build --config Release --target all -j$cpu_num
    create_app_in_tmp_and_link_it yyjson $prefix$ver
    cmake --install build
    set_current_app_clean_strip_cd yyjson $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libjpeg-turbo" ]; then
  ver="3.2.0";
  if should_make libjpeg-turbo $ver; then
    download_unpack_source https://github.com/libjpeg-turbo/libjpeg-turbo/archive/refs/tags/3.2.0.tar.gz libjpeg-turbo libjpeg-turbo-$ver 1
    cmake -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/app/libjpeg-turbo/current \
      -DBUILD_SHARED_LIBS=true -S . -B ./build 
    create_app_in_tmp_and_link_it libjpeg-turbo $prefix$ver
    cmake --build ./build --config Release --target all -j$cpu_num
    create_app_in_tmp_and_link_it libjpeg-turbo $prefix$ver
    cmake --install build
    set_current_app_clean_strip_cd libjpeg-turbo $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "little-cms" ]; then
  ver="2.19.1";
  if should_make little-cms $ver; then
    download_unpack_source https://github.com/mm2/Little-CMS/archive/refs/tags/lcms2.19.1.tar.gz  little-cms Little-CMS-lcms$ver 1
    cmake -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/app/little-cms/current \
      -DBUILD_SHARED_LIBS=true -S . -B ./build 
    create_app_in_tmp_and_link_it little-cms $prefix$ver
    cmake --build ./build --config Release --target all -j$cpu_num
    create_app_in_tmp_and_link_it little-cms $prefix$ver
    cmake --install build
    set_current_app_clean_strip_cd little-cms $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "dbus" ]; then
  ver="1.16.2";
  if should_make dbus $ver; then
    download_unpack_source https://dbus.freedesktop.org/releases/dbus/dbus-1.16.2.tar.xz dbus dbus-$ver 1
    meson setup -Dprefix=/app/dbus/current --buildtype release -Dsystemd=disabled -Dsystemd_system_unitdir=/app/dbus/current/systemd/system \
       -Dsystemd_user_unitdir=/app/dbus/current/systemd/user -Dlibdir=lib build
    ninja -C build
    create_app_in_tmp_and_link_it dbus $prefix$ver
    ninja -C build install
    set_current_app_clean_strip_cd dbus $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "pango" ]; then
  ver="1.58.2";
  if should_make pango $ver; then
    download_unpack_source https://gitlab.gnome.org/GNOME/pango/-/archive/1.58.2/pango-1.58.2.tar.bz2?ref_type=tags pango pango-$ver 1
    meson setup -Dprefix=/app/pango/current --buildtype release -Dlibdir=lib build
    ninja -C build
    create_app_in_tmp_and_link_it pango $prefix$ver
    ninja -C build install
#    set_current_app_clean_strip_cd pango $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "librsvg" ]; then
#cargo-c
#  ver="2.63.4";
#  ver="2.63.0";
ver="2.60.2";
  if should_make librsvg $ver; then
    download_unpack_source https://github.com/GNOME/librsvg/archive/refs/tags/$ver.tar.gz librsvg librsvg-$ver 1
    meson setup -Dprefix=/app/librsvg/current --buildtype release -Dlibdir=lib -Ddocs=disabled -Dpixbuf-loader=disabled -Dtests=false build
    ninja -C build
    create_app_in_tmp_and_link_it librsvg $prefix$ver
    ninja -C build install
    set_current_app_clean_strip_cd librsvg $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "rsync" ]; then
  ver="3.5.0";
  if should_make rsync $ver; then
    download_unpack_source https://download.samba.org/pub/rsync/src/rsync-$ver.tar.gz rsync rsync-$ver 1
    ./configure --disable-xxhash --disable-lz4 --prefix=$output/app/rsync/$prefix$ver
    make all -j$cpu_num
    create_app rsync $prefix$ver
    make install
    set_current_app_clean_strip_cd rsync $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "zstd" ]; then
  ver="1.5.7";
  if should_make zstd $ver; then
    download_unpack_source https://github.com/facebook/zstd/releases/download/v$ver/zstd-$ver.tar.gz zstd zstd-$ver 1
    make all -j$cpu_num
    create_app zstd $prefix$ver
    cp LICENSE $output/app/zstd/$prefix$ver
    rsync -a $curdir/in/zstd/ $output/app/zstd/$prefix$ver
    mkdir $output/app/zstd/$prefix$ver/bin
    for binrentry in zstd zstd-compress zstd-decompress zstd-small zstdgrep zstdsmall; do
      cp programs/$binentry $output/app/zstd/$prefix$ver/bin
    done
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
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "zlib" ]; then
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
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "pcre2" ]; then
  ver="10.47";
  if should_make pcre2 $ver; then
    download_unpack_source https://github.com/PCRE2Project/pcre2/releases/download/pcre2-$ver/pcre2-$ver.tar.gz pcre2 pcre2-$ver 1
    ./configure --prefix=/app/pcre2/current
    make all -j$cpu_num
    create_app pcre2 $prefix$ver
    set_current_app pcre2 $prefix$ver 1
    make install
    cp $out/pcre2/pcre2-$ver/LICENCE.md $output/app/pcre2/$prefix$ver
    rsync -a $curdir/in/pcre2/ $output/app/pcre2/$prefix$ver
    echo "" >> /app/pcre2/current/readme.md
    echo "**Last**" >> /app/pcre2/current/readme.md
    echo "$LATEST_FILE_UPDATE" >> /app/pcre2/current/readme.md
    set_current_app_clean_strip_cd pcre2 $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "ncurses" ]; then
  ver="6.6";
  if should_make ncurses $ver; then
    download_unpack_source https://invisible-island.net/archives/ncurses/ncurses-$ver.tar.gz ncurses ncurses-$ver 1
    ./configure --prefix=/app/ncurses/current --with-shared  --with-termlib  --with-ticlib --disable-widec --with-develop --with-cxx-shared --with-trace --with-versioned-syms
    make all -j$cpu_num
    create_app ncurses $prefix$ver
    set_current_app ncurses $prefix$ver 1
    make install
    rsync -a $curdir/in/ncurses/ $output/app/ncurses/$prefix$ver
    echo "" >> /app/ncurses/current/readme.md
    echo "**Last**" >> /app/ncurses/current/readme.md
    echo "$LATEST_FILE_UPDATE" >> /app/ncurses/current/readme.md
    cp $out/ncurses/ncurses-$ver/COPYING $output/app/ncurses/$prefix$ver
    set_current_app_clean_strip_cd ncurses $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "ncursesw" ]; then
  ver="6.6";
  if should_make ncursesw $ver; then
    download_unpack_source https://invisible-island.net/archives/ncurses/ncurses-$ver.tar.gz ncursesw ncurses-$ver 1
    ./configure --prefix=/app/ncursesw/current --with-shared  --enable-widec --with-cxx-shared --with-versioned-syms --without-normal
    make all -j$cpu_num
    create_app ncursesw $prefix$ver
    set_current_app ncursesw $prefix$ver 1
    make install
    rsync -a $curdir/in/ncurses/ $output/app/ncursesw/$prefix$ver
    echo "" >> /app/ncursesw/current/readme.md
    echo "**Last**" >> /app/ncursesw/current/readme.md
    echo "$LATEST_FILE_UPDATE" >> /app/ncursesw/current/readme.md
    cp $out/ncursesw/ncurses-$ver/COPYING $output/app/ncursesw/$prefix$ver
    set_current_app_clean_strip_cd ncursesw $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "gcc" ]; then
#  ver="14.2.0";
  ver="16.2.0";
  if should_make gcc $ver; then
    # compilation can be done in tmpfs (ca. 4,3 GB)
    download_unpack_source https://ftp.gnu.org/gnu/gcc/gcc-$ver/gcc-$ver.tar.xz gcc gcc-$ver 1
    contrib/download_prerequisites
    mkdir ../gcc-$ver-build
    cd ../gcc-$ver-build
    ../gcc-$ver/configure --enable-shared --disable-multilib --prefix= --enable-languages=c,c++ --disable-bootstrap \
          --enable-default-pie --enable-default-ssp
    make all -j$cpu_num
    create_app_in_tmp_and_link_it gcc $prefix$ver
    make DESTDIR=/app/gcc/current install-strip
    rsync -a /app/gcc/current/lib64/* /app/gcc/current/lib
    rm -r /app/gcc/current/lib64
    rsync -a $curdir/in/gcc/ /app/gcc/current
    remove_duplicates_cd /app/gcc/current/bin
    remove_duplicates_cd /app/gcc/current/share/man/man1
    create_app gcclib $prefix$ver
    mkdir /app/gcclib/$prefix$ver/lib
    mv /app/gcc/current/lib/lib* /app/gcclib/$prefix$ver/lib
    set_current_app_clean_strip_cd gcc $prefix$ver 1
    set_current_app_clean_strip_cd gcclib $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "file" ]; then
  ver="5_48";
  download_unpack_source https://github.com/file/file/archive/refs/tags/FILE$ver.tar.gz FILE file-FILE$ver 1
  autoreconf -f -i
  ./configure --prefix=/app/file/current
  make all -j$cpu_num
  create_app_in_tmp_and_link_it file $prefix$ver
  make install
  cp COPYING /app/file/current
  set_current_app_clean_strip_cd file $prefix$ver 1
fi
if [ "$package" == "fs" ] || [ "$package" == "binutils" ]; then
  ver="2.47";
  download_unpack_source https://sourceware.org/pub/binutils/releases/binutils-$ver.tar.xz binutils binutils-$ver 1
  ./configure --prefix=/app/binutils/current
  make all -j$cpu_num
  create_app_in_tmp_and_link_it binutils $prefix$ver
  make install
  set_current_app_clean_strip_cd binutils $prefix$ver 1
fi
if [ "$package" == "fs" ] || [ "$package" == "grep" ]; then
  ver="3.12";
  download_unpack_source https://ftp.gnu.org/gnu/grep/grep-3.12.tar.xz grep grep-$ver 1
  ./configure --prefix=/app/grep/current
  make all -j$cpu_num
  create_app_in_tmp_and_link_it grep $prefix$ver
  make install
  set_current_app_clean_strip_cd grep $prefix$ver 1
fi
if [ "$package" == "fs" ] || [ "$package" == "slang" ]; then
  ver="2.3.3";
  if should_make slang $ver; then
    download_unpack_source https://www.jedsoft.org/releases/slang/slang-$ver.tar.bz2 slang slang-$ver 1
    ./configure --prefix=/app/slang/current
    make all -j$cpu_num
    create_app slang $prefix$ver
    set_current_app slang $prefix$ver 1
    make install
    chmod a-x $output/app/slang/$prefix$ver/lib/slang/v2/modules/*.so
    set_current_app_clean_strip_cd slang $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "glib" ]; then
  #glib (GTK, gnome), not GNU C library
  ver="2.89.1";
  if should_make glib $ver; then
    download_unpack_source https://github.com/GNOME/glib/archive/refs/tags/$ver.tar.gz glib glib-$ver 1
    if [ -d "subprojects/packagefiles" ]; then
      cd subprojects
      meson subprojects download --sourcedir ..
      rm -r gvdb
      rm -r packagecache
      rm -r packagefiles
      cd ..
    fi
    mkdir ../$prefix$ver-compile
    ln -s ../$prefix$ver-compile _build
    meson setup -Dprefix=/app/glib/current --buildtype minsize _build
    meson compile -C _build
    create_app glib $prefix$ver
    set_current_app glib $prefix$ver 1
    meson install -C _build
    chmod a+x $output/app/glib/$prefix$ver/lib/x86_64-linux-gnu/
    chmod a-x $output/app/glib/$prefix$ver/lib/x86_64-linux-gnu/*so*
    rsync -a $output/app/glib/$prefix$ver/lib/x86_64-linux-gnu/* $output/app/glib/$prefix$ver/lib
    rm -r $output/app/glib/$prefix$ver/lib/x86_64-linux-gnu/
    rsync -a $curdir/in/glib/ $output/app/glib/$prefix$ver
    echo "" >> /app/glib/current/readme.md
    echo "**Last**" >> /app/glib/current/readme.md
    echo "$LATEST_FILE_UPDATE" >> /app/glib/current/readme.md
    set_current_app_clean_strip_cd glib $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libxml2" ]; then
  ver="2.15.4";
  if should_make libxml2 $ver; then
    download_unpack_source https://gitlab.gnome.org/GNOME/libxml2/-/archive/v2.15.4/libxml2-v2.15.4.tar.bz2 libxml2 libxml2-v$ver 1
    meson setup -Dprefix=/app/libxml2/current --buildtype minsize _build
    meson compile -C _build
    create_app libxml2 $prefix$ver
    set_current_app libxml2 $prefix$ver 1
    meson install -C _build
    rsync -a $output/app/libxml2/$prefix$ver/lib/x86_64-linux-gnu/* $output/app/libxml2/$prefix$ver/lib
    rm -r $output/app/libxml2/$prefix$ver/lib/x86_64-linux-gnu/
#fixme do link .so.2 do .so
    set_current_app_clean_strip_cd libxml2 $prefix$ver 0 # no stripping
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
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "tzdb" ]; then
  ver="2026c";
  if should_make tzdata $ver; then
    download_unpack_source https://data.iana.org/time-zones/releases/tzdb-$ver.tar.lz tzdb tzdb-$ver 1
    create_app tzdb $prefix$ver
    set_current_app tzdb $prefix$ver 1
    make TOPDIR="/app/tzdb/current" install
    cp LICENSE $output/app/tzdb/$prefix$ver
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
  cp $curdir/in/pllinux.iso/* $output/boot/grub
  sudo grub-mkrescue -o $isofile $output/ --disable-shim-lock
  rm -r $output/boot
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "groff" ]; then
  # for displaying man pages
  ver="1.24.1";
  if should_make groff $ver; then
    download_unpack_source https://ftp.gnu.org/gnu/groff/groff-$ver.tar.gz groff groff-$ver 1
    ./configure --prefix=/app/groff/current
    make all -j$cpu_num
    create_app groff $prefix$ver
    set_current_app groff $prefix$ver 1
    make install
    rsync -a $curdir/in/groff/ $output/app/groff/$prefix$ver
    echo "" >> /app/groff/current/readme.md
    echo "**Last**" >> /app/groff/current/readme.md
    echo "$LATEST_FILE_UPDATE" >> /app/groff/current/readme.md
    set_current_app_clean_strip_cd groff $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "less" ]; then
  ver="704";
  if should_make less $ver; then
#    download_unpack_source https://github.com/gwsw/less/archive/refs/tags/v$ver.tar.gz less less-$ver 1
    download_unpack_source https://greenwoodsoftware.com/less/less-$ver.tar.gz less less-$ver 1
    create_app less $prefix$ver
    cd $out/less/less-$ver
    autoconf
    ./configure --prefix=/app/less/current
    make all -j$cpu_num
    make install
    set_current_app_clean_strip_cd less $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "dialog" ]; then
  ver="1.3-20260721";
  if should_make dialog $ver; then
    download_unpack_source https://invisible-island.net/archives/dialog/dialog-$ver.tgz dialog dialog-$ver 1
    ./configure --prefix=/app/dialog/$prefix$ver --enable-widec --with-ncursesw
    make all -j$cpu_num
    create_app dialog $prefix$ver
    make install
    set_current_app_clean_strip_cd dialog $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "smartmontools" ]; then
  rel="7_5";
  ver="7.5";
  if should_make smartmontools $ver; then
    download_unpack_source https://github.com/smartmontools/smartmontools/releases/download/RELEASE_$rel/smartmontools-$ver.tar.gz smartmontools smartmontools-$ver 1
    ./configure --prefix=/app/smartmontools/current
    make -j$cpu_num
    create_app smartmontools $prefix$ver
    set_current_app smartmontools $prefix$ver 1
    make install
#    echo "" >> /app/smartmontools/current/readme.md
#    echo "**Last**" >> /app/smartmontools/current/readme.md
#    echo "$LATEST_FILE_UPDATE" >> /app/smartmontools/current/readme.md
    set_current_app_clean_strip_cd smartmontools $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libxcrypt" ]; then
  ver="4.5.2";
  if should_make libxcrypt $ver; then
    download_unpack_source https://github.com/besser82/libxcrypt/releases/download/v$ver/libxcrypt-$ver.tar.xz libxcrypt libxcrypt-$ver 1
    mkdir $out/libxcrypt/libxcrypt-$ver-build
    cd $out/libxcrypt/libxcrypt-$ver-build
    ../libxcrypt-$ver/configure --prefix=/app/libxcrypt/$prefix$ver
    make -j$cpu_num
    create_app libxcrypt $prefix$ver
    make install
    set_current_app_clean_strip_cd libxcrypt $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "readline" ]; then
  ver="8.3";
  if should_make readline $ver; then
    download_unpack_source https://ftp.gnu.org/gnu/readline/readline-$ver.tar.gz readline readline-$ver 1
    mkdir $out/readline/readline-$ver-build
    cd $out/readline/readline-$ver-build
    ../readline-$ver/configure --prefix=/app/readline/current
    make -j$cpu_num
    create_app readline $prefix$ver
    set_current_app readline $prefix$ver 1
    make install
    echo "" >> /app/readline/current/readme.md
    echo "**Last**" >> /app/readline/current/readme.md
    echo "$LATEST_FILE_UPDATE" >> /app/readline/current/readme.md
    set_current_app_clean_strip_cd readline $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "lvm2" ]; then
  ver="2.03.42";
  if should_make lvm2 $ver; then
    install_host_deps "libaio-dev"
    download_unpack_source https://sourceware.org/pub/lvm2/releases/LVM2.$ver.tgz lvm2 LVM2.$ver 1
    ./configure --enable-static_link --without-udev
#    ./configure --enable-static-link --disable-selinux --disable-shared --without-udev --without-systemd \
#           --disable-udev_sync --disable-udev_rules --disable-udev-rule-exec-detection #--prefix=$output/app/lvm2/$prefix$ver --enable-pkgconfig
    make -j$cpu_num
    create_app lvm2 $prefix$ver
    make DESTDIR=$output/app/lvm2/$prefix$ver install
    cd $output/app/lvm2/$prefix$ver/lib
    ln -s libdevmapper.so.1.02 libdevmapper.so.1.02.1 # cross fingers this version works
    set_current_app_clean_strip_cd lvm2 $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "console-fonts-zap" ]; then
  ver="2.4";
  if should_make console-fonts-zap $ver; then
    download_unpack_source https://ftp.zap.org.au/pub/fonts/console-fonts-zap/console-fonts-zap-2.4.tar.xz console-fonts console-fonts-zap-$ver 1
    create_app console-fonts-zap $prefix$ver
    cp *.psf /app/console-fonts-zap/$prefix$ver
    set_current_app_clean_strip_cd console-fonts-zap $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "parted" ]; then
  ver="3.7";
  if should_make parted $ver; then
    install_host_deps "libdevmapper-dev libreadline-dev"
    download_unpack_source https://ftp.gnu.org/gnu/parted/parted-$ver.tar.xz parted parted-$ver 1
    mkdir $out/parted/parted-$ver-build
    cd $out/parted/parted-$ver-build
    ../parted-$ver/configure --prefix=/app/parted/current
    make -j$cpu_num
    create_app parted $prefix$ver
    set_current_app parted $prefix$ver 1
    make install
    set_current_app_clean_strip_cd parted $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "cryptsetup" ]; then
  ver="2.8.8";
  if should_make cryptsetup $ver; then
    install_host_deps "asciidoctor libpopt-dev libjson-c-dev libssh-dev"
    download_unpack_source https://cdn.kernel.org/pub/linux/utils/cryptsetup/v2.8/cryptsetup-$ver.tar.xz cryptsetup cryptsetup-$ver 1
    ./configure --prefix=/app/cryptsetup/$prefix$ver
    make -j$cpu_num
    create_app cryptsetup $prefix$ver
    make install
    set_current_app_clean_strip_cd cryptsetup $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libselinux" ]; then
  ver="3.11";
  if should_make libselinux $ver; then
    download_unpack_source https://github.com/SELinuxProject/selinux/releases/download/$ver/libselinux-$ver.tar.gz libselinux libselinux-$ver 1
    create_app libselinux $prefix$ver
    make -j$cpu_num DESTDIR=$output/app/libselinux/$prefix$ver install
    cp LICENSE $output/app/libselinux/$prefix$ver
    cd $output/app/libselinux/$prefix$ver/lib
    ln -s libselinux.so.1 libselinux.so
    set_current_app_clean_strip_cd libselinux $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "gptfdisk" ]; then
  ver="1.0.10";
  if should_make gptfdisk $ver; then
    download_unpack_source https://sourceforge.net/projects/gptfdisk/files/gptfdisk/$ver/gptfdisk-$ver.tar.gz/download gptfdisk-$ver gptfdisk-$ver 1
    make -j$cpu_num 
    create_app gptfdisk $prefix$ver
    for folderentry in bin man; do
      mkdir $output/app/gptfdisk/$prefix$ver/$folderentry
    done
    for binentry in cgdisk gdisk sgdisk fixparts; do
      cp $binentry $output/app/gptfdisk/$prefix$ver/bin
    done
    cp *.8 $output/app/gptfdisk/$prefix$ver/man
    set_current_app_clean_strip_cd gptfdisk $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "nano" ]; then
  ver="9.2";
  if should_make nano $ver; then
    download_unpack_source https://www.nano-editor.org/dist/v9/nano-$ver.tar.xz nano nano-$ver 1
    ./configure --prefix=/app/nano/current
    make -j$cpu_num
    create_app nano $prefix$ver
    set_current_app nano $prefix$ver 1
    make install
    set_current_app_clean_strip_cd nano $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "dmidecode" ]; then
  ver="3.7";
  if should_make dmidecode $ver; then
    download_unpack_source https://download.savannah.gnu.org/releases/dmidecode/dmidecode-$ver.tar.xz dmidecode dmidecode-$ver 1
    make all -j$cpu_num
    create_app dmidecode $prefix$ver
#    we need make install - this could work with changing DESTDIR maybe
    for folderentry in bin man completion; do
      mkdir $output/app/dmidecode/$prefix$ver/$folderentry
    done
    for binentry in biosdecode dmidecode ownership vpddecode; do
      cp $binentry $output/app/dmidecode/$prefix$ver/bin
    done
    cp completion/* $output/app/dmidecode/$prefix$ver/completion
    cp man/*.8 $output/app/dmidecode/$prefix$ver/man
    set_current_app_clean_strip_cd dmidecode $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "pciutils" ]; then
  ver="3.15.0";
  if should_make pciutils $ver; then
    download_unpack_source https://github.com/pciutils/pciutils/releases/download/v$ver/pciutils-$ver.tar.gz pciutils pciutils-$ver 1
    sed -i 's/HWDB=/HWDB=no/g' Makefile
    make PREFIX=/app/pciutils/current -j$cpu_num
    create_app_in_tmp_and_link_it pciutils $prefix$ver
    make PREFIX=/app/pciutils/current  install
    set_current_app_clean_strip_cd pciutils $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "rsyslog" ]; then
  ver="8.2608.0";
  if should_make rsyslog $ver; then
    install_host_deps "libestr-dev libfastjson-dev libgcrypt20-dev libcurl4-gnutls-dev libprotobuf-c-dev protobuf-c-compiler libsnappy-dev"
    download_unpack_source https://github.com/rsyslog/rsyslog/releases/download/v$ver/rsyslog-$ver.tar.gz rsyslog rsyslog-$ver 1
#    --enable-static doesn't work?
    ./configure --prefix=/app/rsyslog/current --disable-libyaml --enable-kmsg --enable-usertools --disable-libsystemd
    make -j$cpu_num
    create_app_in_tmp_and_link_it rsyslog $prefix$ver
    make install
    chmod a-x /app/rsyslog/current/lib/rsyslog/*.la
    chmod a-x /app/rsyslog/current/lib/rsyslog/*.so
    set_current_app_clean_strip_cd rsyslog $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libestr" ]; then
  ver="0.1.11";
  if should_make libestr $ver; then
    download_unpack_source https://github.com/rsyslog/libestr/archive/refs/tags/v$ver.tar.gz libestr libestr-$ver 1
    mkdir $out/libestr/libestr-$ver-build
    cd $out/libestr/libestr-$ver-build
    ../libestr-$ver/autogen.sh
    ../libestr-$ver/configure --prefix=/app/libestr/$prefix$ver
    make -j$cpu_num
    create_app libestr $prefix$ver
    make install
    set_current_app_clean_strip_cd libestr $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libfastjson" ]; then
  ver="1.2609.0";
  if should_make libfastjson $ver; then
    download_unpack_source https://github.com/rsyslog/libfastjson/releases/download/v$ver/libfastjson-$ver.tar.gz libfastjson libfastjson-$ver 1
    mkdir $out/libfastjson/libfastjson-$ver-build
    cd $out/libfastjson/libfastjson-$ver-build
    ../libfastjson-$ver/autogen.sh
    ../libfastjson-$ver/configure --prefix=/app/libfastjson/$prefix$ver
    make -j$cpu_num
    create_app libfastjson $prefix$ver
    make install
    cp ../libfastjson-$ver/COPYING $output/app/libfastjson/$prefix$ver
    set_current_app_clean_strip_cd libfastjson $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "strace" ]; then
  ver="7.2";
  if should_make strace $ver; then
    download_unpack_source https://github.com/strace/strace/releases/download/v$ver/strace-$ver.tar.xz strace strace-$ver 1
    mkdir $out/strace/strace-$ver-build
    cd $out/strace/strace-$ver-build
    ../strace-$ver/configure --prefix=/app/strace/$prefix$ver --disable-mpers
    make -j$cpu_num
    create_app strace $prefix$ver
    make install
    set_current_app_clean_strip_cd strace $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "elfutils" ]; then
  ver="0.196";
  if should_make elfutils $ver; then
    download_unpack_source https://sourceware.org/elfutils/ftp/$ver/elfutils-$ver.tar.bz2 elfutils elfutils-$ver 1
    mkdir $out/elfutils/elfutils-$ver-build
    cd $out/elfutils/elfutils-$ver-build
    ../elfutils-$ver/configure --prefix=/app/elfutils/$prefix$ver
    make -j$cpu_num
    create_app elfutils $prefix$ver
    make install
    set_current_app_clean_strip_cd elfutils $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "xzutils" ]; then
  ver="5.8.4";
  if should_make xzutils $ver; then
    download_unpack_source https://github.com/tukaani-project/xz/releases/download/v$ver/xz-$ver.tar.xz xzutils xz-$ver 1
    mkdir $out/xzutils/xz-$ver-build
    cd $out/xzutils/xz-$ver-build
    ../xz-$ver/autogen.sh
    ../xz-$ver/configure --prefix=/app/xzutils/$prefix$ver
    make -j$cpu_num
    create_app xzutils $prefix$ver
    make install
    cp ../xz-$ver/COPYING $output/app/xzutils/$prefix$ver
    set_current_app_clean_strip_cd xzutils $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "bzip2" ]; then
  ver="1.0.8";
  if should_make bzip2 $ver; then
    download_unpack_source https://sourceware.org/pub/bzip2/bzip2-$ver.tar.gz bzip2 bzip2-$ver 1
    make -j$cpu_num
    create_app bzip2 $prefix$ver
    make install PREFIX=/app/bzip2/$prefix$ver
    make clean
    make -f Makefile-libbz2_so -j$cpu_num
    cp libbz2.so* $output/app/bzip2/$prefix$ver/lib
    set_current_app_clean_strip_cd bzip2 $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libinput" ]; then
  ver="1.32.0";
#sudo apt-get build-dep libinput
  if should_make libinput $ver; then
    download_unpack_source https://gitlab.freedesktop.org/libinput/libinput/-/archive/1.32.0/libinput-1.32.0.tar.gz libinput libinput-$ver 1
    meson setup -Dprefix=/app/libinput/current -Dlibdir=lib builddir
    ninja -C builddir
    create_app_in_tmp_and_link_it libinput $prefix$ver
    ninja -C builddir install
    set_current_app_clean_strip_cd libinput $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "gdk-pixbuf" ]; then
  ver="2.44.8";
  if should_make gdk-pixbuf $ver; then
    download_unpack_source https://gitlab.gnome.org/GNOME/gdk-pixbuf/-/archive/2.44.8/gdk-pixbuf-2.44.8.tar.bz2 gdk-pixbuf gdk-pixbuf-$ver 1
    meson setup -Dprefix=/app/gdk-pixbuf/current -Dlibdir=lib builddir
#    ninja -C builddir
#    create_app_in_tmp_and_link_it libinput $prefix$ver
#    ninja -C builddir install
#    set_current_app_clean_strip_cd libinput $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "glycin" ]; then
#libheif-dev
#libjxl-dev
#  ver="2.2.5";
  ver="2.2.0";
  if should_make glycin $ver; then
    download_unpack_source https://gitlab.gnome.org/GNOME/glycin/-/archive/$ver/glycin-$ver.tar.bz2 glycin glycin-$ver 1
    PKG_CONFIG_PATH=/app/gobject-introspection/current/lib/pkgconfig      meson setup -Dprefix=/app/glycin/current -Dlibdir=lib builddir
    ninja -C builddir
    create_app_in_tmp_and_link_it glycin $prefix$ver
    ninja -C builddir install
    set_current_app_clean_strip_cd glycin $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "gobject-introspection" ]; then
#rnc2rng*
  ver="1.86.0";
  if should_make gobject-introspection $ver; then
    download_unpack_source https://gitlab.gnome.org/GNOME/gobject-introspection/-/archive/1.86.0/gobject-introspection-1.86.0.tar.bz2 gobject-introspection gobject-introspection-$ver 1
    meson setup -Dprefix=/app/gobject-introspection/current -Dlibdir=lib -Dtests=false builddir
    ninja -C builddir
    create_app_in_tmp_and_link_it gobject-introspection $prefix$ver
    ninja -C builddir install
    set_current_app_clean_strip_cd gobject-introspection $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "graphviz" ]; then
  ver="16.1.0";
  if should_make graphviz $ver; then
    download_unpack_source https://gitlab.com/api/v4/projects/4207231/packages/generic/graphviz-releases/16.1.0/graphviz-16.1.0.tar.xz graphviz graphviz-$ver 1
        ./configure --prefix=/app/graphviz/current
    make -j$cpu_num
    create_app_in_tmp_and_link_it graphviz $prefix$ver
    make install
    set_current_app_clean_strip_cd graphviz $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "vala" ]; then
#vala
  ver="0.56.19";
  if should_make vala $ver; then
    download_unpack_source https://gitlab.gnome.org/GNOME/vala/-/archive/0.56.19/vala-0.56.19.tar.bz2 vala vala-$ver 1
    ./autogen.sh
    PKG_CONFIG_PATH=/app/gobject-introspection/current/lib/pkgconfig:/app/graphviz/current/lib/pkgconfig \
        ./configure --prefix=/app/vala/current PACKAGE_VERSION=$ver
    make -j$cpu_num
    create_app_in_tmp_and_link_it vala $prefix$ver
    make install
    set_current_app_clean_strip_cd vala $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "xlibre-xserver" ]; then
#apt-get install x11proto-dev xtrans-dev libpixman-1-dev libxkbcommon-x11-dev \
#libxfont-dev libxcvt-dev libdrm-dev libepoxy-dev \
#x11proto-present-dev x11proto-dev libxkbfile-dev libudev-dev libxshmfence-dev \
#libbsd-dev x11proto-xf86dri-dev libgl1-mesa-dev libglu1-mesa-dev \
#libglu1-mesa-dev libgl-dev libdrm-dev xutils-dev mesa-common-dev libgbm-dev \
#libxcb-shape0-dev libxcb-util-dev libxcb-icccm4-dev

#libxkbfile-dev xfont2* libxcvt-dev
  ver="25.1.9";
  if should_make xlibre-xserver $ver; then
    download_unpack_source https://github.com/X11Libre/xserver/archive/refs/tags/xlibre-xserver-25.1.9.tar.gz xlibre-xserver xserver-xlibre-xserver-$ver 1
    meson setup -Dprefix=/app/xlibre-xserver/current -Dsystemd_logind=false -Dsystemd_notify=false -Dxselinux=false -Dlibdir=lib builddir
    ninja -C builddir
    create_app_in_tmp_and_link_it xlibre-xserver $prefix$ver
    ninja -C builddir install
    rsync -a $curdir/in/xlibre-xserver/ /app/xlibre-xserver/current
    set_current_app_clean_strip_cd xlibre-xserver $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "xf86-input-evdev" ]; then
  ver="2.11.0";
  if should_make xf86-input-evdev $ver; then
    download_unpack_source https://xorg.freedesktop.org/archive/individual/driver/xf86-input-evdev-2.11.0.tar.xz xf86-input-evdev xf86-input-evdev-$ver 1
    PKG_CONFIG_PATH=/app/xlibre-xserver/current/lib/pkgconfig    ./configure --prefix=/app/xf86-input-evdev/current
    make -j$cpu_num
    create_app_in_tmp_and_link_it xf86-input-evdev $prefix$ver
    make install
    set_current_app_clean_strip_cd xf86-input-evdev $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "mtdev" ]; then
  ver="1.1.7";
  if should_make mtdev $ver; then
    download_unpack_source https://bitmath.org/code/mtdev/mtdev-1.1.7.tar.bz2 mtdev mtdev-$ver 1
    ./configure --prefix=/app/mtdev/current --disable-static
    make all -j$cpu_num
    create_app_in_tmp_and_link_it mtdev $prefix$ver
    make install
    set_current_app_clean_strip_cd mtdev $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fontconfig" ]; then
#  ver="2.18.3";
  ver="2.17.1";
  if should_make fontconfig $ver; then
    download_unpack_source https://gitlab.freedesktop.org/fontconfig/fontconfig/-/archive/$ver/fontconfig-$ver.tar.bz2 fontconfig fontconfig-$ver 1
    meson setup -Dprefix=/app/fontconfig/current --buildtype release -Dlibdir=lib -Ddoc=disabled _build
    meson compile -C _build
    create_app_in_tmp_and_link_it fontconfig $prefix$ver
    meson install -C _build
    cp COPYING /app/fontconfig/current
    set_current_app_clean_strip_cd fontconfig $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libxinerama" ]; then
  ver="1.1.6";
  if should_make libxinerama $ver; then
    download_unpack_source https://gitlab.freedesktop.org/xorg/lib/libxinerama/-/archive/libXinerama-1.1.6/libxinerama-libXinerama-1.1.6.tar.bz2?ref_type=tags libXinerama libxinerama-libXinerama-$ver 1
    meson setup -Dprefix=/app/libxinerama/current --buildtype release -Dlibdir=lib _build
    meson compile -C _build
    create_app_in_tmp_and_link_it libxinerama $prefix$ver
    meson install -C _build
    set_current_app_clean_strip_cd libxinerama $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libxrender" ]; then
  ver="0.9.13";
  if should_make libxrender $ver; then
    download_unpack_source https://gitlab.freedesktop.org/xorg/lib/libxrender/-/archive/libXrender-0.9.13/libxrender-libXrender-0.9.13.tar.bz2?ref_type=tags libXrender libxrender-libXrender-$ver 1
    meson setup -Dprefix=/app/libxrender/current --buildtype release -Dlibdir=lib _build
    meson compile -C _build
    create_app_in_tmp_and_link_it libxrender $prefix$ver
    meson install -C _build
    set_current_app_clean_strip_cd libxrender $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libxkbcommon" ]; then
  ver="1.13.2";
  if should_make libxkbcommon $ver; then
    download_unpack_source https://github.com/xkbcommon/libxkbcommon/archive/refs/tags/xkbcommon-1.13.2.tar.gz libxkbcommon libxkbcommon-xkbcommon-$ver 1
    meson setup -Dprefix=/app/libxkbcommon/current --buildtype release -Dlibdir=lib -Dbash-completion-path=/app/libxkbcommon/current/completion _build
    meson compile -C _build
    create_app_in_tmp_and_link_it libxkbcommon $prefix$ver
    meson install -C _build
    set_current_app_clean_strip_cd libxkbcommon $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "xcalc" ]; then
#libxaw7-dev
  ver="1.1.3";
  if should_make xcalc $ver; then
    download_unpack_source https://xorg.freedesktop.org/archive/individual/app/xcalc-1.1.3.tar.xz xcalc xcalc-$ver 1
    ./configure --prefix=/app/xcalc/current
    make -j$cpu_num
    create_app_in_tmp_and_link_it xcalc $prefix$ver
    make install
    mkdir /app/xcalc/current/bin
    cp xcalc /app/xcalc/current/bin
    set_current_app_clean_strip_cd xcalc $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libxaw" ]; then
  ver="1.0.16";
  if should_make libxaw $ver; then
    download_unpack_source https://gitlab.freedesktop.org/xorg/lib/libxaw/-/archive/libXaw-1.0.16/libxaw-libXaw-1.0.16.tar.bz2?ref_type=tags libxaw libxaw-libXaw-$ver 1
    ./autogen.sh
    ./configure --prefix=/app/libxaw/current
    make -j$cpu_num
    create_app_in_tmp_and_link_it libxaw $prefix$ver
    make install
    set_current_app_clean_strip_cd libxaw $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libxt" ]; then
  ver="1.3.1";
  if should_make libxt $ver; then
    download_unpack_source https://gitlab.freedesktop.org/xorg/lib/libxt/-/archive/libXt-1.3.1/libxt-libXt-1.3.1.tar.bz2?ref_type=tags libxt libxt-libXt-$ver 1
    ./autogen.sh
    ./configure --prefix=/app/libxt/current
    make -j$cpu_num
    create_app_in_tmp_and_link_it libxt $prefix$ver
    make install
    set_current_app_clean_strip_cd libxt $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libxext" ]; then
  ver="1.3.7";
  if should_make libxext $ver; then
    download_unpack_source https://gitlab.freedesktop.org/xorg/lib/libxext/-/archive/libXext-1.3.7/libxext-libXext-1.3.7.tar.bz2?ref_type=tags libxext libxext-libXext-$ver 1
    ./autogen.sh
    ./configure --prefix=/app/libxext/current
    make -j$cpu_num
    create_app_in_tmp_and_link_it libxext $prefix$ver
    make install
    set_current_app_clean_strip_cd libxext $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libxmu" ]; then
  ver="1.3.1";
  if should_make libxmu $ver; then
    download_unpack_source https://gitlab.freedesktop.org/xorg/lib/libxmu/-/archive/libXmu-1.3.1/libxmu-libXmu-1.3.1.tar.bz2?ref_type=tags libxmu libxmu-libXmu-$ver 1
    ./autogen.sh
    ./configure --prefix=/app/libxmu/current
    make -j$cpu_num
    create_app_in_tmp_and_link_it libxmu $prefix$ver
    make install
    set_current_app_clean_strip_cd libxmu $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libxpm" ]; then
  ver="3.5.20";
  if should_make libxpm $ver; then
    download_unpack_source https://xorg.freedesktop.org/archive/individual/lib/libXpm-3.5.20.tar.xz  libxpm libXpm-$ver 1
    ./autogen.sh
    ./configure --prefix=/app/libxpm/current
    make -j$cpu_num
    create_app_in_tmp_and_link_it libxpm $prefix$ver
    make install
    set_current_app_clean_strip_cd libxpm $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libsm" ]; then
  ver="1.2.6";
  if should_make libsm $ver; then
    download_unpack_source https://xorg.freedesktop.org/archive/individual/lib/libSM-1.2.6.tar.xz  libSM libSM-$ver 1
    ./autogen.sh
    ./configure --prefix=/app/libsm/current
    make -j$cpu_num
    create_app_in_tmp_and_link_it libsm $prefix$ver
    make install
    set_current_app_clean_strip_cd libsm $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libice" ]; then
  ver="1.1.2";
  if should_make libice $ver; then
    download_unpack_source https://xorg.freedesktop.org/archive/individual/lib/libICE-$ver.tar.xz  libICE libICE-$ver 1
    ./autogen.sh
    ./configure --prefix=/app/libice/current
    make -j$cpu_num
    create_app_in_tmp_and_link_it libice $prefix$ver
    make install
    set_current_app_clean_strip_cd libice $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "xauth" ]; then
#libxmuu-dev
  ver="1.1.5";
  if should_make xauth $ver; then
    download_unpack_source https://xorg.freedesktop.org/archive/individual/app/xauth-1.1.5.tar.xz xauth xauth-$ver 1
    ./autogen.sh
    ./configure --prefix=/app/xauth/current
    make -j$cpu_num
    create_app_in_tmp_and_link_it xauth $prefix$ver
    make install
    set_current_app_clean_strip_cd xauth $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "xterm" ]; then
  ver="4.12";
  if should_make xterm $ver; then
    download_unpack_source https://invisible-island.net/archives/xterm/xterm-412.tgz xterm xterm-412 1
#    ./autogen.sh
    ./configure --prefix=/app/xterm/current
    make -j$cpu_num
    create_app_in_tmp_and_link_it xterm $prefix$ver
    make install
    set_current_app_clean_strip_cd xterm $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "xinit" ]; then
  ver="1.4.4";
  if should_make xinit $ver; then
    download_unpack_source https://gitlab.freedesktop.org/xorg/app/xinit/-/archive/xinit-1.4.4/xinit-xinit-1.4.4.tar.bz2?ref_type=tags xinit xinit-xinit-$ver 1
    ./autogen.sh
    ./configure --prefix=/app/xinit/current
    make -j$cpu_num
    create_app_in_tmp_and_link_it xinit  $prefix$ver
    make install
    set_current_app_clean_strip_cd xinit $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libxft" ]; then
  ver="2.3.9";
  if should_make libxft $ver; then
    download_unpack_source https://gitlab.freedesktop.org/xorg/lib/libxft/-/archive/libXft-2.3.9/libxft-libXft-2.3.9.tar.bz2?ref_type=tags libxft libxft-libXft-$ver 1
    ./autogen.sh
    ./configure --prefix=/app/libxft/current
    make -j$cpu_num
    create_app_in_tmp_and_link_it libxft  $prefix$ver
    make install
    set_current_app_clean_strip_cd libxft $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "kitty" ]; then
#golang-go
  ver="0.49.2";
  if should_make kitty $ver; then
    download_unpack_source https://github.com/kovidgoyal/kitty/archive/refs/tags/v0.49.2.tar.gz kitty kitty-$ver 1
    ./dev.sh build
    create_app kitty $prefix$ver
    mkdir /app/kitty/$prefix$ver/bin
    cp kitty/launcher/kitty /app/kitty/$prefix$ver/bin
    set_current_app_clean_strip_cd kitty $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "xkbcomp" ]; then
  ver="1.5.0";
  if should_make xkbcomp $ver; then
    download_unpack_source https://xorg.freedesktop.org/archive/individual/app/xkbcomp-1.5.0.tar.xz xkbcomp xkbcomp-$ver 1
    ./configure --prefix=/app/xkbcomp/current
    make -j$cpu_num
    create_app_in_tmp_and_link_it xkbcomp $prefix$ver
    make install
    set_current_app_clean_strip_cd xkbcomp $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libxkbfile" ]; then
  ver="1.2.0";
  if should_make libxkbfile $ver; then
    download_unpack_source https://gitlab.freedesktop.org/xorg/lib/libxkbfile/-/archive/libxkbfile-1.2.0/libxkbfile-libxkbfile-1.2.0.tar.bz2?ref_type=tags libxkbfile libxkbfile-libxkbfile-$ver 1
    meson setup -Dprefix=/app/libxkbfile/current --buildtype release -Dlibdir=lib  _build
    meson compile -C _build
    create_app_in_tmp_and_link_it libxkbfile $prefix$ver
    meson install -C _build
    set_current_app_clean_strip_cd libxkbfile $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "pixman" ]; then
  ver="0.46.4";
  if should_make pixman $ver; then
    download_unpack_source https://gitlab.freedesktop.org/pixman/pixman/-/archive/pixman-0.46.4/pixman-pixman-0.46.4.tar.bz2?ref_type=tags pixman pixman-pixman-$ver 1
    meson setup -Dprefix=/app/pixman/current --buildtype release -Dlibdir=lib _build
    meson compile -C _build
    create_app_in_tmp_and_link_it pixman $prefix$ver
    meson install -C _build
    set_current_app_clean_strip_cd pixman $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libnice" ]; then
  ver="0.1.24";
  if should_make libnice $ver; then
    download_unpack_source https://gitlab.freedesktop.org/libnice/libnice/-/archive/0.1.24/libnice-0.1.24.tar.bz2?ref_type=tags libnice libnice-$ver 1
    meson setup -Dprefix=/app/libnice/current --buildtype release -Dlibdir=lib _build
    meson compile -C _build
    create_app_in_tmp_and_link_it libnice $prefix$ver
    meson install -C _build
    set_current_app_clean_strip_cd libnice $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libxfont2" ]; then
  ver="2.0.9";
  if should_make libxfont2 $ver; then
    download_unpack_source https://gitlab.freedesktop.org/xorg/lib/libxfont/-/archive/libXfont2-2.0.9/libxfont-libXfont2-2.0.9.tar.bz2?ref_type=tags libxfont libxfont-libXfont2-$ver 1
   ./autogen.sh
    ./configure --prefix=/app/libxfont2/current
    make -j$cpu_num
    create_app_in_tmp_and_link_it libxfont2 $prefix$ver
    make install
    set_current_app_clean_strip_cd libxfont2 $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libxcvt" ]; then
  ver="0.1.3";
  if should_make libxcvt $ver; then
    download_unpack_source https://gitlab.freedesktop.org/xorg/lib/libxcvt/-/archive/libxcvt-0.1.3/libxcvt-libxcvt-0.1.3.tar.bz2?ref_type=tags libxcvt libxcvt-libxcvt-$ver 1
    meson setup -Dprefix=/app/libxcvt/current --buildtype release -Dlibdir=lib _build
    meson compile -C _build
    create_app_in_tmp_and_link_it libxcvt $prefix$ver
    meson install -C _build
    set_current_app_clean_strip_cd libxcvt $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "seatd" ]; then
  ver="0.9.3";
  if should_make seatd $ver; then
    download_unpack_source https://github.com/kennylevinsen/seatd/archive/refs/tags/0.9.3.tar.gz seatd seatd-$ver 1
    meson setup -Dprefix=/app/seatd/current --buildtype release -Dlibdir=lib -Dlibseat-logind=disabled _build
    meson compile -C _build
    create_app_in_tmp_and_link_it seatd $prefix$ver
    meson install -C _build
    set_current_app_clean_strip_cd seatd $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libpng" ]; then
  ver="1.6.59";
  if should_make libpng $ver; then
    download_unpack_source https://sourceforge.net/projects/libpng/files/libpng16/1.6.59/libpng-1.6.59.tar.xz/download libpng libpng-$ver 1
    ./configure --prefix=/app/libpng/current
    make -j$cpu_num
    create_app_in_tmp_and_link_it libpng $prefix$ver
    make install
    set_current_app_clean_strip_cd libpng $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libfontenc" ]; then
  ver="1.1.9";
  if should_make libfontenc $ver; then
    download_unpack_source https://gitlab.freedesktop.org/xorg/lib/libfontenc/-/archive/libfontenc-1.1.9/libfontenc-libfontenc-1.1.9.tar.bz2?ref_type=tags libfontenc libfontenc-libfontenc-$ver 1
   ./autogen.sh
    ./configure --prefix=/app/libfontenc/current
    make -j$cpu_num
    create_app_in_tmp_and_link_it libfontenc $prefix$ver
    make install
    set_current_app_clean_strip_cd libfontenc $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "harfbuzz" ]; then
  ver="15.0.0";
  if should_make harfbuzz $ver; then
    download_unpack_source https://github.com/harfbuzz/harfbuzz/archive/refs/tags/15.0.0.tar.gz harfbuzz harfbuzz-$ver 1
    meson setup -Dprefix=/app/harfbuzz/current --buildtype release -Dlibdir=lib _build
    meson compile -C _build
    create_app_in_tmp_and_link_it harfbuzz $prefix$ver
    meson install -C _build
    cp COPYING /app/harfbuzz/current
    set_current_app_clean_strip_cd harfbuzz $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libepoxy" ]; then
  ver="1.5.10";
  if should_make libepoxy $ver; then
    download_unpack_source https://github.com/anholt/libepoxy/archive/refs/tags/1.5.10.tar.gz libepoxy libepoxy-$ver 1
    meson setup -Dprefix=/app/libepoxy/current --buildtype release -Dlibdir=lib _build
    meson compile -C _build
    create_app_in_tmp_and_link_it libepoxy $prefix$ver
    meson install -C _build
    set_current_app_clean_strip_cd libepoxy $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "xkeyboard-config" ]; then
  ver="2.44";
  if should_make xkeyboard-config $ver; then
    download_unpack_source http://www.x.org/releases/individual/data/xkeyboard-config/xkeyboard-config-2.44.tar.xz xkeyboard-config xkeyboard-config-$ver 1
    meson setup -Dprefix=/app/xkeyboard-config/current --buildtype release -Dlibdir=lib _build
    meson compile -C _build
    create_app_in_tmp_and_link_it xkeyboard-config $prefix$ver
    meson install -C _build
    set_current_app_clean_strip_cd xkeyboard-config $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "freetype" ]; then
  ver="2.15.0";
  if should_make freetype $ver; then
    download_unpack_source https://download.savannah.gnu.org/releases/freetype/freetype-2.15.0.tar.gz freetype  freetype-$ver 1
    ./configure --prefix=/app/freetype/current
    make -j$cpu_num
    create_app_in_tmp_and_link_it freetype $prefix$ver
    make install
    set_current_app_clean_strip_cd freetype $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "wayland-protocols" ]; then
  ver="1.49";
  if should_make wayland-protocols $ver; then
    download_unpack_source https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/1.49/downloads/wayland-protocols-1.49.tar.xz wayland-protocols wayland-protocols-$ver 1
    PKG_CONFIG_PATH=/app/wayland/current/lib/pkgconfig  meson setup -Dprefix=/app/wayland-protocols/current --buildtype release _build
    meson compile -C _build
    create_app_in_tmp_and_link_it wayland-protocols $prefix$ver
    meson install -C _build
    set_current_app_clean_strip_cd wayland-protocols $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "tecmake" ]; then
  ver="4.20";
  if should_make tecmake $ver; then
    download_unpack_source https://www.tecgraf.puc-rio.br/tecmake/download/tecmake.tar.gz tecmake . 1
    create_app tecmake $prefix$ver
    cp * /app/tecmake/$prefix$ver
    set_current_app_clean_strip_cd tecmake $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "lua" ]; then
  ver="5.5.0";
  if should_make lua $ver; then
    download_unpack_source https://www.lua.org/ftp/lua-5.5.0.tar.gz lua lua-$ver 1
    make linux
    create_app lua $prefix$ver
    make install INSTALL_TOP=/app/lua/$prefix$ver
    download_unpack_source https://sourceforge.net/projects/luabinaries/files/5.5.0/Docs%20and%20Sources/lua-5.5.0_Sources.tar.gz/download lua lua55 1
    cd src
    make -f Makefile.tecmake
    cp ../lib/Linux612_64/*.so /app/lua/$prefix$ver/lib
    mkdir /app/lua/current/lib/pkgconfig
    cp $curdir/in/lua/lua55.pc /app/lua/current/lib/pkgconfig
    set_current_app_clean_strip_cd lua $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "wayland" ]; then
  ver="1.26.0";
  if should_make wayland $ver; then
    download_unpack_source https://gitlab.freedesktop.org/wayland/wayland/-/releases/1.26.0/downloads/wayland-1.26.0.tar.xz wayland wayland-$ver 1
    meson setup -Dprefix=/app/wayland/current --buildtype release _build -Ddocumentation=false -Dlibdir=lib
    meson compile -C _build
    create_app_in_tmp_and_link_it wayland $prefix$ver
    meson install -C _build
    set_current_app_clean_strip_cd wayland $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "xkbcommon" ]; then
  ver="1.13.2";
  if should_make xkbcommon $ver; then
    download_unpack_source https://github.com/xkbcommon/libxkbcommon/archive/refs/tags/xkbcommon-1.13.2.tar.gz xkbcommon libxkbcommon-xkbcommon-$ver 1
    meson setup -Dprefix=/app/xkbcommon/current --buildtype release _build -Denable-x11=false -Denable-bash-completion=false
    meson compile -C _build
    create_app_in_tmp_and_link_it xkbcommon $prefix$ver
    meson install -C _build
    set_current_app_clean_strip_cd xkbcommon $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "hyprgraphics" ]; then
  ver="0.5.1";
#libmagic-dev
  if should_make hyprgraphics $ver; then
    download_unpack_source https://github.com/hyprwm/hyprgraphics/archive/refs/tags/v0.5.1.tar.gz hyprgraphics hyprgraphics-$ver 1
    cmake -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/app/hyprgraphics/current \
      -S . -B ./build \
      -D CMAKE_PREFIX_PATH="/app/hyprutils/current"
    create_app_in_tmp_and_link_it hyprgraphics $prefix$ver
    cmake --build ./build --config Release --target all -j$cpu_num
    create_app_in_tmp_and_link_it hyprgraphics $prefix$ver
    cmake --install build
    set_current_app_clean_strip_cd hyprgraphics $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "hyprlang" ]; then
  ver="0.6.8";
  if should_make hyprlang $ver; then
    download_unpack_source https://github.com/hyprwm/hyprlang/archive/refs/tags/v0.6.8.tar.gz hyprlang hyprlang-$ver 1
    cmake -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/app/hyprlang/current \
      -D CMAKE_PREFIX_PATH="/app/hyprutils/current" \
      -S . -B ./build
    create_app_in_tmp_and_link_it hyprlang $prefix$ver
    cmake --build ./build --config Release --target all -j$cpu_num
    create_app_in_tmp_and_link_it hyprlang $prefix$ver
    cmake --install build
    set_current_app_clean_strip_cd hyprlang $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "hyprcursor" ]; then
#libcairo-dev libzip-dev libtomlplusplus-dev librsvg2-dev
  ver="0.1.13";
  if should_make hyprcursor $ver; then
    download_unpack_source https://github.com/hyprwm/hyprcursor/archive/refs/tags/v0.1.13.tar.gz hyprcursor hyprcursor-$ver 1
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/app/hyprcursor/current \
      -DBUILD_TESTS=OFF \
      -D CMAKE_PREFIX_PATH="/app/hyprlang/current;/app/hyprutils/current" \
      -S . -B ./build -G Ninja
    cd build
    ln -s /app/hyprutils/current/lib/libhyprutils.so.13 .
    cd ..
    cmake --build ./build --config Release --target all -j$cpu_num
    create_app_in_tmp_and_link_it hyprcursor $prefix$ver
    cmake --install build
    set_current_app_clean_strip_cd hyprcursor $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "hyprwayland-scanner" ]; then
  ver="0.4.6";
  if should_make hyprwayland-scanner $ver; then
    #libpugixml-dev
    download_unpack_source https://github.com/hyprwm/hyprwayland-scanner/archive/refs/tags/v$ver.tar.gz hyprwayland hyprwayland-scanner-$ver 1
    cmake -DCMAKE_INSTALL_PREFIX=/app/hyprwayland-scanner/current -B build
    cmake --build build -j $cpu_num
    create_app_in_tmp_and_link_it hyprwayland-scanner $prefix$ver
    cmake --install build
    set_current_app_clean_strip_cd hyprwayland-scanner $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "hyprutils" ]; then
  ver="0.14.2";
  if should_make hyprutils $ver; then
    download_unpack_source https://github.com/hyprwm/hyprutils/archive/refs/tags/v$ver.tar.gz hyprutils hyprutils-$ver 1
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/app/hyprutils/current -S . -B ./build
    cmake --build ./build --config Release --target all -j $cpu_num
    create_app_in_tmp_and_link_it hyprutils $prefix$ver
    cmake --install build
    set_current_app_clean_strip_cd hyprutils $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "aquamarine" ]; then
  #libseat-dev libinput-dev libdisplay-info-dev hwdata libpixman-1-dev
  ver="0.15.1";
  if should_make aquamarine $ver; then
    download_unpack_source https://github.com/hyprwm/aquamarine/archive/refs/tags/v0.15.1.tar.gz aquamarine aquamarine-$ver 1
    PATH=$PATH:/app/hyprwayland-scanner/current/bin && cmake --no-warn-unused-cli \
      -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/app/aquamarine/current \
      -D CMAKE_PREFIX_PATH="/app/hyprutils/current;/app/hyprwayland-scanner/current" \
      -S . -B ./build
    cmake --build ./build --config Release --target all -j$cpu_num
    create_app_in_tmp_and_link_it aquamarine $prefix$ver
    cmake --install build
    set_current_app_clean_strip_cd aquamarine $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "mediainfo" ]; then
#in progress
  ver="26.10";
  if should_make mediainfo $ver; then
#apt-get install git automake autoconf libtool pkg-config make g++ zlib1g-dev
#libzen-dev
    download_unpack_source https://github.com/MediaArea/MediaInfo/archive/refs/tags/v$ver.tar.gz mediainfo MediaInfo-$ver 1
    cd Project/GNU/CLI
    ./autogen.sh
    ./configure --prefix=/app/mediainfo/current --enable-shared
    make -j$cpu_num
    create_app_in_tmp_and_link_it mediainfo $prefix$ver
    make install
#    set_current_app_clean_strip_cd hyprutils $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "grub" ]; then
  ver="2.16";
  if should_make grub $ver; then
    install_host_deps "autoconf-archive"
    download_unpack_source https://gitlab.freedesktop.org/gnu-grub/grub/-/archive/grub-$ver/grub-grub-$ver.tar.gz?ref_type=tags grub grub-grub-$ver 1
    ./bootstrap
    ./autogen.sh
    ./configure --prefix=/app/grub/$prefix$ver --target=x86_64 --with-platform=efi
    make all -j$cpu_num
    create_app grub $prefix$ver
    make install
    set_current_app_clean_strip_cd grub $prefix$ver 1 #ignors lib in stripping
  fi
fi

if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "efivar" ]; then
  ver="39";
  if should_make efivar $ver; then
    install_host_deps "mandoc"
    download_unpack_source https://github.com/rhboot/efivar/archive/refs/tags/$ver.tar.gz efivar efivar-$ver 1
    make -j$cpu_num
    create_app efivar $prefix$ver
    make install PREFIX=/app/efivar/$prefix$ver
    mv /app/efivar/$prefix$ver/lib64 /app/efivar/$prefix$ver/lib
    set_current_app_clean_strip_cd efivar $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "efibootmgr" ]; then
  ver="18";
  if should_make efibootmgr $ver; then
    install_host_deps "libefivar-dev efivar pkg-config libefiboot-dev"
    download_unpack_source https://github.com/rhboot/efibootmgr/releases/download/$ver/efibootmgr-$ver.tar.bz2 efibootmgr efibootmgr-$ver 1
    make -j$cpu_num EFIDIR=/app/efibootmgr/$prefix$ver/dynamic
    create_app efibootmgr $prefix$ver
    mkdir /app/efibootmgr/$prefix$ver/dynamic
    make install EFIDIR=/app/efibootmgr/$prefix$ver/dynamic DESTDIR=/app/efibootmgr/$prefix$ver
    set_current_app_clean_strip_cd efibootmgr $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "shim" ]; then
  # Source https://github.com/rhboot/shim
  # Currently we take signed package from the https://koji.fedoraproject.org/koji/packageinfo?packageID=14502
  # This must be resolved in the future
  ver="16.1-9";
  if should_make shim $ver; then
    download_unpack_source https://kojipkgs.fedoraproject.org//packages/shim/16.1/9/x86_64/shim-x64-$ver.x86_64.rpm shim shim-$ver 1
    create_app shim $prefix$ver
    cd usr/lib/efi/shim/$ver/EFI
    rsync -a . "$output/app/shim/$prefix$ver"
    set_current_app_clean_strip_cd shim $prefix$ver 0
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "crispy-doom" ]; then
  ver="7.2";
  if should_make crispy-doom $ver; then
    download_unpack_source https://github.com/fabiangreffrath/crispy-doom/archive/refs/tags/crispy-doom-7.2.tar.gz crispy-doom crispy-doom-crispy-doom-$ver 1
PKG_CONFIG_PATH=/app/sdl/261015_2.32.10/lib/pkgconfig ./autogen.sh --disable-sdl2mixer  --disable-sdl2net
    ./configure --installprefix=/app/cripsy-doom/current --disable-sdl2mixer  --disable-sdl2net
    make -j$cpu_num
#    PKG_CONFIG_PATH=/app/wayland/current/lib/pkgconfig  meson setup -Dprefix=/app/wayland-protocols/current --buildtype release _build
#    meson compile -C _build
#    create_app_in_tmp_and_link_it wayland-protocols $prefix$ver
#    meson install -C _build
#    set_current_app_clean_strip_cd wayland-protocols $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "chezscheme" ]; then
  ver="10.4.1";
  if should_make chezscheme $ver; then
    download_unpack_source https://github.com/cisco/ChezScheme/releases/download/v$ver/csv$ver.tar.gz chezscheme csv$ver 1
    ./configure --installprefix=$output/app/chezscheme/$prefix$ver
    make -j$cpu_num
    create_app chezscheme $prefix$ver
    make install
    remove_duplicates_cd $output/app/chezscheme/$prefix$ver/lib/csv$ver/ta6le
    set_current_app_clean_strip_cd chezscheme $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "lm-sensors" ]; then
  ver="3-6-2";
  if should_make lm-sensors $ver; then
    download_unpack_source https://github.com/lm-sensors/lm-sensors/archive/refs/tags/V$ver.tar.gz lm-sensors lm-sensors-$ver 1
    make -j$cpu_num
    create_app lm-sensors $prefix$ver
    make install PREFIX=$output/app/lm-sensors/$prefix$ver
    set_current_app_clean_strip_cd lm-sensors $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "brotli" ]; then
  ver="1.2.0";
  if should_make brotli $ver; then
    download_unpack_source https://github.com/google/brotli/archive/refs/tags/v$ver.tar.gz brotli brotli-$ver 1
    mkdir out && cd out
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$output/app/brotli/$prefix$ver ..
    create_app brotli $prefix$ver
    cmake --build . --config Release --target install
    set_current_app_clean_strip_cd brotli $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "json-c" ]; then
  ver="0.19-20260627";
  if should_make json-c $ver; then
    download_unpack_source https://github.com/json-c/json-c/archive/refs/tags/json-c-$ver.tar.gz json-c json-c-json-c-$ver 1
    meson setup -Dprefix=$output/app/json-c/$prefix$ver --buildtype release _build
    meson compile -C _build
    create_app json-c $prefix$ver
    meson install -C _build
    rsync -a $output/app/json-c/$prefix$ver/lib/x86_64-linux-gnu/* $output/app/json-c/$prefix$ver/lib
    rm -r $output/app/json-c/$prefix$ver/lib/x86_64-linux-gnu/
    set_current_app_clean_strip_cd json-c $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libssh" ]; then
  ver="0.11";
  if should_make libssh $ver; then
    download_unpack_source https://git.libssh.org/projects/libssh.git/snapshot/stable-$ver.tar.gz libssh stable-$ver 1
    mkdir build
    cd build
    create_app libssh $prefix$ver
    set_current_app libssh $prefix$ver 1
    cmake -DCMAKE_INSTALL_PREFIX=/app/libssh/current -DCMAKE_BUILD_TYPE=Release ..
    make
    make install
#    echo "" >> /app/libssh/current/readme.md
#    echo "**Last**" >> /app/libssh/current/readme.md
#    echo "$LATEST_FILE_UPDATE" >> /app/libssh/current/readme.md
    set_current_app_clean_strip_cd libssh $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "dosfstools" ]; then
  ver="4.2";
  if should_make libssh $ver; then
    download_unpack_source https://github.com/dosfstools/dosfstools/releases/download/v4.2/dosfstools-4.2.tar.gz dosfstools dosfstools-$ver 1
    ./configure --prefix=$output/app/dosfstools/$prefix$ver
    make all -j$cpu_num
    create_app dosfstools $prefix$ver
    make install
    set_current_app_clean_strip_cd dosfstools $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "usbutils" ]; then
  ver="019";
  if should_make usbutils $ver; then
    download_unpack_source https://github.com/gregkh/usbutils/archive/refs/tags/v$ver.tar.gz usbutils usbutils-$ver 1
    install_host_deps "libusb-dev libudev-dev"
    meson setup -Dprefix=$output/app/usbutils/$prefix$ver _build
    meson compile -C _build
    create_app usbutils $prefix$ver
    meson install -C _build
    set_current_app_clean_strip_cd usbutils $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libexpat" ]; then
  ver="2.9.0";
  if should_make libexpat $ver; then
    download_unpack_source https://github.com/libexpat/libexpat/releases/download/R_2_9_0/expat-2.9.0.tar.xz libexpat expat-$ver 1
    ./configure --prefix=/app/libexpat/current
    make all -j$cpu_num
    create_app libexpat $prefix$ver
    set_current_app libexpat $prefix$ver 1
    make install
    echo "" >> /app/libexpat/current/readme.md
    echo "**Last**" >> /app/libexpat/current/readme.md
    echo "$LATEST_FILE_UPDATE" >> /app/libexpat/current/readme.md
    set_current_app_clean_strip_cd libexpat $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "sdl" ]; then
  ver="2.32.10";
  if should_make sdl $ver; then
    install_host_deps "cmake ninja-build libasound2-dev libpulse-dev \
    libaudio-dev libfribidi-dev libjack-dev libsndio-dev libx11-dev libxext-dev \
    libxrandr-dev libxcursor-dev libxfixes-dev libxi-dev libxss-dev libxtst-dev \
    libxkbcommon-dev libdrm-dev libgbm-dev libgl1-mesa-dev libgles2-mesa-dev \
    libegl1-mesa-dev libdbus-1-dev libibus-1.0-dev libudev-dev libthai-dev libusb-1.0-0-dev"
    download_unpack_source https://github.com/libsdl-org/SDL/archive/refs/tags/release-2.32.10.tar.gz sdl SDL-release-$ver 1
    ./configure --enable-rpath --enable-video-directfb --enable-directfb-shared --enable-video-kmsdrm --enable-kmsdrm-shared \
          --enable-video-opengl --enable-video-opengles --enable-video-opengles1 --enable-video-opengles2 \
          --disable-video-x11 --disable-video-wayland \
          --disable-libudev --disable-dbus --prefix=/app/sdl/current
    make -j$cpu_num
    create_app sdl $prefix$ver
    set_current_app sdl $prefix$ver 1
    make install
    cd test
    ./configure --prefix=/app/sdl/current --with-sdl-prefix=/app/sdl/current
    make -j$cpu_num
    make install
    set_current_app_clean_strip_cd sdl $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "sdl3" ]; then
  ver="3.4.16";
  if should_make sdl $ver; then
    install_host_deps "cmake ninja-build libasound2-dev libpulse-dev \
    libaudio-dev libfribidi-dev libjack-dev libsndio-dev libx11-dev libxext-dev \
    libxrandr-dev libxcursor-dev libxfixes-dev libxi-dev libxss-dev libxtst-dev \
    libxkbcommon-dev libdrm-dev libgbm-dev libgl1-mesa-dev libgles2-mesa-dev \
    libegl1-mesa-dev libdbus-1-dev libibus-1.0-dev libudev-dev libthai-dev libusb-1.0-0-dev"
    download_unpack_source https://github.com/libsdl-org/SDL/releases/download/release-3.4.16/SDL3-3.4.16.tar.gz sdl SDL3-$ver 1
    cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
       -DSDL_KMSDRM=ON \
       -DSDL_TESTS=ON -DSDL_TEST_LIBRARY=ON -DSDL_INSTALL_TESTS=ON \
       -DSDL_LIBUDEV=OFF -DSDL_STATIC=OFF -DSDL_RPATH=OFF \
       -DSDL_DBUS=OFF -DSDL_IBUS=OFF -DSDL_LIBTHAI=OFF \
       -DSDL_WAYLAND=OFF -DSDL_X11=OFF -DSDL_UNIX_CONSOLE_BUILD=ON
    cmake --build build
    create_app sdl $prefix$ver
    cmake --install build --prefix $output/app/sdl/$prefix$ver
    set_current_app_clean_strip_cd sdl $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "libdrm" ]; then
  ver="2.4.134";
  if should_make libdrm $ver; then
    download_unpack_source https://dri.freedesktop.org/libdrm/libdrm-$ver.tar.xz libdrm libdrm-$ver 1
    meson setup builddir/ --prefix=/app/libdrm/$prefix$ver
    create_app libdrm $prefix$ver
    ninja -C builddir/ install
    rsync -a $output/app/libdrm/$prefix$ver/lib/x86_64-linux-gnu/* $output/app/libdrm/$prefix$ver/lib
    rm -r $output/app/libdrm/$prefix$ver/lib/x86_64-linux-gnu/
    set_current_app_clean_strip_cd libdrm $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libxcb" ]; then
  ver="1.17.0";
  if should_make libxcb $ver; then
    install_host_deps "python3-xcbgen xcb-proto"
    download_unpack_source https://xorg.freedesktop.org/archive/individual/lib/libxcb-1.17.0.tar.xz libxcb libxcb-$ver 1
    ./configure --prefix=/app/libxcb/current
    make all -j$cpu_num
    create_app libxcb $prefix$ver
    set_current_app libxcb $prefix$ver 1
    make install
    set_current_app_clean_strip_cd libxcb $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libxcb-renderutil" ]; then
  ver="0.3.10";
  if should_make libxcb-renderutil $ver; then
    download_unpack_source https://xorg.freedesktop.org/archive/individual/lib/xcb-util-renderutil-$ver.tar.xz xcb-util-renderutil xcb-util-renderutil-$ver 1
    ./configure --prefix=/app/libxcb-renderutil/current
    make all -j$cpu_num
    create_app_in_tmp_and_link_it libxcb-renderutil $prefix$ver
    make install
    set_current_app_clean_strip_cd libxcb-renderutil $prefix$ver 1
  fi
fi
#if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libxcb-errors" ]; then
#  ver="1.0.1";
#  if should_make libxcb-errors $ver; then
#    download_unpack_source https://gitlab.freedesktop.org/xorg/lib/libxcb-errors/-/archive/xcb-util-errors-1.0.1/libxcb-errors-xcb-util-errors-1.0.1.tar.gz?ref_type=tags libxcb-errors libxcb-errors-xcb-util-errors-$ver 1
#    ./autogen.sh
#    ./configure --prefix=/app/libxcb-errors/current
#    make all -j$cpu_num
#    create_app libxcb-errors $prefix$ver
#    set_current_app libxcb-errors $prefix$ver 1
#    make install
#    set_current_app_clean_strip_cd libxcb-error $prefix$ver 1
#  fi
#fi
#if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "xcb-util" ]; then
#  ver="0.4.1";
#  if should_make xcb-util $ver; then
#    download_unpack_source https://xorg.freedesktop.org/archive/individual/lib/xcb-util-$ver.tar.xz xcb-util xcb-util-$ver 1
#    ./configure --prefix=/app/xcb-util/current
#    make all -j$cpu_num
#    create_app xcb-util $prefix$ver
#    set_current_app xcb-util $prefix$ver 1
#    make install
#    set_current_app_clean_strip_cd xcb-util $prefix$ver 1
#  fi
#fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libxau" ]; then
  ver="1.0.12";
  if should_make libxau $ver; then
    download_unpack_source https://xorg.freedesktop.org/archive/individual/lib/libXau-$ver.tar.xz libxau libXau-$ver 1
    ./configure --prefix=/app/libxau/current
    make all -j$cpu_num
    create_app libxau $prefix$ver
    set_current_app libxau $prefix$ver 1
    make install
#    echo "" >> /app/libexpat/current/readme.md
#    echo "**Last**" >> /app/libexpat/current/readme.md
#    echo "$LATEST_FILE_UPDATE" >> /app/libexpat/current/readme.md
    set_current_app_clean_strip_cd libxau $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libxdmcp" ]; then
  ver="1.1.5";
  if should_make libxdmcp $ver; then
    download_unpack_source https://xorg.freedesktop.org/archive/individual/lib/libXdmcp-$ver.tar.xz libxdmcp libXdmcp-$ver 1
    ./configure --prefix=/app/libxdmcp/current
    make all -j$cpu_num
    create_app libxdmcp $prefix$ver
    set_current_app libxdmcp $prefix$ver 1
    make install
#    echo "" >> /app/libexpat/current/readme.md
#    echo "**Last**" >> /app/libexpat/current/readme.md
#    echo "$LATEST_FILE_UPDATE" >> /app/libexpat/current/readme.md
    set_current_app_clean_strip_cd libxdmcp $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libpciaccess" ]; then
  ver="0.19";
  if should_make libpciaccess $ver; then
    download_unpack_source https://xorg.freedesktop.org/archive/individual/lib/libpciaccess-$ver.tar.xz libpciaccess libpciaccess-$ver 1
    meson setup -Dprefix=/app/libpciaccess/$prefix$ver _build
    meson compile -C _build
    create_app libpciaccess $prefix$ver
    set_current_app libpciaccess $prefix$ver 1
    meson install -C _build
    rsync -a $output/app/json-c/$prefix$ver/lib/x86_64-linux-gnu/* $output/app/json-c/$prefix$ver/lib
    rm -r $output/app/json-c/$prefix$ver/lib/x86_64-linux-gnu/
#    echo "" >> /app/libexpat/current/readme.md
#    echo "**Last**" >> /app/libexpat/current/readme.md
#    echo "$LATEST_FILE_UPDATE" >> /app/libexpat/current/readme.md
    set_current_app_clean_strip_cd libpciaccess $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libglvnd" ]; then
  ver="1.7.0";
  if should_make libglvnd $ver; then
    download_unpack_source https://gitlab.freedesktop.org/glvnd/libglvnd/-/archive/v1.7.0/libglvnd-v1.7.0.tar.gz libglvnd libglvnd-v$ver 1
    meson setup -Dprefix=/app/libglvnd/$prefix$ver _build
    meson compile -C _build
    create_app libglvnd $prefix$ver
    set_current_app libglvnd $prefix$ver 1
    meson install -C _build
    rsync -a $output/app/libglvnd/$prefix$ver/lib/x86_64-linux-gnu/* $output/app/libglvnd/$prefix$ver/lib
    rm -r $output/app/libglvnd/$prefix$ver/lib/x86_64-linux-gnu/
    set_current_app_clean_strip_cd libglvnd $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "vulkan-loader" ]; then
  ver="1.4.309";
 # ver="1.4.364";
# need to remove vulkan-headers from host system? inteferfering with compilation?
  if should_make vulkan-loader $ver; then
    download_unpack_source https://github.com/KhronosGroup/Vulkan-Loader/archive/refs/tags/v$ver.tar.gz vulkan-loader Vulkan-Loader-$ver 1
    mkdir build
    cd build
    cmake -D CMAKE_BUILD_TYPE=Release \
      -D VULKAN_HEADERS_INSTALL_DIR=/app/vulkan-loader/current \
      -D CMAKE_INSTALL_PREFIX=/app/vulkan-loader/current \
      -D CMAKE_SKIP_INSTALL_RPATH=ON \
      -D BUILD_WSI_WAYLAND_SUPPORT=OFF \
      -D UPDATE_DEPS=ON ..
    make -j$cpu_num
    create_app_in_tmp_and_link_it vulkan-loader $prefix$ver
    make install
    set_current_app_clean_strip_cd vulkan-loader $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "volk" ]; then
  ver="1.4.350";
  if should_make volk $ver; then
    download_unpack_source https://github.com/zeux/volk/archive/refs/tags/$ver.tar.gz volk volk-$ver 1
    cmake -D CMAKE_BUILD_TYPE=Release -DVOLK_INSTALL=ON \
      -D CMAKE_INSTALL_PREFIX=/app/volk/current \
      -D CMAKE_SKIP_INSTALL_RPATH=ON .
    make -j$cpu_num
    create_app_in_tmp_and_link_it volk $prefix$ver
    make install
    set_current_app_clean_strip_cd volk $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "vulkan-tools" ]; then
  ver="1.4.309";
 # ver="1.4.364";
  if should_make vulkan-tools $ver; then
    download_unpack_source https://github.com/KhronosGroup/Vulkan-Tools/archive/refs/tags/v$ver.tar.gz vulkan-tools Vulkan-Tools-$ver 1
    mkdir build
    cd build
    cmake -D CMAKE_BUILD_TYPE=Release \
      -D CMAKE_PREFIX_PATH=/app/volk-dev/current \
      -D CMAKE_INSTALL_PREFIX=/app/vulkan-tools/current \
      -D CMAKE_SKIP_INSTALL_RPATH=ON ..
    make -j$cpu_num
    create_app_in_tmp_and_link_it vulkan-tools $prefix$ver
    make install
    set_current_app_clean_strip_cd vulkan-tools $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libdisplay-info" ]; then
#  ver="0.4.0";
  ver="0.2.0";
  if should_make libdisplay-info $ver; then
    download_unpack_source https://gitlab.freedesktop.org/emersion/libdisplay-info/-/releases/$ver/downloads/libdisplay-info-$ver.tar.xz \
          libdisplay-info libdisplay-info-$ver 1
    meson setup -Dprefix=/app/libdisplay-info/current _build
    meson compile -C _build
    create_app_in_tmp_and_link_it libdisplay-info $prefix$ver
    meson install -C _build
    rsync -a /app/libdisplay-info/current/lib/x86_64-linux-gnu/* /app/libdisplay-info/current/lib
    rm -r /app/libdisplay-info/current/lib/x86_64-linux-gnu/
    set_current_app_clean_strip_cd libdisplay-info $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libX11" ]; then
  ver="1.8.13";
  if should_make libx11 $ver; then
    download_unpack_source https://xorg.freedesktop.org/archive/individual/lib/libX11-$ver.tar.xz libX11 libX11-$ver 1
    ./configure --prefix=/app/libx11/current
    make all -j$cpu_num
    create_app libx11 $prefix$ver
    set_current_app libx11 $prefix$ver 1
    make install
#    echo "" >> /app/libexpat/current/readme.md
#    echo "**Last**" >> /app/libexpat/current/readme.md
#    echo "$LATEST_FILE_UPDATE" >> /app/libexpat/current/readme.md
    set_current_app_clean_strip_cd libx11 $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libxshmfence" ]; then
  ver="1.3.3";
  if should_make libxshmfence $ver; then
    download_unpack_source https://xorg.freedesktop.org/archive/individual/lib/libxshmfence-$ver.tar.xz libxshmfence libxshmfence-$ver 1
    ./configure --prefix=/app/libxshmfence/current
    make all -j$cpu_num
    create_app libxshmfence $prefix$ver
    set_current_app libxshmfence $prefix$ver 1
    make install
#    echo "" >> /app/libexpat/current/readme.md
#    echo "**Last**" >> /app/libexpat/current/readme.md
#    echo "$LATEST_FILE_UPDATE" >> /app/libexpat/current/readme.md
    set_current_app_clean_strip_cd libxshmfence $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libffi" ]; then
  ver="3.8.0";
  if should_make libffi $ver; then
    download_unpack_source https://github.com/libffi/libffi/archive/refs/tags/v3.8.0.tar.gz libffi libffi-$ver 1
    ./autogen.sh
    ./configure --prefix=/app/libffi/current
    make all -j$cpu_num
    create_app libffi $prefix$ver
    set_current_app libffi $prefix$ver 1
    make install
#    echo "" >> /app/libexpat/current/readme.md
#    echo "**Last**" >> /app/libexpat/current/readme.md
#    echo "$LATEST_FILE_UPDATE" >> /app/libexpat/current/readme.md
    set_current_app_clean_strip_cd libffi $prefix$ver 1
  fi
fi
if [ "$package" == "fs2" ] || [ "$package" == "fsmin2" ] || [ "$package" == "llvm" ]; then
  #  ver="23.1.3";
  ver="19.1.7";   #we use this version because of dep from mesa. Maybe should be more investigated, if 23.* could be used
  if should_make llvm $ver; then
    download_unpack_source https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-$ver.tar.gz llvm llvm-project-llvmorg-$ver 1
    cmake -S llvm -B builddir -G Ninja \
       -DCMAKE_SKIP_INSTALL_RPATH=ON \
       -DLLVM_ENABLE_RTTI=ON \
       -DCLANG_DEFAULT_PIE_ON_LINUX=ON \
       -DLLVM_ENABLE_FFI=ON \
       -DCMAKE_BUILD_TYPE=MinSizeRel -DLLVM_TARGETS_TO_BUILD="X86;AMDGPU" \
       -DCMAKE_INSTALL_PREFIX=/app/llvm/current \
       -DLLVM_BUILD_LLVM_DYLIB=ON -DLLVM_LINK_LLVM_DYLIB=ON \
       -DLLVM_ENABLE_PROJECTS=clang -DLLVM_ENABLE_RUNTIMES=compiler-rt
    create_app llvm $prefix$ver
    set_current_app llvm $prefix$ver 1
    ninja -C builddir install
    set_current_app_clean_strip_cd llvm $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "mesa" ]; then
  # ver="26.2.4";  # not possible because of -Degl-native-platform=drm
  ver="26.1.8"; #OK with GL
#ver="25.3.6";
  if should_make mesa $ver; then
    # sudo apt-get build-dep mesa
    # python3-pycparser
    download_unpack_source https://archive.mesa3d.org/mesa-$ver.tar.xz mesa mesa-$ver 1
    meson setup -Dprefix=/app/mesa/current _build \
       -Dbuildtype=minsize -Ddebug=false -Dstrip=true -Dlibdir=lib -Dvideo-codecs=all -Dlibunwind=disabled \
       -Dgles1=enabled -Dgles2=enabled -Dglvnd=enabled \
       -Dplatforms=x11 \
       -Dgallium-drivers="asahi,crocus,ethosu,etnaviv,freedreno,i915,iris,lima,llvmpipe,nouveau,panfrost,r300,r600,radeonsi,rocket,softpipe,svga,tegra,v3d,vc4,virgl,zink" \
       -Dgallium-d3d12-graphics=disabled -Dgallium-d3d12-video=disabled \
       -Dvulkan-drivers="amd,broadcom,freedreno,intel,intel_hasvk,panfrost,swrast,virtio,imagination,nouveau,asahi,gfxstream,kosmickrisp" \
       -Dvulkan-layers="device-select,intel-nullhw,overlay" \
       -Dglx=dri -Degl-native-platform=drm
    meson compile -C _build
    create_app_in_tmp_and_link_it mesa $prefix$ver
    meson install -C _build
    set_current_app_clean_strip_cd mesa $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "swiftshader" ]; then
  ver="1";
  if should_make swiftshader $ver; then
    download_unpack_source https://github.com/google/swiftshader/archive/refs/heads/master.zip swiftshader swiftshader-master 1
    cd third_party
    git clone https://github.com/google/googletest.git
    git clone https://github.com/KhronosGroup/glslang.git
    cd ..
#          -DSWIFTSHADER_BUILD_WSI_DIRECTFB=true \
    cmake -S . -DCMAKE_INSTALL_PREFIX=/app/swiftshader/current -DSWIFTSHADER_BUILD_WSI_WAYLAND=false \
     -DSWIFTSHADER_BUILD_WSI_D2D=true  -B build
    cmake --build build
    create_app_in_tmp_and_link_it swiftshader $prefix$ver
#    cmake --install build #installs everything excluding important files
    mkdir /app/swiftshader/current/lib
    cp build/Linux/libvk_swiftshader.so /app/swiftshader/current/lib
    cp build/Linux/vk_swiftshader_icd.json /app/swiftshader/current/lib
    cd /app/swiftshader/current/lib
    ln -s libvk_swiftshader.so libvulkan.so.1
    set_current_app_clean_strip_cd swiftshader $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libudev-zero" ]; then
  ver="1.0.5";
  if should_make libudev-zero $ver; then
    download_unpack_source https://github.com/illiliti/libudev-zero/archive/refs/tags/1.0.5.tar.gz libudev-zero libudev-zero-$ver 1
    #    install_host_deps "libusb-dev libudev-dev"
    meson setup -Dprefix=/app/libudev-zero/$prefix$ver _build
    meson compile -C _build
    create_app libudev-zero $prefix$ver
    meson install -C _build
    rsync -a $output/app/libudev-zero/$prefix$ver/lib/x86_64-linux-gnu/* $output/app/libudev-zero/$prefix$ver/lib
    rm -r $output/app/libudev-zero/$prefix$ver/lib/x86_64-linux-gnu/
    set_current_app_clean_strip_cd libudev-zero $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "memtest86plus" ]; then
  ver="9.00";
  if should_make memtest86plus $ver; then
    download_unpack_source https://github.com/memtest86plus/memtest86plus/archive/refs/tags/v9.00.tar.gz memtest86plus memtest86plus-$ver 1
    cd build/x86_64
    make
    create_app memtest86plus $prefix$ver
    cp mt86plus $output/app/memtest86plus/$prefix$ver/mt86plus.efi
    set_current_app_clean_strip_cd memtest86plus $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "python" ]; then
#  ver="3.15.0";
  ver="3.14.0";
  if should_make python $ver; then
    download_unpack_source https://github.com/python/cpython/archive/refs/tags/v$ver.tar.gz cpython cpython-$ver 1
    ./configure --prefix=/app/python/current --enable-shared
    make all -j$cpu_num
    create_app_in_tmp_and_link_it python $prefix$ver
    make install
    set_current_app_clean_strip_cd python $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "perl" ]; then
  ver="5.44.0";
  if should_make perl $ver; then
    download_unpack_source https://www.cpan.org/src/5.0/perl-$ver.tar.gz perl perl-$ver 1
    ./Configure -d -Dprefix=/app/perl/current -e
    make -j$cpu_num
    create_app_in_tmp_and_link_it perl $prefix$ver
    ./perl -Ilib -I. installperl --destdir=/
    remove_duplicates_cd /tmp/installit/bin
    set_current_app_clean_strip_cd perl $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "node" ]; then
  ver="26.10.0";
  if should_make node $ver; then
    download_unpack_source https://github.com/nodejs/node/archive/refs/tags/v26.10.0.tar.gz node node-$ver 1
    ./configure --prefix=$output/app/node/$prefix$ver --ninja
    make all -j$cpu_num
    create_app node $prefix$ver
    make install
    set_current_app_clean_strip_cd node $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "i2c-tools" ]; then
  ver="4.4";
  if should_make i2c-tools $ver; then
    download_unpack_source https://www.kernel.org/pub/software/utils/i2c-tools/i2c-tools-$ver.tar.xz i2c-tools i2c-tools-$ver 1
    sed -i "s/\/usr\/local/\/app\/i2c-tools\/$prefix$ver/g" Makefile
    make all -j$cpu_num
    create_app i2c-tools $prefix$ver
    make install
    set_current_app_clean_strip_cd i2c-tools $prefix$ver 1
  fi
fi
if [ "$package" == "fs2" ] || [ "$package" == "php" ]; then
#work in progress
#libsqlite3-dev
  ver="8.5.11";
  if should_make php $ver; then
    install_host_deps "re2c"
    download_unpack_source https://github.com/php/php-src/archive/refs/tags/php-8.5.11.tar.gz php php-src-php-$ver 1
    autoconf
    ./configure --prefix=/app/php/current
    make all -j$cpu_num
    create_app_in_tmp_and_link_it php $prefix$ver
    make install
#    set_current_app_clean_strip_cd php $prefix$ver 1
  fi
fi
if [ "$package" == "fs" ] || [ "$package" == "v" ]; then
#work in progress
  ver="0.5.2";
  if should_make v $ver; then
     [ -d /tmp/doit/v ] || mkdir /tmp/doit/v
      cd /tmp/doit
     git clone https://github.com/vlang/v.git
     cd v
    make -j$cpu_num
    create_app_in_tmp_and_link_it v $prefix$ver
    cp v /tmp/installit
#    set_current_app_clean_strip_cd v $prefix$ver 1
  fi
fi
if [ "$package" == "fs2" ] || [ "$package" == "fpc" ]; then
#Free Pascal Compiler
#work in progress
  ver="3.2.2";
  if should_make fpc $ver; then
    download_unpack_source http://downloads.freepascal.org/fpc/dist/3.2.2/source/fpc-3.2.2.source.tar.gz fpc fpc-$ver 1
#    autoconf
#    ./configure --prefix=$output/app/v/$prefix$ver
#    make all -j$cpu_num
#    create_app v $prefix$ver
#    make install
#    set_current_app_clean_strip_cd php $prefix$ver 1
  fi
fi
if [ "$package" == "fs2" ] || [ "$package" == "ccadb" ]; then
  ver="${prefix:0:6}";
  if should_make ccadb $ver; then
    download_unpack_source https://ccadb.my.salesforce-sites.com/mozilla/IncludedRootsPEMTxt?TrustBitsInclude=Websites ccadb_$ver . 1
    create_app ccadb $prefix$ver
    rm *.pem
    listnr=1
    while read -r line; do
      case $line in 
      *BEGIN*) listnr=$(($listnr+1)) ;;
      esac
      echo $line >> ${listnr}.pem
    done < "ccadb"
    c_rehash .
    cp *.0 $output/app/ccadb/$prefix$ver
    set_current_app_clean_strip_cd ccadb $prefix$ver 0
  fi
fi
if [ "$package" == "fs2" ] || [ "$package" == "read-edid" ]; then
  ver="3.0.2";
  if should_make read-edid $ver; then
    install_host_deps "cmake libx86-dev"
    download_unpack_source http://www.polypux.org/projects/read-edid/read-edid-$ver.tar.gz read-edid read-edid-$ver 1
    cmake . -DCMAKE_C_FLAGS="-fcommon"
    make
    echo > COPYING
    create_app_in_tmp_and_link_it read-edid $prefix$ver
    cmake --install . --prefix /app/read-edid/current
    set_current_app_clean_strip_cd read-edid $prefix$ver 1
  fi
fi











if [ "$package" == "fs2" ] || [ "$package" == "fsmin2" ] || [ "$package" == "mcnosandbox" ]; then
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
    ./configure --disable-vfs -without-gpm-mouse --prefix=/app/mc/$prefix$ver --exec-prefix=/app/mc/$prefix$ver --bindir=/app/mc/$prefix$ver/bin
    make all -j$cpu_num
    # need to install to /app/mc/current
    create_app mc $prefix$ver
#    cd /app/mcnosandbox
#    rm current
#    ln -s $prefix$ver current
#    cd $out/mc/mc-$ver
    make install
#    cd $output/app/mcnosandbox/$prefix$ver/bin
#    ln -s /app/bash/current/bin/bash bash
#    ln -s /app/busybox/current/bin/sh sh
#    cd $output/app/mc/$prefix$ver
#    mkdir usr
#    cd usr
#    mkdir share
#    cd share
#    ln -s /app/ncurses/current/share/terminfo terminfo
#    cp $curdir/in/mc/mc $output/app/mcnosandbox/$prefix$ver
#    set_current_app_clean_strip_cd mcnosandbox $prefix$ver 1
  fi
fi
#
# musl libc
#
#if [ "$package" == "fs2" ] || [ "$package" == "pciids" ]; then
  # https://pci-ids.ucw.cz/
  # could be used by pciutils, they have own version inside
#  ver="20260815";
#  if should_make pciids $ver; then
#    download_unpack_source https://pci-ids.ucw.cz/v2.2/pci.ids.xz pci.ids.$ver pci.ids 1
#    create_app pciids $prefix$ver
#    cd $curdir
#    cp download/pci.ids.$ver-pci.ids.xz $output/app/pciids/$prefix$ver
#    set_current_app_clean_strip_cd pciids $prefix$ver 1
#  fi
#fi
#if [ "$package" == "fs2" ] || [ "$package" == "man-db" ]; then
  #we don't need it in this moment? groff enough?
  #work in progress
#  ver="2.13.1";
#  if should_make man-db $ver; then
#    install_host_deps "autopoint libpipeline-dev"
#    download_unpack_source https://gitlab.com/man-db/man-db/-/archive/$ver/man-db-$ver.tar.bz2 man-db man-db-$ver 1
#    ./bootstrap
#    ./configure --prefix=$output/app/man-db/$prefix$ver
#    make -j$cpu_num
#    create_app man-db $prefix$ver
#    make install
#    set_current_app_clean_strip_cd man-db $prefix$ver 1
#  fi
#fi
#if [ "$package" == "fs2" ] || [ "$package" == "syslog-ng" ]; then
#  ver="4.12.0";
#  if should_make syslog-ng $ver; then
#    download_unpack_source https://github.com/syslog-ng/syslog-ng/releases/download/syslog-ng-$ver/syslog-ng-$ver.tar.gz syslog-ng syslog-ng-$ver 1
#    mkdir $out/syslog-ng/syslog-ng-$ver-build
#    cd $out/syslog-ng/syslog-ng-$ver-build
#    ../syslog-ng-$ver/configure --prefix=$output/app/syslog-ng/$prefix$ver
#    make -j$cpu_num
#    create_app syslog-ng $prefix$ver
#    make install
#    set_current_app_clean_strip_cd syslog-ng $prefix$ver 1
#  fi
#fi
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
#if [ "$package" == "fs2" ] || [ "$package" == "eudev" ]; then
#  ver="3.2.15";
#  if should_make eudev $ver; then
#    download_unpack_source https://github.com/eudev-project/eudev/archive/refs/tags/v$ver.tar.gz eudev eudev-$ver 1
#    install_host_deps "gperf"
#    ./autogen.sh
#    ./configure --prefix=$output/app/eudev/$prefix$ver
#    make -j$cpu_num
#    create_app eudev $prefix$ver
#    make install
#    set_current_app_clean_strip_cd eudev $prefix$ver 1
#  fi
#fi
#if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "libgbm" ]; then
#this is extraction. should we use mesa implementation?
 # ver="1.0.9";
#  if should_make libgbm $ver; then
#    download_unpack_source https://github.com/glfs-book/libgbm/archive/refs/tags/1.0.9.tar.gz libgbm libgbm-$ver 1
#    meson setup -Dprefix=/app/libgbm/current _build -Dlibdir=lib
#    meson compile -C _build
#    create_app libgbm $prefix$ver
#    set_current_app libgbm $prefix$ver 1
#    meson install -C _build
#    set_current_app_clean_strip_cd libgbm $prefix$ver 1
#  fi
#fi
#if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "linuxfb" ]; then
#  ver="1";
#  if should_make linuxfb $ver; then
#    download_unpack_source https://github.com/roddehugo/linuxfb/archive/refs/heads/master.zip linuxfb linuxfb-master 1
#    make -j$cpu_num
#    create_app linuxfb $prefix$ver
#    for fileentry in fbinfo fbmmap vconsole; do
#      cp $fileentry $output/app/linuxfb/$prefix$ver
#    done
#    set_current_app_clean_strip_cd linuxfb $prefix$ver 1
#  fi
#fi
#if [ "$package" == "fs" ] || [ "$package" == "grub-dejavu-fonts" ]; then
#  ver="2.37";
#  if should_make grub-dejavu-fonts $ver; then
#    download_unpack_source https://github.com/dejavu-fonts/dejavu-fonts/releases/download/version_2_37/dejavu-fonts-ttf-2.37.tar.bz2 dejavu-fonts dejavu-fonts-ttf-$ver 1
#    create_app grub-dejavu-fonts $prefix$ver
#    cd ttf
#    grub-mkfont -s 16 -o $output/app/grub-dejavu-fonts/$prefix$ver/DejaVuSansMono.pf2 DejaVuSansMono.ttf
#    grub-mkfont -s 16 -o $output/app/grub-dejavu-fonts/$prefix$ver/DejaVuSans.pf2 DejaVuSans.ttf
#    set_current_app_clean_strip_cd grub-dejavu-fonts $prefix$ver 0
#  fi
#fi
