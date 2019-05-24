// Official CEN111 SimonSays working code:

// LED pin definitions
#define LED_RED     13
#define LED_GREEN   12
#define LED_BLUE    10
#define LED_YELLOW  11

// Button pin definitions
#define BUTTON_RED    2
#define BUTTON_GREEN  3
#define BUTTON_BLUE   5
#define BUTTON_YELLOW 4

// Buzzer definitions
#define BUZZER  9
#define RED_TONE 220
#define GREEN_TONE 262
#define BLUE_TONE 330
#define YELLOW_TONE 392
#define TONE_DURATION 250

// Game Variables
int GAME_SPEED = 250;
int GAME_STATUS = 0;
int const GAME_MAX_SEQUENCE = 50;
int GAME_SEQUENCE[GAME_MAX_SEQUENCE];
int GAME_STEP = 0;
int READ_STEP = 0;

void setup(){
  Serial.begin(9600);
  
  randomSeed(analogRead(0));
  
  pinMode(LED_RED, OUTPUT);
  pinMode(LED_GREEN, OUTPUT);
  pinMode(LED_BLUE, OUTPUT);
  pinMode(LED_YELLOW, OUTPUT);
  pinMode(BUTTON_RED, INPUT_PULLUP);
  pinMode(BUTTON_GREEN, INPUT_PULLUP);
  pinMode(BUTTON_BLUE, INPUT_PULLUP);
  pinMode(BUTTON_YELLOW, INPUT_PULLUP);
  pinMode(BUZZER, OUTPUT);
}

void loop(){
  
  // In what mode are we?
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

void playSequence(){
  // play a step of our sequence
  for(int i=0; i<=GAME_STEP; i++){
    Serial.print("Set LED");
    Serial.println(GAME_SEQUENCE[i]);
    delay(GAME_SPEED*2);
    setLED(GAME_SEQUENCE[i]);
    playTone(GAME_SEQUENCE[i]);
    delay(GAME_SPEED);
    clearLEDs();
    
  }
  // Go to next step: reading buttons
  GAME_STATUS = 2;
}

void readSequence(){
  // read our buttons
  int button_value = readButtons();
  
  if(button_value > 0){
    // a button has been pressed
    if(button_value == GAME_SEQUENCE[READ_STEP]){
      // correct value!
      setLED(button_value);
      playTone(button_value);
      delay(GAME_SPEED);
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
        
        // Light all LEDs to indicate next sequence
        setLEDs(true,true,true,true);
        delay(GAME_SPEED);
        setLEDs(false,false,false,false);
        
        
      }else{
        READ_STEP++;
      }
      
      delay(10);
      
    }else{
      // wrong value!
      // Go to game over mode
      GAME_STATUS = 3;
      Serial.println("Game Over!");
    }
  }
  delay(10);
}

void resetGame(){
  // reset steps
  READ_STEP = 0;
  GAME_STEP = 0;
  
  // create random sequence
  for(int i=0; i<GAME_MAX_SEQUENCE; i++){
    GAME_SEQUENCE[i] = random(4) + 1;
  }
  
  // Go to next game state; show led sequence
  GAME_STATUS = 1;
}

void gameOver(){
  // Red RGB
  // Play Pwa Pwa Pwa
  tone(BUZZER, 98, TONE_DURATION);
  delay(TONE_DURATION);
  tone(BUZZER, 93, TONE_DURATION);
  delay(TONE_DURATION);
  tone(BUZZER, 87, TONE_DURATION);
  delay(TONE_DURATION);
  delay(GAME_SPEED);
}

// HELPER FUNCTIONS
void setLED(int id){
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

int readButtons(void){
  if (digitalRead(BUTTON_RED) == 0) return 1;
  else if (digitalRead(BUTTON_GREEN) == 0) return 2;
  else if (digitalRead(BUTTON_BLUE) == 0) return 3;
  else if (digitalRead(BUTTON_YELLOW) == 0) return 4;
  
  return 0;
}

