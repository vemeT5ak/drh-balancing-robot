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

boolean isDebugEnabled = false;

#define dataPin 34
#define cmndPin 35
#define attPin 37
#define clockPin 36

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

unsigned long previousMilliseconds = 0;
unsigned long updateInterval = 100; // update interval in milli seconds

Psx Psx;

SpeedController speedControllerMotor1 = SpeedController(&encoderMotor1, 0);
SpeedController speedControllerMotor2 = SpeedController(&encoderMotor2, 12);

// Instantiate Messenger object with the message function and the default separator (the space character)
Messenger messenger = Messenger(); 

float commandedSpeedMotor1 = 0.0;
float commandedSpeedMotor2 = 0.0;

boolean _PS2ControllerActive = false;

void setup()
{
  analogReference(EXTERNAL); // we set the analog reference for the analog to digital converters to 3.3V
  Serial.begin(115200);

  isDebugEnabled = true;
  
  attachInterrupt(5, HandleMotor1InterruptA, CHANGE); // Pin 18 
  attachInterrupt(4, HandleMotor2InterruptA, CHANGE); // Pin 19

  Psx.setupPins(dataPin, cmndPin, attPin, clockPin);  // Defines what each pin is used (Data Pin #, Cmnd Pin #, Att Pin #, Clk Pin #)
  Psx.initcontroller(psxAnalog);    

  // give Sabertooth motor driver time to get ready
  delay(2000);

  // Setting baud rate for communication with the Sabertooth device.
  sabertooth.InitializeCom(19200);
  sabertooth.SetMinVoltage(12.4);

  previousMilliseconds = millis();

  speedControllerMotor1.Initialize();
  speedControllerMotor2.Initialize();

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


  Psx.poll(); // poll the Sony Playstation controller
  if (Psx.Controller_mode == 140)
  {
    // analog mode; we use the right joystick to determine the desired speed
    _PS2ControllerActive = true;

    float maxSpeed = 2.0;
    float mainSpeed = -(Psx.Right_y - 128.0) / 128.0 * maxSpeed;
    
    float rightLeftRatio = -(Psx.Right_x - 128) / 128.0;
    
    commandedSpeedMotor1 = mainSpeed + rightLeftRatio * maxSpeed;
    commandedSpeedMotor2 = mainSpeed - rightLeftRatio * maxSpeed;
    
    if (commandedSpeedMotor1 > maxSpeed) { commandedSpeedMotor1 = maxSpeed; }
    if (commandedSpeedMotor2 > maxSpeed) { commandedSpeedMotor2 = maxSpeed; }
  }
  else
  {
    if (_PS2ControllerActive)
    {
      // we swicthed from PS2 controller active to not activ
      commandedSpeedMotor1 = 0;
      commandedSpeedMotor2 = 0;
    }
    _PS2ControllerActive = false;
  }

  float motorSignal1 = speedControllerMotor1.ComputeOutput(commandedSpeedMotor1, secondsSinceLastUpdate);
  float motorSignal2 = speedControllerMotor2.ComputeOutput(commandedSpeedMotor2, secondsSinceLastUpdate);

  Serial.print(rawTiltAngleRad, 4); // 4 decimal places
  Serial.print("\t");
  Serial.print(tiltCalculator.AngleRad, 4);
  Serial.print("\t");
  Serial.print(tiltCalculator.AngularRateRadPerSec, 4);
  Serial.print("\t");
  Serial.print(speedControllerMotor1.CurrentSpeed, 4);
  Serial.print("\t");
  Serial.print(speedControllerMotor2.CurrentSpeed, 4);
  Serial.print("\t");
  Serial.print(motorSignal1, 4);
  Serial.print("\t");
  Serial.print(motorSignal2, 4);
  Serial.println();

  //float motor1Torque = balancer1.CalculateTorque(tiltCalculator.AngleRad, tiltCalculator.AngularRateRadPerSec, secondsSinceLastUpdate);
  //float motor2Torque = balancer1.CalculateTorque(tiltCalculator.AngleRad, tiltCalculator.AngularRateRadPerSec, secondsSinceLastUpdate);

  sabertooth.SetSpeedMotorB(motorSignal1);
  sabertooth.SetSpeedMotorA(motorSignal2);
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
  if (messenger.checkString("SetSpeed"))
  {
    SetCommandedSpeed();
    return;
  }

  if (messenger.checkString("SendSpeedCtrlParams"))
  {
    SendSpeedCtrlParams();
    return;
  }

  if (messenger.checkString("SetSpeedCtrlParams"))
  {
    SetSpeedCtrlParams();
    return;
  }

  if (messenger.checkString("SendCoeffs"))
  {
    SendCoefficients();
    return;
  }

  /*
  if (messenger.checkString("SetCoeffs"))
  {
    SetCoefficients(&balancer1);
    SetCoefficients(&balancer2);
    return;
  }
  */
  
  // clear out unrecognized content
  while(messenger.available())
  {
    messenger.readInt();
  }
}

void SetCommandedSpeed()
{
  commandedSpeedMotor1 = GetFloatFromBaseAndExponent(messenger.readInt(), messenger.readInt());
  commandedSpeedMotor2 = GetFloatFromBaseAndExponent(messenger.readInt(), messenger.readInt());
}

void SendSpeedCtrlParams()
{
  Serial.print("SpeedCtrlParams");
  Serial.print("\t");
  Serial.print(speedControllerMotor1.GetP(), 4);
  Serial.print("\t");
  Serial.print(speedControllerMotor1.GetI(), 4);
  Serial.print("\t");
  Serial.print(speedControllerMotor1.GetD(), 4);
  Serial.println();
}

void SetSpeedCtrlParams()
{
  float p = GetFloatFromBaseAndExponent(messenger.readInt(), messenger.readInt());;
  float i = GetFloatFromBaseAndExponent(messenger.readInt(), messenger.readInt());;
  float d = GetFloatFromBaseAndExponent(messenger.readInt(), messenger.readInt());;
  
  speedControllerMotor1.SetPIDParams(p, i, d);
  speedControllerMotor2.SetPIDParams(p, i, d);
}

void SendCoefficients()
{
  /*
  Serial.print("Coeffs");
  Serial.print("\t");
  Serial.print(balancer1.K1, 4);
  Serial.print("\t");
  Serial.print(balancer1.K2, 4);
  Serial.print("\t");
  Serial.print(balancer1.K3, 4);
  Serial.print("\t");
  Serial.print(balancer1.K4, 4);
  Serial.println();
  */
}

/*
void SetCoefficients(Balancer* pBalancer)
{
  float k1 = (float)messenger.readDouble();
  float k2 = (float)messenger.readDouble();
  float k3 = (float)messenger.readDouble();
  float k4 = (float)messenger.readDouble();

  //pBalancer -> SetCoefficients(k1, k2, k3, k4);
}
*/

float GetFloatFromBaseAndExponent(int base, int exponent)
{
  return base * pow(10, exponent);
}


