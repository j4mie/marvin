
// Pins
#define  BUMP_SENSOR_PIN  8
#define  SERVO_LEFT_PIN   11
#define  SERVO_RIGHT_PIN  12
#define  LED_PIN          13

// Servo settings
#define  MAX_PULSE        2500
#define  MIN_PULSE        500
#define  RIGHT_STOPPED    1460
#define  LEFT_STOPPED     1465

// States
#define  STOPPED        0
#define  FORWARD        1
#define  REVERSE        2
#define  LEFT           3
#define  RIGHT          4
#define  ENABLE_INPUT   5
#define  DISABLE_INPUT  6

// Switch debounce level
#define  DEBOUNCE  7000

// Current state
int state = STOPPED;

// How often to pulse the servos
#define  SERVO_PULSE_INTERVAL  20

// The size of the event schedule
#define  SCHEDULE_SIZE  50

// Current motor speeds
int left_speed = 100;
int right_speed = 100;

// Servo last pulses
unsigned long last_pulse_left = 0;
unsigned long last_pulse_right = 0;

// Debounce the switch
int switch_integrator = 0;

// Are we listening to inputs?
boolean input_enabled = true;

// The event schedule
unsigned long schedule_times[SCHEDULE_SIZE];
int schedule_states[SCHEDULE_SIZE];

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
    
    case LEFT:
      left_speed = -100;
      right_speed = 100;
      break;
      
    case RIGHT:
      left_speed = 100;
      right_speed = -100;
      break;
      
    case DISABLE_INPUT:
      input_enabled = false;
      break;
    
    case ENABLE_INPUT:
      input_enabled = true;
      break;
  }
  
  if (input_enabled)
  {
    handle_input();
  }
  
  handle_schedule();
  update_servos();
}

void handle_input()
{
  handle_bump_sensor();
}

void handle_bump_sensor()
{
  int switch_pressed = digitalRead(BUMP_SENSOR_PIN);
  
  if (switch_pressed)
  {
    switch_integrator++;
  }
  
  if (switch_integrator > DEBOUNCE)
  {
    switch(state)
    {
      case STOPPED:
        state = FORWARD;
        break;
      case FORWARD:
        state = DISABLE_INPUT;
        schedule_state_change(REVERSE, 100);
        schedule_state_change(LEFT, 5000);
        schedule_state_change(ENABLE_INPUT, 7000);
        schedule_state_change(FORWARD, 7000);
        break;
    }
    switch_integrator = 0;
  }
  
  else if (switch_integrator > DEBOUNCE && state == FORWARD)
  {
    state = STOPPED;
    switch_integrator = 0;
  }
}

// Figure out whether any schedules events need to take place
void handle_schedule()
{
  for (int schedule_slot = 0; schedule_slot<SCHEDULE_SIZE; schedule_slot++)
  {
    unsigned long schedule_time = schedule_times[schedule_slot];
    if (schedule_time && millis() >= schedule_time)
    {
      int new_state = schedule_states[schedule_slot];
      Serial.print("Executing scheduled state change: changing to ");
      Serial.println(new_state);
      state = new_state;
      schedule_times[schedule_slot] = 0; // slot is now empty
      break;
    }
  }
}

// Schedule a state transition for some point in the future
void schedule_state_change(int state_to_schedule, int time_in_the_future)
{
  // Find an empty slot in the schedule
  int schedule_slot = 0;
  while (schedule_times[schedule_slot])
  {
    schedule_slot++;
  }
  
  if (schedule_slot == SCHEDULE_SIZE) // Schedule is full!
  {
    digitalWrite(LED_PIN, HIGH);
    delay(1000000);
  }
  
  unsigned long schedule_at = millis() + time_in_the_future;
  schedule_times[schedule_slot] = schedule_at;
  schedule_states[schedule_slot] = state_to_schedule;
  
  // Debug
  Serial.print("Scheduled: ");
  Serial.print(state_to_schedule);
  Serial.print(" at ");
  Serial.println(schedule_at);
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
