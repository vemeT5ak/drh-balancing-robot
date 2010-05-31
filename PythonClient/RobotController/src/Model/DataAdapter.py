'''
Created on May 15, 2010

@author: Dr. Rainer Hessmer
'''

from Support.TimeStampedData import TimeStampedData
import math 
import threading
import time

_RadToDeg = 180.0/math.pi

class DataAdapter(object):
    '''
    classdocs
    '''
    
    def __init__(self, dataGateway, mainModel):
        '''
        Constructor
        '''
        self._DataGateway = dataGateway
        self._DataGateway.ReceivedLineHandler = self._OnLineReceived
        self._MainModel = mainModel
        self._MaxAgeBuffer = mainModel.MaxAgeBuffer
        
        self._AddDefaultValuesIfEmpty()
        
    def Start(self):
        self._ReceiverThread = threading.Thread(target=self._AddDefaultValuesIfEmpty)
        self._ReceiverThread.setDaemon(1)
        self._ReceiverThread.start()
        
        self._DataGateway.Start()
        #self._DataGateway.Write('SendCoeffs')
        
    def _OnLineReceived(self, line):
        try:
            print(line)
            lineParts = line.split('\t')
            #print(lineParts)
            
            if (len(lineParts) == 0):
                pass
            
            if (lineParts[0] == 'Debug'):
                print(line)
            
#            elif (lineParts[0] == 'Coeffs'):
#                coefficients = list(float(linePart) / 1000 for linePart in lineParts)
#                self._MainModel.OnCoefficientsReceived(coefficients)
            elif (lineParts[0] == 'SpeedCtrlParams'):
                pass
            else:
                data = (float(lineParts[0]) * _RadToDeg, # raw tilt angle [degree] from accelerometer
                        float(lineParts[1]) * _RadToDeg, # tilt angle [degree] from sensor fusion (accelerometer & gyroscope)
                        float(lineParts[2]) * _RadToDeg, # angular rate [degree / sec]
                        float(lineParts[3]), # current speed motor 1 [m/sec]
                        float(lineParts[4]), # current speed motor 2 [m/sec]
                        )
                timeStampedData = TimeStampedData(data)
                
                self._MaxAgeBuffer.append(timeStampedData)
                #print(self._MaxAgeBuffer)
        except ValueError:
            print("Unrecognized format: " + line)
        
        
    def _AddDefaultValuesIfEmpty(self):
        if len(self._MaxAgeBuffer) == 0:
            timeStampedData = TimeStampedData((0,0,0,0,0))
            self._MaxAgeBuffer.append(timeStampedData)
        
        # next we wait a tenth of the maximum age of the buffer before we check again
        maxAge = self._MaxAgeBuffer.MaximumAge
        waitSeconds = (maxAge.seconds + maxAge.microseconds / 1000.0) / 10.0
        #print(waitSeconds)
        time.sleep(waitSeconds)
        
    def RequestCoefficients(self):
        self._DataGateway.Write('SendCoeffs\r')
        
    def SendCoefficients(self, coefficients):
        '''
        Sends the specified controller coefficients (a tuple of four floats) to the Arduino board.
        '''
        message = 'SetCoeffs %d %d %d %d\r' % coefficients
        self._DataGateway.Write(message)
        
    def SendSpeedControllerParams(self, pidParams):
        '''
        Sends the provided PID loop parameters provided as a tuple of three floats to the Arduino board.
        Each value is broken into an integer base and exponent.
        '''
        # the receiver code only understands integers
        message = 'SetSpeedCtrlParams %d %d %d %d %d %d\r' % self._GetBaseAndExponents(pidParams)
        self._DataGateway.Write(message)
        
    def SendSpeed(self, speed):
        '''
        Sends the specified desired speed to the Arduino board.
        Each value is broken into an integer base and exponent.
        '''
        
        # the receiver code only understands integers
        message = 'SetSpeed %d %d %d %d\r' % self._GetBaseAndExponents((speed, speed))
        self._DataGateway.Write(message)

    def Stop(self):
        self._DataGateway.Stop()
        
    def _GetBaseAndExponent(self, floatValue, resolution=4):
        '''
        Converts a float into a tuple holding two integers:
        The base, an integer with the number of digits equaling resolution.
        The exponent indicating what the base needs to multiplied with to get
        back the original float value with the specified resolution. 
        '''
        
        if (floatValue == 0.0):
            return (0, 0)
        else:
            exponent = int(1.0 + math.log10(floatValue))
            multiplier = math.pow(10, resolution - exponent)
            base = int(floatValue * multiplier)
            
            return(base, exponent - resolution)
        
    def _GetBaseAndExponents(self, floatValues, resolution=4):
        '''
        Converts a list or tuple of floats into a tuple holding two integers for each float:
        The base, an integer with the number of digits equaling resolution.
        The exponent indicating what the base needs to multiplied with to get
        back the original float value with the specified resolution. 
        '''
        
        baseAndExponents = []
        for floatValue in floatValues:
            baseAndExponent = self._GetBaseAndExponent(floatValue)
            baseAndExponents.append(baseAndExponent[0])
            baseAndExponents.append(baseAndExponent[1])
        
        return tuple(baseAndExponents)
