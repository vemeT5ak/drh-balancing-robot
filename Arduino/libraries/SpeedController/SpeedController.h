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

#include "QuadratureEncoder.h"
#include <EEPROM.h>

class SpeedController
{
	public:
		float CurrentSpeed;

		// Base address is used as the address in the EEPROM to store the parameters to.
		// The SpeedController consumes 12 bytes.
		SpeedController(QuadratureEncoder* pQuadratureEncoder, int baseAddress)
		{
			_pQuadratureEncoder = pQuadratureEncoder;
			_EEPROMBaseAddress = baseAddress;
			_LastWheelPosition = 0;
			_EncoderTicksPerMeterPerSec = 2328.21;
			_EncoderTicksPerMeterPerSec = 1000.0;

			ReadFloatFromEEPROM(_EEPROMBaseAddress, _P);
			ReadFloatFromEEPROM(_EEPROMBaseAddress + 1 * sizeof(float), _I);
			ReadFloatFromEEPROM(_EEPROMBaseAddress + 2 * sizeof(float), _D);

			// The maximum number of encoder ticks at full speed is roughly 2500 per second
			// For our update interval this comes to
			//float maxTicksPerUpdate = 2500.0 * updateInterval / 1000.0;
			_LastError = 0.0;
			_ErrorIntegral = 0.0;
			_ErrorDiff = 0.0;
		}

		void Initialize()
		{
			_LastWheelPosition = _pQuadratureEncoder->GetPosition();
		}

		// Inputs:
		//    Desired speed in m/sec
		//    seconds since the last update was called
		// Returns:
		//    A value in the range [-127 ... +127] to be used to control the Sabertooth motor controller
		float ComputeOutput(float desiredSpeed, float secondsSinceLastUpdate)
		{
			//float desiredWheelPositionChange = desiredSpeed * _EncoderTicksPerMeterPerSec * secondsSinceLastUpdate;
			long wheelPosition = _pQuadratureEncoder->GetPosition();
			float actualWheelPositionChange = -(wheelPosition - _LastWheelPosition);
			_LastWheelPosition = wheelPosition;

			CurrentSpeed = actualWheelPositionChange / _EncoderTicksPerMeterPerSec / secondsSinceLastUpdate;

			float error = desiredSpeed - CurrentSpeed;

			// Integral part
			if (_I == 0.0)
			{
				_ErrorIntegral = 0.0;
			}
			else
			{
				_ErrorIntegral = _ErrorIntegral + error * secondsSinceLastUpdate;
			}

			float deltaError = error - _LastError;
			if (deltaError > 0.0)
			{
				_ErrorDiff = deltaError / secondsSinceLastUpdate;
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
		long _LastWheelPosition;
		float _EncoderTicksPerMeterPerSec;

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