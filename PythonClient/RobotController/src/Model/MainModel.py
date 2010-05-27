'''
Created on May 17, 2010

@author: Dr. Rainer Hessmer
'''
from Settings import Settings
from datetime import timedelta
from Support.MaxAgeBuffer import MaxAgeBuffer
from DataAdapter import DataAdapter
#from Support.TestDataGateway import TestDataGateway
from Support.SerialDataGateway import SerialDataGateway

class MainModel(object):
    '''
    The model behind the main window
    '''

    _ConfigFileName = 'BalancingBotConfig.txt'

    def __init__(self, serialPort = 6):
        '''
        Constructor
        '''
        
        self.SerialPort = serialPort
        self.Coefficients = [0,0,0,0] # Coefficients K1, .. K4
        
        self._Settings = Settings(self)
        self._Settings.Load()

        self.MaxAgeBuffer = MaxAgeBuffer(timedelta(seconds=10))
        #dataReceiver = TestDataReceiver()
        self._DataAdapter = DataAdapter(SerialDataGateway(self.SerialPort), self)
        self._DataAdapter.Start()
    
    def OnCoefficientsReceived(self, coefficients):
        self.Coefficients = coefficients
    
    def Close(self):
        self._DataAdapter.Stop()
        self._Settings.Save()
        