'''
Created on May 14, 2010

@author: Dr. Rainer Hessmer
'''

from datetime import datetime, timedelta


class TimeStampedData(object):
    '''
    classdocs
    '''

    def __init__(self, value, timeStamp = None):
        '''
        Constructor
        '''
        
        if timeStamp is None:
            self.TimeStamp = datetime.now()
        else:
            self.TimeStamp = timeStamp
        self.Value = value

    def __str__(self):
        return 'TimeStampedData (' + str(self.TimeStamp) + ', ' + str(self.Value) + ')'

    def __repr__(self):
        return '(' + str(self.TimeStamp) + ', ' + str(self.Value) + ')'


if __name__ == '__main__':
    now = datetime.now()
    timeStampedData = TimeStampedData(5, now - timedelta(seconds=5))
    print timeStampedData

    timeStampedData = TimeStampedData(6)
    print timeStampedData
