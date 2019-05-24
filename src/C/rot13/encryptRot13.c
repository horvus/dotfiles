/* ROT13 encryption procedure */
#include "encryptRot13.h"

void encryptRot13 (char str[SIZE]) {
   for (int i=0; i<SIZE; i++) {
        str[i] -= 13;
        printf ("%c", str[i]);
   }
   puts("\n");
}

