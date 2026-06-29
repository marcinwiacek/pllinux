#!/mnt/x/app/busybox/current/bin/sh
# Package manager
INFO="Version from 28.06.2026. Part of PLLINUX"
DIR="/mnt/x"
ALL_APP=$(ls $DIR/app --sort name)
IFSORIG=$IFS

# getting app dependencies from app readme.md
find_app_deps() {
  local DIR=$1
  local SECTION=$2
  local GET_CURRENT=$3
  if [ -e "$DIR/readme.md" ]; then
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
              SAVE=1
              case $line in
                *current* )
                    SAVE=$GET_CURRENT
                    ;;
              esac
              if [ "$SAVE" == "1" ]; then
                complete=0
                if [ "$DEPS" != "" ]; then
                  DEPS="$DEPS:"
                fi
                DEPS=$DEPS$line
              fi
              ;;
         esac
       fi
     done < $DIR/readme.md
  fi
}

# getting name of install script (if any) from app readme.md
find_app_install_script() {
  local DIR=$1
  if [ -e "$DIR/readme.md" ]; then
     sectionInstall=0
     while read -r line; do
       if [ "$line" = "**Install**" ]; then
         sectionInstall=1
       elif [ "$line" = "" ]; then
         sectionInstall=0;
       elif [ "$sectionInstall" = 1 ]; then
         INSTALL_SCRIPT=$line
       fi
     done < $DIR/readme.md
  fi
}

# compare one segment from two version strings
compare_app_version_segment() {
  # if they were equal earlier
  if [ $first_bigger = "0" ]; then
    if [ "$1" != "" ] && [ "$2" = "" ]; then
      # first longer
      first_bigger=1
    elif [ "$1" = "" ] && [ "$2" != "" ]; then
      # second longer
      first_bigger=-1
    elif [ "$1" != "" ] || [ "$2" != "" ]; then
      # are both numbers ?
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

# comparing two version strings and finding, which one is later (higher)
compare_app_version() {
  local DATE1="${1:0:6}"
  local DATE2="${2:0:6}"
  local VER1="${1:7}"
  local VER2="${2:7}"

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

get_repo_updates() {
  REPO_UPDATES=""
  while read -r repo_line; do
    if [ "$repo_line" != "http" ]; then
      if [ ! -d "$repo_line" ]; then
        echo Repo directory $repo_line not found. Skipping
      elif [ ! -f "${repo_line}/app.repo.updates" ]; then
        echo "Repo directory $repo_line without app.repo.updates file. Skipping"
      else
#        echo "Repo $repo_line OK"
        while read -r line; do
          REPO_UPDATES="$REPO_UPDATES$line $repo_line
"
        done < "${repo_line}app.repo.updates"
      fi
    fi
  done < "app.repos"
}

#install_app() {
#}

if [ "$1" = "install" ] && [ "$2" != "" ]; then
  REPO_UPDATES=""
  get_repo_updates
  rm -f -r /tmp/app
  DEPS=$2
  NEW_DEPS=""
  DEPS_PROCESSED=""
  while true; do
    complete=1
    IFS=":"
    for DEP in $DEPS; do
      IFS=" " read -r APP_NAME APP_VER << EOF
$DEP
EOF
      case $DEPS_PROCESSED in
        *${APP_NAME}${APP_VER}* )
           ;;
        * )
           DEPS_PROCESSED="$DEPS_PROCESSED:${APP_NAME}${APP_VER}"

           NEW_VER=0
           NEW_REPO=""
           LEN=${#APP_VER}-1
           if [ "$APP_VER" = "current" ]; then
             # we search the highest possible update version
             while read -r line; do
               IFS=" " read -r APP_NAME2 APP_VER2 APP_REPO2 << EOF
$line
EOF
               if [ "$APP_NAME" = "$APP_NAME2" ]; then
                 compare_app_version $NEW_VER $APP_VER2
                 if [ $first_bigger = "-1" ] || [ "$NEW_VER" = "" ]; then
                   NEW_VER=$APP_VER2
                   NEW_REPO=$APP_REPO2
                 fi
               fi
             done <<< "$REPO_UPDATES"
           elif [ "${APP_VER:$LEN:1}" = "-" ]; then
             # we will search the highest/latest version but lower than specified in APP_VER
             MAX_VER=${APP_VER:0:$LEN}
             while read -r line; do
               IFS=" " read -r APP_NAME2 APP_VER2 APP_REPO2 << EOF
$line
EOF
               if [ "$APP_NAME" == "$APP_NAME2" ]; then
                 compare_app_version $MAX_VER $APP_VER2
                 if [ $first_bigger = "1" ]; then
                   compare_app_version $NEW_VER $APP_VER2
                   if [ $first_bigger = "-1" ]; then
                     NEW_VER=$APP_VER2
                     NEW_REPO=$APP_REPO2
                   fi
                 fi
               fi
             done <<< "$REPO_UPDATES"
           else
             while read -r line; do
               IFS=" " read -r APP_NAME2 APP_VER2 APP_REPO2 << EOF
$line
EOF
               if [ "$APP_NAME" = "$APP_NAME2" ] && [ "$APP_VER" = "$APP_VER2" ]; then
                 NEW_VER=$APP_VER2
                 NEW_REPO=$APP_REPO2
               fi
             done <<< "$REPO_UPDATES"
           fi
           if [ "$NEW_VER" = "0" ]; then
             echo "App ${APP_NAME} ${APP_VER} not found in repo. Skipping"
             exit 1
           elif [ -d "$DIR/app/${APP_NAME}/${NEW_VER}" ]; then
             echo "App ${APP_NAME} ${NEW_VER} already installed. Skipping"
           elif [ ! -f "${NEW_REPO}${APP_NAME}_${NEW_VER}.tar.xz" ]; then
             echo "Backup file ${NEW_REPO}${APP_NAME}_${NEW_VER}.tar.xz does not exist."
             exit 1
           else
             mkdir /tmp/app
             mkdir /tmp/app/${APP_NAME}
             mkdir /tmp/app/${APP_NAME}/${NEW_VER}
             olddir=$(pwd)
             cd /tmp/app/${APP_NAME}/${NEW_VER}
             echo Unpacking $olddir/${NEW_REPO}${APP_NAME}_${NEW_VER}.tar.xz
             tar -xvf $olddir/${NEW_REPO}${APP_NAME}_${NEW_VER}.tar.xz 2> /dev/null > /dev/null
             find_app_deps /tmp/app/${APP_NAME}/${NEW_VER} "Deps" 1
             cd $olddir
#echo ${APP_NAME} ${NEW_VER} adding new deps $NEW_DEPS
             if [ "$NEW_DEPS" != "" ]; then
               NEW_DEPS="${APP_NAME} ${NEW_VER}:$NEW_DEPS"
             else
               NEW_DEPS="${APP_NAME} ${NEW_VER}"
             fi
           fi
           ;;
      esac
    done
    if [ "$complete" = 1 ]; then
      break;
    fi
  done
#echo $DEPS
#echo $NEW_DEPS
  IFS=":"
  for DEP in $NEW_DEPS; do
    IFS=" " read -r APP_NAME APP_VER << EOF
$DEP
EOF
    if [ ! -d "/tmp/app/${APP_NAME}/${APP_VER}" ]; then
      echo "No directory ${APP_NAME} ${APP_VER}. Smth wrong"
      exit 1
    fi
    INSTALL_SCRIPT=""
    find_app_install_script /tmp/app/$APP_NAME/$APP_VER
    if [ "$INSTALL_SCRIPT" != "" ]; then
      PARAMS=""
      IFS=":"
#fixme: wrong dep list
      for DEP3 in $DEPS; do
        IFS=" " read -r APP_NAME3 APP_VER3 << EOF
$DEP
EOF
        if [ -d "/tmp/app/${APP_NAME3}/${APP_VER3}" ]; then
          PARAMS="$PARAMS --ro-bind /tmp/app/${APP_NAME3}/${APP_VER3} /app/${APP_NAME3}/${APP_VER3} "
        else
          PARAMS="$PARAMS --ro-bind $DIR/app/${APP_NAME3}/${APP_VER3} /app/${APP_NAME3}/${APP_VER3} "
        fi
      done
      PARAMS="$PARAMS --ro-bind $DIR/app/busybox/current /app/busybox/current "
      PARAMS="$PARAMS --ro-bind /tmp/app/${APP_NAME}/${APP_VER} /app/${APP_NAME}/${APP_VER} "
      mkdir -p /tmp/app/${APP_NAME}/${APP_VER}/dynamic || true
      PARAMS="$PARAMS --bind /tmp/app/${APP_NAME}/${APP_VER}/dynamic /app/${APP_NAME}/${APP_VER}/dynamic "
      PARAMS="$PARAMS --dev dev --unshare-all --tmpfs tmp "
      PARAMS="$PARAMS --chdir /app/${APP_NAME}/${APP_VER}/scripts "
      PARAMS="$PARAMS /app/busybox/current/bin/sh $INSTALL_SCRIPT"
      echo "Starting install script for the app ${APP_NAME} ${APP_VER}"
      IFS=" "
      bwrap $PARAMS
      IFS=":"
    fi
  done
  #run modules dependent from new installed
elif [ "$1" = "update" ]; then
  REPO_UPDATES=""
  get_repo_updates
  # find all numeric deps (non current)
  DEPS=""
  for APP_NAME3 in $ALL_APP; do
    for APP_VER3 in $(ls $DIR/app/$APP_NAME3); do
      if [ "$APP_VER3" != "current" ]; then
        find_app_deps $DIR/app/$APP_NAME3/$APP_VER3 "Deps" 0
      fi
    done
  done
  DEPS_NON_CURRENT=$DEPS
  #go over all apps
  for APP_NAME in $ALL_APP; do
    CURRENT=$(realpath $DIR/app/$APP_NAME/current)
    APP_VER_CURRENT=""
    for APP_VER in $(ls $DIR/app/$APP_NAME); do
      if [ "$APP_VER" != "current" ]; then
        DEPS=""
        find_app_deps $DIR/app/$APP_NAME/$APP_VER "Deps" 1
        if [ "$CURRENT" = "$DIR/app/$APP_NAME/$APP_VER" ]; then
          # we search the highest possible update version
          NEW_VER=$APP_VER
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
          done <<< "$REPO_UPDATES"
          if [ "$NEW_VER" != "$APP_VER" ]; then
            echo "Installing $APP_NAME $NEW_VER and setting as current"
          fi
        fi
      fi
    done
    IFS=":"
    for APP4 in $DEPS_NON_CURRENT; do
      IFS=" " read -r APP_NAME4 APP_VER4 << EOF
$APP4
EOF
      if [ "$APP_NAME4" = "$APP_NAME" ]; then
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
          done <<< "$REPO_UPDATES"
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
    for DEP in $DEPS; do
      IFS=" " read -r APP_NAME APP_VER << EOF
$DEP
EOF
      find_app_deps $DIR/app/$APP_NAME/$APP_VER "Deps" 1
    done
    if [ "$complete" = 1 ]; then
      break;
    fi
  done
  IFS=":"
  for APP in $DEPS; do
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
  if [ "$DEPS" == "" ]; then
    for APP_NAME in $ALL_APP; do
      ALL_APP_VER=$(ls $DIR/app/$APP_NAME --sort name)
      for APP_VER in $ALL_APP_VER; do
        if [ "$APP_VER" != "current" ]; then
          if [ "$DEPS" != "" ]; then
            DEPS="$DEPS:"
          fi
          DEPS="$DEPS${APP_NAME} ${APP_VER}"
        fi
      done
    done
  fi
  while true; do
    complete=1
    IFS=":"
    for DEP in $DEPS; do
      IFS=" " read -r APP_NAME APP_VER << EOF
$DEP
EOF
      find_app_deps $DIR/app/$APP_NAME/$APP_VER "Deps" 1
    done
    if [ "$complete" = 1 ]; then
      break;
    fi
  done
  IFS=":"
  for APP in $DEPS; do
    IFS=" " read -r APP_NAME APP_VER << EOF
$APP
EOF
    LEN=${#APP_VER}-1
    #fixme: with - dependency we have to find correct version
    if [ "$APP_VER" != "current" ] && [ "${APP_VER:$LEN:1}" != "-" ]; then
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
    fi
  done
elif [ "$1" = "available" ]; then
  REPO_UPDATES=""
  get_repo_updates
#echo "$REPO_UPDATES"
  # find all numeric deps (non current)
  DEPS=""
  for APP_NAME3 in $ALL_APP; do
    for APP_VER3 in $(ls $DIR/app/$APP_NAME3); do
      if [ "$APP_VER3" != "current" ]; then
        find_app_deps $DIR/app/$APP_NAME3/$APP_VER3 "Deps" 0
      fi
    done
  done
  DEPS_NON_CURRENT=$DEPS
  #go over all apps
  for APP_NAME in $ALL_APP; do
    echo App $APP_NAME
    CURRENT=$(realpath $DIR/app/$APP_NAME/current)
    APP_VER_CURRENT=""
    for APP_VER in $(ls $DIR/app/$APP_NAME); do
      if [ "$APP_VER" != "current" ]; then
        DEPS=""
        find_app_deps $DIR/app/$APP_NAME/$APP_VER "Deps" 1
        echo -n "  Version $APP_VER"
        if [ "$CURRENT" = "$DIR/app/$APP_NAME/$APP_VER" ]; then
          echo -n " [current]"
          # we search the highest possible update version
          NEW_VER=$APP_VER
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
          done <<< "$REPO_UPDATES"
          if [ "$NEW_VER" != "$APP_VER" ]; then
            echo -n " [update $NEW_VER]"
          fi
        fi
        if [ "$DEPS" != "" ]; then
          echo -n " [deps $DEPS]"
        fi
        echo
      fi
    done
    IFS=":"
    for APP4 in $DEPS_NON_CURRENT; do
      IFS=" " read -r APP_NAME4 APP_VER4 << EOF
$APP4
EOF
      if [ "$APP_NAME4" = "$APP_NAME" ]; then
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
          done <<< "$REPO_UPDATES"
          if [ "$NEW_VER" != "${APP_VER:-1}" ]; then
            echo -n " [update $NEW_VER]"
          fi
        fi
        echo
      fi
    done
    IFS=$IFSORIG
  done
elif [ "$1" == "" ]; then
  #go over all apps
  for APP_NAME in $ALL_APP; do
    echo App $APP_NAME
    CURRENT=$(realpath $DIR/app/$APP_NAME/current)
    APP_VER_CURRENT=""
    for APP_VER in $(ls $DIR/app/$APP_NAME); do
      if [ "$APP_VER" != "current" ]; then
        DEPS=""
        find_app_deps $DIR/app/$APP_NAME/$APP_VER "Deps" 1
        echo -n "  Version $APP_VER"
        if [ "$CURRENT" = "$DIR/app/$APP_NAME/$APP_VER" ]; then
          echo -n " [current]"
        fi
        if [ "$DEPS" != "" ]; then
          echo -n " [deps $DEPS]"
        fi
        echo
      fi
    done
    IFS=":"
    for APP4 in $DEPS_NON_CURRENT; do
      IFS=" " read -r APP_NAME4 APP_VER4 << EOF
$APP4
EOF
      if [ "$APP_NAME4" = "$APP_NAME" ]; then
        echo "  Dep from other app $APP_VER4"
      fi
    done
    IFS=$IFSORIG
  done
else
  echo "$INFO"
  echo
  echo "Without params:"
  echo "Shows versions and dependiences in /app"
  echo
  echo "With param:"
  echo "help - this info"
  echo "available - gets all repo info and shows versions, dependiences and possible updates in /app"
  echo "backup [package_list] - backup packages and related (or all) to the xz installation files, example: backup \"busybox current:kernel current\""
  echo "install package_list - gets all repo info and install packages from repo"
  echo "remove package_list - remove package and dependencies from /app"
  echo "update - gets all repo info and install all updates"
fi
