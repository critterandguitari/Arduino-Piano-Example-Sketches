/*********************************************
 * Plays Sine Tone on Arduino Pocket Piano
 * Author: Owen Osborn, Copyright: GPL 
 * 
 *  This uses Direct Digital Synthesis (DDS)  for tone generation
 * 
 *   
 *
 * 5 October 2007
 *
 * FOR MCP4921 DAC
 *
 * Chip type           : ATMEGA168
 * Clock frequency     : 16MHz
 *********************************************/


#define PP_LED 8   // LED on pocket piano

// holds frequency value used for oscillator in phase steps
// this is an integer proportial to Hertz in the following way:
// frequency  = (FrequencyInHertz * 65536) / SampleRate, here sample rate is 15625
uint32_t frequency = 0;

uint8_t gain = 0xff;      // gain of oscillator


void setup(){

  //Timer2 setup  This is the audio rate timer, fires an interrupt at 15625 Hz sampling rate
  TIMSK2 = 1<<OCIE2A;  // interrupt enable audio timer
  OCR2A = 127;
  TCCR2A = 2;               // CTC mode, counts up to 127 then resets
  TCCR2B = 0<<CS22 | 1<<CS21 | 0<<CS20;   // different for atmega8 (no 'B' i think)
  SPCR = 0x50;   // set up SPI port
  SPSR = 0x01;
  DDRB |= 0x2E;       // PB output for DAC CS, and SPI port
  PORTB |= (1<<1);
  //led
  pinMode(PP_LED, OUTPUT);

  Serial.begin(9600);
  Serial.println("hello");
  Serial.println("welcome to synthesizer");

  sei();			// global interrupt enable
}


void loop(void)
{
  float frequencyInHertz = 440.0;   // use this to hold a frequency in hertz
                                    // normally we wouldn't use floats, and just use integers,
                                    // but it is convinient here to show freqency calculation

  // using formula above, calculate correct oscillator frequency value
  frequency =  (frequencyInHertz * 65536.0) / 15625.0;  

  // wait 2 seconds
  delay(2000);
  
  // ramp up frequency,  this might sound strange when it gets above the Nyquist frequency
  for(;;){
    frequency++;
    delay(10); 
  }
}



