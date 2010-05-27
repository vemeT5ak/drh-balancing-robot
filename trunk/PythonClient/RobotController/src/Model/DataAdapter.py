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
        self._DataGateway.Write('SendCoeffs')
        
    def _OnLineReceived(self, line):
        #print(line)
        lineParts = line.split('\t')
        #print(lineParts)
        
        if (len(lineParts) == 0):
            pass
        
        if (lineParts[0]=='Coeffs'):
            coefficients = list(float(linePart) / 1000 for linePart in lineParts)
            self._MainModel.OnCoefficientsReceived(coefficients)
        else:
            data = tuple(float(linePart) * _RadToDeg for linePart in lineParts)
            timeStampedData = TimeStampedData(data)
            
            self._MaxAgeBuffer.append(timeStampedData)
            #print(self._MaxAgeBuffer)
        
        
    def _AddDefaultValuesIfEmpty(self):
        if len(self._MaxAgeBuffer) == 0:
            timeStampedData = TimeStampedData((0,0))
            self._MaxAgeBuffer.append(timeStampedData)
        
        # next we wait a tenth of the maximum age of the buffer before we check again
        maxAge = self._MaxAgeBuffer.MaximumAge
        waitSeconds = (maxAge.seconds + maxAge.microseconds / 1000.0) / 10.0
        #print(waitSeconds)
        time.sleep(waitSeconds)
        
    def RequestCoefficients(self):
        self._DataGateway.Write('SendCoeffs')
        
    def SendCoefficients(self, coefficients):
        '''
        Sends the specified controller coefficients (a tuple of four floats) to the arduino board.
        '''
        message = 'SetCoeffs %d %d %d %d\n' % coefficients
        self._DataGateway.Write(message)

    def Stop(self):
        self._DataGateway.Stop()
