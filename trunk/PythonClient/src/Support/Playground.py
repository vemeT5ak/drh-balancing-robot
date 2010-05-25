'''
Created on May 15, 2010

@author: Dr. Rainer Hessmer
'''

from datetime import datetime, timedelta
from TimeStampedData import TimeStampedData
from MaxAgeBuffer import MaxAgeBuffer
import wx 
import os
import ConfigParser

    
def GetFloat(configParser, section, option, defaultValue=0):
    try:
        return configParser.getfloat(section, option)
    except ConfigParser.NoSectionError:
        return defaultValue
    except ConfigParser.NoOptionError:
        return defaultValue
    except ValueError:
        return defaultValue 


if __name__ == '__main__':
    app = wx.App(False)
    app.AppName = 'Test'
    
    # for details see: http://www.wxpython.org/docs/api/wx.StandardPaths-class.html
    standardPaths = wx.StandardPaths_Get()
    
    print(standardPaths.GetUserLocalDataDir())
    
    configFileName = "TestConfig.txt"
    configFilePath = os.path.join(standardPaths.GetUserLocalDataDir(), configFileName)
    print(configFilePath)
    
    configParser = ConfigParser.RawConfigParser()
    configParser.read('example.cfg')
    
    float1 = GetFloat(configParser, 'section1', 'option1', 42)
    print(float1)

    
    
    
#    timeSpan = timedelta(seconds=123)
#    print(timeSpan.seconds)
#    print(timeSpan.microseconds)
#    
#    maxAgeBuffer = MaxAgeBuffer(timedelta(seconds=10))
#    now = datetime.now()
#    for i in xrange(10):
#        timeStampedData = TimeStampedData((10-i,i), now - timedelta(seconds=10-i))
#        maxAgeBuffer.append(timeStampedData)
#
#    timeStamps = []
#    values1 = []
#    values2 = []
#    for timeStampedData in maxAgeBuffer:
#        timeStamps.append(timeStampedData.TimeStamp)
#        values1.append(timeStampedData.Value[0])
#        values2.append(timeStampedData.Value[1])
#        
#    print timeStamps
#    print values1
#    print values2