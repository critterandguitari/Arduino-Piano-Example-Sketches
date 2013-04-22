/*********************************************
 * Plays Sine Tone on Arduino Pocket Piano
 * Author: Owen Osborn, Copyright: GPL 
 * 
 *  This uses Direct Digital Synthesis (DDS)  for tone generation
 *   maps 25 of the buttons to tones
 * 5 October 2007
 * FOR MCP4921 DAC
 *
 * Chip type           : ATMEGA168
 * Clock frequency     : 16MHz
 *********************************************/
 /*
  * WaveTable-o-licious - Josh Brandt
  * mute@sidehack.gweep.net
  * 6 October 2008
  * updated with multiple waveforms in a giant wavetable in progmem!
  * 
  * when you start using this much memory, things occasionally overwrite
  * one another. it is very picky about the order the various arrays and stuff
  * are defined in this file. there is basically no free ram. If, for example, 
  * you move the miditof array anywhere
  * else in this file it will be randomly overwritten by something along the
  * way and your keys may stop making noise.  Clearly a better setup
  * is needed.
  * 
  * one possibility is to use memcpy_P (or something similar) to grab
  * a single byte from progmem rather than slapping the whole table
  * back and forth every time you twist a knob.
  * another is to actually compute the functions in realtime, but that
  * includes a lot of trig functions and may get slow.
  * I figure that's why Mr. Osborn used a wavetable to start with.
  * Turns out this is too slow if you do it on a per-sample basis
  * so if you turn things up too far you get funky digital garbage
  * conveniently, it sounds cool.
  *
  * To run this you may need to change the RX_BUFFER_SIZE to 16 or 32
  * as described here: http://www.ladyada.net/library/arduino/hacks.html
  * 
  * thanks to Owen Osborn for a very cool toy.
  */
  

// let me use progmem for the giant wavetables
#include <avr/pgmspace.h>

// define pins to read buttons
#define MUX_SEL_A 4
#define MUX_SEL_B 3
#define MUX_SEL_C 2
#define MUX_OUT_0 7
#define MUX_OUT_1 6
#define MUX_OUT_2 5

// here are some 12 tone equal temperament pitches. 
uint32_t miditof[] = {
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

// carrier frequency (pitch)
// frequency value used for oscillator in phase steps
// this is an integer proportial to Hertz in the following way:
// frequency  = (FrequencyInHertz * 65536) / SampleRate, here sample rate is 15625
uint32_t pitch = 1400;

// gain  (0 - 255)
uint8_t gain = 0; 

// this scales the pitch so the synth can be tuned over large range
int pitchScale = 700 ;

int waveForm = 0;

// this 32 bit number holds the states of the 24 buttons, 1 bit per button
uint32_t buttons = 0xFFFFFFFF;

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

  sei();           // enable interrupts
  
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
  
  // set up initial waves
  waveForm=0;

  Serial.begin(9600);
  Serial.println("hello");
  Serial.println("welcome to synth3siz0r");
  
}


void loop(void)
{

  int i, j;

  // read knobs

  waveForm = analogRead(2) >> 6;

  getButtons();  

  j = 0;
  for (i = 0; i < 25; i++){
    if ( !((buttons >> i) & 1) ){
      j = ((miditof[i]) * (pitchScale)) >> 12;
      break;
    }
  }
  pitch = j;
  if (i == 25){
    gain = 0;
  }
  else
    gain = 0xff;

// delay(5);   // wait 10 ms
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


