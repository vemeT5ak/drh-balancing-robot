'''
I learned a lot from the sample code that Eli Bendersky (eliben@gmail.com) published
at: http://eli.thegreenplace.net/2008/08/01/matplotlib-with-wxpython-guis/

Created on May 5, 2010

@author: Dr. Rainer Hessmer
'''

import wx
import wx.lib.sized_controls as sc
import matplotlib
matplotlib.use('WXAgg')
from matplotlib.figure import Figure
from matplotlib.backends.backend_wxagg import FigureCanvasWxAgg as FigureCanvas
import matplotlib.dates as mpldates 
import pylab
import os

from datetime import datetime, timedelta
from Support.TimeStampedData import TimeStampedData
from Support.MaxAgeBuffer import MaxAgeBuffer
from CoefficientsDialog import CoefficientsDialog

class MainWindow(sc.SizedFrame):
    _Title = "Robot Controller"

    def __init__(self, parent, mainModel):
        self.dirname=''
        
        #self.datagen = DataGen()
        self._MaxAgeBuffer = mainModel.MaxAgeBuffer

        self._TimeStamps = []
        self._Values1 = []
        self._Values2 = []
        
        self._ExtractPlotData()


        # A "-1" in the size parameter instructs wxWidgets to use the default size.
        # In this case, we select 200px width and the default height.
        sc.SizedFrame.__init__(self, parent, title=MainWindow._Title, size=(800,400))
        #self.CreateStatusBar() # A Statusbar in the bottom of the window

        # Always use self.GetContentsPane() - this ensures that your dialog
        # automatically adheres to HIG spacing requirements on all platforms.
        # _Panel here is a sc.SizedPanel with a vertical sizer layout. All children
        # should be added to this _Panel, NOT to self.
        _Panel = self.GetContentsPane()
        
        self._InitializePlot(_Panel)

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

        
        self._RedrawTimer = wx.Timer(self)
        self.Bind(wx.EVT_TIMER, self._OnRedrawTimerFired, self._RedrawTimer)        
        self._RedrawTimer.Start(50)

    def _InitializePlot(self, panel):
        self._DPI = 100
        self._Figure = Figure(dpi=self._DPI)

        self._Plot = self._Figure.add_subplot(111)
        self._Plot.set_axis_bgcolor('black')
        self._Plot.set_title('Tilt Angle', size=12)
        self._Plot.grid(True, color='gray')
        
        pylab.setp(self._Plot.get_xticklabels(), fontsize=8)
        pylab.setp(self._Plot.get_yticklabels(), fontsize=8)
        
        formatter = mpldates.DateFormatter('%M:%S') 
        self._Plot.xaxis.set_major_formatter(formatter)


        # plot the data as a line series, and save the reference 
        # to the plotted line series
        #
        self._Traces = []
        trace = self._Plot.plot(
            self._TimeStamps,
            self._Values1,
            linewidth=1,
            color=(1, 0, 0),
            )[0]
        self._Traces.append(trace)

        trace = self._Plot.plot(
            self._TimeStamps,
            self._Values2,
            linewidth=1,
            color=(0, 1, 0),
            )[0]
            
        self._Traces.append(trace)
        
        legend = self._Plot.legend(('Acceleration', 'Kalman'), shadow=False, labelspacing=0.001)
        for text in legend.get_texts():
            text.set_fontsize('x-small')    # the legend text fontsize


        self._FigureCanvas = FigureCanvas(panel, -1, self._Figure)
        self._FigureCanvas.SetSizerProps(expand=True, proportion=1)

    def _CreateMenu(self):
        # Setting up the menu.
        _FileMenu= wx.Menu()
        _MenuSave = _FileMenu.Append(wx.ID_SAVE, "&Save plot\tCtrl-S", "Save plot to file")
        #menuOpen = _FileMenu.Append(wx.ID_OPEN, "&Open"," Open a file to edit")
        _MenuEditCoefficients = _FileMenu.Append(wx.ID_PROPERTIES, "Coefficients", "Edit Coefficients")
        _MenuAbout= _FileMenu.Append(wx.ID_ABOUT, "&About"," Information about this program")
        _MenuExit = _FileMenu.Append(wx.ID_EXIT,"E&xit"," Terminate the program")

        # Creating the menubar.
        _MenuBar = wx.MenuBar()
        _MenuBar.Append(_FileMenu,"&File") # Adding the "_FileMenu" to the MenuBar

        # Events.
        #self.Bind(wx.EVT_MENU, self.OnOpen, menuOpen)
        self.Bind(wx.EVT_MENU, self._OnSavePlot, _MenuSave)
        self.Bind(wx.EVT_MENU, self._OnEditCoefficients, _MenuEditCoefficients)
        self.Bind(wx.EVT_MENU, self._OnExit, _MenuExit)
        self.Bind(wx.EVT_MENU, self._OnAbout, _MenuAbout)

        self.SetMenuBar(_MenuBar)  # Adding the MenuBar to the Frame content.
   
    def _OnRedrawTimerFired(self, event):
        self._ExtractPlotData()
        self._DrawPlot()

    def _ExtractPlotData(self):

        del self._TimeStamps[:]
        del self._Values1[:]
        del self._Values2[:]

        for timeStampedValue in self._MaxAgeBuffer:
            self._TimeStamps.append(timeStampedValue.TimeStamp)
            self._Values1.append(timeStampedValue.Value[0])
            self._Values2.append(timeStampedValue.Value[1])       

    def _DrawPlot(self):
        """ Redraws the plot
        """
        
        #print 'redrawing'
        #print self._TimeStamps
        #print self._Values1
        
        now = datetime.now()
        self._Plot.set_xbound(lower=now - self._MaxAgeBuffer.MaximumAge, upper=now)
        self._Plot.set_ybound(lower=-10.0, upper=10.0)


        self._Traces[0].set_xdata(self._TimeStamps)
        self._Traces[0].set_ydata(self._Values1)

        self._Traces[1].set_xdata(self._TimeStamps)
        self._Traces[1].set_ydata(self._Values2)

#        self.plot_data.set_xdata(np.arange(len(self.data)))
#        self.plot_data.set_ydata(np.array(self.data))
        
        if len(self._TimeStamps) > 0:
            self._FigureCanvas.draw()
       
    def _Onclick(self, evt):
        text = 'You clicked on "%s" at %s\n' % (evt.EventObject.GetLabel())
        
        self._TextControl.AppendText(text)

    def _OnAbout(self,e):
        # Create a message dialog box
        dlg = wx.MessageDialog(self, "Controller for the\nBalancing Robot\n\nBy Dr. Rainer Hessmer", "About " + self.Title, wx.OK)
        dlg.ShowModal() # Shows it
        dlg.Destroy() # finally destroy it when finished.

    def _OnEditCoefficients(self,e):
        # Opens the coefficients dialog
        dlg = CoefficientsDialog(self, -1)
        dlg.CenterOnScreen()

        # this does not return until the dialog is closed.
        val = dlg.ShowModal()
    
        if val == wx.ID_OK:
            pass
            #self.log.WriteText("You pressed OK\n")
        else:
            #self.log.WriteText("You pressed Cancel\n")
            pass

        dlg.Destroy()

    def _OnExit(self,e):
        self.Close(True)  # Close the frame.

#    def _OnOpen(self,e):
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
