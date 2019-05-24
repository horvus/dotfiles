/*
 * This test program writes a line to a file.
 * (not appends, writes. Careful not to erase valuable content.)
*/

#include <stdio.h>
#include <stdlib.h>

int main (int argc, char* argv[]) {
	// Write to a file in variable stream of type file pointer
	FILE* stream = NULL;
	puts("Opening \"test.txt\"...");
	stream = fopen("test.txt", "w");

	/* Error case: test if file could open
	 * and if correct number of arguments used */
	if (stream == NULL) {
		fprintf(stderr, "%s\n", "Could not open file \"test.txt\".");
		return EXIT_FAILURE;
	}
	if (argc != 2) {
		fprintf(stderr, "%s\n", "Usage: w.bin \"mystring\" ");
		fclose(stream);
		return EXIT_FAILURE;
	}

	// Print the argument string into the file
	fprintf(stream, "%s\n", argv[1]);

	fclose(stream);
	return 0;
}
