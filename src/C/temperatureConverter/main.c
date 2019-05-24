#include "tempConv.h"
// Main program
int main (int argc, char* argv[]) {
    const int maxArgumentsAllowed = 2;
    double Cel;
    double Fahr;

    if (argc != maxArgumentsAllowed) {
        puts ("Error: Usage: Pass one temperature as argument for conversion.");
        return 1;
    }
//    else if (argv[1]) {
//        puts ("Error: Usage: Argument must be a number.");
//    }

    puts ("Temp Converter, v1.2.0");
    printf ("%s\n%s\n%s\n", "Decide the mode you want: ", 
                            "1. Celsius to Fahrenheit",
                            "2. Fahrenheit to Celsius");

    unsigned short mode;
    scanf ("%hu", &mode);
    switch (mode) {
        case 1:
            Cel = atof (argv[1]);
            printf ("%lf%s%lf%s\n", Cel, "°C is equal to ", celToFahr(Cel), " °F.");
            return 0;
            break;
        case 2:
            Fahr = atof (argv[1]);
            printf ("%lf%s%lf%s\n", Fahr, "°F is equal to ", fahrToCel(Fahr), " °C.");
            return 0;
            break;
        default:
            puts ("Error: Usage: mode variable is incorrect.");
            return 1;
            break;
    }
}
