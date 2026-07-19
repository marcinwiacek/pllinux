#!/app/busybox/current/bin/sh
# Creates bwrap for user
# Options: mnt - user has got access to /mnt
#          net - access to net
#          reset|services - access to the /app/dinit
#          app - user has got access to everything in /app
#          "app name1 ver1:name2 ver2:name3 ver3" - access to apps
# Example: mnt "app mc current:bash current"

# green [time] user:folder $
# OR
# green [time] user:folder amber git branch name $
export PS1="\e[32m[\t] $USER:\w\$(if [ -f "/app/git/current/bin/git" ] && git rev-parse --git-dir > /dev/null 2>&1; then echo -n \" \e[33m\";git branch --show-current; fi) $ \e[m"

processesall=0
for ARG in "$@"
do
  if [ "$ARG" = "processesall" ]; then processesall=1; fi
done
if [ "$processesall" = 1 ]; then
  PARAMS="$PARAMS --unshare-user-try --unshare-ipc --unshare-net --unshare-uts --unshare-cgroup-try "
else
  PARAMS="$PARAMS --unshare-all "
fi
#PARAMS="$PARAMS --perms 0777 "
PARAMS="$PARAMS --dev dev "
#PARAMS="$PARAMS --dev-bind-try /dev/null /dev/null "
#PARAMS="$PARAMS --chmod 0777 /dev "
PARAMS="$PARAMS --tmpfs tmp "
PARAMS="$PARAMS --bind home/$USER/files home "
PARAMS="$PARAMS --bind home/$USER other "
PARAMS="$PARAMS --ro-bind /etc/localtime /etc/localtime "
PARAMS="$PARAMS --ro-bind /lib64 lib64 "
allapp=0
deps=""
path=""
shell=""


for ARG in "$@"
do
#  echo $ARG
  if [ "$ARG" = "services" ] || [ "$ARG" = "reset" ]; then 
     deps="$deps:dinit current"; 
     PARAMS="$PARAMS --bind run run "
  fi
  if [ "$ARG" = "processes" ] || [ "$ARG" = "processesall" ]; then 
     PARAMS="$PARAMS --proc proc "
  fi
  if [ "$ARG" = "mnt" ]; then PARAMS="$PARAMS --bind mnt mnt " ; fi
  if [ "$ARG" = "net" ]; then PARAMS="$PARAMS --share-net --ro-bind /etc/resolv.conf /etc/resolv.conf " ; fi
  if [ "${ARG:0:3}" = "app" ]; then
    if [ "$ARG" = "app" ]; then
      allapp=1;
    else
      deps="$deps:${ARG:4}";
#      echo $deps
    fi
  fi
done
#echo $deps
deps="$deps:bwrap current"
#echo $deps
while true; do
  complete=1
  IFS=":"
  for DEP in $deps
  do
    if [ -n "$DEP" ]; then
      IFS=" " read -r APP_NAME APP_VER << EOF
$DEP
EOF
#      echo "-$APP_NAME-$APP_VER-"
      if [ -e "/app/${APP_NAME}/${APP_VER}/readme.md" ]; then
        sectionDeps=0
        sectionPath=0
        sectionShell=0
        while read -r line; do
          if [ "$line" = "**PATH**" ]; then
            sectionPath=1
          elif [ "$line" = "**SHELL**" ]; then
            sectionShell=1
          elif [ "$line" = "**Deps**" ]; then
            sectionDeps=1
          elif [ "$line" = "" ]; then
            sectionDeps=0;
            sectionPath=0;
            sectionShell=0;
          elif [ "$sectionDeps" = 1 ]; then
            case $deps in
              *$line* )
                ;;
               * )
                complete=0
                deps=$deps:$line
#                echo $deps
                ;;
            esac
          elif [ "$sectionShell" = 1 ]; then
            shell=/app/${APP_NAME}/${APP_VER}/$line
          elif [ "$sectionPath" = 1 ]; then
            IFS=":"
            for folder in $line
            do
              if [ "$folder" = "." ]; then
                case $path in
                  */app/${APP_NAME}/${APP_VER}* )
                    ;;
                  * )
		    if [ "$path" = "" ]; then
                      path=/app/${APP_NAME}/${APP_VER}
                    else
                      path=$path:/app/${APP_NAME}/${APP_VER}
                    fi
                    ;;
                esac
              else
                case $path in
                  */app/${APP_NAME}/${APP_VER}/$folder* )
                    ;;
                  * )
		    if [ "$path" = "" ]; then
                      path=/app/${APP_NAME}/${APP_VER}/$folder
                    else
                      path=$path:/app/${APP_NAME}/${APP_VER}/$folder
                    fi
                    ;;
                esac
              fi
            done
          fi
        done < /app/${APP_NAME}/${APP_VER}/readme.md
      fi
    fi
  done
  if [ "$complete" = 1 ]; then break; fi
done
if [ "$allapp" = "1" ]; then
  PARAMS="$PARAMS --ro-bind app app "
else
  IFS=":"
  for DEP in $deps
  do
    if [ -n "$DEP" ]; then
      IFS=" " read -r APP_NAME APP_VER << EOF
$DEP
EOF
      PARAMS="$PARAMS --ro-bind app/${APP_NAME}/${APP_VER} app/${APP_NAME}/${APP_VER} "
#      PARAMS="$PARAMS --ro-bind $(/app/busybox/current/bin/realpath "/app/${APP_NAME}/${APP_VER}") $(/app/busybox/current/bin/realpath "/app/${APP_NAME}/${APP_VER}") "
    fi
  done
fi
PARAMS="$PARAMS --setenv PATH $path "
PARAMS="$PARAMS --setenv SHELL $shell "
IFS="/"
LAST=""
for PART in $shell
do
  LAST=$PART;
done
PARAMS="$PARAMS --setenv HOME /other/app/$LAST "
PARAMS="$PARAMS -- $LAST"
#echo "$PARAMS"
cd /
IFS=" "
/app/bwrap/current/bin/bwrap $PARAMS
