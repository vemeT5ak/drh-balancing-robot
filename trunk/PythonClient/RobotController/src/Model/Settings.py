'''
Created on May 8, 2010

@author: Dr. Rainer Hessmer
'''

import wx
import os
import ConfigParser

class Settings(object):
    '''
    classdocs
    '''

    _ConfigFileName = 'BalancingBotConfig.txt'
    _SectionGeneral = 'General'
    _SectionSpeedControl = 'SpeedControl'
    _SectionCoeffs = 'Coeffs'

    def __init__(self, mainModel):
        '''
        Constructor
        '''
        
        # for details see: http://www.wxpython.org/docs/api/wx.StandardPaths-class.html
        standardPaths = wx.StandardPaths_Get()
        self._ConfigFilePath = os.path.join(standardPaths.GetUserLocalDataDir(), self._ConfigFileName)
        self._MainModel = mainModel
        
    def Load(self):
        configParser = ConfigParser.RawConfigParser()
        configParser.read(self._ConfigFilePath)
        
        self._MainModel.SerialPort = self.GetInt(configParser, self._SectionGeneral, 'Port', self._MainModel.SerialPort)
        
        speedControlParams = self._MainModel.SpeedControlParams
        speedControlParams['P'] = self.GetFloat(configParser, self._SectionSpeedControl, 'P', speedControlParams['P'])
        speedControlParams['I'] = self.GetFloat(configParser, self._SectionSpeedControl, 'I', speedControlParams['I'])
        speedControlParams['D'] = self.GetFloat(configParser, self._SectionSpeedControl, 'D', speedControlParams['D'])
        
        coefficients = self._MainModel.Coefficients
        coefficients['K1'] = self.GetInt(configParser, self._SectionCoeffs, 'K1', coefficients['K1'])
        coefficients['K2'] = self.GetInt(configParser, self._SectionCoeffs, 'K2', coefficients['K2'])
        coefficients['K3'] = self.GetInt(configParser, self._SectionCoeffs, 'K3', coefficients['K3'])
        coefficients['K4'] = self.GetInt(configParser, self._SectionCoeffs, 'K4', coefficients['K4'])
    
    def Save(self):
        configParser = ConfigParser.RawConfigParser()

        configParser.add_section(self._SectionGeneral)
        configParser.set(self._SectionGeneral, 'Port', self._MainModel.SerialPort)

        configParser.add_section(self._SectionSpeedControl)
        speedControlParams = self._MainModel.SpeedControlParams
        configParser.set(self._SectionSpeedControl, 'P', speedControlParams['P'])
        configParser.set(self._SectionSpeedControl, 'I', speedControlParams['I'])
        configParser.set(self._SectionSpeedControl, 'D', speedControlParams['D'])

        configParser.add_section(self._SectionCoeffs)
        coefficients = self._MainModel.Coefficients
        configParser.set(self._SectionCoeffs, 'K1', coefficients['K1'])
        configParser.set(self._SectionCoeffs, 'K2', coefficients['K2'])
        configParser.set(self._SectionCoeffs, 'K3', coefficients['K3'])
        configParser.set(self._SectionCoeffs, 'K4', coefficients['K4'])

        with open(self._ConfigFilePath,'w') as configFile:
            configParser.write(configFile)

    def GetFloat(self, configParser, section, option, defaultValue=0.0):
        try:
            return configParser.getfloat(section, option)
        except ConfigParser.NoSectionError:
            return defaultValue
        except ConfigParser.NoOptionError:
            return defaultValue
        except ValueError:
            return defaultValue 
  
    def GetInt(self, configParser, section, option, defaultValue=0):
        try:
            return configParser.getint(section, option)
        except ConfigParser.NoSectionError:
            return defaultValue
        except ConfigParser.NoOptionError:
            return defaultValue
        except ValueError:
            return defaultValue 
    
