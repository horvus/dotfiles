rot13.exe : main.o encryptRot13.o
	gcc main.o encryptRot13.o -o rot13.exe

main.o : main.c encryptRot13.h
	gcc -Wall -c main.c

encryptRot13.o : encryptRot13.c encryptRot13.h
	gcc -Wall -c encryptRot13.c

clean :
	rm *.o rot13.exe
