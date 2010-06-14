#include "WProgram.h"
#include <HardwareSerial.h>
#include <math.h>
#include <Messenger.h>
#include <EEPROM.h>
#include "Psx_analog.h"      // Includes the Psx Library to access a Sony Playstation controller
#include "TimeInfo.h"
#include <Sabertooth.h>
#include <QuadratureEncoder.h>
#include <Balancer.h>
#include <ADXL330.h>
#include <IDG300.h>
#include <TiltCalculator.h>
#include <SpeedController.h>

#define c_MaxSpeed 1.0
#define c_MetersPerTick 0.000430
#define c_EncoderTicksPerMeterPerSec 2300.0

float _TopSpeed = c_MaxSpeed * 0.9;

TimeInfo _TimeInfo = TimeInfo();
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

SpeedController _SpeedControllerMotor1 = SpeedController(&_EncoderMotor1, c_EncoderTicksPerMeterPerSec, 0);
SpeedController _SpeedControllerMotor2 = SpeedController(&_EncoderMotor2, c_EncoderTicksPerMeterPerSec, 12);
Balancer _Balancer = Balancer(24);

float _FixedAngleOffset = -4.0 * PI / 180;
float _AngleOffset = 0.0;

// Instantiate Messenger object with the message function and the default separator (the space character)
Messenger _Messenger = Messenger(); 

float _CommandedSpeedMotor1 = 0.0;
float _CommandedSpeedMotor2 = 0.0;

boolean _PS2ControllerActive = false;

#define c_UpdateInterval 5 // update interval in milli seconds

long _StartPositionTicks = 0;

void setup()
{
  analogReference(EXTERNAL); // we set the analog reference for the analog to digital converters to 3.3V
  Serial.begin(115200);
  
  attachInterrupt(5, HandleMotor1InterruptA, CHANGE); // Pin 18 
  attachInterrupt(4, HandleMotor2InterruptA, CHANGE); // Pin 19

  _Psx.setupPins(c_PsxDataPin, c_PsxCommandPin, c_PsxAttPin, c_PsxClockPin);  // Defines what each pin is used (Data Pin #, Cmnd Pin #, Att Pin #, Clk Pin #)
  _Psx.initcontroller(psxAnalog);

  _Messenger.attach(OnMssageCompleted);
  
  // give the system time to settle in and the Sabertooth motor driver time to get ready
  Warmup();

  // Setting baud rate for communication with the Sabertooth device.
  _Sabertooth.InitializeCom(19200);
  _Sabertooth.SetMinVoltage(12.4);

  _SpeedControllerMotor1.Reset(_TimeInfo.CurrentMillisecs);
  _SpeedControllerMotor2.Reset(_TimeInfo.CurrentMillisecs);
  
  _StartPositionTicks = (_EncoderMotor1.GetPosition() + _EncoderMotor2.GetPosition()) / 2;
}

// We give the system time to settle in. during this time we only measure and calculate but don't drive
void Warmup()
{
  _TimeInfo.Update();
  
  unsigned long endWarmupMillisecs = _TimeInfo.CurrentMillisecs + 2000; // 2 sec to settle in
  UpdateTiltInfo();

  while(true)
  {
    unsigned long currentMilliseconds = millis();
    unsigned long milliSecsSinceLastUpdate = currentMilliseconds - _TimeInfo.LastUpdateMillisecs;;
    if(milliSecsSinceLastUpdate > c_UpdateInterval)
    {
      // time for another update
      _TimeInfo.Update();
      UpdateTiltInfo();
    }

    ReadSerial();
    
    if (currentMilliseconds > endWarmupMillisecs)
    {
      // done warming up
      break;
    }
  }
}

void loop()
{
  unsigned long currentMilliseconds = millis();

  unsigned long milliSecsSinceLastUpdate = currentMilliseconds - _TimeInfo.LastUpdateMillisecs;;
  if(milliSecsSinceLastUpdate > c_UpdateInterval)
  {
    // time for another update
    _TimeInfo.Update();
    UpdateTiltInfo();
    IssueCommands();
  }

  ReadSerial();
}

void UpdateTiltInfo()
{
  _ADXL330.Update();
  float rawTiltAngleRad = atan2(_ADXL330.ZAcceleration, -_ADXL330.YAcceleration);

  _TiltCalculator.UpdateKalman(rawTiltAngleRad);
  _IDG300.Update();
  _TiltCalculator.UpdateState(_IDG300.XRadPerSec, _TimeInfo.SecondsSinceLastUpdate);
}

void ReadSerial()
{
  while (Serial.available())
  {
    _Messenger.process(Serial.read());
  }
}

void IssueCommands()
{
  UpdateTiltInfo();
  
  float motorSignal1, motorSignal2;
  float torque;
  
  _Psx.poll(); // poll the Sony Playstation controller
  if (_Psx.Controller_mode == 140)
  {
    // analog mode; we use the right joystick to determine the desired speed
    _PS2ControllerActive = true;

    float mainSpeed = -(_Psx.Right_y - 128.0) / 128.0 * c_MaxSpeed;
    
    float rightLeftRatio = -(_Psx.Right_x - 128) / 128.0;
    
    _CommandedSpeedMotor1 = mainSpeed + rightLeftRatio * c_MaxSpeed;
    _CommandedSpeedMotor2 = mainSpeed - rightLeftRatio * c_MaxSpeed;
    
    if (_CommandedSpeedMotor1 > _TopSpeed) { _CommandedSpeedMotor1 = _TopSpeed; }
    if (_CommandedSpeedMotor2 > _TopSpeed) { _CommandedSpeedMotor2 = _TopSpeed; }

    motorSignal1 = _SpeedControllerMotor1.ComputeOutput(_CommandedSpeedMotor1, &_TimeInfo);
    motorSignal2 = _SpeedControllerMotor2.ComputeOutput(_CommandedSpeedMotor2, &_TimeInfo);
  }
  else
  {
    if (_PS2ControllerActive)
    {
      // we switched from PS2 controller active to not active
      _PS2ControllerActive = false;
      motorSignal1 = 0;
      motorSignal2 = 0;
      
      _CommandedSpeedMotor1 = 0;
      _CommandedSpeedMotor2 = 0;
    }
    
    _SpeedControllerMotor1.Update(&_TimeInfo);
    _SpeedControllerMotor2.Update(&_TimeInfo);
    float speedError = (_SpeedControllerMotor1.CurrentSpeed + _SpeedControllerMotor2.CurrentSpeed) / 2.0;
    float positionError = (_SpeedControllerMotor1.DistanceTraveled + _SpeedControllerMotor2.DistanceTraveled) / 2.0;
    
    torque = _Balancer.CalculateTorque(
      _TiltCalculator.AngleRad + _FixedAngleOffset + _AngleOffset,
      _TiltCalculator.AngularRateRadPerSec,
      positionError,  // position position
      speedError  // velocity error
      );
    
    // The motors don't start with low requested torque values -> we add an offset
    if (torque > 0)
    {
      torque += 5;
    }
    if (torque < 0)
    {
      torque -= 5;
    }
    
    motorSignal1 = torque;
    motorSignal2 = torque;
  }

  _Sabertooth.SetSpeedMotorB(motorSignal1);
  _Sabertooth.SetSpeedMotorA(motorSignal2);

  Serial.print(_TiltCalculator.MeasuredAngleRad + _FixedAngleOffset + _AngleOffset, 4); // 4 decimal places
  Serial.print("\t");
  Serial.print(_TiltCalculator.AngleRad + _FixedAngleOffset + _AngleOffset, 4);
  Serial.print("\t");
  Serial.print(_TiltCalculator.AngularRateRadPerSec, 4);
  Serial.print("\t");
  Serial.print(_SpeedControllerMotor1.CurrentSpeed, 4);
  Serial.print("\t");
  Serial.print(_SpeedControllerMotor2.CurrentSpeed, 4);
  Serial.print("\t");
  Serial.print(torque, 4);
  Serial.print("\t");
  Serial.print(motorSignal1, 4);
  Serial.print("\t");
  Serial.print(motorSignal2, 4);
  Serial.print("\t");
  Serial.print(_AngleOffset * 180 / PI, 4);
  Serial.println();
}

void SendInfo()
{
  Serial.print(_TiltCalculator.MeasuredAngleRad + _FixedAngleOffset + _AngleOffset, 4); // 4 decimal places
  Serial.print("\t");
  Serial.print(_TiltCalculator.AngleRad + _FixedAngleOffset + _AngleOffset, 4);
  Serial.print("\t");
  Serial.print(_TiltCalculator.AngularRateRadPerSec, 4);
  Serial.print("\t");
  Serial.print(_SpeedControllerMotor1.CurrentSpeed, 4);
  Serial.print("\t");
  Serial.print(_SpeedControllerMotor2.CurrentSpeed, 4);
  Serial.print("\t");
  Serial.print(0.0, 4);
  Serial.print("\t");
  Serial.print(0.0, 4);
  Serial.print("\t");
  Serial.print(0.0, 4);
  Serial.print("\t");
  Serial.print(_AngleOffset * 180 / PI, 4);
  Serial.println();
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

  if (_Messenger.checkString("SetCoeffs"))
  {
    SetBalancerCoefficients();
    return;
  }
  
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
  float p = GetFloatFromBaseAndExponent(_Messenger.readInt(), _Messenger.readInt());
  float i = GetFloatFromBaseAndExponent(_Messenger.readInt(), _Messenger.readInt());
  float d = GetFloatFromBaseAndExponent(_Messenger.readInt(), _Messenger.readInt());
  
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

void SetBalancerCoefficients()
{
  float k1 = GetFloatFromBaseAndExponent(_Messenger.readInt(), _Messenger.readInt());
  float k2 = GetFloatFromBaseAndExponent(_Messenger.readInt(), _Messenger.readInt());
  float k3 = GetFloatFromBaseAndExponent(_Messenger.readInt(), _Messenger.readInt());
  float k4 = GetFloatFromBaseAndExponent(_Messenger.readInt(), _Messenger.readInt());

  _Balancer.SetCoefficients(k1, k2, k3, k4);
  
  _AngleOffset = PI / 180.0 * GetFloatFromBaseAndExponent(_Messenger.readInt(), _Messenger.readInt());
}

float GetFloatFromBaseAndExponent(int base, int exponent)
{
  return base * pow(10, exponent);
}


