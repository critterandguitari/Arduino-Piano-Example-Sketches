#include "WProgram.h"
void getButtons(void);
/*********************************************
 * Plays Sine Tone on Arduino Pocket Piano
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

// harmonicity (first 8 bits are fractional)
uint16_t harmonicity = 0;

// modulation depth (0 - 255)
uint8_t modulatorDepth = 0;

// gain  (0 - 255)
uint8_t gain = 0; 

// this scales the pitch so the synth can be tuned over large range
int pitchScale;

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

  Serial.begin(9600);
  Serial.println("hello");
  Serial.println("welcome to synthesizer");

}


void loop(void)
{

  int i, j;

  // read knobs
  harmonicity = analogRead(0) >> 2;
  modulatorDepth = analogRead(1) >> 2;
  pitchScale = analogRead(2);

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
    

  delay(5);   // wait 10 ms
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





/*********************************************
 * Plays Sine Tone on Arduino Pocket Piano
 * Author: Owen Osborn, Copyright: GPL 
 * 
 *  This uses Direct Digital Synthesis (DDS)  for tone generation
 * 
 *   
 * 5 October 2007
 *
 * FOR MCP4921 DAC
 *
 * Chip type           : ATMEGA168
 * Clock frequency     : 16MHz
 *********************************************/

#define SPI_SCK 5
#define SPI_MOSI 3

// Here are variables for digital audio.  
// They are declared using normal AVR-GCC notation ('uint8_t' for unsigned 8 bit number)

// Here is the sine wave.  It is a one cycle of sine tone, 255 8 bit samples, in hex values
// you could put any wave form you line in here...
uint8_t sineTable[]={
  0x80,0x83,0x86,0x89,0x8c,0x8f,0x92,0x95,0x98,0x9c,0x9f,0xa2,0xa5,0xa8,0xab,0xae,
  0xb0,0xb3,0xb6,0xb9,0xbc,0xbf,0xc1,0xc4,0xc7,0xc9,0xcc,0xce,0xd1,0xd3,0xd5,0xd8,
  0xda,0xdc,0xde,0xe0,0xe2,0xe4,0xe6,0xe8,0xea,0xec,0xed,0xef,0xf0,0xf2,0xf3,0xf5,
  0xf6,0xf7,0xf8,0xf9,0xfa,0xfb,0xfc,0xfc,0xfd,0xfe,0xfe,0xff,0xff,0xff,0xff,0xff,
  0xff,0xff,0xff,0xff,0xff,0xff,0xfe,0xfe,0xfd,0xfc,0xfc,0xfb,0xfa,0xf9,0xf8,0xf7,
  0xf6,0xf5,0xf3,0xf2,0xf0,0xef,0xed,0xec,0xea,0xe8,0xe6,0xe4,0xe2,0xe0,0xde,0xdc,
  0xda,0xd8,0xd5,0xd3,0xd1,0xce,0xcc,0xc9,0xc7,0xc4,0xc1,0xbf,0xbc,0xb9,0xb6,0xb3,
  0xb0,0xae,0xab,0xa8,0xa5,0xa2,0x9f,0x9c,0x98,0x95,0x92,0x8f,0x8c,0x89,0x86,0x83,
  0x80,0x7c,0x79,0x76,0x73,0x70,0x6d,0x6a,0x67,0x63,0x60,0x5d,0x5a,0x57,0x54,0x51,
  0x4f,0x4c,0x49,0x46,0x43,0x40,0x3e,0x3b,0x38,0x36,0x33,0x31,0x2e,0x2c,0x2a,0x27,
  0x25,0x23,0x21,0x1f,0x1d,0x1b,0x19,0x17,0x15,0x13,0x12,0x10,0x0f,0x0d,0x0c,0x0a,
  0x09,0x08,0x07,0x06,0x05,0x04,0x03,0x03,0x02,0x01,0x01,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x01,0x02,0x03,0x03,0x04,0x05,0x06,0x07,0x08,
  0x09,0x0a,0x0c,0x0d,0x0f,0x10,0x12,0x13,0x15,0x17,0x19,0x1b,0x1d,0x1f,0x21,0x23,
  0x25,0x27,0x2a,0x2c,0x2e,0x31,0x33,0x36,0x38,0x3b,0x3e,0x40,0x43,0x46,0x49,0x4c,
  0x4f,0x51,0x54,0x57,0x5a,0x5d,0x60,0x63,0x67,0x6a,0x6d,0x70,0x73,0x76,0x79,0x7c};

uint16_t sample;     // final sample that goes to the DAC    

// variables for carrier oscillator
uint16_t phaseAccumCarrier;
uint16_t phaseDeltaCarrier;
uint8_t indexCarrier;
uint8_t carrier;
uint8_t carrierAmp;

// variables for frequency mod oscillator
uint16_t phaseAccumModulator;
uint16_t phaseDeltaModulator;
uint8_t indexModulator;
int16_t modulatorSigned;
uint16_t modulator;
uint16_t modDepth;

// the two bytes that go to the DAC over SPI
uint8_t dacSPI0;
uint8_t dacSPI1;


// timer 2 is audio interrupt timer
ISR(TIMER2_COMPA_vect) {
  OCR2A = 127;
 
  PORTB &= ~(1<<1); // Frame sync low for SPI (making it low here so that we can measure lenght of interrupt with scope)

  phaseDeltaModulator = (pitch * harmonicity) >> 6;   // calculate modulator frequency for a  given harmonicity
  phaseDeltaCarrier = pitch;                           // this is just pitch (although not in Hz)

  // calculate frequency mod
  phaseAccumModulator = phaseAccumModulator + phaseDeltaModulator;
  indexModulator = phaseAccumModulator >> 8;
  modulator = sineTable[indexModulator];
  modulator = (modulator * modulatorDepth) >> 3;
  modulatorSigned = modulator - ((128 * modulatorDepth) >> 3);   // center at 0

  // get carrier frequency
  phaseDeltaCarrier += modulatorSigned;

  // calculate carrier
  phaseAccumCarrier = phaseAccumCarrier + (phaseDeltaCarrier);
  indexCarrier = phaseAccumCarrier >> 8;
  carrier = sineTable[indexCarrier];

  // output gain
  sample = carrier * gain;

  // format sample for SPI port
  dacSPI0 = sample >> 8;
  dacSPI0 >>= 4;
  dacSPI0 |= 0x30;
  dacSPI1 = sample >> 4;

  // transmit value out the SPI port
  SPDR = dacSPI0;
  while (!(SPSR & (1<<SPIF)));
  SPDR = dacSPI1;
  while (!(SPSR & (1<<SPIF)));
  PORTB |= (1<<1); // Frame sync high
}

int main(void)
{
	init();

	setup();
    
	for (;;)
		loop();
        
	return 0;
}

