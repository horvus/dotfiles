#include "plantGrowth.h"

void plantGrowth (double initMass, double growthRate, double yearsGrow) {
    double finalMass;
    finalMass = initMass * pow((1.0 + growthRate), yearsGrow);
    printf ("%s%lf%s%lf\n", "Final mass after ", yearsGrow, " years is: ", finalMass);
    printf ("%s\n", "Note: This program could be repurposed to calculate any type of growth over time.");
}
