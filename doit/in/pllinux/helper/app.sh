#!/bin/bash

DIR="/mnt/x"
ALL_APP=$(ls $DIR/app)

find_app_deps() {
  DIR=$1
  APP_NAME=$2
  APP_VER=$3
  SECTION=$4
  if [ -e "$DIR/app/${APP_NAME}/${APP_VER}/readme.md" ]; then
     sectionDeps=0
     while read -r line; do
       if [ "$line" = "**$SECTION**" ]; then
         sectionDeps=1
       elif [ "$line" = "" ]; then
         sectionDeps=0;
       elif [ "$sectionDeps" = 1 ]; then
         case $DEPS in
              *$line* )
                ;;
              * )
                complete=0
                if [ "$DEPS" != "" ]; then
                  DEPS="$DEPS:"
                fi
                DEPS=$DEPS$line
                ;;
         esac
       fi
     done < $DIR/app/${APP_NAME}/${APP_VER}/readme.md
  fi
}

find_app_install_script() {
  DIR=$1
  APP_NAME=$2
  APP_VER=$3
  if [ -e "$DIR/app/${APP_NAME}/${APP_VER}/readme.md" ]; then
     sectionInstall=0
     while read -r line; do
       if [ "$line" = "**Install**" ]; then
         sectionInstall=1
       elif [ "$line" = "" ]; then
         sectionInstall=0;
       elif [ "$sectionDeps" = 1 ]; then
         case $DEPS in
              *$line* )
                ;;
              * )
                complete=0
                if [ "$DEPS" != "" ]; then
                  DEPS="$DEPS:"
                fi
                DEPS=$DEPS$line
                ;;
         esac
       fi
     done < $DIR/app/${APP_NAME}/${APP_VER}/readme.md
  fi
}

if [ "$1" == "install" ]; then
  DEPS=$2
  while true; do
    complete=1
    IFS=":"
    for DEP in $DEPS
    do
      IFS=" " read -r APP_NAME APP_VER << EOF
$DEP
EOF
      find_app_deps $DIR $APP_NAME $APP_VER "Deps"
    done
    if [ "$complete" = 1 ]; then break; fi
  done
  IFS=":"
  for APP in $DEPS
  do
    IFS=" " read -r APP_NAME APP_VER << EOF
$APP
EOF
    CURRENT=$(realpath $DIR/app/$APP_NAME/$APP_VER)
    APP_VER=${CURRENT##*/}
    if [ -d "$DIR/app/${APP_NAME}/${APP_VER}" ]; then
      echo "App ${APP_NAME} ${APP_VER} already installed. Skipping"
    elif [! -f "${APP_NAME}_${APP_VER}.tar.xz" ]; then
      echo "Backup file ${APP_NAME}_${APP_VER}.tar.xz not exists. Skipping"
    else
      echo "installing"
#      find_app_deps $DIR $APP_NAME $APP_VER "InstallDeps"
    fi
  done
elif [ "$1" == "remove" ]; then
  DEPS=$2
  while true; do
    complete=1
    IFS=":"
    for DEP in $DEPS
    do
      IFS=" " read -r APP_NAME APP_VER << EOF
$DEP
EOF
      find_app_deps $DIR $APP_NAME $APP_VER "Deps"
    done
    if [ "$complete" = 1 ]; then break; fi
  done
  IFS=":"
  for APP in $DEPS
  do
    IFS=" " read -r APP_NAME APP_VER << EOF
$APP
EOF
    CURRENT=$(realpath $DIR/app/$APP_NAME/$APP_VER)
    APP_VER=${CURRENT##*/}
    if [! -d "$DIR/app/${APP_NAME}/${APP_VER}" ]; then
      echo "No app -$APP_NAME $APP_VER. Skipping"
    else
      echo "Removing app -$APP_NAME $APP_VER"
    fi
  done
elif [ "$1" == "backup" ]; then
  DEPS=$2
  while true; do
    complete=1
    IFS=":"
    for DEP in $DEPS
    do
      IFS=" " read -r APP_NAME APP_VER << EOF
$DEP
EOF
      find_app_deps $DIR $APP_NAME $APP_VER "Deps"
    done
    if [ "$complete" = 1 ]; then break; fi
  done
  IFS=":"
  for APP in $DEPS
  do
    IFS=" " read -r APP_NAME APP_VER << EOF
$APP
EOF
    CURRENT=$(realpath $DIR/app/$APP_NAME/$APP_VER)
    APP_VER=${CURRENT##*/}
    if [ -f "${APP_NAME}_${APP_VER}.tar.xz" ]; then
      echo "Backup file ${APP_NAME}_${APP_VER}.tar.xz already exists. Skipping"
    elif [ -d "$DIR/app/${APP_NAME}/${APP_VER}" ]; then
      echo "Creating backup file ${APP_NAME}_${APP_VER}.tar.xz"
      tar cfJ ${APP_NAME}_${APP_VER}.tar.xz -C $DIR/app/${APP_NAME}/${APP_VER} .
    else
      echo "No app $APP_NAME $APP_VER. Skipping"
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
        find_app_deps $DIR $APP_NAME $APP_VER "Deps"
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
