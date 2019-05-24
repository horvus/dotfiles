xor.exe : main.o xor.o
	gcc main.o xor.o -o xor.exe

main.o : main.c xor.h
	gcc -Wall -c main.c

xor.o : xor.c xor.h
	gcc -Wall -c xor.c

clean :
	rm *.o xor.exe
