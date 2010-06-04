#include "WProgram.h"
#include <HardwareSerial.h>
#include <math.h>
#include <ADXL330.h>
#include <IDG300.h>
#include <TiltCalculator.h>

ADXL330 _ADXL330 = ADXL330(15,14,13);
IDG300 _IDG300 = IDG300(8,9);
TiltCalculator _TiltCalculator = TiltCalculator();

#define c_UpdateInterval 1000 // update interval in milli seconds

void setup()
{
  analogReference(EXTERNAL); // we set the analog reference for the analog to digital converters to 3.3V
  Serial.begin(115200);
}

void loop()
{
  _ADXL330.Update();
  float rawTiltAngleRad = atan2(_ADXL330.ZAcceleration, -_ADXL330.YAcceleration);

  _TiltCalculator.UpdateKalman(rawTiltAngleRad);

  _IDG300.Update();

  _TiltCalculator.UpdateState(_IDG300.XRadPerSec, c_UpdateInterval / 1000.0);
  
  float radToDegree = 180.0 / 3.14;

  Serial.print(_ADXL330.ZAcceleration, 4); // 4 decimal places
  Serial.print("\t");
  Serial.print(_ADXL330.YAcceleration, 4); // 4 decimal places
  Serial.print("\t");
  Serial.print(rawTiltAngleRad * radToDegree, 4); // 4 decimal places
  Serial.print("\t");
  Serial.print(_TiltCalculator.AngleRad * radToDegree, 4);
  Serial.print("\t");
  Serial.print(_TiltCalculator.AngularRateRadPerSec * radToDegree, 4);
  Serial.println();
  
  delay(c_UpdateInterval);
}

