#include "xor.h"
// Swaps x and y through bitwise manipulation, without any temp variable
void xor_swap(int *x, int *y) {
    if (x != y) {
        *x ^= *y;
        *y ^= *x;
        *x ^= *y;
    }
    // if statement safeguard against aliasing:
    // always use one of these when xor_swapping 
    else {
        puts("XOR swap failed: arguments have same memory address");
    }
}
