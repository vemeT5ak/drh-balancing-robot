/*
  IDG300.h - Library for the IDG300 2-axis gyroscope.
  Created by Dr. Rainer Hessmer, February, 2010.
  Released into the public domain.
*/

#ifndef IDG300_h
#define IDG300_h

#include "WProgram.h"

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

			rawXValue = analogRead(_xPin);
			rawYValue = analogRead(_yPin);

			/*Serial.print("double");
			Serial.print("\t");
			Serial.print(rawXValue);
			Serial.print("\t");
			Serial.print(rawYValue);
			Serial.println();*/

			// Calibrate
			XDegreesPerSec = (rawXValue - c_ZeroX) * c_Scaling;
			YDegreesPerSec = (rawYValue - c_ZeroY) * c_Scaling;

			XRadPerSec = XDegreesPerSec / 180.0 * M_PI;
			YRadPerSec = YDegreesPerSec / 180.0 * M_PI;
		}

		float rawXValue, rawYValue; // public to facilitate calibration of zero point
		float XDegreesPerSec, YDegreesPerSec;
		float XRadPerSec, YRadPerSec;

	private:
		int _xPin, _yPin;
};

#endif
