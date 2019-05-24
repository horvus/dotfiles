#include "tempConv.h"
// Function definitions
double celToFahr (double Cel) {
    double Fahr;
    Fahr = (Cel * 1.8000) + 32.00;
    return Fahr;
}
double fahrToCel (double Fahr) {
    double Cel;
    Cel = (Fahr - 32.00) / 1.8000;
    return Cel;
}
