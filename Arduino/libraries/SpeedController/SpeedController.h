/*
  SpeedController.h - Library for controlling the speed using
  input from a quadrature encoder and a PID controller for
  controlling the ouput to the motors.

  Dr. Rainer Hessmer, May, 2010.
  Released into the public domain.

  Acknowledgements:
  The following article provided valuable input:
  http://www.barello.net/Papers/Motion_Control/index.htm
*/

#ifndef SpeedController_h
#define SpeedController_h

#include <EEPROM.h>
#include "QuadratureEncoder.h"
#include "WProgram.h"
#include "TimeInfo.h"

class SpeedController
{
	public:
		float CurrentSpeed;
		float DistanceIncrement;
		float TotalDistanceTraveled;

		// Base address is used as the address in the EEPROM to store the parameters to.
		// The SpeedController consumes 12 bytes.
		SpeedController(QuadratureEncoder* pQuadratureEncoder, float encoderTicksPerMeter, int baseAddress)
		{
			_pQuadratureEncoder = pQuadratureEncoder;
			_EEPROMBaseAddress = baseAddress;
			_TravelStartTickCount = 0;
			_LastUpdateTickCount = 0;
			_EncoderTicksPerMeter = encoderTicksPerMeter;
			_DirectionFactor = -1;

			ReadFloatFromEEPROM(_EEPROMBaseAddress, _P);
			ReadFloatFromEEPROM(_EEPROMBaseAddress + 1 * sizeof(float), _I);
			ReadFloatFromEEPROM(_EEPROMBaseAddress + 2 * sizeof(float), _D);

			_LastError = 0.0;
			_ErrorIntegral = 0.0;
			_ErrorDiff = 0.0;
		}

		void Reset(unsigned long millisecs)
		{
			_TravelStartMillisecs = millisecs;
			_TravelStartTickCount = _pQuadratureEncoder->GetPosition();

			_LastUpdateTickCount = _TravelStartTickCount;
			CurrentSpeed = 0.0;
			DistanceIncrement = 0.0;
			TotalDistanceTraveled = 0.0;
		}

		//void ResetDistanceTraveled(unsigned long millisecs)
		//{
		//	_TravelStartMillisecs = millisecs;
		//	_TravelStartTickCount = _pQuadratureEncoder->GetPosition();
		//}

		void Update(TimeInfo* pTimeInfo)
		{
			long currentTickCount = _pQuadratureEncoder->GetPosition();
			long tickCountChange = _DirectionFactor * (currentTickCount - _LastUpdateTickCount);
			_LastUpdateTickCount = currentTickCount;

			DistanceIncrement= tickCountChange / _EncoderTicksPerMeter;
			CurrentSpeed = DistanceIncrement / pTimeInfo->SecondsSinceLastUpdate;

			TotalDistanceTraveled += DistanceIncrement;
		}

		// Inputs:
		//    Desired speed in m/sec
		// Returns:
		//    A value in the range [-127 ... +127] to be used to control the Sabertooth motor controller
		float ComputeOutput(float desiredSpeed, TimeInfo* pTimeInfo)
		{
			Update(pTimeInfo);
			float error = desiredSpeed - CurrentSpeed;

			// Integral part
			if (_I == 0.0)
			{
				_ErrorIntegral = 0.0;
			}
			else
			{
				_ErrorIntegral = _ErrorIntegral + error * pTimeInfo->SecondsSinceLastUpdate;
			}

			float deltaError = error - _LastError;
			if (deltaError > 0.0)
			{
				_ErrorDiff = deltaError / pTimeInfo->SecondsSinceLastUpdate;
			}
			else
			{
				_ErrorDiff = 0;
			}

			float cv =
				_P * error +
				_I * _ErrorIntegral +
				_D * _ErrorDiff;

			_LastError = error;

			return cv;
		}

		void SetPIDParams(float p, float i, float d)
		{
			WriteFloatToEEPROM(_EEPROMBaseAddress, p);
			WriteFloatToEEPROM(_EEPROMBaseAddress + 1 * sizeof(float), i);
			WriteFloatToEEPROM(_EEPROMBaseAddress + 2 * sizeof(float), d);

			_P = p;
			_I = i;
			_D = d;

			/*_LastError = 0.0;
			_ErrorIntegral = 0.0;
			_ErrorDiff = 0.0;*/
		}

		float GetP()
		{
			return _P;
		}

		float GetI()
		{
			return _I;
		}

		float GetD()
		{
			return _D;
		}

	private:
		QuadratureEncoder* _pQuadratureEncoder;
		int _EEPROMBaseAddress;

		unsigned long _TravelStartMillisecs;
		long _TravelStartTickCount;

		unsigned long _LastUpdateMillisecs;
		float _SecondsSinceLastUpdate;
		long _LastUpdateTickCount;

		float _EncoderTicksPerMeter;
		float _DirectionFactor; // +1 means moving forward increases the ticks; -1 means ticks decrease

		float _P, _I, _D;
		float _LastError, _ErrorIntegral, _ErrorDiff;

		// Saves float in EEPROM
		// For details see http://www.arduino.cc/playground/Code/EEPROMWriteAnything
		void WriteFloatToEEPROM(int address, const float& value)
		{
			const byte* p = (const byte*)(const void*)&value;
			int i;
			for (i = 0; i < sizeof(value); i++)
			{
				EEPROM.write(address++, *p++);
			}
		}

		void ReadFloatFromEEPROM(int address, float& value)
		{
			byte* p = (byte*)(void*)&value;
			int i;
			for (i = 0; i < sizeof(value); i++)
			{
				*p++ = EEPROM.read(address++);
			}
		}
};

#endif