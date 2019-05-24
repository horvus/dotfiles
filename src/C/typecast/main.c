#include <stdio.h>
#include <stdlib.h>

int main (int argc, char* argv[])
    {
    int var1;
    int var2;
    double result;

    if (argc != 3) 
        {
        printf ("%s\n", "Error: Usage.");
        return 1;
        }

    var1 = atoi(argv[1]);
    var2 = atoi(argv[2]);

    result = (double)var1 / var2;

    printf("%s%lf\n", "Result equals ", result);

    return 0;
    }
