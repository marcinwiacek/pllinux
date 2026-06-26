#!/bin/bash

VER1=$1
VER2=$2

      IFS="." read -r -a APP_VER1 << EOF
$VER1
EOF

      IFS="." read -r -a APP_VER2 << EOF
$VER2
EOF


first_bigger=0
SEG_NUM=0
MAX_NUM=${#APP_VER2[@]}

for SEG in ${APP_VER1[@]}
do
  if [ $first_bigger == "0" ]; then
    if [ ${SEG_NUM} -lt ${#APP_VER2[@]} ]; then
      if [ -z "${APP_VER1[$SEG_NUM]//[0-9]}" ] && [ -z "${APP_VER2[$SEG_NUM]//[0-9]}" ]; then
        if [ ${APP_VER2[$SEG_NUM]} -gt ${APP_VER1[$SEG_NUM]} ]; then
          first_bigger=-1
        elif [ ${APP_VER2[$SEG_NUM]} -lt ${APP_VER1[$SEG_NUM]} ]; then
          first_bigger=1
        fi
      else
        if [ "${APP_VER2[$SEG_NUM]}" \> "${APP_VER1[$SEG_NUM]}" ]; then
          first_bigger=-1
        elif [ "${APP_VER2[$SEG_NUM]}" \< "${APP_VER1[$SEG_NUM]}" ]; then
          first_bigger=1
        fi
      fi
      SEG_NUM=$[$SEG_NUM+1]
    else
      first_bigger=1
    fi
  fi
done

if [ $first_bigger = "1" ]; then
  echo ${APP_VER1[*]} \> ${APP_VER2[*]}
elif [ $first_bigger = "-1" ]; then
  echo ${APP_VER1[*]} \< ${APP_VER2[*]}
else
  echo ${APP_VER1[*]} = ${APP_VER2[*]}
fi
