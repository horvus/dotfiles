// Original code

// LED pin definitions
#define led_Red 13
#define led_Green 12
#define led_Yellow 11
#define led_Blue 10

// Button pin definitions
#define btn_Red 2
#define btn_Green 3
#define btn_Yellow 4
#define btn_Blue 5

// Speaker definition
#define buzzer  9

// 
int lastBtn1Value = HIGH;
int lastBtn2Value = HIGH;
int lastBtn3Value = HIGH;
int lastBtn4Value = HIGH;

// 
boolean ledOn1 = false;
boolean ledOn2 = false;
boolean ledOn3 = false;
boolean ledOn4 = false;


void setup() 
{
	// Activate serial monitor (baud rate 9600)
	Serial.begin (9600);
	
	// Random generator
	randomSeed (analogRead(0));

	// Set LED pins as output
	pinMode (led_Red, OUTPUT);
	pinMode (led_Green, OUTPUT);
	pinMode (led_Yellow, OUTPUT);
	pinMode (led_Blue, OUTPUT);

	// Set button pins as input
	pinMode (btn_Red, INPUT);
	pinMode (btn_Green, INPUT);
	pinMode (btn_Yellow, INPUT);
	pinMode (btn_Blue, INPUT);

	// Set buzzer pin as output
	pinMode (buzzer, OUTPUT);

}

void loop()
{
/* This block of code links buttons to LEDs,
	/* LED will be ON when user TAPS the button once.
	TAP again to turn off.	*/

	// Creates variable to read if button was pressed or not
	int btnValue1 = digitalRead (btnPin1);
	int btnValue2 = digitalRead (btnPin2);
	int btnValue3 = digitalRead (btnPin3);
	int btnValue4 = digitalRead (btnPin4);
	
	// If-else statements to make buttons control LEDs and buzzer

	if (btnValue1 == HIGH && lastBtn1Value == LOW) {
		if (ledOn1)
			digitalWrite (ledPin1, LOW);
		else {
			digitalWrite (ledPin1, HIGH);
			tone (buzzer, 2000);
			delay (390);
			noTone(buzzer);
			delay (50);
			tone (buzzer, 1950);
			delay (150);
			noTone (buzzer);
		}
		ledOn1 = !ledOn1;
	}
	lastBtn1Value = btnValue1;


	if (btnValue2 == HIGH && lastBtn2Value == LOW) {
		if (ledOn2)
			digitalWrite (ledPin2, LOW);
		else {
			digitalWrite (ledPin2, HIGH);
			tone (buzzer, 2200);
			delay (390);
			noTone(buzzer);
			delay (50);
			tone (buzzer, 2280);
			delay (350);
			noTone(buzzer);
			delay (50);
			tone (buzzer, 1950);
			delay (200);
			noTone (buzzer);
		}
		ledOn2 = !ledOn2;
	}
	lastBtn2Value = btnValue2;



	if (btnValue3 == HIGH && lastBtn3Value == LOW) {
		if (ledOn3)
			digitalWrite (ledPin3, LOW);
		else {
			digitalWrite (ledPin3, HIGH);
			tone (buzzer, 2100);
			delay (350);
			noTone(buzzer);
			delay (50);
			tone (buzzer, 1980);
			delay (300);
			noTone(buzzer);
		}
		ledOn3 = !ledOn3;
	}
	lastBtn3Value = btnValue3;



	if (btnValue4 == HIGH && lastBtn4Value == LOW) {
		if (ledOn4)
			digitalWrite (ledPin4, LOW);
		else {
			digitalWrite (ledPin4, HIGH);
			tone (buzzer, 278);
			delay (300);
			noTone (buzzer);
		}
		ledOn4 = !ledOn4;
	}
	lastBtn4Value = btnValue4;



/* This block of code continually displays the value of the button pressed (0 or 1)
	into the serial monitor-- essentially, if the button is pressed or not.	*/

	// Set variable to read from the button
	int btn1 = digitalRead (btnPin1);
	int btn2 = digitalRead (btnPin2);
	int btn3 = digitalRead (btnPin3);
	int btn4 = digitalRead (btnPin4);

	// Display every 500 ms
	Serial.println ("btn1 = ");
	Serial.println (btn1);

	Serial.println ("btn2 = ");
	Serial.println (btn2);

	Serial.println ("btn3 = ");
	Serial.println (btn3);

	Serial.println ("btn4 =  ");
	Serial.println (btn4);

	delay (500);

}