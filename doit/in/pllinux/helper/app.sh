DIR="/mnt/x"
ALL_APP=$(ls $DIR/app)

for APP_NAME in $ALL_APP
do
  echo Application $APP_NAME
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