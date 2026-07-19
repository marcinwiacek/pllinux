#!/app/busybox/current/bin/sh
cd /
export PATH=/app/rsync/current:/app/wget2/current:/app/kbd/current:/app/nftables/current:/app/dinit/current/:/app/util-linux/current:/app/mc/current:/app/busybox/current/bin:/app/busybox/current/sbin:/app/pllinux/current/helper:/app/openssl/current
export SHELL=/app/busybox/current/bin/sh
export HOME=/other/app/sh
mkdir $HOME 2> /dev/null
# red [time] user:folder #
# OR
# red [time] user:folder amber git branch name #
export PS1="\e[31m[\t] root:\w\$(if [ -f "/app/git/current/bin/git" ] && /app/git/current/git rev-parse --git-dir > /dev/null 2>&1; then echo -n \" \e[33m\";/app/git/current/git branch --show-current; fi) # \e[m"
sh
