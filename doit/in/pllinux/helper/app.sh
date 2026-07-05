#!/mnt/x/app/busybox/current/bin/sh
INFO="Package manager. Version from 6 Jul 2026. Part of PLLINUX"
DIR="/mnt/x" # in real system /
SYSTEM_APPS="busybox:bwrap:dinit:e2fsprogs:initramfs:kbd:kernel:ldso:libc:libtinfo:nftables:pllinux:util-linux" # we cannot remove "current" version for these apps

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
                DEPS="$DEPS$line"
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
        while read -r line; do
          REPO_UPDATES="$REPO_UPDATES$line $repo_line
"
        done < "${repo_line}app.repo.updates"
      fi
    fi
  done < "app.repos"
}

# we search the highest possible update version
find_latest_latest_app_version_in_repo() {
  local APP_NAME=$1
  while read -r line; do
    IFS=" " read -r APP_NAME10 APP_VER10 APP_REPO10 << EOF
$line
EOF
    if [ "$APP_NAME" = "$APP_NAME10" ]; then
      compare_app_version $NEW_VER $APP_VER10
      if [ $first_bigger = "-1" ] || [ "$NEW_VER" = 0 ]; then
        NEW_VER=$APP_VER10
        NEW_REPO=$APP_REPO10
      fi
    fi
  done <<< "$REPO_UPDATES"
}

# we search the highest/latest version but lower than specified in APP_VER
find_latest_app_version_lower_than_given_in_repo() {
  local APP_NAME=$1
  MAX_VER=$2
  while read -r line; do
    IFS=" " read -r APP_NAME10 APP_VER10 APP_REPO10 << EOF
$line
EOF
    if [ "$APP_NAME" = "$APP_NAME10" ]; then
      compare_app_version $MAX_VER $APP_VER10
      if [ $first_bigger = "1" ]; then
        compare_app_version $NEW_VER $APP_VER10
        if [ $first_bigger = "-1" ]; then
          NEW_VER=$APP_VER10
          NEW_REPO=$APP_REPO10
        fi
      fi
    fi
  done <<< "$REPO_UPDATES"
}

find_all_app_versions_in_repo() {
  UPDATE_CURRENT=$1
  NEW_DEPS=""
  IFS=":"
  for DEP in $DEPS; do
    IFS=" " read -r APP_NAME20 APP_VER20 << EOF
$DEP
EOF
    NEW_VER=0
    NEW_REPO="-"
    LEN=${#APP_VER20}-1
    if [ "$APP_VER20" = "current" ]; then
      if [ ! -d "$DIR/app/${APP_NAME20}/current" ] || [ $UPDATE_CURRENT = "1" ]; then
        find_latest_latest_app_version_in_repo $APP_NAME20
      else
        NEW_VER="current"
      fi
    elif [ "$((LEN))" -lt 5 ] || [ ${APP_VER20:6:1} != "_" ]; then
      # version without date
      while read -r line; do
        IFS=" " read -r APP_NAME21 APP_VER21 APP_REPO21 << EOF
$line
EOF
        if [ "$APP_NAME20" = "$APP_NAME21" ] && [ "$APP_VER20" = "${APP_VER21:7}" ]; then
          if [ $NEW_VER == 0 ] || [ "${APP_VER21:0:6}" \> "${NEW_VER:0:6}" ]; then
            NEW_VER=$APP_VER21
            NEW_REPO=$APP_REPO21
          fi
        fi
      done <<< "$REPO_UPDATES"
    elif [ "${APP_VER20:$LEN:1}" = "-" ]; then
      find_latest_app_version_lower_than_given_in_repo $APP_NAME20 ${APP_VER20:0:$LEN}
    else
      # we get version string "as is" and search in repo
      while read -r line; do
        IFS=" " read -r APP_NAME21 APP_VER21 APP_REPO21 << EOF
$line
EOF
        if [ "$APP_NAME20" = "$APP_NAME21" ] && [ "$APP_VER20" = "$APP_VER21" ]; then
          NEW_VER=$APP_VER21
          NEW_REPO=$APP_REPO21
        fi
      done <<< "$REPO_UPDATES"
    fi
    NEW_DEPS="$NEW_DEPS${APP_NAME20} ${NEW_VER} ${NEW_REPO}:"
  done
}

install_single_app() {
  rm -f -r /tmp/app
  UPDATE_CURRENT=$1
  INSTALL_ERROR=0
  while true; do
    complete=1
    find_all_app_versions_in_repo $UPDATE_CURRENT
    IFS=":"
    for DEP in $NEW_DEPS; do
      IFS=" " read -r APP_NAME APP_VER APP_REPO << EOF
$DEP
EOF
      if [ -d "$DIR/app/${APP_NAME}/${APP_VER}" ]; then
        if [ $UPDATE_CURRENT = "0" ]; then
          echo "  App ${APP_NAME} ${APP_VER} already installed. Skipping"
        fi
      elif [ "$APP_REPO" = "-" ]; then
#        if [ $UPDATE_CURRENT = "0" ]; then
          echo "  App ${APP_NAME} not found in repo. Skipping"
#        fi
      elif [ ! -f "${APP_REPO}${APP_NAME}_${APP_VER}.tar.xz" ]; then
        echo "  File ${APP_REPO}${APP_NAME}_${APP_VER}.tar.xz does not exist. Skipping"
        INSTALL_ERROR=1
        break
      elif [ ! -d "/tmp/app/${APP_NAME}/${APP_VER}" ]; then
        mkdir /tmp/app 2> /dev/null
        mkdir /tmp/app/${APP_NAME} 2> /dev/null
        mkdir /tmp/app/${APP_NAME}/${APP_VER} 2> /dev/null
        olddir=$(pwd)
        cd /tmp/app/${APP_NAME}/${APP_VER}
        echo "  Unpacking $olddir/${APP_REPO}${APP_NAME}_${APP_VER}.tar.xz to /tmp/app"
        tar -xvf $olddir/${APP_REPO}${APP_NAME}_${APP_VER}.tar.xz 2> /dev/null > /dev/null
        cd ..
        if [ $UPDATE_CURRENT = "1" ] || [ ! -d "$DIR/app/${APP_NAME}/current" ]; then
          ln -s ${APP_VER} current
        fi
        cd $olddir
        find_app_deps /tmp/app/${APP_NAME}/${APP_VER} "Deps" 1
      fi
    done
    if [ "$complete" = 1 ]; then
      break;
    fi
  done
  if [ -d "/tmp/app" ] && [ "$INSTALL_ERROR" = "0" ]; then
    # searching and running installation scripts if any
    IFS=$IFSORIG
    for APP_NAME in $(ls /tmp/app --sort name); do
      for APP_VER in $(ls /tmp/app/${APP_NAME}); do
        if [ "$APP_VER" != "current" ]; then
          INSTALL_SCRIPT=""
          find_app_install_script /tmp/app/$APP_NAME/$APP_VER
          if [ "$INSTALL_SCRIPT" != "" ]; then
            DEPS=""
            find_app_deps /tmp/app/${APP_NAME}/${APP_VER} "Deps" 1
            find_all_app_versions_in_repo
            PARAMS=""
            IFS=":"
            for DEP in $NEW_DEPS; do
              IFS=" " read -r APP_NAME3 APP_VER3 APP_REPO3 << EOF
$DEP
EOF
              if [ -d "/tmp/app/${APP_NAME3}/${APP_VER3}" ]; then
                PARAMS="$PARAMS --ro-bind /tmp/app/${APP_NAME3}/${APP_VER3} /app/${APP_NAME3}/${APP_VER3} "
              elif [ -d "$DIR/app/${APP_NAME3}/${APP_VER3}" ]; then
                PARAMS="$PARAMS --ro-bind $DIR/app/${APP_NAME3}/${APP_VER3} /app/${APP_NAME3}/${APP_VER3} "
              else
                echo "Something wrong. Dependency ${APP_NAME3} ${APP_VER3}"
              fi
            done
            PARAMS="$PARAMS --ro-bind $DIR/app/busybox/current /app/busybox/current "
            PARAMS="$PARAMS --ro-bind /tmp/app/${APP_NAME}/${APP_VER} /app/${APP_NAME}/${APP_VER} "
            mkdir -p /tmp/app/${APP_NAME}/${APP_VER}/dynamic || true
            PARAMS="$PARAMS --bind /tmp/app/${APP_NAME}/${APP_VER}/dynamic /app/${APP_NAME}/${APP_VER}/dynamic "
            PARAMS="$PARAMS --dev dev --unshare-all --tmpfs tmp "
            PARAMS="$PARAMS --chdir /app/${APP_NAME}/${APP_VER}/scripts "
            PARAMS="$PARAMS /app/busybox/current/bin/sh $INSTALL_SCRIPT"
            echo "  Starting install script for the app ${APP_NAME} ${APP_VER}"
            IFS=" "
            bwrap $PARAMS
            IFS=$IFSORIG
          fi
        fi
      done
    done
  fi
  #fixme:run modules dependent from new installed
#  if [ -d "/tmp/app" ]; then
#    rsync -a /tmp/app $DIR
#    rm -r -f /tmp/app
#  fi
}

# we search the highest/latest version but lower than specified in MAX_VER
# returns NEW_VER
find_latest_app_version_lower_than_given_in_app() {
  local APP_NAME=$1
  local MAX_VER=$2
  IFS=$IFSORIG
  for APP_VER in $(ls $DIR/app/$APP_NAME); do
    if [ "$APP_VER" != "current" ]; then
      compare_app_version $MAX_VER $APP_VER
      if [ $first_bigger = "1" ]; then
        compare_app_version $NEW_VER $APP_VER
        if [ $first_bigger = "-1" ]; then
          NEW_VER=$APP_VER
        fi
      fi
    fi
  done
}

find_current_app_versions_in_app() {
  NEW_DEPS=""
  IFS=":"
  for DEP in $DEPS; do
    IFS=" " read -r APP_NAME20 APP_VER20 << EOF
$DEP
EOF
    NEW_VER=$APP_VER20
    LEN=${#APP_VER20}-1
    IFS=$IFSORIG
    if [ -d "$DIR/app/$APP_NAME20" ]; then
      if [ "$APP_VER20" = "current" ]; then
        CURRENT=$(realpath $DIR/app/$APP_NAME20/current)
        for APP_VER21 in $(ls $DIR/app/$APP_NAME20); do
          if [ "$CURRENT" = "$DIR/app/$APP_NAME20/$APP_VER21" ]; then
            NEW_VER=$APP_VER21
            break
          fi
        done
      elif [ "$((LEN))" -lt 5 ] || [ ${APP_VER20:6:1} != "_" ]; then
        # version without date
        for APP_VER21 in $(ls $DIR/app/$APP_NAME20); do
          if [ "$APP_VER20" = "${APP_VER21:7}" ]; then
            if [ $NEW_VER == $APP_VER ] || [ "${APP_VER21:0:6}" \> "${NEW_VER:0:6}" ]; then
              NEW_VER=$APP_VER21
            fi
          fi
        done
      elif [ "${APP_VER20:$LEN:1}" = "-" ]; then
        # we search the highest/latest version but lower than specified in APP_VER
        MAX_VER=${APP_VER20:0:$LEN}
        for APP_VER31 in $(ls $DIR/app/$APP_NAME20); do
         compare_app_version $MAX_VER $APP_VER21
          if [ $first_bigger = "1" ]; then
            compare_app_version $NEW_VER $APP_VER31
            if [ $first_bigger = "-1" ]; then
              NEW_VER=$APP_VER31
            fi
          fi
        done
      fi
    fi
    NEW_DEPS="$NEW_DEPS${APP_NAME20} ${NEW_VER}:"
  done
}

IFSORIG=$IFS

if [ "$1" = "install" ] || [ "$1" = "installcheck" ]; then
  if [ "$2" != "" ]; then
    REPO_UPDATES=""
    get_repo_updates
    IFS=":"
    for DEP in $2; do
      IFS=" " read -r APP_NAME APP_VER << EOF
$DEP
EOF
      if [ "$APP_VER" == "" ]; then
        APP_VER=current
      fi
      echo "Processing app ${APP_NAME} ${APP_VER}"
      DEPS="${APP_NAME} ${APP_VER}"
      install_single_app 0
      if [ "$1" = "install" ]; then
        if [ -d "/tmp/app" ] && [ "$INSTALL_ERROR" = "0" ]; then
          rsync -a /tmp/app $DIR
          echo "Installing to /app"
   #    rm -r -f /tmp/app
        fi
      fi
    done
  fi
elif [ "$1" = "update" ] || [ "$1" == "upgrade" ] || [ "$1" = "updatecheck" ] || [ "$1" == "upgradecheck" ]; then
  REPO_UPDATES=""
  get_repo_updates
  APP_LIST=$2
  if [ "$APP_LIST" = "" ]; then
    APP_LIST=$(ls $DIR/app --sort name)
  fi 
  # find all deps with concrete version number (non current)
  DEPS=""
  for APP_NAME3 in $APP_LIST; do
    for APP_VER3 in $(ls $DIR/app/$APP_NAME3); do
      if [ "$APP_VER3" != "current" ]; then
        find_app_deps $DIR/app/$APP_NAME3/$APP_VER3 "Deps" 0
      fi
    done
  done
  DEPS_NON_CURRENT=$DEPS
  for APP_NAME in $APP_LIST; do
    DEPS="${APP_NAME} current"
    install_single_app 1
    if [ "$1" = "update" ] || [ "$1" == "upgrade" ]; then
      if [ -d "/tmp/app" ]; then
        rsync -a /tmp/app $DIR
   #    rm -r -f /tmp/app
      fi
    fi
    IFS=":"
    for APP4 in $DEPS_NON_CURRENT; do
      IFS=" " read -r APP_NAME4 APP_VER4 << EOF
$APP4
EOF
      if [ "$APP_NAME4" = "$APP_NAME" ]; then
        DEPS="${APP_NAME4} ${APP_VER4}"
        find_all_app_versions_in_repo 0
        IFS=" " read -r APP_NAME5 APP_VER5 NEW_REPO5 << EOF
$NEW_DEPS
EOF
        if [ ! -d "$DIR/app/${APP_NAME}/${APP_VER5}" ]; then
          DEPS="${APP_NAME} ${APP_VER5}"
          install_single_app 0
          if [ "$1" = "update" ] || [ "$1" == "upgrade" ]; then
            if [ -d "/tmp/app" ]; then
              rsync -a /tmp/app $DIR
         #    rm -r -f /tmp/app
            fi
          fi
        fi
      fi
    done
    IFS=" "
  done
elif [ "$1" = "delete" ] || [ "$1" = "deletecheck" ] || [ "$1" = "remove" ] || [ "$1" = "removecheck" ]; then
  if [ "$2" != "" ]; then
    DEPS=""
    IFS=":"
#    for DEP in $2; do
#      IFS=" " read -r APP_NAME APP_VER << EOF
#$DEP
#EOF
#      if [ "$APP_VER" = "" ]; then
#        APP_VER="current"
#      fi
#      if [ $DEPS != "" ]; then
#        DEPS="$DEPS:"
#      fi
#      DEPS="$DEPS${APP_NAME} ${APP_VER}"
#    done
    DEPS=$2
    # finding and dependencies and dependencies from their dependencies
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
    # replace everything with concrete version numbers
    find_current_app_versions_in_app
    DEPS_FROM_APP_TO_REMOVE=$NEW_DEPS
#    echo $DEPS_FROM_APP_TO_REMOVE
    # get deps from all other apps than apps for removing
    DEPS_FROM_OTHER_APPS=""
    for APP_NAME in $(ls $DIR/app --sort name); do
      for APP_VER in $(ls $DIR/app/$APP_NAME); do
        if [ $APP_VER != "current" ]; then
          found=0
          IFS=":"
          for APP in $DEPS_FROM_APP_TO_REMOVE; do
            IFS=" " read -r APP_NAME2 APP_VER2 << EOF
$APP
EOF
            if [ "$APP_NAME" = "$APP_NAME2" ] && [ "$APP_VER" = "$APP_VER2" ]; then
              found=1
              break
            fi
          done
          IFS=$IFSORIG
          if [ $found = "0" ]; then
            DEPS=""
            find_app_deps $DIR/app/$APP_NAME/$APP_VER "Deps" 1
            if [ "$DEPS" != "" ]; then
              # replace everything with concrete version numbers
              find_current_app_versions_in_app
              DEPS_FROM_OTHER_APPS="${DEPS_FROM_OTHER_APPS}$NEW_DEPS"
            fi
          fi
        fi
      done
    done
#    echo $DEPS_FROM_OTHER_APPS
    # removing
    IFS=":"
    for APP in $DEPS_FROM_APP_TO_REMOVE; do
      IFS=" " read -r APP_NAME APP_VER << EOF
$APP
EOF
      DONT_REMOVE=0
      if [ ! -d "$DIR/app/$APP_NAME/$APP_VER" ]; then
        echo "App $APP_NAME $APP_VER not installed. Skipping" 
        DONT_REMOVE=1
      fi
      if [ "$DONT_REMOVE" = "0" ]; then
        for APP_NAME2 in $SYSTEM_APPS; do
          if [ "$APP_NAME" = "$APP_NAME2" ]; then
            CURRENT=$(realpath $DIR/app/$APP_NAME/current)
            if [ "$DIR/app/$APP_NAME/$APP_VER" = "$CURRENT" ]; then
              echo "Cannot remove $APP_NAME $APP_VER (current). Required for system work" 
              DONT_REMOVE=1
              break
            fi
          fi
        done
      fi
      if [ "$DONT_REMOVE" = "0" ]; then
        for APP2 in $DEPS_FROM_OTHER_APPS; do
          IFS=" " read -r APP_NAME2 APP_VER2 << EOF
$APP2
EOF
          if [ "$APP_NAME" = "$APP_NAME2" ] && [ "$APP_VER" = "$APP_VER2" ]; then
            echo "$APP_NAME $APP_VER cannot be removed because of dependency"
            DONT_REMOVE=1
            break
          fi
        done
        IFS=":"
        if [ $DONT_REMOVE == "0" ]; then
          if [ "$1" = "delete" ] || [ "$1" = "remove" ]; then
            echo "Removing app $APP_NAME $APP_VER"
          else
            echo "(check) Removing app $APP_NAME $APP_VER"
          fi
        fi
      fi
    done
  fi
elif [ "$1" = "backup" ]; then
  DEPS=$2
  if [ "$DEPS" == "" ]; then
    for APP_NAME in $(ls $DIR/app --sort name); do
      for APP_VER in $(ls $DIR/app/$APP_NAME --sort name); do
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
elif [ "$1" = "help" ]; then
  echo "$INFO"
  echo
  echo "[name_part]                 - shows versions and dependiences in the /app for all or specified apps"
  echo "available [name_part]       - gets repo info and shows versions, dependiences and possible updates for the /app for all or specified apps"
  echo "backup [package_list]       - backup packages and related packages from the /app (all, when \"package_list\" not given) to the xz package files"
  echo "                              Example: backup \"busybox current:kernel:pllinux 260221_0.1:mc:x 0.2\""
  echo
  echo "install package_list        - gets repo info and install packages from the repo."
  echo "                              Note: it takes latest and greatest available version, but doesn't update \"current\" links for dependencies."
  echo "                              Example: install \"mc:kernel 7.1.1:mc 260232_0.1\""
  echo "installcheck package_list   - like install, but shows info only (no updates in the /app)"
  echo
  echo "delete package_list         - remove package and dependencies from the /app"
  echo "deletecheck package_list    - like delete, but shows info only (no updates in the /app)"
  echo "remove package_list         - like delete"
  echo "removecheck package_list    - like delete, but shows info only (no updates in the /app)"
  echo
  echo "update [package_list]       - gets repo info and install updates in the /app"
  echo "                              Note: Updates \"current\" links when necessary"
  echo "                              Example: update \"mc:busybox\""
  echo "updatecheck [package_list]  - like update, but shows info only (no updates in the /app)"
  echo "upgrade [package_list]      - like update"
  echo "upgradecheck [package_list] - like update, but shows info only (no updates in the /app)"
  echo
  echo "help                        - this info"
  echo
  echo "Repo list:"
  echo $(cat app.repos)
else
  MASK=""
  if [ "$1" = "available" ]; then
    REPO_UPDATES=""
    get_repo_updates
    if [ "$2" != "" ]; then
      MASK=$2
    fi
  elif [ "$1" != "" ]; then
    MASK=$1
  fi
  # find all deps with concrete version number (non current)
  DEPS=""
  for APP_NAME3 in $(ls $DIR/app --sort name); do
    for APP_VER3 in $(ls $DIR/app/$APP_NAME3); do
      if [ "$APP_VER3" != "current" ]; then
        find_app_deps $DIR/app/$APP_NAME3/$APP_VER3 "Deps" 0
      fi
    done
  done
  DEPS_NON_CURRENT=$DEPS
  #go over all apps
  for APP_NAME in $(ls $DIR/app --sort name); do
    DISP=0
    if [ "$MASK" = "" ]; then
      DISP=1
    else
      case $APP_NAME in
        *$MASK* )
           DISP=1
           ;;
      esac
    fi
    if [ "$DISP" = "0" ]; then
      continue
    fi
    echo App $APP_NAME
    CURRENT=$(realpath $DIR/app/$APP_NAME/current)
    for APP_VER in $(ls $DIR/app/$APP_NAME); do
      if [ "$APP_VER" != "current" ]; then
        if [ "$CURRENT" = "$DIR/app/$APP_NAME/$APP_VER" ]; then
          echo -n "  Version [$APP_VER]"
        else
          echo -n "  Version $APP_VER"
        fi
        DEPS=""
        find_app_deps $DIR/app/$APP_NAME/$APP_VER "Deps" 1
        if [ "$DEPS" != "" ]; then
          echo -n " [deps $DEPS]"
        fi
        if [ "$1" = "available" ] && [ "$CURRENT" = "$DIR/app/$APP_NAME/$APP_VER" ]; then
          NEW_VER=$APP_VER
          find_latest_latest_app_version_in_repo $APP_NAME
          if [ "$NEW_VER" != "$APP_VER" ]; then
            echo -n " [update $NEW_VER]"
          fi
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
        echo -n "  Dep from the other app $APP_VER4"
        if [ "$1" = "available" ]; then
          DEPS="${APP_NAME4} ${APP_VER4}"
          find_all_app_versions_in_repo 0
          IFS=" " read -r APP_NAME5 APP_VER5 NEW_REPO5 << EOF
$NEW_DEPS
EOF
          if [ ! -d "$DIR/app/${APP_NAME}/${APP_VER5}" ]; then
            echo -n " [update $APP_VER5]"
          fi
        fi
        echo
      fi
    done
    IFS=$IFSORIG
  done
fi
