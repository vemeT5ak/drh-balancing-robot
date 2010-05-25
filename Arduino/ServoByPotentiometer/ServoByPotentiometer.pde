/*
  Analog Input
 Demonstrates analog input by reading an analog sensor on analog pin 0 and
 turning on and off a light emitting diode(LED)  connected to digital pin 13. 
 The amount of time the LED will be on and off depends on
 the value obtained by analogRead(). 
 
 The circuit:
 * Potentiometer attached to analog input 0
 * center pin of the potentiometer to the analog pin
 * one side pin (either one) to ground
 * the other side pin to +5V
 * LED anode (long leg) attached to digital output 13
 * LED cathode (short leg) attached to ground
 
 * Note: because most Arduinos have a built-in LED attached 
 to pin 13 on the board, the LED is optional.
 
 
 Created by David Cuartielles
 Modified 16 Jun 2009
 By Tom Igoe
 
 http://arduino.cc/en/Tutorial/AnalogInput
 
 */

#include <Servo.h> 

Servo myservo;  // create servo object to control a servo 


int sensorPin = 0;    // select the input pin for the potentiometer
//int ledPin = 13;      // select the pin for the LED
int sensorValue = 0;  // variable to store the value coming from the sensor
int msecValue;

void setup() {
  // declare the ledPin as an OUTPUT:
  //pinMode(ledPin, OUTPUT);
  Serial.begin(115200);
  myservo.attach(9);  // attaches the servo on pin 9 to the servo object 
}

void loop() {
  // read the value from the sensor:
  sensorValue = analogRead(sensorPin);
  
  Serial.println(sensorValue);
  
  msecValue = map(sensorValue, 0, 1023, 1000, 2000);     // scale it to use it with the servo (value between 1000 and 2000)
  myservo.writeMicroseconds(msecValue);          // sets the servo position according to the scaled value 
  
  delay(15);                           // waits for the servo to get there 
}
