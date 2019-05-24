/*
 * This test program reads one line from a file
 * and prints it to stdout.
*/

#include <stdio.h>
#include <stdlib.h>

int main (void) {
	const int NUM_CHAR_READ = 25;
	FILE* stream = NULL;
	char* str = NULL;

	// Allocate enough space in string
	str = (char*)malloc(sizeof(char)*NUM_CHAR_READ);

	puts("Opening file \"test.txt\"...");
	stream = fopen("test.txt", "r");

	// Error case: test if file could open
	if (stream == NULL) {
		fprintf(stderr, "%s\n", "Could not open file \"test.txt\".");
		return EXIT_FAILURE;
	}

	// Place in string what was read from file
	fgets(str, NUM_CHAR_READ, stream);
	fclose(stream);

	printf("%s\n%s\n", "Output:", str);
	return 0;
}
