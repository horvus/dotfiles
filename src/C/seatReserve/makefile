seatReserve.exe: main.o seat.o
	gcc main.o seat.o -o seatReserve.exe

main.o: main.c seat.h
	gcc -Wall -g -c main.c

seat.o: seat.c seat.h
	gcc -Wall -g -c seat.c

clean:
	rm *.o *.exe
