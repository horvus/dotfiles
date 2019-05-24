#include "seat.h"

int main(void) {
   const int NUM_SEATS = 5;
   char userKey;
   int  seatNum;
   Seat allSeats[NUM_SEATS];
   Seat currSeat;
   
   userKey = '-';

   SeatsMakeEmpty(allSeats, NUM_SEATS);
   
   while (userKey != 'q') {
      printf("Enter command (p/r/d/q): ");
      scanf(" %c", &userKey);
      
      if (userKey == 'p') { // Print seats
         SeatsPrint(allSeats, NUM_SEATS);
         printf("\n");
      }
      else if (userKey == 'r') { // Reserve seat
         printf("Enter seat num: ");
         scanf("%d", &seatNum);
         
         if (!SeatIsEmpty(allSeats[seatNum])) {
            printf("Seat not empty.\n\n");
         }
         else {
            printf("Enter first name: ");
            scanf("%s", currSeat.firstName);
            printf("Enter last name: ");
            scanf("%s", currSeat.lastName);
            printf("Enter amount paid: ");
            scanf("%d", &currSeat.amountPaid);
            
            allSeats[seatNum] = currSeat;
            
            printf("Completed.\n\n");
         }
      }
      else if (userKey == 'd') { // Delete reservation
         printf("Enter seat num: ");
         scanf("%d", &seatNum);

         if (SeatIsEmpty(allSeats[seatNum])) {
            printf("Seat already empty.\n\n");
         }
         else {
            SeatMakeEmpty(&allSeats[seatNum]);

            printf("\nCompleted.\n\n");
         }
      }
      else if (userKey == 'q') { // Quit
         printf("Quitting.\n");
      }
      else {
         printf("Invalid command.\n\n");
      }
   }
   
   return 0;
}
