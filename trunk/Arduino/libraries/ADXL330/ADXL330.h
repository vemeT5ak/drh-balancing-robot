/*
  ADXL330.h - Library for the ADXL330 3-axis accelerometer.
  Created by Dr. Rainer Hessmer, February, 2010.
  Released into the public domain.
*/

#ifndef ADXL330_h
#define ADXL330_h

#include "WProgram.h"
#include "UtilityFunctions.h"
#include <math.h>

// My rough measurements indicate the following analog values:
//      -g  +g  delta mean
// x	620 416 -204  518
// y    620 411 -209  515.5
// z    604 410 -194  507

class ADXL330
{
	public:
		float XAcceleration, YAcceleration, ZAcceleration;  // acceleration in units of g
		float TotalAcceleration; // total acceleration in units of g

		ADXL330(int xPin, int yPin, int zPin)
		{
			_xPin = xPin;
			_yPin = yPin;
			_zPin = zPin;

			analogReference(EXTERNAL);
		}

		void Update()
		{
			double xRaw, yRaw, zRaw;
			const int count = 5;

			for(int i = 0; i < count; i++)
			{
				xRaw += analogRead(_xPin);
				yRaw += analogRead(_yPin);
				zRaw += analogRead(_zPin);
			}

			xRaw = xRaw / count;
			yRaw = yRaw / count;
			zRaw = zRaw / count;

			/*Serial.print("double");
			Serial.print("\t");
			Serial.print(xRaw);
			Serial.print("\t");
			Serial.print(yRaw);
			Serial.print("\t");
			Serial.print(zRaw);
			Serial.println();*/

			// Calibrate
			// Low pass filter
			const double contribution = 0.1;

			XAcceleration = Smooth(XAcceleration, (xRaw - 518.0) / -204.0 * 2.0, contribution);
			YAcceleration = Smooth(YAcceleration, (yRaw - 515.5) / -209.0 * 2.0, contribution);
			ZAcceleration = Smooth(ZAcceleration, (zRaw - 507.0) / -194.0 * 2.0, contribution);

			TotalAcceleration = sqrt(XAcceleration * XAcceleration + YAcceleration * YAcceleration + ZAcceleration * ZAcceleration);

			/*Serial.print("double");
			Serial.print("\t");
			Serial.print(XAcceleration);
			Serial.print("\t");
			Serial.print(YAcceleration);
			Serial.print("\t");
			Serial.print(ZAcceleration);
			Serial.println();*/
		}

		// calculated angles
		float GetXYAngleRad()
		{
			return atan2(YAcceleration, XAcceleration);
		}

		float GetXZAngleRad()
		{
			return atan2(ZAcceleration, XAcceleration);
		}

		float GetYZAngleRad()
		{
			return atan2(ZAcceleration, YAcceleration);
		}

	private:
		int _xPin, _yPin, _zPin;
};

#endif
