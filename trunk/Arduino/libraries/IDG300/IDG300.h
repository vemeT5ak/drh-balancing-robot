/*
  IDG300.h - Library for the IDG300 2-axis gyroscope.
  Created by Dr. Rainer Hessmer, February, 2010.
  Released into the public domain.
*/

#ifndef IDG300_h
#define IDG300_h

#include "WProgram.h"
#include "UtilityFunctions.h"

class IDG300
{
	public:
		IDG300(int xPin, int yPin)
		{
			_xPin = xPin;
			_yPin = yPin;

			analogReference(EXTERNAL);
		}

		void Update()
		{
			// Center: AnalogIn values for zero change (x and y)
			const int c_ZeroX = 471;
			const int c_ZeroY = 355;

			// Scaling from analog in values to degree/sec
			// Sensitivity: 2.0 mV/degree/Sec
			//    10 bits (1024 values) for 3.3 V: 3.22265625 mV per step
			//    or: 1.611328125 degree/sec for each step
			const float c_Scaling = 1.611328125;

			double xRaw, yRaw;
			const int count = 5;

			for(int i = 0; i < count; i++)
			{
				xRaw += analogRead(_xPin);
				yRaw += analogRead(_yPin);
			}

			xRaw = xRaw / count;
			yRaw = yRaw / count;

			const double contribution = 0.1;
			RawXValue = Smooth(RawXValue, xRaw, contribution);
			RawYValue = Smooth(RawYValue, yRaw, contribution);

			/*Serial.print("double");
			Serial.print("\t");
			Serial.print(RawXValue);
			Serial.print("\t");
			Serial.print(RawYValue);
			Serial.println();*/

			// Calibrate
			XDegreesPerSec = (RawXValue - c_ZeroX) * c_Scaling;
			YDegreesPerSec = (RawYValue - c_ZeroY) * c_Scaling;

			XRadPerSec = XDegreesPerSec / 180.0 * M_PI;
			YRadPerSec = YDegreesPerSec / 180.0 * M_PI;
		}

		float RawXValue, RawYValue; // public to facilitate calibration of zero point
		float XDegreesPerSec, YDegreesPerSec;
		float XRadPerSec, YRadPerSec;

	private:
		int _xPin, _yPin;
};

#endif
