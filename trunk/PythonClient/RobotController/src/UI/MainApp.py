'''
Created on May 15, 2010

@author: Dr. Rainer Hessmer
'''

from Model.MainModel import MainModel
import wx
import sys
from MainWindow import MainWindow
#import matplotlib
#matplotlib.use('WXAgg')


app = wx.App(False)

try:
    mainModel = MainModel(serialPort = 6)
    frame = MainWindow(None, mainModel)
    frame.Show()

    app.MainLoop()
    app.AppName = 'Balancing Robot'

    mainModel.Close()
except:
    print "Unexpected error:", sys.exc_info()[0]
