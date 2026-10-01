#!/app/busybox/current/bin/sh
# Script for running shebang with params
while read -r line; do
  line=${line:2}
  IFS=" " read -r BIN_NAME BIN_PARAM << EOF
$line
EOF
  case $BIN_NAME in
  /usr/bin/env*) /app/busybox/current/bin/env $BIN_PARAM $1
  esac
  break
done < $1
