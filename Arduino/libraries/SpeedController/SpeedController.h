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
		// Base address is used as the address in the EEPROM to store the parameters to.
		// The SpeedController consumes 12 bytes.
		SpeedController(int updateInterval, QuadratureEncoder* pQuadratureEncoder, int baseAddress)
		{
			_pQuadratureEncoder = pQuadratureEncoder;
			_EEPROMBaseAddress = baseAddress;
			_LastWheelPosition = 0;

			float pParam, iParam, dParam;
			ReadFloatFromEEPROM(_EEPROMBaseAddress, pParam);
			ReadFloatFromEEPROM(_EEPROMBaseAddress + 1 * sizeof(float), iParam);
			ReadFloatFromEEPROM(_EEPROMBaseAddress + 2 * sizeof(float), dParam);

			*_pPID = PID(&_PIDInput, &_PIDOutput, &_PIDSetpoint, pParam, iParam, dParam);
			_pPID->SetSampleTime(updateInterval);
			_pPID->SetOutputLimits(-127, +127); // the Sabertooth motor controller expects an imput from -127 to +127
		}

		void Initialize()
		{
			_LastWheelPosition = _pQuadratureEncoder->GetPosition();
		}
		
		float ComputeOutput(float desiredSpeed, float secondsSinceLastUpdate)
		{
			long wheelPosition = _pQuadratureEncoder->GetPosition();
			long wheelPositionChange = wheelPosition - _LastWheelPosition;

			float wheelVelocity = 0;
			if (wheelPositionChange != 0)
			{
				wheelVelocity = wheelPositionChange / secondsSinceLastUpdate;
			}
			_LastWheelPosition = wheelPosition;
			
			_PIDSetpoint = desiredSpeed;
			_PIDInput = wheelVelocity;

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