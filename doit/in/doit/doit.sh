#!/app/busybox/current/bin/sh
# Part of PLLINUX. Creating binaries (from the source) inside PLLinux and installing them in the PLLinux partition.

output="app";  # location of the package to be put
download="download"; # location of the downloaded source files
package="bash"; 
cpu_num=6; # how many CPU cores are used during compilation
#dont_process_the_same_ver=0; # 1 - on; 0 - off; don't compile and install app, when the same version (even from other day) available
use_tmpfs=1; # 1 - some compilations will be done in RAM disk (currently excluded: kernel and gcc part); 0 - save all to disk

# options below shouldn't be probably changed
curdir=$(pwd)
prefix="$(date +"%y%m%d")_" # prefix for packages versions in /app in new system

IFSORIG=$IFS

# Check if makes sense to build the whole package
should_make() {
  packagename=$1
  packagever=$2

#  if [ $dont_process_the_same_ver == "1" ]; then
#    if [ ! -d "out/$packagename" ]; then
#      return 0; // true
#    fi
#    dirlist=$(ls "$output/app/$packagename")
#    for singledir in $dirlist; do
#      if [ "${singledir:7}" == "$packagever" ]; then return 1; fi
#    done
#    return 0; //true
#  fi
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

  if [ ! -f "$download/$localfile" ]; then
    echo $url
    wget -O /tmp/$localfile.tmp $url;
    if [ $? -eq 0 ]; then
      mv /tmp/$localfile.tmp $download/$localfile
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
        ccadb* ) cp $download/$localfile $out/$packagename/ccadb ;;
        *.rpm* ) install_host_deps "rpm"
                 rpm2cpio $download/$localfile | cpio -idmv ;;
        *.zip* ) unzip $download/$localfile -d .
                 cd $unpackeddir ;;
        *.lz )   tar --lzip -xvf $download/$localfile
                 cd $unpackeddir ;;
        * )      tar -xvf $download/$localfile
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

create_app_in_tmp_and_link_it2() {
  packagename=$1
  version=$2

  rm -r -f /tmp/installit2 2> /dev/null
  mkdir /tmp/installit2
  rm -r -f $output/app/$packagename/$version 2> /dev/null
  [ -d $output/app/$packagename ] || mkdir $output/app/$packagename
  ln -s /tmp/installit2 $output/app/$packagename/$version
}

set_current_app_clean_strip_cd2() {
  if [ $? != 0 ]; then
    return
  fi

  packagename=$1
  version=$2
  stripapp=$3

  if [ -d "/tmp/installit2" ]; then
    pathtoapp="/tmp/installit2"
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

  if [ -d "/tmp/installit2" ]; then
#    [ -d $output/app/$packagename ] || mkdir $output/app/$packagename
#    if [ -d $output/app/$packagename/$version ]; then 
    rm $output/app/$packagename/$version 2> /dev/null
    mkdir $output/app/$packagename/$version || true
  fi

  #set "current" directory to the new installed app
  cd $output/app/$packagename
  if [ -d "current" ]; then rm -r current; fi
  ln -s $version current

  if [ -d "/tmp/installit2" ]; then
    rsync -a /tmp/installit2/ $output/app/$packagename/$version
    rm -r -f /tmp/installit2
  fi

  if [ "$use_tmpfs" = "1" ]; then
    rm -r -f $out
  fi

  cd $curdir
}

mkdir $output
mkdir $download

# --------------------------------- basic - console env and basic tools -------------------------------------
if [ "$package" == "fs" ] || [ "$package" == "fsmin" ] || [ "$package" == "bash" ]; then
  ver="5.3";
  if should_make bash $ver; then
    download_unpack_source https://ftp.gnu.org/gnu/bash/bash-$ver.tar.gz bash bash-$ver 1
    ./configure --prefix=/app/bash/$prefix$ver
    make all -j$cpu_num
    create_app_in_tmp_and_link_it2 bash $prefix$ver
    make install
    chmod a-x /app/bash/$prefix$ver/lib/bash/*
    set_current_app_clean_strip_cd2 bash $prefix$ver 1
  fi
fi
