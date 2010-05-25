#include "WProgram.h"
#include <Sabertooth.h>

unsigned long previousMilliseconds = 0;
unsigned long updateInterval = 50; // update interval in milli seconds

// temporary: contolling the motors with one potentiometer
int potiAnalogInPin = 5;

// Sabertooth address 128 set with the DIP switches on the controller (OFF OFF ON ON  ON ON)
// Using Serial3 for communicating with the Sabertooth motor driver. Requires a connection
// from pin 14 on the Arduino Mega board to S1 on the Sabertooth device.
Sabertooth sabertooth = Sabertooth(128, &Serial3);

void setup()
{
  analogReference(EXTERNAL); // we set the analog reference for the analog to digital converters to 3.3V
  
  Serial.begin(115200);

  // give Sabertooth motor driver time to get ready
  delay(2000);
  
  // Setting baud rate for communication with the Sabertooth device.
  sabertooth.InitializeCom(19200);
  sabertooth.SetMinVoltage(12.4);
}

void loop()
{
  unsigned long currentMilliseconds = millis();

  unsigned long milliSecsSinceLastUpdate = currentMilliseconds - previousMilliseconds;
  if(milliSecsSinceLastUpdate > updateInterval)
  {
    // save the last time we updated
    previousMilliseconds = currentMilliseconds;

    int potiValue = analogRead(potiAnalogInPin);  // read the input pin
    int speedValue = potiValue / 4 - 127; // (-127 ... +127)
    
    Serial.println(speedValue);

    sabertooth.SetSpeedMotorA(speedValue);
    sabertooth.SetSpeedMotorB(speedValue);
  }
}


