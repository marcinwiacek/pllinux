#!/app/busybox/current/bin/sh
# Helper script to recreate entries in /etc. In the future will be included into app.sh script

DIR="/" # path with / in the end. In real system /
if [ -d "/mnt/x" ]; then
  DIR="/mnt/x/"
fi
if [ -d "/pllinux" ]; then
  DIR="/pllinux/"
fi

IFSORIG=$IFS

APP_LIST=$(${DIR}app/busybox/current/bin/ls /app)
for APP_NAME in $APP_LIST; do
  if [ -e "${DIR}app/${APP_NAME}/current/readme.md" ]; then
    sectionprocess=0
    destpath=""
    while read -r line; do
      if [ "$line" = "**X11-conf**" ]; then
        sectionprocess=1
        destpath="etc/x11/xorg.conf.d"
      elif [ "$line" = "**X11-modules**" ]; then
        sectionprocess=1
        destpath="etc/x11/modules"
      elif [ "$line" = "**Vulkan-modules**" ]; then
        sectionprocess=1
        destpath="etc/vulkan"
      elif [ "$line" = "" ]; then
        sectionprocess=0;
      elif [ "$sectionprocess" = 1 ]; then
        IFS=":"
        for folder in $line; do
          if [ -d "${DIR}app/${APP_NAME}/current/$folder" ]; then
            if [ ! -d "${DIR}$destpath" ]; then
              mkdir ${DIR}$destpath
            fi
            # we don't have many dirs level. for now it's enough simple for...if, no need to make it recurrent
            IFS=$IFSORIG
            LISTLIST=$(${DIR}app/busybox/current/bin/ls ${DIR}app/${APP_NAME}/current/$folder)
            for NAMENAME in $LISTLIST; do
echo linking1 /app/${APP_NAME}/current/$folder/$NAMENAME to the $DIR$destpath/$NAMENAME
              cd ${DIR}$destpath
              if [ -d ${DIR}app/${APP_NAME}/current/$folder/$NAMENAME ]; then
                if [ ! -d $NAMENAME ]; then mkdir $NAMENAME; fi
              else
                if [ ! -f $NAMENAME ]; then ln -s /app/${APP_NAME}/current/$folder/$NAMENAME $NAMENAME; fi
              fi
              if [ -d ${DIR}app/${APP_NAME}/current/$folder/$NAMENAME ]; then
                cd $NAMENAME
                LISTLIST2=$(${DIR}app/busybox/current/bin/ls ${DIR}app/${APP_NAME}/current/$folder/$NAMENAME)
                for NAMENAME2 in $LISTLIST2; do
echo linking2 /app/${APP_NAME}/current/$folder/$NAMENAME/$NAMENAME2 to the $DIR$destpath/$NAMENAME/$NAMENAME2
                  if [ ! -f $NAMENAME2 ]; then ln -s /app/${APP_NAME}/current/$folder/$NAMENAME/$NAMENAME2 $NAMENAME2; fi
                done
                cd ..
              fi
            done
          fi
        done
      fi
    done < ${DIR}app/${APP_NAME}/current/readme.md
  fi
done
