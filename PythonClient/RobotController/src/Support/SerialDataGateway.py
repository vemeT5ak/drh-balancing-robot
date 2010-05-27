'''
Created on May 7, 2010

@author: Dr. Rainer Hessmer
'''
import threading
import serial
from cStringIO import StringIO
import time

def _OnLineReceived(line):
    print(line)


class SerialDataGateway(object):
    '''
    Helper class for receiving lines from a serial port
    '''

    def __init__(self, port):
        '''
        Initializes the receiver class. 
        port: The serial port to listen to.
        receivedLineHandler: The function to call when a line was received.
        '''
        self._Port = port
        self.ReceivedLineHandler = _OnLineReceived
        self._KeepRunning = False
        
    def Start(self):
        self._Serial = serial.Serial(port=self._Port, baudrate=115200)

        self._KeepRunning = True
        self._ReceiverThread = threading.Thread(target=self._Listen)
        self._ReceiverThread.setDaemon(1)
        self._ReceiverThread.start()
        
    def Stop(self):
        print("stopping")
        self._KeepRunning = False
        time.sleep(.1)
        self._Serial.close()

    def _Listen(self):
        stringIO = StringIO()
        while self._KeepRunning:
            data = self._Serial.read(1)
            if data == '\r':
                pass
            elif data == '\n':
                self.ReceivedLineHandler(stringIO.getvalue())
                stringIO.close()
                stringIO = StringIO()
            else:
                stringIO.write(data)
    
    def Write(self, data):
        self._Serial.write(data)

if __name__ == '__main__':
    dataReceiver = SerialDataGateway(6)
    dataReceiver.Start()
    
    raw_input("Hit <Enter> to end.")
    dataReceiver.Stop()
