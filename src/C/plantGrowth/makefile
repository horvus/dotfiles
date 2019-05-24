plantGrowth.exe : main.o plantGrowth.o
	gcc main.o plantGrowth.o -o plantGrowth.exe -lm

main.o : main.c plantGrowth.h
	gcc -Wall -g -c main.c 

plantGrowth.o : plantGrowth.c plantGrowth.h
	gcc -Wall -g -c plantGrowth.c 

clean :
	rm *.o plantGrowth.exe
