/*********************************************
 * Plays Tones on Arduino Pocket Piano
 * Author: Owen Osborn, Copyright: GPL 
 * 
 *  This uses Direct Digital Synthesis (DDS)  for tone generation
 * 
 *   maps 25 of the buttons to tones
 *
 * 5 October 2007
 *
 * FOR MCP4921 DAC
 *
 * Chip type           : ATMEGA168
 * Clock frequency     : 16MHz
 *********************************************/

// define pins to read buttons
#define MUX_SEL_A 4
#define MUX_SEL_B 3
#define MUX_SEL_C 2
#define MUX_OUT_0 7
#define MUX_OUT_1 6
#define MUX_OUT_2 5

// here are some 12 tone equal temperament pitches.  We will scale these with a 'tune' knob
uint32_t miditof[] = {
  0,
  5920,
  6272,
  6645,
  7040,
  7459,
  7902,
  8372,
  8870,
  9397,
  9956,
  10548,
  11175,
  11840,
  12544,
  13290,
  14080,
  14918,
  15804,
  16744,
  17740,
  18794,
  19912,
  21096,
  22350,
  23680,
  25088
};


#define PP_LED 8   // LED on pocket piano

// this 32 bit number holds the states of the 24 buttons, 1 bit per button
uint32_t buttons = 0xFFFFFFFF;

// holds frequency value used for oscillator in phase steps
// this is an integer proportial to Hertz in the following way:
// frequency  = (FrequencyInHertz * 65536) / SampleRate, here sample rate is 15625
uint32_t frequency[] = {
  1400, 0, 0, 0};

// this is the wave form of the oscillators 1 = sine wave, 2 = triangle, 0 = sawtooth
uint8_t waveForm = 2;

// tuning knob 
int pitchScale;

// voices (up to keys held down)
uint8_t key[] = {0, 0, 0, 0};

// octave multiplier
uint8_t octave = 0;

void setup(){
  //Timer2 setup  This is the audio rate timer, fires an interrupt at 15625 Hz sampling rate
  TIMSK2 = 1<<OCIE2A;  // interrupt enable audio timer
  OCR2A = 127;
  TCCR2A = 2;               // CTC mode, counts up to 127 then resets
  TCCR2B = 0<<CS22 | 1<<CS21 | 0<<CS20;   // different for atmega8 (no 'B' i think)
  SPCR = 0x50;   // set up SPI port
  SPSR = 0x01;
  DDRB |= 0x2E;       // PB output for DAC CS, and SPI port
  PORTB |= (1<<1);   // CS high
  
  sei();          // enable interrupts

  // configure pins for multiplexer
  pinMode(MUX_SEL_A, OUTPUT);  // these are the select pins
  pinMode(MUX_SEL_B, OUTPUT);
  pinMode(MUX_SEL_C, OUTPUT);
  
  
  pinMode(MUX_OUT_0, INPUT);
  pinMode(MUX_OUT_1, INPUT);
  pinMode(MUX_OUT_2, INPUT);

  digitalWrite(MUX_SEL_A, 1);   // multiplexer outputs, 8 each
  digitalWrite(MUX_SEL_B, 1);
  digitalWrite(MUX_SEL_C, 1);

  //flash led
  pinMode(PP_LED, OUTPUT);
  digitalWrite(PP_LED, 1);
  delay(100);
  digitalWrite(PP_LED, 0);
  delay(100);
  digitalWrite(PP_LED, 1);
  delay(100);
  digitalWrite(PP_LED, 0);

  Serial.begin(9600);
  Serial.println("hello");
  Serial.println("welcome to synthesizer");

}


void loop(void)
{

  int i, j;
  
  pitchScale = analogRead(2);

  getButtons();  
  
  j = 0;  
  key[0] = key[1] = key[2] = key[3] = 0;
  for (i = 0; i < 25; i++){             // read through buttons
    if ( !((buttons >> i) & 1) ){
      key[j] = i + 1;
      j++;
      j &= 0x3;
    }
  }
  
  // do octave increase
  octave++;
  
  // only from 0 - 3
  octave &= 3;

  frequency[0] = ((((miditof[key[0]]) * (pitchScale)) >> 9)>> octave);  // scale frequency by tuning knob and octave
  frequency[1] = ((((miditof[key[1]]) * (pitchScale)) >> 9)>> octave);
  frequency[2] = ((((miditof[key[2]]) * (pitchScale)) >> 9)>> octave);
  frequency[3] = ((((miditof[key[3]]) * (pitchScale)) >> 9)>> octave);
  
  
  delay(analogRead(0) >> 2);   // sweep speed
}

// this funcion reads the buttons and stores their states in the global 'buttons' variable
void getButtons(void){
  int i;
  buttons = 0;
  for (i = 0; i < 8; i++){
    digitalWrite(MUX_SEL_A, i & 1);
    digitalWrite(MUX_SEL_B, (i >> 1) & 1);
    digitalWrite(MUX_SEL_C, (i >> 2) & 1);
    buttons |= digitalRead(MUX_OUT_2) << i;  
  }
  buttons <<= 8;
  for (i = 0; i < 8; i++){
    digitalWrite(MUX_SEL_A, i & 1);
    digitalWrite(MUX_SEL_B, (i >> 1) & 1);
    digitalWrite(MUX_SEL_C, (i >> 2) & 1);
    buttons |= digitalRead(MUX_OUT_1) << i;
  }
  buttons <<= 8;
  for (i = 0; i < 8; i++){
    digitalWrite(MUX_SEL_A, i & 1);
    digitalWrite(MUX_SEL_B, (i >> 1) & 1);
    digitalWrite(MUX_SEL_C, (i >> 2) & 1);
    buttons |= digitalRead(MUX_OUT_0) << i;   
  }
  buttons |= 0x1000000;  // for the 25th button
  
  // uncomment these two lines to use the 25th button, if the board is modified so button connects to PC 3
  //if (!(PINC & 0x8))      
  //  buttons &= ~0x1000000;  
}




