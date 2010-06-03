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

#define c_MaxSpeed 1.0

ADXL330 _ADXL330 = ADXL330(15,14,13);
IDG300 _IDG300 = IDG300(8,9);
TiltCalculator _TiltCalculator = TiltCalculator();

// Sabertooth address 128 set with the DIP switches on the controller (OFF OFF ON ON  ON ON)
// Using Serial3 for communicating with the Sabertooth motor driver. Requires a connection
// from pin 14 on the Arduino Mega board to S1 on the Sabertooth device.
Sabertooth _Sabertooth = Sabertooth(128, &Serial3);

// The quadrature encoder for motor 1 uses external interupt 5 on pin 18 and the regular input at pin 24
QuadratureEncoder _EncoderMotor1(18, 24, 22);
// The quadrature encoder for motor 2 uses external interupt 4 on pin 19 and the regular input at pin 25
QuadratureEncoder _EncoderMotor2(19, 25);

// Sony Playstation 2 Controller
#define c_PsxDataPin 36
#define c_PsxCommandPin 35
#define c_PsxAttPin 33
#define c_PsxClockPin 34
Psx _Psx;

#define encoderTicksPerMeterPerSec 2300.0
SpeedController _SpeedControllerMotor1 = SpeedController(&_EncoderMotor1, encoderTicksPerMeterPerSec, 0);
SpeedController _SpeedControllerMotor2 = SpeedController(&_EncoderMotor2, encoderTicksPerMeterPerSec, 12);
//Balancer balancer = Balancer(&_EncoderMotor1, 24);

// Instantiate Messenger object with the message function and the default separator (the space character)
Messenger _Messenger = Messenger(); 

float _CommandedSpeedMotor1 = 0.0;
float _CommandedSpeedMotor2 = 0.0;

boolean _PS2ControllerActive = false;

#define c_UpdateInterval 100 // update interval in milli seconds
unsigned long _PreviousMilliseconds = 0;

void setup()
{
  analogReference(EXTERNAL); // we set the analog reference for the analog to digital converters to 3.3V
  Serial.begin(115200);
  
  attachInterrupt(5, HandleMotor1InterruptA, CHANGE); // Pin 18 
  attachInterrupt(4, HandleMotor2InterruptA, CHANGE); // Pin 19

  _Psx.setupPins(c_PsxDataPin, c_PsxCommandPin, c_PsxAttPin, c_PsxClockPin);  // Defines what each pin is used (Data Pin #, Cmnd Pin #, Att Pin #, Clk Pin #)
  _Psx.initcontroller(psxAnalog);    

  // give Sabertooth motor driver time to get ready
  delay(2000);

  // Setting baud rate for communication with the Sabertooth device.
  _Sabertooth.InitializeCom(19200);
  _Sabertooth.SetMinVoltage(12.4);

  _SpeedControllerMotor1.Initialize();
  _SpeedControllerMotor2.Initialize();
  //balancer.Initialize();

  _Messenger.attach(OnMssageCompleted);

  _PreviousMilliseconds = millis();
}

void loop()
{
  unsigned long currentMilliseconds = millis();

  unsigned long milliSecsSinceLastUpdate = currentMilliseconds - _PreviousMilliseconds;
  if(milliSecsSinceLastUpdate > c_UpdateInterval)
  {
    Update(milliSecsSinceLastUpdate);
    // save the last time we updated
    _PreviousMilliseconds = currentMilliseconds;
  }

  while (Serial.available())
  {
    _Messenger.process(Serial.read());
  }
}

void Update(unsigned long milliSecsSinceLastUpdate)
{
  _ADXL330.Update();
  float rawTiltAngleRad = atan2(_ADXL330.ZAcceleration, -_ADXL330.YAcceleration);

  _TiltCalculator.UpdateKalman(rawTiltAngleRad);

  _IDG300.Update();

  float secondsSinceLastUpdate = milliSecsSinceLastUpdate / 1000.0;
  _TiltCalculator.UpdateState(_IDG300.XRadPerSec, secondsSinceLastUpdate);


  _Psx.poll(); // poll the Sony Playstation controller
  if (_Psx.Controller_mode == 140)
  {
    // analog mode; we use the right joystick to determine the desired speed
    _PS2ControllerActive = true;

    float mainSpeed = -(_Psx.Right_y - 128.0) / 128.0 * c_MaxSpeed;
    
    float rightLeftRatio = -(_Psx.Right_x - 128) / 128.0;
    
    _CommandedSpeedMotor1 = mainSpeed + rightLeftRatio * c_MaxSpeed;
    _CommandedSpeedMotor2 = mainSpeed - rightLeftRatio * c_MaxSpeed;
    
    if (_CommandedSpeedMotor1 > c_MaxSpeed) { _CommandedSpeedMotor1 = c_MaxSpeed; }
    if (_CommandedSpeedMotor2 > c_MaxSpeed) { _CommandedSpeedMotor2 = c_MaxSpeed; }
  }
  else
  {
    if (_PS2ControllerActive)
    {
      // we swicthed from PS2 controller active to not activ
      _CommandedSpeedMotor1 = 0;
      _CommandedSpeedMotor2 = 0;
    }
    _PS2ControllerActive = false;
  }

  float motorSignal1 = _SpeedControllerMotor1.ComputeOutput(_CommandedSpeedMotor1, secondsSinceLastUpdate);
  float motorSignal2 = _SpeedControllerMotor2.ComputeOutput(_CommandedSpeedMotor2, secondsSinceLastUpdate);

  Serial.print(rawTiltAngleRad, 4); // 4 decimal places
  Serial.print("\t");
  Serial.print(_TiltCalculator.AngleRad, 4);
  Serial.print("\t");
  Serial.print(_TiltCalculator.AngularRateRadPerSec, 4);
  Serial.print("\t");
  Serial.print(_SpeedControllerMotor1.CurrentSpeed, 4);
  Serial.print("\t");
  Serial.print(_SpeedControllerMotor2.CurrentSpeed, 4);
  Serial.print("\t");
  Serial.print(motorSignal1, 4);
  Serial.print("\t");
  Serial.print(motorSignal2, 4);
  Serial.println();

  //float motor1Torque = balancer1.CalculateTorque(tiltCalculator.AngleRad, tiltCalculator.AngularRateRadPerSec, secondsSinceLastUpdate);
  //float motor2Torque = balancer1.CalculateTorque(tiltCalculator.AngleRad, tiltCalculator.AngularRateRadPerSec, secondsSinceLastUpdate);

  _Sabertooth.SetSpeedMotorB(motorSignal1);
  _Sabertooth.SetSpeedMotorA(motorSignal2);
}

// Interrupt service routines for motor 1 quadrature encoder
void HandleMotor1InterruptA()
{
  _EncoderMotor1.OnAChanged();
}

// Interrupt service routines for motor 2 quadrature encoder
void HandleMotor2InterruptA()
{
  _EncoderMotor2.OnAChanged();
}

// Define messenger function
// We expect a message that contains the values for K1..K4 for balancer 1 followed by the same values for balancer 2.
// The Kx values are read as integers and are devided by 1000 to get floats.
void OnMssageCompleted()
{
  if (_Messenger.checkString("SetSpeed"))
  {
    SetCommandedSpeed();
    return;
  }

  if (_Messenger.checkString("SendSpeedCtrlParams"))
  {
    SendSpeedCtrlParams();
    return;
  }

  if (_Messenger.checkString("SetSpeedCtrlParams"))
  {
    SetSpeedCtrlParams();
    return;
  }

  if (_Messenger.checkString("SendCoeffs"))
  {
    SendCoefficients();
    return;
  }

  /*
  if (_Messenger.checkString("SetCoeffs"))
  {
    SetCoefficients(&balancer);
    return;
  }
  */
  
  // clear out unrecognized content
  while(_Messenger.available())
  {
    _Messenger.readInt();
  }
}

void SetCommandedSpeed()
{
  _CommandedSpeedMotor1 = GetFloatFromBaseAndExponent(_Messenger.readInt(), _Messenger.readInt());
  _CommandedSpeedMotor2 = GetFloatFromBaseAndExponent(_Messenger.readInt(), _Messenger.readInt());
}

void SendSpeedCtrlParams()
{
  Serial.print("SpeedCtrlParams");
  Serial.print("\t");
  Serial.print(_SpeedControllerMotor1.GetP(), 4);
  Serial.print("\t");
  Serial.print(_SpeedControllerMotor1.GetI(), 4);
  Serial.print("\t");
  Serial.print(_SpeedControllerMotor1.GetD(), 4);
  Serial.println();
}

void SetSpeedCtrlParams()
{
  float p = GetFloatFromBaseAndExponent(_Messenger.readInt(), _Messenger.readInt());;
  float i = GetFloatFromBaseAndExponent(_Messenger.readInt(), _Messenger.readInt());;
  float d = GetFloatFromBaseAndExponent(_Messenger.readInt(), _Messenger.readInt());;
  
  _SpeedControllerMotor1.SetPIDParams(p, i, d);
  _SpeedControllerMotor2.SetPIDParams(p, i, d);
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
  float k1 = (float)_Messenger.readDouble();
  float k2 = (float)_Messenger.readDouble();
  float k3 = (float)_Messenger.readDouble();
  float k4 = (float)_Messenger.readDouble();

  //pBalancer -> SetCoefficients(k1, k2, k3, k4);
}
*/

float GetFloatFromBaseAndExponent(int base, int exponent)
{
  return base * pow(10, exponent);
}


