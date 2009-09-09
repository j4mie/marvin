
// Pins
#define  BUMP_SENSOR_PIN  8
#define  SERVO_LEFT_PIN   11
#define  SERVO_RIGHT_PIN  12
#define  LED_PIN          13

// Servo settings
#define  MAX_PULSE        2500
#define  MIN_PULSE        500
#define  RIGHT_STOPPED    1460
#define  LEFT_STOPPED     1475

// States
#define  STOPPED  0
#define  FORWARD  1
#define  REVERSE  2

// Current state
int state = STOPPED;

// How often to pulse the servos
#define  SERVO_PULSE_INTERVAL  20

// Current motor speeds
int left_speed = 100;
int right_speed = 100;

// Servo last pulses
unsigned long last_pulse_left = 0;
unsigned long last_pulse_right = 0;

void setup()
{
  Serial.begin(9600);
  Serial.println("Debugging started");
  
  pinMode(SERVO_LEFT_PIN, OUTPUT);
  pinMode(SERVO_RIGHT_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
  
  pinMode(BUMP_SENSOR_PIN, INPUT);
  digitalWrite(BUMP_SENSOR_PIN, HIGH); // Turn on pulldown resistor
}

void loop()
{
  switch(state)
  {
    case STOPPED:
      left_speed = 0;
      right_speed = 0;
      break;
    
    case FORWARD:
      left_speed = 100;
      right_speed = 100;
      break;
      
    case REVERSE:
      left_speed = -100;
      right_speed = -100;
      break;
  }
  if (millis() % 1000 == 0) Serial.println(state);
  handle_input();
  update_servos();
}

void handle_input()
{
  handle_bump_sensor();
}

void handle_bump_sensor()
{
  int switch_pressed = digitalRead(BUMP_SENSOR_PIN);
  
  if (switch_pressed && state == STOPPED)
  {
    state = FORWARD;
  }
  
  else if (switch_pressed && state == FORWARD)
  {
    state = STOPPED;
  }
}

void update_servos()
{
  if (millis() - last_pulse_left >= SERVO_PULSE_INTERVAL)
  {
    digitalWrite(SERVO_LEFT_PIN, HIGH);
    delayMicroseconds(LEFT_STOPPED + (left_speed * -1));
    digitalWrite(SERVO_LEFT_PIN, LOW);
    last_pulse_left = millis();
  }
  
  if (millis() - last_pulse_right >= SERVO_PULSE_INTERVAL)
  {
    digitalWrite(SERVO_RIGHT_PIN, HIGH);
    delayMicroseconds(RIGHT_STOPPED + (right_speed));
    digitalWrite(SERVO_RIGHT_PIN, LOW);
    last_pulse_right = millis();
  }
}
