chr=/mnt/x/app/util-linux/current
mkdir -p $chr/{bin,lib,lib64}
#cp -v /bin/mc $chr/bin
list="$(ldd bin/mount | egrep -o '/lib.*\.[0-9]')"
for i in $list; do cp -v --parents "$i" "${chr}"; done
