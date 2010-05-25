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
    IDG300(int xPin, int yPin);
	void Update();
	float XDegreesPerSec, YDegreesPerSec;
	float XRadPerSec, YRadPerSec;
  private:
    int _xPin, _yPin;
};

#endif
