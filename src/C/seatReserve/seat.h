/*** Headers ***/
    #pragma once
    #include <stdio.h>
    #include <string.h>
    #include <stdbool.h>

/*** Struct definition ***/
    typedef struct Seat_struct {
       char firstName[50];
       char lastName[50];
       int  amountPaid;
    } Seat;

/*** Function declarations ***/

    /*** Functions for Seat ***/
    void SeatMakeEmpty(Seat* seat);
    bool SeatIsEmpty(Seat seat);
    void SeatPrint(Seat seat);

    /*** Functions for array of Seat ***/
    void SeatsMakeEmpty(Seat seats[], int numSeats);
    void SeatsPrint(Seat seats[], int numSeats);
