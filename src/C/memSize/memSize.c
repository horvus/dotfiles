#include <stdio.h>
#include <stdlib.h>

int main (int argc, char* argv[]) {
    unsigned long memSizeGb;
    unsigned long long memSizeBytes;
    unsigned long long memSizeBits;

    if (argc != 2) {
        printf ("%s\n", "Error: Usage: memSize.exe [unsigned long] $arg1");
        return EXIT_FAILURE;
    }

    memSizeGb = atoi(argv[1]);

    printf ("%s%lu\n", "Memory size in Gb: ", memSizeGb);
    
    memSizeBytes = memSizeGb * (1024 * 1024 * 1024);
    memSizeBits = memSizeBytes * 8;

    printf ("Memory size in bytes: %llu\n", memSizeBytes);
    printf ("Memory size in bits: %llu\n", memSizeBits);

    return EXIT_SUCCESS;
}

