#!/mnt/x/app/busybox/current/bin/sh

      IFS="." read -r APP_VER11 APP_VER12 APP_VER13 APP_VER14 APP_VER15 << EOF
$1
EOF

      IFS="." read -r APP_VER21 APP_VER22 APP_VER23 APP_VER24 APP_VER25 << EOF
$2
EOF

function process_ver_segment() {
  if [ $first_bigger = "0" ]; then
    if [ "$1" != "" ] && [ "$2" = "" ]; then
      first_bigger=1
    elif [ "$1" = "" ] && [ "$2" != "" ]; then
      first_bigger=-1
    elif [ "$1" != "" ] || [ "$2" != "" ]; then
      if [ -z "${1//[0-9]}" ] && [ -z "${2//[0-9]}" ]; then
        if [ $2 -gt $1 ]; then
          first_bigger=-1
        elif [ $2 -lt $1 ]; then
          first_bigger=1
        fi
      else
        if [ $2 \> $1 ]; then
          first_bigger=-1
        elif [ $2 \< $1 ]; then
          first_bigger=1
        fi
      fi
    fi
  fi
}

first_bigger=0
process_ver_segment "$APP_VER11" "$APP_VER21"
process_ver_segment "$APP_VER12" "$APP_VER22"
process_ver_segment "$APP_VER13" "$APP_VER23"
process_ver_segment "$APP_VER14" "$APP_VER24"
process_ver_segment "$APP_VER15" "$APP_VER25"

if [ $first_bigger = "1" ]; then
  echo $1 \> $2
elif [ $first_bigger = "-1" ]; then
  echo $1 \< $2
else
  echo $1 = $2
fi
