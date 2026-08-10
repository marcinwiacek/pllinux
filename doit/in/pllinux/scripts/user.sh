#!/app/busybox/current/bin/sh

CONS=$(/app/busybox/current/bin/tty)
echo User $USER on console $CONS

FEATURES=""
APPS=""

if [ -e "/etc/pllinux.conf" ]; then
  while read -r line; do
    IFS="=" read -r PARAM_NAME PARAM_VALUE << EOF
$line
EOF
    case $PARAM_NAME in
    ${USER}_FEATURES )
      FEATURES="$PARAM_VALUE" ;;
    ${USER}_APPS )
      APPS="$PARAM_VALUE" ;;
    ${USER}_KEYB )
      /app/kbd/current/bin/loadkeys -C $CONS /app/kbd/current/share/keymaps/i386/$PARAM_VALUE ;;
    ${USER}_FONT )
      /app/kbd/current/bin/setfont -C $CONS $PARAM_VALUE ;;
    esac
  done < "/etc/pllinux.conf"
fi

if [ "$APPS" = "" ]; then
  echo User $USER does not have any apps
else
#/app/pllinux/current/scripts/userwrap.sh mnt reset net processes "app mc current:util-linux current:busybox current:openssl current:groff current"
  /app/pllinux/current/scripts/userwrap.sh "app $APPS"
fi
