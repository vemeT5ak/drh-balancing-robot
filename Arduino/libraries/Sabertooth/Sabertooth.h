/*
  Sabertooth.h - Library for communicating with the Sabertooth motor driver using Packetized Serial Mode.
  Dr. Rainer Hessmer, April, 2010.
  Released into the public domain.

  Acknowledgements:
  The following article helped me get started: http://psurobotics.org/wiki/index.php?title=SyRen_10
*/

#ifndef Sabertooth_h
#define Sabertooth_h

#include "WProgram.h"
#include "HardwareSerial.h"

class Sabertooth
{
public:
	// address:     The address of the Sabertooth motor driver defined by its dip switches.
	//              Must be a value between 128 and go to 135.
	// pSerial:     The pointer to the serial port to use. In the case of a regular arduino only
	//              port 0 is possible (&Serial). On the Arduino Mega ports 1,2,3 are possible as
	//              well (&Serial1, &Serial2, &Serial13). It implicitly specifies the TX pin that
	//              needs to be connected to the Sabertooth motor driver.
	//              Serial port | TX Pin
	//                  0       |   1
	//                  1       |   18
	//                  2       |   16
	//                  3       |   14
	Sabertooth(int address, HardwareSerial* pSerial)
	{
		_Address = address;
		_pSerial = pSerial;
	}

	// Initializes the communication. Must be called no earlier than 2 secs after the Sabertooth
	// driver has been powered up.
	//
	// baud:        Baud rate of the communication between the Arduino board and the Sabertooth
	//              driver. Allowed values are: 2400, 9600, 19200 and 38400
	void InitializeCom(int baud)
	{
		_pSerial->begin(baud);
		// Send the bauding character to establish the baud rate
		_pSerial->print(170, BYTE);
	}

	// Sets the minimum voltage for the battery feeding the Sabertooth. If the
	// battery voltage drops below this value, the output will shut down.
	// The value is sent in .2 volt increments. The supported voltage range is
	// from 6V to 30V.
	void SetMinVoltage(float volts)
	{
		int value = (volts-6) * 5;
		Send(2, value);
	}

	// Valid speed is between -127 and +127
	void SetSpeedMotorA(int speed)
	{
		SetMotorSpeed(A, speed);
	}

	// Valid speed is between -127 and +127
	void SetSpeedMotorB(int speed)
	{
		SetMotorSpeed(B, speed);
	}

	// Valid speed is between -127 and +127
	int GetCommandedSpeedA()
	{
		return _CurrentSpeed[A];
	}

	// Valid speed is between -127 and +127
	int GetCommandedSpeedB()
	{
		return _CurrentSpeed[B];
	}


private:
	int _Address;
	HardwareSerial* _pSerial;
	int _CurrentSpeed[1];

	enum Motor { A, B };

	void SetMotorSpeed(Motor motor, int speed)
	{
		speed = ClipSpeed(speed);
		_CurrentSpeed[(int)motor] = speed;

		int motorCommandStart = (motor == A ? 0 : 4);

		if (speed >= 0)
		{
			// forward
			Send(motorCommandStart + 0, speed);
		}
		else
		{
			// backwards
			Send(motorCommandStart + 1, -speed);
		}
	}

	int ClipSpeed(int speed)
	{
		if (speed < -127)
		{
			return -127;
		}
		if (speed > 127)
		{
			return 127;
		}
		return speed;
	}

	void Send(int command, int value)
	{
		_pSerial->print(_Address, BYTE);
		_pSerial->print(command, BYTE);
		_pSerial->print(value, BYTE);
		_pSerial->print((_Address + command + value) & 0b01111111, BYTE);
	}
};

#endif
