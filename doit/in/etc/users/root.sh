#!/app/busybox/current/bin/sh
cd /
export PATH=/app/rsync/current:/app/wget2/current:/app/kbd/current:/app/nftables/current:/app/dinit/current/:/app/util-linux/current:/app/mc/current:/app/busybox/current/bin:/app/busybox/current/sbin:/app/gnupg/current:/app/pllinux/current/helper:/app/openssl/current
export SHELL=/app/busybox/current/bin/sh
export HOME=/other/app/sh
mkdir $HOME 2> /dev/null
export PS1="\e[31m[\t] \u:\w # \e[0m"  # red [time] user : folder #
sh
