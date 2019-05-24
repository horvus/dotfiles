/*  Fall 2018 - CEN 111 Intro to Electrical and Computer Engineering
 *  Final Project: Line-following Robot (Guy-Michel, Andrew)
 *  Milestone #1 : Improved Line Follower
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
const int lightThresholdLeft = 210;
const int lightThresholdRight = 550;


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

  
	if (leftLightLevel > lightThresholdLeft && rightLightLevel < lightThresholdRight){
		// Go Straight
		Serial.println("STRAIGHT");
    Serial.print("L =");
    Serial.println(leftLightLevel);
		Serial.print("R=");
		Serial.println(rightLightLevel);
    digitalWrite(leftMotorPin, HIGH);
    digitalWrite(rightMotorPin, HIGH);
	}
	else if (leftLightLevel > lightThresholdLeft && rightLightLevel > lightThresholdRight){
		// Both Stop
		Serial.println("STOP");
    Serial.print("L =");
    Serial.println(leftLightLevel);
		Serial.print("R=");
		Serial.println(rightLightLevel);
    digitalWrite(leftMotorPin, LOW);
    digitalWrite(rightMotorPin, LOW);
	}
	else if (leftLightLevel < lightThresholdLeft && rightLightLevel > lightThresholdRight){
		// Turn Left
		Serial.println("TURN LEFT");
    Serial.print("L =");
    Serial.println(leftLightLevel);
		Serial.print("R=");
		Serial.println(rightLightLevel);
    digitalWrite(leftMotorPin, LOW);
    digitalWrite(rightMotorPin, HIGH);
	}
	else (leftLightLevel < lightThresholdLeft && rightLightLevel > lightThresholdRight){
		// Turn Right
		Serial.println("TURN RIGHT");
    Serial.print("L =");
    Serial.println(leftLightLevel);
		Serial.print("R=");
		Serial.println(rightLightLevel);
    digitalWrite(leftMotorPin, HIGH);
    digitalWrite(rightMotorPin, LOW);
	}


}
