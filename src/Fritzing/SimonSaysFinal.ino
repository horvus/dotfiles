// Modified CEN111 SimonSays working code:

// LED pin definitions
#define LED_RED       	13
#define LED_GREEN    		12
#define LED_YELLOW 			11
#define LED_BLUE      	10

// Extra win/lose LED pin definitions 
#define WIN							6
#define LOSE						7

// Button pin definitions
#define BUTTON_RED			2
#define BUTTON_GREEN		3
#define BUTTON_YELLOW		4
#define BUTTON_BLUE			5

// Buzzer definitions
#define BUZZER					9
#define RED_TONE 				220
#define GREEN_TONE			262
#define BLUE_TONE				330
#define YELLOW_TONE			392
#define TONE_DURATION		250

// Game Variables
int GAME_SPEED = 250;
int GAME_STATUS = 0;
int const GAME_MAX_SEQUENCE = 50;
int GAME_SEQUENCE[GAME_MAX_SEQUENCE];
int GAME_STEP = 0;
int READ_STEP = 0;

void setup() {

	// start serial connection
	Serial.begin (9600);

	// seed the random() function used in resetGame()
	randomSeed (analogRead(0));
	
	// set LEDs as output
	pinMode (LED_RED, OUTPUT);
	pinMode (LED_GREEN, OUTPUT);
	pinMode (LED_BLUE, OUTPUT);
	pinMode (LED_YELLOW, OUTPUT);

	pinMode (WIN, OUTPUT);
	pinMode (LOSE, OUTPUT);

	// set Buttons as input
	pinMode (BUTTON_RED, INPUT_PULLUP);
	pinMode (BUTTON_GREEN, INPUT_PULLUP);
	pinMode (BUTTON_BLUE, INPUT_PULLUP);
	pinMode (BUTTON_YELLOW, INPUT_PULLUP);

	// set Speaker as output
 	pinMode (BUZZER, OUTPUT);
}

void loop() {

	// In what mode are we? 
	// a relevant function will be selected depending on the value of GAME_STATUS

	switch(GAME_STATUS){
		case 0:
    	resetGame();
    	break;
		case 1:
    	playSequence();
    	break;
    case 2:
    	readSequence();
    	break;
    case 3:
    	gameOver();
    	break;
  }
}

void playSequence() {

	// Play a step of our sequence
	for (int i=0; i<=GAME_STEP; i++) {
    	
		Serial.print ("Set LED");
    		Serial.println (GAME_SEQUENCE[i]);
    		delay  (GAME_SPEED*2);

    		setLED (GAME_SEQUENCE[i]);
    		playTone (GAME_SEQUENCE[i]);
    		delay (GAME_SPEED);
    		clearLEDs();
	}

	 // Go to next step: reading buttons
 	GAME_STATUS = 2;
}

void readSequence() {

  // read our buttons
  int button_value = readButtons();
  
  if(button_value > 0) {
    // a button has been pressed
    if(button_value == GAME_SEQUENCE[READ_STEP]){
      // correct value!
      setLED (button_value);
      playTone (button_value);
      delay (GAME_SPEED);
      clearLEDs();
      
      // Lets speed it up!
      GAME_SPEED = GAME_SPEED-15;
      
      Serial.println("Correct!");
      
      if(READ_STEP == GAME_STEP){
        // reset read step
        READ_STEP = 0;
        // Go to next game step
        GAME_STEP++;
        // Go to playback sequence mode of our game
        GAME_STATUS = 1;
        Serial.println("Go To Next Step");
        
        // Light all LEDs to indicate next sequence...
        setLEDs(true,true,true,true);
				// ...and light win LED, before turning it all off
				digitalWrite (WIN, HIGH);
        delay(GAME_SPEED);
        setLEDs(false,false,false,false);
        digitalWrite (WIN, LOW);
        
      }
      else{
        READ_STEP++;
      }
      
      delay(10);
      
    }
    else{
      // wrong value!
      // Go to game over mode
      GAME_STATUS = 3;
      Serial.println("Game Over!");
    }
  }
  delay(10);
}

void resetGame(){
  // Reset steps
  READ_STEP = 0;
  GAME_STEP = 0;
  
  // Create random sequence
  for(int i=0; i < GAME_MAX_SEQUENCE; i++){
		// Assign the ith element to a number between 1 and 4
    GAME_SEQUENCE[i] = random(4) + 1;
  }
  
  // Go to next game state; show LED sequence
  GAME_STATUS = 1;
}

void gameOver(){
  // Red RGB
  // Play Pwa Pwa Pwa

	digitalWrite (LOSE, HIGH);

 	tone(BUZZER, 3951.07, TONE_DURATION);
 	delay(TONE_DURATION);
	tone(BUZZER, 2793.88, TONE_DURATION);
	delay(TONE_DURATION);
	tone(BUZZER, 2637.02, TONE_DURATION);
	delay(TONE_DURATION);
	delay(GAME_SPEED);

	digitalWrite (LOSE, LOW);

	/* If any button pressed, reset game
	if (readButtons() > 0) {
		GAME_STATUS = 0;
		
	}*/
	
}

// HELPER FUNCTIONS
void setLED(int id){
	// choose which LED to light up
  switch(id){
    case 0:
    	setLEDs(false,false,false,false);
    	break;
    case 1:
      setLEDs(true,false,false,false);
      break;
    case 2:
      setLEDs(false,true,false,false);
      break;
    case 3:
      setLEDs(false,false,true,false);
      break;
    case 4:
      setLEDs(false,false,false,true);
      break; 
  }
}

void playTone(int id){
	// choose which tone to play
  switch(id){
    case 0:
      noTone(BUZZER);
      break;
    case 1:
      tone(BUZZER, RED_TONE, TONE_DURATION);
      break;
    case 2:
      tone(BUZZER, GREEN_TONE, TONE_DURATION);
      break;
    case 3:
      tone(BUZZER, BLUE_TONE, TONE_DURATION);
     break;
    case 4:
      tone(BUZZER, YELLOW_TONE, TONE_DURATION);
      break; 
  }
}

void setLEDs(boolean red, boolean green, boolean blue, int yellow ){
  if (red) digitalWrite(LED_RED, HIGH);
  else digitalWrite(LED_RED, LOW);
  if (green) digitalWrite(LED_GREEN, HIGH);
  else digitalWrite(LED_GREEN, LOW);
  if (blue) digitalWrite(LED_BLUE, HIGH);
  else digitalWrite(LED_BLUE, LOW);
  if (yellow) digitalWrite(LED_YELLOW, HIGH);
  else digitalWrite(LED_YELLOW, LOW);
}

void clearLEDs(){
  setLEDs(false,false,false,false);
}

int readButtons(void) {
  if (digitalRead(BUTTON_RED) == 0) return 1;
  else if (digitalRead(BUTTON_GREEN) == 0) return 2;
  else if (digitalRead(BUTTON_BLUE) == 0) return 3;
  else if (digitalRead(BUTTON_YELLOW) == 0) return 4;
  
  return 0;
}
