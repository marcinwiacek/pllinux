#!/mnt/x/app/busybox/current/bin/sh
# Package manager
INFO="Version from 27.06.2026. Part of PLLINUX"
DIR="/mnt/x"
ALL_APP=$(ls $DIR/app)
IFSORIG=$IFS

find_app_deps() {
  local DIR=$1
  local APP_NAME20=$2
  local APP_VER20=$3
  local SECTION=$4
#echo find_app_deps $1 $2 $3 $4
  if [ -e "$DIR/app/${APP_NAME20}/${APP_VER20}/readme.md" ]; then
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
     done < $DIR/app/${APP_NAME20}/${APP_VER20}/readme.md
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
       elif [ "$sectionInstall" = 1 ]; then
	 INSTALL_SCRIPT=$line
       fi
     done < $DIR/app/${APP_NAME}/${APP_VER}/readme.md
  fi
}

compare_app_version_segment() {
  if [ $first_bigger = "0" ]; then
    if [ "$1" != "" ] && [ "$2" = "" ]; then
      first_bigger=1
    elif [ "$1" = "" ] && [ "$2" != "" ]; then
      first_bigger=-1
    elif [ "$1" != "" ] || [ "$2" != "" ]; then
      if [ -z "${1//[0-9]}" ] && [ -z "${2//[0-9]}" ]; then
	# numeric comparison
        if [ $2 -gt $1 ]; then
          first_bigger=-1
        elif [ $2 -lt $1 ]; then
          first_bigger=1
        fi
      else
	# string comparison
        if [ $2 \> $1 ]; then
          first_bigger=-1
        elif [ $2 \< $1 ]; then
          first_bigger=1
        fi
      fi
    fi
  fi
}

compare_app_version() {
  DATE1="${1:0:6}"
  DATE2="${2:0:6}"
  VER1="${1:7}"
  VER2="${2:7}"

  IFS="." read -r APP_VER11 APP_VER12 APP_VER13 APP_VER14 APP_VER15 << EOF
$VER1
EOF

  IFS="." read -r APP_VER21 APP_VER22 APP_VER23 APP_VER24 APP_VER25 << EOF
$VER2
EOF

  first_bigger=0
  compare_app_version_segment "$APP_VER11" "$APP_VER21"
  compare_app_version_segment "$APP_VER12" "$APP_VER22"
  compare_app_version_segment "$APP_VER13" "$APP_VER23"
  compare_app_version_segment "$APP_VER14" "$APP_VER24"
  compare_app_version_segment "$APP_VER15" "$APP_VER25"

  if [ $first_bigger = "0" ]; then
    if [ $DATE1 \> $DATE2 ]; then
      first_bigger=1
    elif [ $DATE1 \< $DATE2 ]; then
      first_bigger=-1
    fi
  fi
}

if [ "$1" = "install" ]; then
  # build list of all dependencies
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
  # install all apps
  DEPS2="" # build list of new installed apps
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
      #FIXME: remove after testing
      if [ "$DEPS2" != "" ]; then
        DEPS2="$DEPS2:"
      fi
      DEPS2="$DEPS2${APP_NAME} ${APP_VER}"
    elif [! -f "${APP_NAME}_${APP_VER}.tar.xz" ]; then
      echo "Backup file ${APP_NAME}_${APP_VER}.tar.xz not exists. Skipping"
    else
      echo "installing app ${APP_NAME} ${APP_VER}"
      mkdir $DIR/app/${APP_NAME}/${APP_VER}
      cd $DIR/app/${APP_NAME}/${APP_VER}
#      tar -xvf ../../download/$localfile
#      cd
      if [ "$DEPS2" != "" ]; then
        DEPS2="$DEPS2:"
      fi
      DEPS2="$DEPS2${APP_NAME} ${APP_VER}"
    fi
  done
  # find and run all install scripts from new added packages
  IFS=":"
  for APP in $DEPS2
  do
    IFS=" " read -r APP_NAME APP_VER << EOF
$APP
EOF
    CURRENT=$(realpath $DIR/app/$APP_NAME/$APP_VER)
    APP_VER=${CURRENT##*/}
    if [ -d "$DIR/app/${APP_NAME}/${APP_VER}" ]; then
      INSTALL_SCRIPT=""
      find_app_install_script $DIR $APP_NAME $APP_VER
      if [ "$INSTALL_SCRIPT" != "" ]; then
        PARAMS=""
        IFS=":"
        for DEP3 in $DEPS
        do
          IFS=" " read -r APP_NAME3 APP_VER3 << EOF
$DEP
EOF
          PARAMS="$PARAMS --ro-bind $DIR/app/${APP_NAME3}/${APP_VER3} app/${APP_NAME3}/${APP_VER3} "
        done
        PARAMS="$PARAMS --ro-bind $DIR/app/busybox/current /app/busybox/current "
        PARAMS="$PARAMS --ro-bind $DIR/app/${APP_NAME}/${APP_VER} app/${APP_NAME}/${APP_VER} "
	mkdir -p $DIR/app/${APP_NAME}/${APP_VER}/dynamic || true
        PARAMS="$PARAMS --bind $DIR/app/${APP_NAME}/${APP_VER}/dynamic app/${APP_NAME}/${APP_VER}/dynamic "
        PARAMS="$PARAMS --dev dev --unshare-all --tmpfs tmp "
        PARAMS="$PARAMS --chdir /app/${APP_NAME}/${APP_VER}/scripts "
        PARAMS="$PARAMS /app/busybox/current/bin/sh $INSTALL_SCRIPT"
        echo "Starting install script for the app ${APP_NAME} ${APP_VER}"
        IFS=" "
        bwrap $PARAMS
        IFS=":"
      fi
    fi
  done
  #run modules dependent from new installed
elif [ "$1" = "updateall" ]; then
  #get new updates file
  for APP_NAME in $ALL_APP; do
    ALL_APP_VER=$(ls $DIR/app/$APP_NAME)
    CURRENT=$(realpath $DIR/app/$APP_NAME/current)
    APP_VER_CURRENT=""
    for APP_VER in $ALL_APP_VER; do
      if [ "$APP_VER" != "current" ]; then
        if [ "$CURRENT" = "$DIR/app/$APP_NAME/$APP_VER" ]; then
	  APP_VER_CURRENT=$APP_VER
	  # we search the highest possible update version
          NEW_VER=$APP_VER_CURRENT
          while read -r line; do
            IFS=" " read -r APP_NAME2 APP_VER2 APP_SIZE2 << EOF
$line
EOF
            if [ "$APP_NAME" = "$APP_NAME2" ]; then
   	      compare_app_version $NEW_VER $APP_VER2
              if [ $first_bigger = "-1" ]; then
  	        NEW_VER=$APP_VER2
	      fi
            fi
          done < "app.updates"
          if [ "$NEW_VER" != "$APP_VER_CURRENT" ]; then
            echo "Updating $APP_NAME current to the $NEW_VER"
          fi
        fi
      fi
    done
    DEPS=""
    for APP_NAME3 in $ALL_APP; do
      ALL_APP_VER3=$(ls $DIR/app/$APP_NAME3)
      CURRENT3=$(realpath $DIR/app/$APP_NAME3/current)
      APP_VER_CURRENT3=""
      for APP_VER3 in $ALL_APP_VER3; do
        if [ "$APP_VER3" != "current" ]; then
          find_app_deps $DIR $APP_NAME3 $APP_VER3 "Deps"
	fi
      done
    done
    IFS=":"
    for APP4 in $DEPS; do
      IFS=" " read -r APP_NAME4 APP_VER4 << EOF
$APP4
EOF
      if [ "$APP_NAME4" = "$APP_NAME" ] && [ "$APP_VER4" != "current" ]; then
	LEN=${#APP_VER4}-1
	# we will search the highest/latest version but lower than specified in APP_VER4
	if [ "${APP_VER4:$LEN:1}" = "-" ]; then
          MAX_VER=${APP_VER4:0:$LEN}
	  NEW_VER="0"
          while read -r line; do
	    IFS=" " read -r APP_NAME5 APP_VER5 APP_SIZE5 << EOF
$line
EOF
	    if [ "$APP_NAME4" == "$APP_NAME5" ]; then
   	      compare_app_version $MAX_VER $APP_VER5
              if [ $first_bigger = "1" ]; then
   	        compare_app_version $NEW_VER $APP_VER5
                if [ $first_bigger = "-1" ]; then
  	          NEW_VER=$APP_VER5
		fi
	      fi
	    fi
          done < "app.updates"
	  if [ "$NEW_VER" != "${APP_VER:-1}" ]; then
            echo "Installing $APP_NAME $NEW_VER because of other app dependency $APP_VER4"
          fi
        fi
      fi
    done
    IFS=$IFSORIG
  done
elif [ "$1" = "remove" ]; then
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
elif [ "$1" = "backup" ]; then
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
      tar cfJ ${APP_NAME}_${APP_VER}.tar.xz --exclude dynamic -C $DIR/app/${APP_NAME}/${APP_VER} .
    else
      echo "No app $APP_NAME $APP_VER. Skipping"
    fi
  done
elif [ "$1" = "help" ]; then
  echo "$INFO"
  echo
  echo "<no options> - show all versions, dependiences and updates with downloaded repo file"
  echo "help - this info"
  echo
  echo "updateall - download repo file and install latest version of all packages from repo"
  echo
  echo "backup package list - writes all packages to the xz installation files"
  echo "install filelist - install packages from files"
  echo "remove package_list - remove package and dependencies"
else
  for APP_NAME in $ALL_APP; do
    echo App $APP_NAME
    ALL_APP_VER=$(ls $DIR/app/$APP_NAME)
    CURRENT=$(realpath $DIR/app/$APP_NAME/current)
    APP_VER_CURRENT=""
    for APP_VER in $ALL_APP_VER; do
      if [ "$APP_VER" != "current" ]; then
	DEPS=""
        find_app_deps $DIR $APP_NAME $APP_VER "Deps"
        echo -n "  Version $APP_VER"
        if [ "$CURRENT" = "$DIR/app/$APP_NAME/$APP_VER" ]; then
	  APP_VER_CURRENT=$APP_VER
          echo -n " [current]"
	  # we search the highest possible update version
          NEW_VER=$APP_VER_CURRENT
          while read -r line; do
            IFS=" " read -r APP_NAME2 APP_VER2 APP_SIZE2 << EOF
$line
EOF
            if [ "$APP_NAME" = "$APP_NAME2" ]; then
   	      compare_app_version $NEW_VER $APP_VER2
              if [ $first_bigger = "-1" ]; then
  	        NEW_VER=$APP_VER2
	      fi
            fi
          done < "app.updates"
          if [ "$NEW_VER" != "$APP_VER_CURRENT" ]; then
            echo -n " [update avail $NEW_VER]"
          fi
        fi
        if [ "$DEPS" != "" ]; then
          echo -n " [deps $DEPS]"
        fi
        echo
      fi
    done
    DEPS=""
    for APP_NAME3 in $ALL_APP; do
      ALL_APP_VER3=$(ls $DIR/app/$APP_NAME3)
      CURRENT3=$(realpath $DIR/app/$APP_NAME3/current)
      APP_VER_CURRENT3=""
      for APP_VER3 in $ALL_APP_VER3; do
        if [ "$APP_VER3" != "current" ]; then
          find_app_deps $DIR $APP_NAME3 $APP_VER3 "Deps"
	fi
      done
    done
    IFS=":"
    for APP4 in $DEPS; do
      IFS=" " read -r APP_NAME4 APP_VER4 << EOF
$APP4
EOF
      if [ "$APP_NAME4" = "$APP_NAME" ] && [ "$APP_VER4" != "current" ]; then
	echo -n "  Dep from other app $APP_VER4"
	LEN=${#APP_VER4}-1
	# we will search the highest/latest version but lower than specified in APP_VER4
	if [ "${APP_VER4:$LEN:1}" = "-" ]; then
          MAX_VER=${APP_VER4:0:$LEN}
	  NEW_VER="0"
          while read -r line; do
	    IFS=" " read -r APP_NAME5 APP_VER5 APP_SIZE5 << EOF
$line
EOF
	    if [ "$APP_NAME4" == "$APP_NAME5" ]; then
   	      compare_app_version $MAX_VER $APP_VER5
              if [ $first_bigger = "1" ]; then
   	        compare_app_version $NEW_VER $APP_VER5
                if [ $first_bigger = "-1" ]; then
  	          NEW_VER=$APP_VER5
		fi
	      fi
	    fi
          done < "app.updates"
	  if [ "$NEW_VER" != "${APP_VER:-1}" ]; then
            echo -n " [update avail $NEW_VER]"
          fi
        fi
	echo
      fi
    done
    IFS=$IFSORIG
  done
fi
