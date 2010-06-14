/*
  TimeInfo.h - A very simple class that contains time related information

  Dr. Rainer Hessmer, May, 2010.
  Released into the public domain.
*/

#ifndef TimeInfo_h
#define TimeInfo_h

#include "WProgram.h"

class TimeInfo
{
	public:
		unsigned long LastUpdateMillisecs;
		unsigned long CurrentMillisecs;
		unsigned long MillisecsSinceLastUpdate;
		float SecondsSinceLastUpdate;

		TimeInfo()
		{
			CurrentMillisecs = millis();
			LastUpdateMillisecs = CurrentMillisecs;
			MillisecsSinceLastUpdate = 0;
			SecondsSinceLastUpdate = 0.0;
		}

		void Update()
		{
			CurrentMillisecs = millis();
			MillisecsSinceLastUpdate = CurrentMillisecs - LastUpdateMillisecs;
			LastUpdateMillisecs = CurrentMillisecs;
			SecondsSinceLastUpdate = MillisecsSinceLastUpdate / 1000.0;
		}
};

#endif