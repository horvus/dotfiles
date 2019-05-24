/*  Fall 2018 - CEN 111 Intro to Electrical and Computer Engineering
 *  Final Project: Line-following Robot (Guy-Michel, Andrew)
 *  Milestone #1 : Standard Line Follower
 *  Due : EOD December 10
 */

// Definitions

// light sensor pin definitions
const int leftSensorPin = A0;
const int rightSensorPin = A1;

// motor pin definitions
const int leftMotorPin = 9;
const int rightMotorPin = 10;

// light sensitivity
const int rightLightThreshold = 100;
const int leftLightThreshold = 100;


// Main
void setup(){
  
	// Begin communications
	Serial.begin(9600);
	
	// set Motor pins as output
	pinMode(leftMotorPin, OUTPUT);
	pinMode(rightMotorPin, OUTPUT);
	
	// set Sensor pins as input
	pinMode(leftSensorPin, INPUT);
	pinMode(rightSensorPin, INPUT);
}


void loop(){
  
	// Read sensor values
	int leftLightLevel = analogRead(leftSensorPin);
	int rightLightLevel = analogRead(rightSensorPin);

  
	// If light sensor is greater than threshold
	// then turn motor on, else turn motor off
	
// Left motor
	
	if (leftLightLevel > leftLightThreshold){
	  Serial.println("L = 1");
	  Serial.println(leftLightLevel);
	  digitalWrite(leftMotorPin, HIGH);
	}
	else {
	  Serial.println("L = 0");
	  Serial.println(leftLightLevel);
	  digitalWrite(leftMotorPin, LOW);
	}
  
// Right motor
  
	if (rightLightLevel > rightLightThreshold){
	  Serial.println("R = 1");
	  Serial.println(rightLightLevel);
	  digitalWrite(rightMotorPin, HIGH);
	}
	else {
	  Serial.println("R = 0");
	  Serial.println(rightLightLevel);
	  digitalWrite(rightMotorPin, LOW);
	}
}