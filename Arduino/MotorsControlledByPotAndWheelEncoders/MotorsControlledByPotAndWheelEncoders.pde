#include "WProgram.h"
#include <Sabertooth.h>
#include <QuadratureEncoder.h>

unsigned long previousMilliseconds = 0;
unsigned long updateInterval = 50; // update interval in milli seconds

// temporary: contolling the motors with one potentiometer
int potiAnalogInPin = 5;

// Sabertooth address 128 set with the DIP switches on the controller (OFF OFF ON ON  ON ON)
// Using Serial3 for communicating with the Sabertooth motor driver. Requires a connection
// from pin 14 on the Arduino Mega board to S1 on the Sabertooth device.
Sabertooth sabertooth = Sabertooth(128, &Serial3);

// The quadrature encoder for motor 1 uses external interupt 5 on pin 18 and the regular input at pin 24
QuadratureEncoder encoderMotor1(18, 24, 22);
// The quadrature encoder for motor 2 uses external interupt 4 on pin 19 and the regular input at pin 25
QuadratureEncoder encoderMotor2(19, 25);

volatile unsigned long interruptMilliSecs;
volatile bool a;
volatile bool b;
volatile long position;
unsigned long previousInterruptMilliSecs;


void setup()
{
  analogReference(EXTERNAL); // we set the analog reference for the analog to digital converters to 3.3V

  //attachInterrupt(0, HandleMotor1InterruptA, CHANGE); // Pin 2
  //attachInterrupt(1, HandleMotor1InterruptB, CHANGE); // Pin 3

  attachInterrupt(5, HandleMotor1InterruptA, CHANGE); // Pin 18 
  attachInterrupt(4, HandleMotor2InterruptA, CHANGE); // Pin 19

  Serial.begin(115200);

  // give Sabertooth motor driver time to get ready
  delay(2000);

  // Setting baud rate for communication with the Sabertooth device.
  sabertooth.InitializeCom(19200);
  sabertooth.SetMinVoltage(12.4);
}

void loop()
{
  if (interruptMilliSecs != previousInterruptMilliSecs)
  {
    previousInterruptMilliSecs = interruptMilliSecs;
      
    Serial.print(interruptMilliSecs);
    Serial.print("\t");
    Serial.print(a);
    Serial.print("\t");
    Serial.print(b);
    Serial.print("\t");
    Serial.print(position);
    Serial.println();
  }

  unsigned long currentMilliseconds = millis();

  unsigned long milliSecsSinceLastUpdate = currentMilliseconds - previousMilliseconds;
  if(milliSecsSinceLastUpdate > updateInterval)
  {
    // save the last time we updated
    previousMilliseconds = currentMilliseconds;

    int potiValue = analogRead(potiAnalogInPin);  // read the input pin
    int speedValue = potiValue / 4 - 127; // (-127 ... +127)

    // Serial.println(speedValue);

    sabertooth.SetSpeedMotorA(speedValue);
    sabertooth.SetSpeedMotorB(speedValue);
  }
}

// Interrupt service routines for motor 1 quadrature encoder
void HandleMotor1InterruptA()
{
  encoderMotor1.OnAChanged();
  //encoderMotor1.GetInfo(interruptMilliSecs, a, b, position);
}

//void HandleMotor1InterruptB()
//{
//  encoderMotor1.OnBChanged();
//  //encoderMotor1.GetInfo(interruptMilliSecs, a, b);
//}

// Interrupt service routines for motor 2 quadrature encoder
void HandleMotor2InterruptA()
{
  encoderMotor2.OnAChanged();
  encoderMotor2.GetInfo(interruptMilliSecs, a, b, position);
}

//void HandleMotor2InterruptB()
//{
//  encoderMotor2.OnBChanged();
//  encoderMotor2.GetInfo(interruptMilliSecs, a, b);
//}


