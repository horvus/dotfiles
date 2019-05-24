test.bin: main.o
	gcc main.o -o test.bin

main.o: main.c
	gcc -Wall -Wextra -c main.c

main.s: main.c
	gcc -S main.c


clean:
	rm *.o *.s *.bin


test2.bin: main2.o
	gcc main2.o -o test2.bin

main2.o: main2.c
	gcc -Wall -Wextra -c main2.c