#include "WProgram.h"
#include <HardwareSerial.h>
#include <math.h>
#include <Messenger.h>
#include <EEPROM.h>
#include <Sabertooth.h>
#include <QuadratureEncoder.h>
#include <Balancer.h>
#include <ADXL330.h>
#include <IDG300.h>
#include <TiltCalculator.h>


ADXL330 adxl330 = ADXL330(15,14,13);
IDG300 idg300 = IDG300(8,9);
TiltCalculator tiltCalculator = TiltCalculator();

// Sabertooth address 128 set with the DIP switches on the controller (OFF OFF ON ON  ON ON)
// Using Serial3 for communicating with the Sabertooth motor driver. Requires a connection
// from pin 14 on the Arduino Mega board to S1 on the Sabertooth device.
Sabertooth sabertooth = Sabertooth(128, &Serial3);

// The quadrature encoder for motor 1 uses external interupt 5 on pin 18 and the regular input at pin 24
QuadratureEncoder encoderMotor1(18, 24, 22);
// The quadrature encoder for motor 2 uses external interupt 4 on pin 19 and the regular input at pin 25
QuadratureEncoder encoderMotor2(19, 25);

Balancer balancer1 = Balancer(&encoderMotor1, 0);
Balancer balancer2 = Balancer(&encoderMotor2, 16);

unsigned long previousMilliseconds = 0;
unsigned long updateInterval = 50; // update interval in milli seconds

// Instantiate Messenger object with the message function and the default separator (the space character)
Messenger messenger = Messenger(); 


// temporary: contolling the motors with one potentiometer
int potiAnalogInPin = 5;
int motor1PwmOutPin = 11;
int motor2PwmOutPin = 12;

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
  
  previousMilliseconds = millis();
  balancer1.Initialize();
  balancer2.Initialize();
  
  messenger.attach(OnMssageCompleted);
}

void loop()
{
  unsigned long currentMilliseconds = millis();

  unsigned long milliSecsSinceLastUpdate = currentMilliseconds - previousMilliseconds;
  if(milliSecsSinceLastUpdate > updateInterval)
  {
    Update(milliSecsSinceLastUpdate);
    // save the last time we updated
    previousMilliseconds = currentMilliseconds;
  }
  
  while (Serial.available())
  {
    messenger.process(Serial.read());
  }
}

void Update(unsigned long milliSecsSinceLastUpdate)
{
  adxl330.Update();
  float rawTiltAngleRad = atan2(adxl330.ZAcceleration, -adxl330.YAcceleration);

  tiltCalculator.UpdateKalman(rawTiltAngleRad);

  idg300.Update();

  float secondsSinceLastUpdate = milliSecsSinceLastUpdate / 1000.0;
  tiltCalculator.UpdateState(idg300.XRadPerSec, secondsSinceLastUpdate);

  /*
  Serial.print("double");
   Serial.print("\t");
   Serial.print(idg300.XRadPerSec);
   Serial.println();
   */


  float adjustedTiltAngle = tiltCalculator.AngleRad;

  //Serial.print("rad");
  //Serial.print("\t");
  //Serial.print(adxl330.ZAcceleration);
  //Serial.print("\t");
  //Serial.print(-adxl330.YAcceleration);
  //Serial.print("\t");
  Serial.print(rawTiltAngleRad, 4); // 4 decimal places
  Serial.print("\t");
  Serial.print(adjustedTiltAngle, 4);
  Serial.println();

  //Serial.println(encoderMotor1.getPosition());
  
  float motor1Torque = balancer1.CalculateTorque(tiltCalculator.AngleRad, tiltCalculator.AngularRateRadPerSec, secondsSinceLastUpdate);
  float motor2Torque = balancer1.CalculateTorque(tiltCalculator.AngleRad, tiltCalculator.AngularRateRadPerSec, secondsSinceLastUpdate);
  
  sabertooth.SetSpeedMotorA(motor1Torque);
  sabertooth.SetSpeedMotorB(motor2Torque);
}

// Interrupt service routines for motor 1 quadrature encoder
void HandleMotor1InterruptA()
{
  encoderMotor1.OnAChanged();
  //encoderMotor1.GetInfo(interruptMilliSecs, a, b, position);
}

// Interrupt service routines for motor 2 quadrature encoder
void HandleMotor2InterruptA()
{
  encoderMotor2.OnAChanged();
  //encoderMotor2.GetInfo(interruptMilliSecs, a, b, position);
}

// Define messenger function
// We expect a message that contains the values for K1..K4 for balancer 1 followed by the same values for balancer 2.
// The Kx values are read as integers and are devided by 1000 to get floats.
void OnMssageCompleted()
{
  if (messenger.checkString("SendCoeffs"))
  {
    SendCoefficients();
  }
    
  if (messenger.checkString("SetCoeffs"))
  {
    SetCoefficients(&balancer1);
    SetCoefficients(&balancer2);
  }
}

void SendCoefficients()
{
  Serial.print("Coefficients");
  Serial.print("\t");
  Serial.print(balancer1.K1, 4);
  Serial.print("\t");
  Serial.print(balancer1.K2, 4);
  Serial.print("\t");
  Serial.print(balancer1.K3, 4);
  Serial.print("\t");
  Serial.print(balancer1.K4, 4);
  Serial.println();
}

void SetCoefficients(Balancer* pBalancer)
{
  float k1, k2, k3, k4;
  float factor = 1000;
  
  k1 = messenger.readInt() / factor;
  k2 = messenger.readInt() / factor;
  k3 = messenger.readInt() / factor;
  k4 = messenger.readInt() / factor;
  
  pBalancer -> SetCoefficients(k1, k2, k3, k4);
}

