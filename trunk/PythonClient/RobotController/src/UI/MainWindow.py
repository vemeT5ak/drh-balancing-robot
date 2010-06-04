'''
I learned a lot from the sample code that Eli Bendersky (eliben@gmail.com) published
at: http://eli.thegreenplace.net/2008/08/01/matplotlib-with-wxpython-guis/

Created on May 5, 2010

@author: Dr. Rainer Hessmer
'''

import wx
import wx.lib.sized_controls as sc
import os

from datetime import datetime
from TiltPlotPanel import TiltPlotPanel
from SpeedPlotPanel import SpeedPlotPanel
from SpeedControllerSettingsDialog import SpeedControllerSettingsDialog
from CoefficientsDialog import CoefficientsDialog

class MainWindow(sc.SizedFrame):
    _Title = "Robot Controller"

    def __init__(self, parent, mainModel):
        self.dirname=''
        
        #self.datagen = DataGen()
        self._MainModel = mainModel
        self._MaxAgeBuffer = mainModel.MaxAgeBuffer


        # A "-1" in the size parameter instructs wxWidgets to use the default size.
        # In this case, we select 200px width and the default height.
        sc.SizedFrame.__init__(self, parent, title=MainWindow._Title, size=(800,800))
        #self.CreateStatusBar() # A Statusbar in the bottom of the window

        # Always use self.GetContentsPane() - this ensures that your dialog
        # automatically adheres to HIG spacing requirements on all platforms.
        # _Panel here is a sc.SizedPanel with a vertical sizer layout. All children
        # should be added to this _Panel, NOT to self.
        _Panel = self.GetContentsPane()
        
        self._TiltPlotPanel = TiltPlotPanel(_Panel, self._MaxAgeBuffer)
        self._TiltPlotPanel.SetSizerProps(expand=True, proportion=1)

        self._SpeedPlotPanel = SpeedPlotPanel(_Panel, self._MaxAgeBuffer)
        self._SpeedPlotPanel.SetSizerProps(expand=True, proportion=1)

        #self._InitializePlot(_Panel)

#        self._Button1 = wx.Button(_Panel, label='Button 1')      
#        self._Button2 = wx.Button(_Panel, label='Button 2')
#        
#        self._TextControl = wx.TextCtrl(_Panel, style=wx.TE_MULTILINE)
#        self._TextControl.SetSizerProps(expand=True, proportion=1)
#        
#        self._Button1.Bind(wx.EVT_BUTTON, self._Onclick)
#        self._Button2.Bind(wx.EVT_BUTTON, self._Onclick)
#        
#        self._Box = wx.StaticBox(_Panel, -1, "Coefficients")
#        self._Box.SetSizerProps(expand=True, proportion=1)

        self._CreateMenu()
        
        self.Bind(wx.EVT_CLOSE, self._OnClose)

        
        self._RedrawTimer = wx.Timer(self)
        self.Bind(wx.EVT_TIMER, self._OnRedrawTimerFired, self._RedrawTimer)        
        self._RedrawTimer.Start(50)

    def _CreateMenu(self):
        # Setting up the menu.
        _FileMenu= wx.Menu()
        _MenuSave = _FileMenu.Append(wx.ID_SAVE, "&Save plot\tCtrl-S", "Save plot to file")
        #menuOpen = _FileMenu.Append(wx.ID_OPEN, "&Open"," Open a file to edit")
        _MenuEditSpeedController = _FileMenu.Append(wx.ID_ANY, "Speed controller", "Edit speed controller settings")
        _MenuEditBalancerParams = _FileMenu.Append(wx.ID_PROPERTIES, "Balancer params", "Edit balancer parameters")
        _MenuAbout= _FileMenu.Append(wx.ID_ABOUT, "&About"," Information about this program")
        _MenuExit = _FileMenu.Append(wx.ID_EXIT,"E&xit"," Terminate the program")

        # Creating the menubar.
        _MenuBar = wx.MenuBar()
        _MenuBar.Append(_FileMenu,"&File") # Adding the "_FileMenu" to the MenuBar

        # Events.
        #self.Bind(wx.EVT_MENU, self.OnOpen, menuOpen)
        self.Bind(wx.EVT_MENU, self._OnSavePlot, _MenuSave)
        self.Bind(wx.EVT_MENU, self._OnEditSpeedController, _MenuEditSpeedController)
        self.Bind(wx.EVT_MENU, self._OnEditEditBalancerParams, _MenuEditBalancerParams)
        self.Bind(wx.EVT_MENU, self._OnExit, _MenuExit)
        self.Bind(wx.EVT_MENU, self._OnAbout, _MenuAbout)

        self.SetMenuBar(_MenuBar)  # Adding the MenuBar to the Frame content.
   
    def _OnRedrawTimerFired(self, event):
        now = datetime.now()
        self._TiltPlotPanel.Refresh(self._MaxAgeBuffer, now)
        self._SpeedPlotPanel.Refresh(self._MaxAgeBuffer, now)
       
    def _Onclick(self, evt):
        text = 'You clicked on "%s" at %s\n' % (evt.EventObject.GetLabel())
        
        self._TextControl.AppendText(text)

    def _OnAbout(self, e):
        # Create a message dialog box
        dlg = wx.MessageDialog(self, "Controller for the\nBalancing Robot\n\nBy Dr. Rainer Hessmer", "About " + self.Title, wx.OK)
        dlg.ShowModal() # Shows it
        dlg.Destroy() # finally destroy it when finished.

    def _OnEditSpeedController(self, e):
        # Opens the coefficients dialog
        dlg = SpeedControllerSettingsDialog(self, self._MainModel)
        dlg.CenterOnParent()

        # this does not return until the dialog is closed.
        val = dlg.ShowModal()
    
        if val == wx.ID_OK:
            pass
            #self.log.WriteText("You pressed OK\n")
        else:
            #self.log.WriteText("You pressed Cancel\n")
            pass

        dlg.Destroy()

    def _OnEditEditBalancerParams(self, e):
        # Opens the coefficients dialog
        dlg = CoefficientsDialog(self, self._MainModel)
        dlg.CenterOnParent()

        # this does not return until the dialog is closed.
        val = dlg.ShowModal()
    
        if val == wx.ID_OK:
            pass
            #self.log.WriteText("You pressed OK\n")
        else:
            #self.log.WriteText("You pressed Cancel\n")
            pass

        dlg.Destroy()

    def _OnExit(self, e):
        self.Close(True)  # Close the frame.
        
    def _OnClose(self, e):
        self._RedrawTimer.Stop()
        self.Destroy() # I don't know why this is necessary. Without the app does not close down.

        #self.Close(True)  # Close the frame.

#    def _OnOpen(self, e):
#        """ Open a file"""
#        dlg = wx.FileDialog(self, "Choose a file", self.dirname, "", "*.*", wx.OPEN)
##        if dlg.ShowModal() == wx.ID_OK:
##            self.filename = dlg.GetFilename()
##            self.dirname = dlg.GetDirectory()
##            f = open(os.path.join(self.dirname, self.filename), 'r')
##            self.control.SetValue(f.read())
##            f.close()
#        dlg.Destroy()
    
    def _OnSavePlot(self, event):
        fileChoices = "PNG (*.png)|*.png"
        
        dlg = wx.FileDialog(
            self, 
            message="Save plot as...",
            defaultDir=os.getcwd(),
            defaultFile="plot.png",
            wildcard=fileChoices,
            style=wx.SAVE)
        
        if dlg.ShowModal() == wx.ID_OK:
            path = dlg.GetPath()
            self._FigureCanvas.print_figure(path, dpi=self._DPI)
            #self._FlashStatusMessage("Saved to %s" % path)
    
    def _FlashStatusMessage(self, msg, flash_len_ms=1500):
        self.StatusBar.SetStatusText(msg)
        self._StatusBarFlashTimer = wx.Timer(self)
        self.Bind(
            wx.EVT_TIMER, 
            self._OnFlashStatusOff, 
            self.timeroff)
        self._StatusBarFlashTimer.Start(flash_len_ms, oneShot=True)
    
    def _OnFlashStatusOff(self, event):
        self.StatusBar.SetStatusText('')
