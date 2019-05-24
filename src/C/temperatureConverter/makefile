tempConv.exe : main.o tempConv.o
	gcc main.o tempConv.o -o tempConv.exe

main.o : main.c tempConv.h
	gcc -Wall -g -c main.c

tempConv.o : tempConv.c tempConv.h
	gcc -Wall -g -c tempConv.c

clean :
	rm *.o *.exe
