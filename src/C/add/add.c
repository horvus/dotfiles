#include <stdio.h>
#include <stdlib.h>

int main (int argc, char* argv[]) {
    if (argc != 3) {
        printf ("%s\n", "Usage: add.exe $arg1 $arg2");
        return EXIT_FAILURE;
    } 

    int res = atoi (argv[1]) + atoi (argv[2]);
    printf ("%d", res);

    return EXIT_SUCCESS;
}

