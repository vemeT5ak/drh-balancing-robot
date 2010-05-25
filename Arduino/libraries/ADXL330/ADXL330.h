/*
  ADXL330.h - Library for the ADXL330 3-axis accelerometer.
  Created by Dr. Rainer Hessmer, February, 2010.
  Released into the public domain.
*/

#ifndef ADXL330_h
#define ADXL330_h

#include "WProgram.h"

class ADXL330
{
  public:
    ADXL330(int xPin, int yPin, int zPin);
	void Update();
	float XAcceleration, YAcceleration, ZAcceleration;  // acceleration in units of g
	float TotalAcceleration; // total acceleration in units of g

	// calculated angles
	float GetXYAngleRad();
	float GetXZAngleRad();
	float GetYZAngleRad();  
  private:
    int _xPin, _yPin, _zPin;
};

#endif
