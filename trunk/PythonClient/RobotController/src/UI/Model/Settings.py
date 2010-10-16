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
    _SectionBalancerParams = 'BalancerParams'

    def __init__(self, mainModel):
        '''
        Constructor
        '''
        # Get user's app data folder
        # http://snipplr.com/view/7354/home-directory-crossos/
        try:
            from win32com.shell import shellcon, shell
            self._UserLocalDataDir = shell.SHGetFolderPath(0, shellcon.CSIDL_LOCAL_APPDATA, 0, 0)
        except ImportError: # quick semi-nasty fallback for non-windows/win32com case
            self._UserLocalDataDir = os.path.expanduser("~")
        self._ConfigFilePath = os.path.join(self._UserLocalDataDir, self._ConfigFileName)
        self._MainModel = mainModel
        
    def Load(self):
        configParser = ConfigParser.RawConfigParser()
        configParser.read(self._ConfigFilePath)
        
        self._MainModel.SerialPort = self.GetInt(configParser, self._SectionGeneral, 'Port', self._MainModel.SerialPort)
        
        speedControlParams = self._MainModel.SpeedControlParams
        speedControlParams['P'] = self.GetFloat(configParser, self._SectionSpeedControl, 'P', speedControlParams['P'])
        speedControlParams['I'] = self.GetFloat(configParser, self._SectionSpeedControl, 'I', speedControlParams['I'])
        speedControlParams['D'] = self.GetFloat(configParser, self._SectionSpeedControl, 'D', speedControlParams['D'])
        
        balancerParams = self._MainModel.BalancerParams
        balancerParams['K1'] = self.GetFloat(configParser, self._SectionBalancerParams, 'K1', balancerParams['K1'])
        balancerParams['K2'] = self.GetFloat(configParser, self._SectionBalancerParams, 'K2', balancerParams['K2'])
        balancerParams['K3'] = self.GetFloat(configParser, self._SectionBalancerParams, 'K3', balancerParams['K3'])
        balancerParams['K4'] = self.GetFloat(configParser, self._SectionBalancerParams, 'K4', balancerParams['K4'])
        balancerParams['DPhi'] = self.GetFloat(configParser, self._SectionBalancerParams, 'DPhi', balancerParams['DPhi'])
    
    def Save(self):
        configParser = ConfigParser.RawConfigParser()

        configParser.add_section(self._SectionGeneral)
        configParser.set(self._SectionGeneral, 'Port', self._MainModel.SerialPort)

        configParser.add_section(self._SectionSpeedControl)
        speedControlParams = self._MainModel.SpeedControlParams
        configParser.set(self._SectionSpeedControl, 'P', speedControlParams['P'])
        configParser.set(self._SectionSpeedControl, 'I', speedControlParams['I'])
        configParser.set(self._SectionSpeedControl, 'D', speedControlParams['D'])

        configParser.add_section(self._SectionBalancerParams)
        balancerParams = self._MainModel.BalancerParams
        configParser.set(self._SectionBalancerParams, 'K1', balancerParams['K1'])
        configParser.set(self._SectionBalancerParams, 'K2', balancerParams['K2'])
        configParser.set(self._SectionBalancerParams, 'K3', balancerParams['K3'])
        configParser.set(self._SectionBalancerParams, 'K4', balancerParams['K4'])
        configParser.set(self._SectionBalancerParams, 'DPhi', balancerParams['DPhi'])

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
    
