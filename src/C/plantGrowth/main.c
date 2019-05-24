#include "plantGrowth.h"

int main (int argc, char* argv[]) {
    if (argc != 4) {
        printf ("%s\n%s\n", "Error: Usage: plantGrowth.exe [double] $arg1 $arg2 $arg3 $arg4", "Usage: Enter the initial mass, the growth rate and the years of growth next to the program name.");
        return EXIT_FAILURE;
    }
    
    plantGrowth (atof(argv[1]), atof(argv[2]), atof(argv[3]) );

    return EXIT_SUCCESS;
}
