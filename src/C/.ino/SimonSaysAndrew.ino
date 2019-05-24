// LED pin definitions

#define LED_RED     11
#define LED_GREEN   10
#define LED_BLUE    12
#define LED_YELLOW  13
#define LED_CORRECT 8     //Assigned green "correct" LED to pin 8
#define LED_WRONG   9     //Assigned red "wrong" LED to pin 9

// Button pin definitions

#define BUTTON_RED    3
#define BUTTON_GREEN  2
#define BUTTON_BLUE   4
#define BUTTON_YELLOW 5

// Buzzer definitions

#define BUZZER  7
#define RED_TONE 392
#define GREEN_TONE 261
#define BLUE_TONE 587
#define YELLOW_TONE 493.88
#define TONE_DURATION 250

// Game Variables

int GAME_SPEED = 250;
int GAME_STATUS = 0;
int const GAME_MAX_SEQUENCE = 50;
int GAME_SEQUENCE[GAME_MAX_SEQUENCE];
int GAME_STEP = 0;
int READ_STEP = 0;
int GAME_ROUND = 1;

// Assigns pins to recieve or send signal

void setup() {

  Serial.begin(9600);

  randomSeed(analogRead(0)); // chooses random LED to start with


  pinMode(LED_RED, OUTPUT);
  pinMode(LED_GREEN, OUTPUT);
  pinMode(LED_BLUE, OUTPUT);
  pinMode(LED_YELLOW, OUTPUT);

  pinMode(BUTTON_RED, INPUT_PULLUP);
  pinMode(BUTTON_GREEN, INPUT_PULLUP);
  pinMode(BUTTON_BLUE, INPUT_PULLUP);
  pinMode(BUTTON_YELLOW, INPUT_PULLUP);

  pinMode(BUZZER, OUTPUT);

  pinMode(LED_CORRECT, OUTPUT); // setting the pin mode to use pin 8 as an output
  pinMode(LED_WRONG, OUTPUT); // setting the pin mode to use pin 9 as an output

}


void loop() {

  // In what mode are we?
  // These are the sequences that take place when a correct or incorrect button is pressed

  switch (GAME_STATUS) {
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
    /*case 4:
      newGameSet();
      break;*/
      // Case 4: a funtion that will reset the game with a new sequence once you lost
  }
}

void playSequence() {

  // play a step of our sequence//

  for (int i = 0; i <= GAME_STEP; i++) {

    Serial.print("Set LED");
    Serial.println(GAME_SEQUENCE[i]);
    delay(GAME_SPEED * 2);           // speeds up the game
    setLED(GAME_SEQUENCE[i]);
    playTone(GAME_SEQUENCE[i]);
    delay(GAME_SPEED);
    clearLEDs();
  }

  // Go to next step: reading buttons
  GAME_STATUS = 2;
}


void readSequence() {

  // read our buttons
  int button_value = readButtons();

  if (button_value > 0) {
    // a button has been pressed

    if (button_value == GAME_SEQUENCE[READ_STEP]) {
      // correct value!

      setLED(button_value);
      playTone(button_value);
      delay(GAME_SPEED);
      clearLEDs();

      // Lets speed it up!

      GAME_SPEED = GAME_SPEED - 5; //speeds up game

      Serial.println("Correct!");

      digitalWrite(LED_CORRECT, HIGH); // Turns on the green LED when the correct button is pushed
      delay(250);  // Sets the duration of the "blink" of the LED
      digitalWrite(LED_CORRECT, LOW); // Turns off the LED after the duration of the

      //"blink" has ended

      if (READ_STEP == GAME_STEP) {

        // reset read step
        READ_STEP = 0;

        // Go to next game step
        GAME_STEP++;

        // Go to playback sequence mode of our game
        GAME_STATUS = 1;

        Serial.println("Go To Next Step");


        // Light all LEDs to indicate next sequence
        setLEDs(true, true, true, true);

        delay(GAME_SPEED);
        setLEDs(false, false, false, false);

        GAME_ROUND++; // increases the GAME_Round by 1

        Serial.println(GAME_ROUND);

        if (GAME_ROUND == 5) {

          // If you reach level 5 then "Clocks" by Coldplay plays

          tone(BUZZER, 622.25, 392); // Eb
          delay(250);

          tone(BUZZER, 466.16); // Bb
          delay(250);

          tone(BUZZER, 392); // G
          delay(250);

          tone(BUZZER, 622.25); // Eb
          delay(250);

          tone(BUZZER, 466.16); // Bb
          delay(250);

          tone(BUZZER, 392); // G
          delay(250);

          tone(BUZZER, 622.25); // Eb
          delay(250);

          tone(BUZZER, 466.16); // Bb
          delay(250);

          tone(BUZZER, 554.37); // Db
          delay(250);

          tone(BUZZER, 466.16); // Bb
          delay(250);

          tone(BUZZER, 349.23); // F
          delay(250);

          tone(BUZZER, 554.37); // Db
          delay(250);

          tone(BUZZER, 466.16); // Bb
          delay(250);

          tone(BUZZER, 349.23); // F
          delay(250);

          tone(BUZZER, 554.37); // Db
          delay(250);

          tone(BUZZER, 466.16); // Bb
          delay(250);

          tone(BUZZER, 554.37); // Db
          delay(250);

          tone(BUZZER, 466.16); // Bb
          delay(250);

          tone(BUZZER, 349.23); // F
          delay(250);

          tone(BUZZER, 554.37); // Db
          delay(250);

          tone(BUZZER, 466.16); // Bb
          delay(250);

          tone(BUZZER, 349.23); // F
          delay(250);

          tone(BUZZER, 554.37); // Db
          delay(250);

          tone(BUZZER, 466.16); // Bb
          delay(250);

          tone(BUZZER, 523.25); // C
          delay(250);

          tone(BUZZER, 415.3); // Ab
          delay(250);

          tone(BUZZER, 349.23); // F
          delay(250);

          tone(BUZZER, 523.25); // C
          delay(250);

          tone(BUZZER, 415.3); // Ab
          delay(250);

          tone(BUZZER, 349.23); // F
          delay(250);

          tone(BUZZER, 523.25); // C
          delay(250);

          tone(BUZZER, 415.3); // Ab
          delay(250);
          
          noTone(BUZZER);

          // End of the song
        }
        
        if (GAME_ROUND == 10) {

          // If you reach level 10 then "We Are the Champions" by Queen plays.

          tone(BUZZER, 523.25); // C
          delay(250);

          tone(BUZZER, 698.46); // F
          delay(1000);

          tone(BUZZER, 659.25); // E
          delay(250);

          tone(BUZZER, 698.46); // F
          delay(250);

          tone(BUZZER, 659.25); // E
          delay(500);

          tone(BUZZER, 523.25); // C
          delay(500);

          tone(BUZZER, 440); // A
          delay(500);

          tone(BUZZER, 587.33); // D
          delay(500);

          tone(BUZZER, 440); // A
          delay(1000);

          noTone(BUZZER);
          delay(50);

          tone(BUZZER, 523.25); // C
          delay(250);

          tone(BUZZER, 698.46); // F
          delay(1000);

          tone(BUZZER, 783.99); // G
          delay(250);

          tone(BUZZER, 880); // A
          delay(250);

          tone(BUZZER, 1046.5); // C
          delay(500);

          tone(BUZZER, 880); // A
          delay(500);


          tone(BUZZER, 587.33); // D
          delay(500);

          tone(BUZZER, 659.25); // E
          delay(500);

          tone(BUZZER, 587.33); // D
          delay(1000);

          noTone(BUZZER);
          delay(50);

          tone(BUZZER, 293.66); // D
          delay(500);

          tone(BUZZER, 261.63); // C
          delay(500);

          tone(BUZZER, 293.66); // D
          delay(250);

          tone(BUZZER, 261.63); // C
          delay(500);

          tone(BUZZER, 233.08); // Bb
          delay(500);

          noTone(BUZZER);
          delay(50);

          tone(BUZZER, 466.16); // Bb
          delay(500);

          tone(BUZZER, 440); // A
          delay(500);

          tone(BUZZER, 466.16); // Bb
          delay(250);

          tone(BUZZER, 440); // A
          delay(500);

          tone(BUZZER, 349.23); // F
          delay(500);

          noTone(BUZZER);
          delay(50);

          tone(BUZZER, 440); // A
          delay(500);

          tone(BUZZER, 349.23); // F
          delay(500);

          tone(BUZZER, 466.16); // Bb
          delay(250);

          tone(BUZZER, 440); // A
          delay(500);

          tone(BUZZER, 349.23); // F
          delay(500);

          tone(BUZZER, 466.16); // Bb
          delay(250);

          tone(BUZZER, 415.30); // G#
          delay(500);

          tone(BUZZER, 349.23); // F
          delay(250);

          tone(BUZZER, 466.16); // Bb
          delay(250);

          tone(BUZZER, 415.30); // G#
          delay(500);

          tone(BUZZER, 349.23); // F
          delay(2000);

          noTone(BUZZER);
          delay(50);

          tone(BUZZER, 311.13); // Eb
          delay(250);

          tone(BUZZER, 261.63); // C
          delay(250);

          tone(BUZZER, 349.23); // F
          delay(4000);

          noTone(BUZZER);
          
          // End of the song
        }

        else {
          READ_STEP++;
        }
        delay(10);
      }

      else {
        // wrong value!
        // Go to game over mode
        GAME_STATUS = 3;
        Serial.println("Game Over!");
      }
    }
    delay(10);
  }
}

void resetGame() {

  // reset steps
  READ_STEP = 0;
  GAME_STEP = 0;


  // create random sequence
  for (int i = 0; i < GAME_MAX_SEQUENCE; i++) {

    GAME_SEQUENCE[i] = random(4) + 1;
  }


  // Go to next game state; show led sequence
  GAME_STATUS = 1;

}


void gameOver() {

  // Red RGB
  // Play Pwa Pwa Pwa

  digitalWrite(LED_WRONG, HIGH);    // Turns on the red LED when the incorrect button is pressed


  // "The Imperial March (Darth Vader's Theme)" by John WIlliams

  tone(BUZZER, 196); // G
  delay(1000);
  noTone(BUZZER);
  delay(50);

  tone(BUZZER, 196); // G
  delay(1000);
  noTone(BUZZER);
  delay(50);

  tone(BUZZER, 196); // G
  delay(1000);
  noTone(BUZZER);
  delay(50);

  tone(BUZZER, 155.56); // Eb
  delay(750);
  noTone(BUZZER);
  delay(50);

  tone(BUZZER, 233.08); // Bb
  delay(250);
  noTone(BUZZER);
  delay(50);

  tone(BUZZER, 196); // G
  delay(1000);
  noTone(BUZZER);
  delay(50);

  tone(BUZZER, 155.56); // Eb
  delay(750);
  noTone(BUZZER);
  delay(50);

  tone(BUZZER, 233.08); // Bb
}


// Helper functions

void setLEDs(boolean red, boolean green, boolean blue, boolean yellow){
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

int readButtons(void){
  if (digitalRead(BUTTON_RED) == 0) return 1;
  else if (digitalRead(BUTTON_GREEN) == 0) return 2;
  else if (digitalRead(BUTTON_BLUE) == 0) return 3;
  else if (digitalRead(BUTTON_YELLOW) == 0) return 4;
  
  return 0;
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