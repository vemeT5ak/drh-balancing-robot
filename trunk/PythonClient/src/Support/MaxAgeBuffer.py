'''
Created on May 14, 2010

@author: Dr. Rainer Hessmer
'''
from collections import deque # double ended queue
from datetime import datetime, timedelta
from TimeStampedData import TimeStampedData


class MaxAgeBuffer(deque):
    '''
    Stores time stamped data up to a specified maximum age. As new data is added
    old data is pushed out provided it is older then the specified maximum age.
    '''


    def __init__(self, maximumAge):
        '''
        Constructor. maximumAge is an instance of datetime.timedelta
        '''
        deque.__init__(self)
        self.MaximumAge = maximumAge
    
    def append(self, timeStampedValue):
        cutoffDateTime = datetime.now() - self.MaximumAge
        #print 'cutoffDateTime: ' + str(cutoffDateTime)
        #print(timeStampedValue)
        done = False
        while not done:
            if len(self) == 0:
                done = True
            else:
                oldestTimeStampedValue = deque.popleft(self)
                if oldestTimeStampedValue.TimeStamp >= cutoffDateTime:
                    # not old enough; we need to keep it
                    deque.appendleft(self, oldestTimeStampedValue)
                    done = True
        
        deque.append(self, timeStampedValue)

    
#    def __str__(self):
#        return 'MaxAgeBuffer: ' + str(self._Deque)

import time


if __name__ == '__main__':
    maxAgeBuffer = MaxAgeBuffer(timedelta(seconds=10))
    now = datetime.now()
    for i in xrange(10):
        timeStampedData = TimeStampedData(10-i, now - timedelta(seconds=10-i))
        maxAgeBuffer.append(timeStampedData)
        print maxAgeBuffer

    print 'waiting ...'
    time.sleep(2)
    timeStampedData = TimeStampedData(11)
    maxAgeBuffer.append(timeStampedData)
    print maxAgeBuffer

