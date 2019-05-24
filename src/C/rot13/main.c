#include "encryptRot13.h"

int main (int argc, char* argv[]) {
    if (argc != 2) {
        printf ("Usage: rot13.exe $argv\n");
        return 1;
    }
    printf ("%s\n%s(%d):\n", "*** ROT13 encryption or decryption program ***","String entered ", SIZE);

    printf ("%s", argv[1]);
    puts("");

    encryptRot13 (argv[1]);
    return 0;
}
