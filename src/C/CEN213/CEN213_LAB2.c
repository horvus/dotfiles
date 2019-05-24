/*
 * Wed Nov 7 | CEN213 - Fall 2018
 *  
 *  Guy-Michel Assi Bodje
 *  
 *  Lab Assignment 2: Reverse strings recursively
 *  
 *  Sources:
 *           
 *
 */

#include <stdio.h>
#include <stdlib.h>
#define SIZE 100

// Prototype
void reverse(const char * const stringPtr);

int main(void) {
    // Create character array
    char string[SIZE];
    
    // Prompt and take a line of text as input from user
    printf("%s", "Enter a string: ");
    fgets(string, SIZE, stdin);
    
    // Output reversed string
    printf("\n%s", "The reversed string is: ");
    reverse(string);
    puts("");
    
    return 0;
}

// Prototype definition
void reverse(const char * const stringPtr)
{
    /* Base Case
    *
    * stringPtr is a substring
    * created through the use of pointers
    * Program will check if its first index is the null character
    *
    */
    
    if (stringPtr[0] == '\0') {
        return;
    }
    
    /* If not the end of the string,
    *  recursive calls are made to the reverse function,
    *  this time with the second index of the previous call (i.e. str[1])
    *  as the first index of the next (as str[0]). And so until
    *  the terminating null character is found.
    *  The string will then be printed in reverse order.
    */
    
    else {
        reverse(&stringPtr[1]); // Recursion step
        putchar (stringPtr[0]); // display character
    }

   /* I learned this particular way of using recursion from
    * "C How to Program" 8th ed. Pg 346.
    */
}

