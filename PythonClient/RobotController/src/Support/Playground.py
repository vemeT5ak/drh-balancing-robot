'''
Created on May 15, 2010

@author: Dr. Rainer Hessmer
'''

import math 

    

def GetBaseAndExponent(floatValue, resolution=4):
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

def TestRoundTrip(floatValue):
    pair = GetBaseAndExponent(floatValue)
    print(pair)
    
    regenFloat = pair[0] * math.pow(10, pair[1])
    print(regenFloat)


if __name__ == '__main__':
    TestRoundTrip(3.14)
    TestRoundTrip(12.345)
    TestRoundTrip(9.999999)
    TestRoundTrip(0)
