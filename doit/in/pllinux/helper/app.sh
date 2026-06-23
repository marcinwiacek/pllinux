#!/bin/bash

DIR="/mnt/x"
ALL_APP=$(ls $DIR/app)

if [ "$1" == "install" ]; then
  echo "install file"
elif [ "$1" == "remove" ]; then
  echo "remove package"
elif [ "$1" == "backup" ]; then
  IFS=":"
  for APP in $2
  do
    echo $APP
    IFS=" " read -r APP_NAME APP_VER << EOF
$APP
EOF
    CURRENT=$(realpath $DIR/app/$APP_NAME/$APP_VER)
    echo $CURRENT
    APP_VER=${CURRENT##*/}
    if [ -d "$DIR/app/${APP_NAME}/${APP_VER}" ]; then
      echo "Compressing app $APP_NAME $APP_VER"
      echo $DIR/app/${APP_NAME}/${APP_VER}
      tar cfJ ${APP_NAME}_${APP_VER}.tar.xz -v --totals -C $DIR/app/${APP_NAME}/${APP_VER} .
    else
      echo "No app -$APP_NAME-$APP_VER-"
    fi
  done
elif [ "$1" == "help" ]; then
  echo "install file"
  echo "remove package"
  echo "backup package"
  echo "help - this info"
else
  for APP_NAME in $ALL_APP
  do
    echo App $APP_NAME
    ALL_APP_VER=$(ls $DIR/app/$APP_NAME)
    CURRENT=$(realpath $DIR/app/$APP_NAME/current)
    for APP_VER in $ALL_APP_VER
    do
      if [ "$APP_VER" != "current" ]; then
        DEPS=""
        if [ -e "$DIR/app/${APP_NAME}/${APP_VER}/readme.md" ]; then
          sectionDeps=0
          while read -r line; do
            if [ "$line" = "**Deps**" ]; then
              sectionDeps=1
            elif [ "$line" = "" ]; then
              sectionDeps=0;
            elif [ "$sectionDeps" = 1 ]; then
              if [ "$DEPS" != "" ]; then
                DEPS="$DEPS:"
              fi
              DEPS=$DEPS$line
            fi
          done < $DIR/app/${APP_NAME}/${APP_VER}/readme.md
        fi
        echo -n "  Version $APP_VER"
        if [ "$CURRENT" == "$DIR/app/$APP_NAME/$APP_VER" ]; then
          echo -n " [current]"
        fi
        if [ "$DEPS" != "" ]; then
          echo -n " [deps $DEPS]"
        fi
        echo
      fi
    done
  done
fi
