/*
  IDG300.cpp - Library for the IDG300 2-axis gyroscope.
  Created by Dr. Rainer Hessmer, February, 2010.
  Released into the public domain.
*/

#include "WProgram.h"
#include "IDG300.h"
#include <math.h>


IDG300::IDG300(int xPin, int yPin)
{
  _xPin = xPin;
  _yPin = yPin;

  analogReference(EXTERNAL);
}

void IDG300::Update()
{
	// Center: AnalogIn values for zero change (x and y)
	const int c_ZeroX = 472;
	const int c_ZeroY = 353;

	// Scaling from analog in values to degree/sec
	// Sensitivity: 2.0 mV/degree/Sec
	//    10 bits (1024 values) for 3.3 V: 3.22265625 mV per step
	//    or: 1.611328125 degree/sec for each step
	const float c_Scaling = 1.611328125;

	int rawXValue = analogRead(_xPin);
	int rawYValue = analogRead(_yPin);

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

