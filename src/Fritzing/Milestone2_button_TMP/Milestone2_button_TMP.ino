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
const int lightThresholdRight = 170;
const int lightThresholdLeft = 230;
const int lightThresholdTotal = lightThresholdRight + lightThresholdLeft;

const int led1 = 4;
const int led2 = 5;

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

		pinMode(led1, OUTPUT);
    pinMode(led2, OUTPUT);

		digitalWrite(led1, HIGH);
		digitalWrite(led2, HIGH);
}




void loop(){
  
    // Read sensor values
    int leftLightLevel = analogRead(leftSensorPin);
    int rightLightLevel = analogRead(rightSensorPin);
    int LightLevelTotal = leftLightLevel + rightLightLevel;
  
    // If light sensor is less than threshold
    // then turn, else run both motors to go forwards


    Serial.println(leftLightLevel);
    Serial.println("^left^");
    Serial.println(rightLightLevel);
    Serial.println("^right^");
    

	if (leftLightLevel < lightThresholdLeft){
		// Turn Left
		Serial.println("TURN LEFT");
    Serial.print("L =");
    Serial.println(leftLightLevel);
		Serial.print("R=");
		Serial.println(rightLightLevel);
    digitalWrite(leftMotorPin, LOW);
    digitalWrite(rightMotorPin, HIGH);
		delay(200);
		digitalWrite(rightMotorPin, LOW);
		delay(200);
	}
	if (rightLightLevel < lightThresholdRight){
		// Turn Right
		Serial.println("TURN RIGHT");
    Serial.print("L =");
    Serial.println(leftLightLevel);
		Serial.print("R=");
		Serial.println(rightLightLevel);
		digitalWrite(rightMotorPin, LOW);
    digitalWrite(leftMotorPin, HIGH);
		delay(200);
    digitalWrite(leftMotorPin, LOW);
		delay(200);
	}


}