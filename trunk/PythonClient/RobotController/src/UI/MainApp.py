'''
Created on May 15, 2010

@author: Dr. Rainer Hessmer
'''

from Model.MainModel import MainModel
import wx
from MainWindow import MainWindow


app = wx.App(False)

mainModel = MainModel()
frame = MainWindow(None, mainModel)
frame.Show()

app.MainLoop()
app.AppName = 'Balancing Robot'

mainModel.Close()