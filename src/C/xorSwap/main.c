#include "xor.h" 
/* Example usage */
int main(int argc, char* argv[]) {
    if (argc != 3) {
        printf ("%s\n", "Error: Usage: Pass two arguments a and b to swap");
        return 1;
    }

    int a = atoi(argv[1]);
    int b = atoi(argv[2]);
    int *aPtr = &a;
    int *bPtr = &b;
    
    // Passing the same memory location causes aliasing:
    // the value is zeroed out and lost
    xor_swap(aPtr, bPtr);
    
    printf("a = %d, b = %d\n", a, b);
    return 0;
}
