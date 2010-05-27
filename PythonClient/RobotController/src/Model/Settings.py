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
        coefficients = self._MainModel.Coefficients
        coefficients[0] = self.GetInt(configParser, self._SectionCoeffs, 'K1', coefficients[0])
        coefficients[1] = self.GetInt(configParser, self._SectionCoeffs, 'K1', coefficients[1])
        coefficients[2] = self.GetInt(configParser, self._SectionCoeffs, 'K1', coefficients[2])
        coefficients[3] = self.GetInt(configParser, self._SectionCoeffs, 'K1', coefficients[3])
    
    def Save(self):
        configFile = open(self._ConfigFilePath,'w')

        configParser = ConfigParser.RawConfigParser()

        configParser.add_section(self._SectionGeneral)
        configParser.set(self._SectionGeneral, 'Port', self._MainModel.SerialPort)

        configParser.add_section(self._SectionCoeffs)
        coefficients = self._MainModel.Coefficients
        configParser.set(self._SectionCoeffs, 'K1', coefficients[0])
        configParser.set(self._SectionCoeffs, 'K2', coefficients[1])
        configParser.set(self._SectionCoeffs, 'K3', coefficients[2])
        configParser.set(self._SectionCoeffs, 'K4', coefficients[3])

        configParser.write(configFile)
        configParser.close()

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
    
