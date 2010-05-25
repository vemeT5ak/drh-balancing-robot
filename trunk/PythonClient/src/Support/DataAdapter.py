'''
Created on May 15, 2010

@author: Dr. Rainer Hessmer
'''

from TimeStampedData import TimeStampedData
import math 
import threading
import time

_RadToDeg = 180.0/math.pi

class DataAdapter(object):
    '''
    classdocs
    '''
    
    def __init__(self, dataReceiver, maxAgeBuffer):
        '''
        Constructor
        '''
        dataReceiver.ReceivedLineHandler = self._OnLineReceived
        self._MaxAgeBuffer = maxAgeBuffer
        
        self._AddDefaultValuesIfEmpty()
        
        self._ReceiverThread = threading.Thread(target=self._AddDefaultValuesIfEmpty)
        self._ReceiverThread.setDaemon(1)
        self._ReceiverThread.start()
   
    def _OnLineReceived(self, line):
        print(line)
        lineParts = line.split('\t')
        #print(lineParts)
        
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
        print(waitSeconds)
        time.sleep(waitSeconds)
        