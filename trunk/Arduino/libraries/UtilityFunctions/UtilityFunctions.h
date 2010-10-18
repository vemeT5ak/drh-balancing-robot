/*
  UtilityFunctions.h - A couple of utility functions

  Dr. Rainer Hessmer, October, 2010.
  Released into the public domain.
*/

#ifndef UtilityFunctions_h
#define UtilityFunctions_h

#include "WProgram.h"

int ReadAnalogMultiple(int pin, int count)
{
	int value = 0;

	for(int i = 0; i < count; i++)
	{
		value += analogRead(pin);
	}
	return value / count;
}

double Smooth(double oldValue, double newValue, double contribution)
{
	return oldValue * (1 - contribution) + newValue * contribution;
}

#endif