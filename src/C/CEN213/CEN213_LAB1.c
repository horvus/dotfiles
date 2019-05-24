/*
 * Wed Oct 10 | CEN213 - Fall 2018
 *  
 *  Guy-Michel Assi Bodje
 *  
 *  Lab Assignment 1: Sorting Algorithms (C program)
 *  
 *  Sources:
 *           Bubble Sort : https://www.wikiwand.com/en/Bubble_sort
 *           Quicksort : https://www.wikiwand.com/en/Quicksort
 */

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define SIZE 10

// Function prototypes
void swap(int *xp, int *yp);

void bubblesort(int array[], unsigned int loop_count);
void quicksort(int array[], int low, int high, unsigned int loop_count);

int partition(int array[], int low, int high, unsigned int loop_count);

// Function main begins program execution
int main(void) {
    // Random number generator using current time
    srand(time(NULL));
    
    unsigned int loop_count = 1;
    
    while (loop_count <= 10)
    {
    
        // create an integer array of 100 elements
        int list[SIZE];
        
        // initialize all elements of list[] as random numbers from 0 to 99
        for (int i = 0; i < SIZE; i++) {   
            list[i] = rand()%100;
        }
        
        printf("\nThe  original random list (%u): \n", loop_count);
        for(int a = 0; a < SIZE; a++) {
            printf("%d ", list[a]);
        }
        puts("");
        
        // First sort : Bubblesort
        bubblesort(list, loop_count);
        
        // Second sort: Quicksort
        //quicksort(list, 0, SIZE-1, loop_count);
        
        loop_count += 1;
    }
    return 0;
}

// Prototype definitions

void swap(int *xp, int *yp) {
    int buff = *xp;
    *xp = *yp;
    *yp = buff;
}

void bubblesort(int array[], unsigned int loop_count) {
    
    int comparison_count = 0;
    
    for (int i = 0; i < SIZE - 1; i++) {
        for (int j = 0; j < SIZE-1-i; j++) {
            comparison_count++;

            if (array[j+1] < array[j]) {
                swap(&array[j], &array[j+1]);
            }
        }
    }
    
    printf("Bubblesorted list (%u): \n", loop_count);
        for(int a = 0; a < SIZE; a++) {
            printf("%d ", array[a]);
        }
    printf("\n\n%d comparisons were done.\n\n", comparison_count);
}

void quicksort(int array[], int low, int high, unsigned int loop_count) {
    
    // Low = First index, High = Last index
    
    if (low < high) {
        // p_index is the partitoning index 
        int p_index = partition(array, low, high, loop_count);
        
        quicksort(array, low, p_index - 1, loop_count);
        //quicksort(array, p_index + 1, high, loop_count);
    }
}

int partition(int array[], int low, int high, unsigned int loop_count) {
    
    // pivot is last element of the array,
    /* array is partitioned by placing elements
       greater than pivot on its rignt and
       smaller than pivot on its left.
    */
    
    int pivot = array[high];
    
    // i is the index of the smallest element
    int i = low;
    
    int comparison_count = 0;
    
    for (int j = low; i < high - 1; j++) {
        comparison_count++;

        if (array[j] < pivot) {
            i++;
            swap(&array[j], &array[i]);
        }
    }
    swap(&array[high], &array[i]);

    return (i+1);
}
