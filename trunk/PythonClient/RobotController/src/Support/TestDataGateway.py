'''
Created on May 14, 2010

@author: Dr. Rainer Hessmer
'''

import threading
import time
import random

def _OnLineReceived(line):
    print(line)

class TestDataGateway(object):
    '''
    classdocs
    '''

    def __init__(self):
        '''
        Initializes the receiver class. 
        port: The serial port to listen to.
        receivedLineHandler: The function to call when a line was received.
        '''
        self.ReceivedLineHandler = _OnLineReceived
            
    def Start(self):
        self._ReceiverThread = threading.Thread(target=self._CreateDataLines)
        self._ReceiverThread.setDaemon(1)
        self._ReceiverThread.start()
       
    def Stop(self):
        print("stopping")

    def _CreateDataLines(self):
        while True:
            random1 = random.uniform(-0.5, 0.5)
            random2 = random.uniform(-0.5, 0.5)

            self.ReceivedLineHandler(str(random1) + '\t' + str(random2))
            time.sleep(.05)


if __name__ == '__main__':
    dataReceiver = TestDataGateway()
    dataReceiver.ReceivedLineHandler = _OnLineReceived
    dataReceiver.Start()
    
    raw_input("Hit <Enter> to end.")
    dataReceiver.Stop()
