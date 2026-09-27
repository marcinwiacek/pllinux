#!/app/busybox/current/bin/sh
# called, when something fails during start. We try with normal boot script and login root
if [ ! -d "/log" ]; then
  echo "Cannot be run from host"
  return
fi
/app/pllinux/current/scripts/boot.sh || true
/app/busybox/current/bin/busybox sulogin

