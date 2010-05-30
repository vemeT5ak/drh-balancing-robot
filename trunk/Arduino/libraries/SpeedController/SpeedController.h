/*
  SpeedController.h - Library for controlling the speed using
  input from a quadrature encoder and a PID controller for
  controlling the ouput to the motors.

  Dr. Rainer Hessmer, May, 2010.
  Released into the public domain.

  Acknowledgements:
  The following article provided valuable input:
  http://www.barello.net/Papers/Motion_Control/index.htm

  Brett Beauregard's implementation of the PID controller:
  http://www.arduino.cc/playground/Code/PIDLibrary
*/

#ifndef SpeedController_h
#define SpeedController_h

#include "QuadratureEncoder.h"
#include "Sabertooth.h"
#include "PID_Beta6.h"
#include <EEPROM.h>

class SpeedController
{
	public:
		float CurrentSpeed;

		// update interval: miliseconds
		// Base address is used as the address in the EEPROM to store the parameters to.
		// The SpeedController consumes 12 bytes.
		SpeedController(int updateInterval, QuadratureEncoder* pQuadratureEncoder, int baseAddress)
		{
			_pQuadratureEncoder = pQuadratureEncoder;
			_EEPROMBaseAddress = baseAddress;
			_LastWheelPosition = 0;
			_EncoderTicksPerMeterPerSec = 2328.21;

			float pParam, iParam, dParam;
			ReadFloatFromEEPROM(_EEPROMBaseAddress, pParam);
			ReadFloatFromEEPROM(_EEPROMBaseAddress + 1 * sizeof(float), iParam);
			ReadFloatFromEEPROM(_EEPROMBaseAddress + 2 * sizeof(float), dParam);

			*_pPID = PID(&_PIDInput, &_PIDOutput, &_PIDSetpoint, pParam, iParam, dParam);
			_pPID->SetSampleTime(updateInterval);

			// The maximum number of encoder ticks at full speed is roughly 2500 per second
			// For out update interval this come to
			float maxTicksPerUpdate = 2500.0 * updateInterval / 1000.0;
			_pPID->SetInputLimits(-maxTicksPerUpdate, maxTicksPerUpdate);
			_pPID->SetOutputLimits(-127, +127); // the Sabertooth motor controller expects an imput from -127 to +127
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
			float desiredWheelPositionChange = desiredSpeed * _EncoderTicksPerMeterPerSec * secondsSinceLastUpdate;
			long wheelPosition = _pQuadratureEncoder->GetPosition();
			float actualWheelPositionChange = (wheelPosition - _LastWheelPosition);

			CurrentSpeed = actualWheelPositionChange / _EncoderTicksPerMeterPerSec;

		/*	float wheelVelocity = 0;
			if (wheelPositionChange != 0)
			{
				wheelVelocity = wheelPositionChange / secondsSinceLastUpdate;
			}*/
			_LastWheelPosition = wheelPosition;
			
			_PIDSetpoint = desiredWheelPositionChange;
			_PIDInput = actualWheelPositionChange;

			_pPID->Compute();

			return _PIDOutput;
		}

		void SetPIDParams(float pParam, float iParam, float dParam)
		{
			WriteFloatToEEPROM(_EEPROMBaseAddress, pParam);
			WriteFloatToEEPROM(_EEPROMBaseAddress + 1 * sizeof(float), iParam);
			WriteFloatToEEPROM(_EEPROMBaseAddress + 2 * sizeof(float), dParam);

			_pPID->SetTunings(pParam, iParam, dParam);
		}

		float GetPParam()
		{
			return _pPID->GetP_Param();
		}

		float GetIParam()
		{
			return _pPID->GetI_Param();
		}

		float GetDParam()
		{
			return _pPID->GetD_Param();
		}

	private:
		QuadratureEncoder* _pQuadratureEncoder;
		int _EEPROMBaseAddress;
		long _LastWheelPosition;
		float _EncoderTicksPerMeterPerSec;

		float _PIDInput, _PIDOutput, _PIDSetpoint;
		PID *_pPID;

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