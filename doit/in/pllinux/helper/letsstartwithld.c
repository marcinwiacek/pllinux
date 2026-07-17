#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

//serdeczne pozdrowienia dla Michala

int main() {
    FILE* fptr;
    char buff[100];

    fptr = fopen("readme.md", "r");
    if (fptr != NULL) {
      bool sectionDeps=false;
      while (fgets(buff, sizeof(buff), fptr)) {
        if (sectionDeps == false) {
          if (strlen(buff)>=8 && !strncmp(buff,"**Deps**",8)) sectionDeps=true;
        } else {
          if (strlen(buff)<3) {
            sectionDeps=false;
          } else {
            buff[strlen(buff)-1]=0;
            int pos=-1;
            for (int i=0;i<sizeof(buff);i++) {
               if (buff[i]==' ') {
                 buff[i]=0;
                 pos = i;
                 break;
               }
            }
            if (pos != -1) {
              printf("/app/%s/%s/lib%c", buff,buff+pos+1,10);
            }
          }
        }
      }
      fclose(fptr);
    }

    return 0;
}