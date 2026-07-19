#!/app/busybox/current/bin/sh
cd /

APP_LIST=$(/app/busybox/current/bin/ls /app)
path=""
for APP_NAME in $APP_LIST; do
  if [ -e "/app/${APP_NAME}/current/readme.md" ]; then
    sectionPath=0
    sectionPathFirst=0
    while read -r line; do
      if [ "$line" = "**PATH**" ]; then
        sectionPath=1
      elif [ "$line" = "**PATH_First**" ]; then
        sectionPathFirst=1
      elif [ "$line" = "" ]; then
        sectionPath=0;
        sectionPathFirst=0;
      elif [ "$sectionPath" = 1 ] || [ "$sectionPathFirst" = 1 ]; then
        IFS=":"
        for folder in $line
        do
          if [ "$folder" = "." ]; then
            folder=""
          else
            folder="/$folder"
          fi
          if [ "$path" = "" ]; then
            path=/app/${APP_NAME}/current$folder
          else
            if [ "$sectionPathFirst" = 1 ]; then
              path=/app/${APP_NAME}/current$folder:$path
            else
              path=$path:/app/${APP_NAME}/current$folder
            fi
          fi
        done
      fi
    done < /app/${APP_NAME}/current/readme.md
  fi
done

export PATH=$path
export SHELL=/app/busybox/current/bin/sh
export HOME=/other/app/sh
mkdir $HOME 2> /dev/null

# red [time] user:folder #
# OR
# red [time] user:folder amber git branch name #
export PS1="\e[31m[\t] root:\w\$(if [ -f "/app/git/current/bin/git" ] && /app/git/current/git rev-parse --git-dir > /dev/null 2>&1; then echo -n \" \e[33m\";/app/git/current/git branch --show-current; fi) # \e[m"

sh
