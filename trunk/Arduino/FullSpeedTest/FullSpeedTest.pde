#include "WProgram.h"
#include <HardwareSerial.h>
#include <math.h>
#include <Messenger.h>
#include <EEPROM.h>
#include "Psx_analog.h"      // Includes the Psx Library to access a Sony Playstation controller
#include <Sabertooth.h>
#include <QuadratureEncoder.h>
#include <Balancer.h>
#include <ADXL330.h>
#include <IDG300.h>
#include <TiltCalculator.h>
#include <SpeedController.h>

// Sabertooth address 128 set with the DIP switches on the controller (OFF OFF ON ON  ON ON)
// Using Serial3 for communicating with the Sabertooth motor driver. Requires a connection
// from pin 14 on the Arduino Mega board to S1 on the Sabertooth device.
Sabertooth sabertooth = Sabertooth(128, &Serial3);

// The quadrature encoder for motor 1 uses external interupt 5 on pin 18 and the regular input at pin 24
QuadratureEncoder encoderMotor1(18, 24, 22);
// The quadrature encoder for motor 2 uses external interupt 4 on pin 19 and the regular input at pin 25
QuadratureEncoder encoderMotor2(19, 25);

void setup()
{
  analogReference(EXTERNAL); // we set the analog reference for the analog to digital converters to 3.3V
  Serial.begin(115200);
  
  attachInterrupt(5, HandleMotor1InterruptA, CHANGE); // Pin 18 
  attachInterrupt(4, HandleMotor2InterruptA, CHANGE); // Pin 19

  // give Sabertooth motor driver time to get ready
  delay(2000);

  // Setting baud rate for communication with the Sabertooth device.
  sabertooth.InitializeCom(19200);
  sabertooth.SetMinVoltage(12.4);

  MeasureForSpeed(127);
  MeasureForSpeed(-127);

  sabertooth.SetSpeedMotorB(0);
  sabertooth.SetSpeedMotorA(0);

  delay(1000);
  sabertooth.SetSpeedMotorB(127);
  delay(1000);

  sabertooth.SetSpeedMotorB(0);
  sabertooth.SetSpeedMotorA(0);
  delay(1000);
}

void MeasureForSpeed(int speed)
{
  // set both motors to the same speed
  sabertooth.SetSpeedMotorB(speed);
  sabertooth.SetSpeedMotorA(speed);
  // give the motors time to get to this speed
  delay(1000);
  
  unsigned long startMilliseconds = millis();
  long startTicksMotor1 = encoderMotor1.GetPosition();
  long startTicksMotor2 = encoderMotor2.GetPosition();
  
  // run for a while
  delay(10000);

  unsigned long endMilliseconds = millis();
  long endTicksMotor1 = encoderMotor1.GetPosition();
  long endTicksMotor2 = encoderMotor2.GetPosition();
  
  Serial.print(speed);
  Serial.print("\t");
  Serial.print(endMilliseconds - startMilliseconds);
  Serial.print("\t");
  Serial.print(endTicksMotor1 - startTicksMotor1);
  Serial.print("\t");
  Serial.print(endTicksMotor2 - startTicksMotor2);
  Serial.println();
}

void loop()
{
}

// Interrupt service routines for motor 1 quadrature encoder
void HandleMotor1InterruptA()
{
  encoderMotor1.OnAChanged();
}

// Interrupt service routines for motor 2 quadrature encoder
void HandleMotor2InterruptA()
{
  encoderMotor2.OnAChanged();
}


