/*
  Balancer.h - Library for balancing a two-wheeled robot.
  Dr. Rainer Hessmer, April, 2010.
  Released into the public domain.

  Acknowledgements:
  The code is based on the algorithm for nbot balancing robot: 
  http://www.geology.smu.edu/~dpa-www/robo/nbot/
  http://www.geology.smu.edu/~dpa-www/robo/nbot/bal2.txt
*/

#ifndef Balancer_h
#define Balancer_h

#include "QuadratureEncoder.h"
#include <EEPROM.h>

class Balancer
{
	public:
		float K1, K2, K3, K4;

		// Base address is used as the address in the EEPROM to store the coefficients to.
		// The Balancer consumes 16 bytes.
		Balancer(QuadratureEncoder* pQuadratureEncoder, int baseAddress)
		{
			_pQuadratureEncoder = pQuadratureEncoder;
			_EEPROMBaseAddress = baseAddress;
			_LastWheelPosition = 0;

			LoadCoefficients();
		}

		void Initialize()
		{
			_LastWheelPosition = _pQuadratureEncoder -> GetPosition();
		}

		float CalculateTorque(float angle, float angleVelocity, float secondsSinceLastUpdate)
		{
			long wheelPosition = _pQuadratureEncoder -> GetPosition();
			long wheelPositionChange = wheelPosition - _LastWheelPosition;

			float wheelVelocity = 0;
			if (wheelPositionChange != 0)
			{
				wheelVelocity = wheelPositionChange / secondsSinceLastUpdate;
			}
			_LastWheelPosition = wheelPosition;

			float torque =
				angle * K1 +
				angleVelocity * K2 +
				wheelPosition * K3 +
				wheelVelocity * K4;

			return torque; 
		}

		void SetCoefficients(float k1, float k2, float k3, float k4)
		{
			K1 = k1;
			K2 = k2;
			K3 = k3;
			K4 = k4;

			SaveCoefficients();
		}

	private:
		QuadratureEncoder* _pQuadratureEncoder;
		int _EEPROMBaseAddress;
		long _LastWheelPosition;

		void SaveCoefficients()
		{
			WriteFloatToEEPROM(_EEPROMBaseAddress, K1);
			WriteFloatToEEPROM(_EEPROMBaseAddress + 1 * sizeof(float), K2);
			WriteFloatToEEPROM(_EEPROMBaseAddress + 2 * sizeof(float), K3);
			WriteFloatToEEPROM(_EEPROMBaseAddress + 3 * sizeof(float), K4);
		}

		void LoadCoefficients()
		{
			ReadFloatFromEEPROM(_EEPROMBaseAddress, K1);
			ReadFloatFromEEPROM(_EEPROMBaseAddress + 1 * sizeof(float), K2);
			ReadFloatFromEEPROM(_EEPROMBaseAddress + 2 * sizeof(float), K3);
			ReadFloatFromEEPROM(_EEPROMBaseAddress + 3 * sizeof(float), K4);
		}

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