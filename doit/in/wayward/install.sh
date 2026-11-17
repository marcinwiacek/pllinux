#!/bin/bash

#GPL
#original source: 0.16.0

#cd `dirname $0`

echo $1
echo $0

/usr/bin/install -Dm644 o/wayward "/app/wayward/current/bin"
/usr/bin/install -Dm644 scripts/wayward-lsdesktopf "/app/wayward/current/scripts/wayward-lsdesktopf"
/usr/bin/install -Dm644 scripts/wayward-get-brightness-ddc "/app/wayward/current/scripts/wayward-get-brightness-ddc"
/usr/bin/install -Dm644 scripts/wayward-get-brightness-ctl "/app/wayward/current/scripts/wayward-get-brightness-ctl"
/usr/bin/install -Dm644 scripts/wayward-set-sound-card "/app/wayward/current/scripts/wayward-set-sound-card"
/usr/bin/install -Dm655 wayward-set-pincode "/app/wayward/current/bin/wayward-set-pincode"
/usr/bin/install -Dm644 o/shell_helper.so "/app/wayward/current/lib/shell_helper.so"
/usr/bin/install -Dm655 o/wayward-terminal "/app/wayward/current/bin/wayward-terminal"
/usr/bin/install -Dm655 o/wayward-pincode "/app/wayward/current/bin/wayward-pincode"

/usr/bin/install -Dm644 weston.ini "/app/wayward/current/etc/weston/weston.ini"

chmod +x "/app/wayward/current/bin/wayward"
chmod +x "$1/usr/lib/weston/wayward-lsdesktopf"

#clean up
#rm -rf o/*

#mkdir -p $1/usr/share/wayward
#cp icons/* $1/usr/share/wayward/

echo OOOK!
