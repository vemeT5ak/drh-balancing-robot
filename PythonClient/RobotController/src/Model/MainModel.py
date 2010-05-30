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
        self.SpeedControlParams = {'P':0, 'I':0, 'D':0} # P,I,D parameters for the speed controller
        self.Coefficients = {'K1':0, 'K2':0, 'K3':0, 'K4':0} # Coefficients K1, .. K4
        
        self._Settings = Settings(self)
        self._Settings.Load()

        self.MaxAgeBuffer = MaxAgeBuffer(timedelta(seconds=10))
        #dataReceiver = TestDataReceiver()
        self._DataAdapter = DataAdapter(SerialDataGateway(self.SerialPort), self)
        self._DataAdapter.Start()
    
    def OnCoefficientsReceived(self, coefficients):
        self.Coefficients = coefficients
        
    def SetSpeedControlParams(self, params):
        '''
        params is expected to a tuple holding three values that can be converted to floats representing the P,I,D parameters
        '''
        
        floatParams = tuple(float(param) for param in params)
        
        self.SpeedControlParams['P'] = floatParams[0]
        self.SpeedControlParams['I'] = floatParams[1]
        self.SpeedControlParams['D'] = floatParams[2]
        
        self._DataAdapter.SendSpeedControllerParams(floatParams)
    
    def Close(self):
        self._DataAdapter.Stop()
        self._Settings.Save()
        