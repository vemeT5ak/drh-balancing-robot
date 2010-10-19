#include "WProgram.h"
#include <HardwareSerial.h>
#include <math.h>
#include <Messenger.h>
#include <EEPROM.h>
#include "TimeInfo.h"
#include <Sabertooth.h>
#include <QuadratureEncoder.h>
#include <UtilityFunctions.h>
#include <ADXL330.h>
#include <IDG300.h>
#include <TiltCalculator.h>
#include <SpeedController.h>

#define c_MaxSpeed 1.0
#define c_EncoderTicksPerMeter 2300.0

float _TopSpeed = c_MaxSpeed * 0.9;

#define c_SendInfo 1 // 0: Don't send info via the serial port; 1: Send info

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

SpeedController _SpeedControllerMotor1 = SpeedController(&_EncoderMotor1, c_EncoderTicksPerMeter, 0);
SpeedController _SpeedControllerMotor2 = SpeedController(&_EncoderMotor2, c_EncoderTicksPerMeter, 12);

#define c_KpAnalogPin 5
float _Kp = 0.0;
#define c_KiAnalogPin 4
float _Ki = 0.0;
#define c_KdAnalogPin 3
float _Kd = 0.0;
#define c_AngleOffsetPin 6
float _AngleOffset = 0.0;
#define c_SteeringOffsetPin 7
float _SteeringOffset = 0.0;

// Instantiate Messenger object with the message function and the default separator (the space character)
Messenger _Messenger = Messenger(); 

float _CommandedSpeedMotor1 = 0.0;
float _CommandedSpeedMotor2 = 0.0;

#define c_UpdateInterval 5 // update interval in milli seconds

long _StartPositionTicks = 0;

void setup()
{
  analogReference(EXTERNAL); // we set the analog reference for the analog to digital converters to 3.3V
  Serial.begin(115200);
  
  attachInterrupt(5, HandleMotor1InterruptA, CHANGE); // Pin 18 
  attachInterrupt(4, HandleMotor2InterruptA, CHANGE); // Pin 19

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
  
  unsigned long endWarmupMillisecs = _TimeInfo.CurrentMillisecs + 5000; // 5 sec to settle in
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
  float motorSignal1, motorSignal2;
  float torque;
  
  _SpeedControllerMotor1.Update(&_TimeInfo);
  _SpeedControllerMotor2.Update(&_TimeInfo);
  float speedError = (_SpeedControllerMotor1.CurrentSpeed + _SpeedControllerMotor2.CurrentSpeed) / 2.0;
  //float positionError = (_SpeedControllerMotor1.TotalDistanceTraveled + _SpeedControllerMotor2.TotalDistanceTraveled) / 2.0;

  torque = CalculateTorque(_TiltCalculator.AngleRad, _TiltCalculator.AngularRateRadPerSec);
  //torque = _Balancer.CalculateTorque(
  //  _TiltCalculator.AngleRad + _AngleOffset,
  //  _TiltCalculator.AngularRateRadPerSec,
  //  positionError,  // position position
  //  speedError  // velocity error
  //  );


  int value = map(analogRead(c_SteeringOffsetPin), 0, 1023, -512, 512);
  float steeringOffset = value / 512.0 * 80;
  //int potiValue = analogRead(c_SteeringPotAnalogIn);  // read the input pin
  //float steeringOffset = potiValue / 4.0 - 127.0; // (-127 ... +127)
  
 
  motorSignal1 = AdjustMotorSignal(torque + steeringOffset);
  motorSignal2 = AdjustMotorSignal(torque - steeringOffset);

  _Sabertooth.SetSpeedMotorB(motorSignal1);
  _Sabertooth.SetSpeedMotorA(motorSignal2);

  if (c_SendInfo == 1)
  {
    Serial.print(_TiltCalculator.MeasuredAngleRad + _AngleOffset, 4); // 4 decimal places
    Serial.print("\t");
    Serial.print(_TiltCalculator.AngleRad + _AngleOffset, 4);
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
    Serial.print("\tP:");
    Serial.print(_Kp, 4);
    Serial.print("\tI:");
    Serial.print(_Ki, 4);
    Serial.print("\tD:");
    Serial.print(_Kd, 4);
    Serial.println();
  }
}

float CalculateTorque(float angleRad, float angularRateRadPerSec)
{
  int value = map(analogRead(c_KpAnalogPin), 0, 1023, 1023, 0);
  _Kp = value / 1023.0 * 5000;

  value = map(analogRead(c_KiAnalogPin), 0, 1023, 1023, 0);
  _Ki = value / 512.0 * 200;
  
  float maxIntegral = 0.0;
  if (_Ki > 0.001)
  {
    maxIntegral = 127 / _Ki;
  }

  value = map(analogRead(c_KdAnalogPin), 0, 1023, 1023, 0);
  _Kd = value / 512.0 * 500;

  value = map(analogRead(c_AngleOffsetPin), 0, 1023, 512, -512);
  _AngleOffset = value / 512.0 * 10.0 / 180 * PI;

  float error = angleRad - _AngleOffset;
  static float integratedError;
  static float lastError = 0;
  
  if (abs(error) > 10.0 / 180.0 * PI)
  {
    // if we tilt too far we give up
    integratedError = 0;
    return 0.0;
  }

  float pTerm = _Kp * error;
  
  integratedError = constrain(integratedError + error * _TimeInfo.SecondsSinceLastUpdate, -maxIntegral, +maxIntegral);
  float iTerm = _Ki * integratedError;
  
  float dTerm = _Kd * (error - lastError) / _TimeInfo.SecondsSinceLastUpdate;
  lastError = error;
  //float dTerm = _Kd * angularRateRadPerSec;
  
  return pTerm + iTerm + dTerm;
}

float AdjustMotorSignal(float motorSignal)
{
  // The motors don't start with low requested torque values -> we add an offset
  if (abs(motorSignal) > 1)
  {
    if (motorSignal > 0)
    {
      return motorSignal + 5;
    }
    else
    {
      return motorSignal + 5;
    }
  }
  else
  {
    return motorSignal;
  }
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

  //_Balancer.SetCoefficients(k1, k2, k3, k4);
  
  _AngleOffset = PI / 180.0 * GetFloatFromBaseAndExponent(_Messenger.readInt(), _Messenger.readInt());
}

float GetFloatFromBaseAndExponent(int base, int exponent)
{
  return base * pow(10, exponent);
}


