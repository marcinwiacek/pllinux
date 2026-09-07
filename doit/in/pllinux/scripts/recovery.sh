#!/app/busybox/current/bin/sh
# called, when something fails during start. We try with normal boot script and login root
/app/pllinux/current/scripts/boot.sh || true
/app/busybox/current/bin/busybox sulogin

