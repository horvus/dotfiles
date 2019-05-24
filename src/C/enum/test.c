#include <stdio.h>
#include <stdlib.h>

int main(int argc, char* argv[]) {
	typedef enum color {green, yellow, red}Color;

	if (argc != 2) {
		printf("%s\n", "Error: Usage.");
	}

	Color try;
	try = atoi(argv[1]);
	printf("%s %d", "The color is: ", try);


	return 0;
}
