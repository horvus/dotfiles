#include <stdio.h>

int main (void) {
    int a = 1;
    int b = 2;
    int c = a + b;
    int d = a + b + c;
    int e = a + b + c + d;
    
    printf ("%d\n", a);
    printf ("%d\n", b);
    printf ("%d\n", c);
    printf ("%d\n", d);
    printf ("%d\n", e);

    return 0;
}

