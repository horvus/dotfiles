#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int main (void) {
    char nameArr[100];                // User specified name
    char* greetingArr = NULL;         // Output greeting and name
    
    // Prompt user to enter a name
    printf("Enter name: ");
    fgets(nameArr, 100, stdin);
    
    // Eliminate end-of-line char
    nameArr[strlen(nameArr)-1] = '\0';

    // Dynamic allocation of greetingArr
    greetingArr = (char*) malloc( (strlen(nameArr) + 8) * sizeof(char));
    
    // Modify string, hello + user specified name
    strcpy(greetingArr, "Hello ");
    strcat(greetingArr, nameArr);
    strcat(greetingArr, ".");
    
    // Output greeting and name
    printf("%s\n", greetingArr);

    free(greetingArr);

    return 0;
}