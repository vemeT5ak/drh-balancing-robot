'''
Created on May 29, 2010

@author: Dr. Rainer Hessmer
'''

import wx.lib.sized_controls as sc
from matplotlib.figure import Figure
from matplotlib.backends.backend_wxagg import FigureCanvasWxAgg as FigureCanvas
import matplotlib.dates as mpldates 
import pylab

class SpeedPlotPanel(sc.SizedPanel):
    '''
    classdocs
    '''

    def __init__(self, parent, maxAgeBuffer, *args, **kwargs):
        """Create the DemoPanel."""
        sc.SizedPanel.__init__(self, parent, *args, **kwargs)

        #self.parent = parent
        
        self._TimeStamps = []
        self._SpeedValuesMotor1 = []
        self._SpeedValuesMotor2 = []
        
        self._ExtractPlotData(maxAgeBuffer)

        self._InitializePlot()

    def _InitializePlot(self):
        self._DPI = 100
        self._Figure = Figure(dpi=self._DPI)

        self._Plot = self._Figure.add_subplot(111)
        self._Plot.set_axis_bgcolor('black')
        self._Plot.set_title('Speed', size=12)
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
            self._SpeedValuesMotor1,
            linewidth=1,
            color=(1, 0, 0),
            )[0]
        self._Traces.append(trace)

        trace = self._Plot.plot(
            self._TimeStamps,
            self._SpeedValuesMotor2,
            linewidth=1,
            color=(0, 1, 0),
            )[0]
            
        self._Traces.append(trace)
        
        legend = self._Plot.legend(('Motor 1', 'Motor 2'), shadow=False, labelspacing=0.001, loc='upper left')
        for text in legend.get_texts():
            text.set_fontsize('x-small')    # the legend text fontsize


        self._FigureCanvas = FigureCanvas(self, -1, self._Figure)
        self._FigureCanvas.SetSizerProps(expand=True, proportion=1)
        
    def Refresh(self, maxAgeBuffer, now):
        self._ExtractPlotData(maxAgeBuffer)
        self._DrawPlot(maxAgeBuffer, now)
        
    def _ExtractPlotData(self, maxAgeBuffer):

        del self._TimeStamps[:]
        del self._SpeedValuesMotor1[:]
        del self._SpeedValuesMotor2[:]

        try:
            for timeStampedValue in maxAgeBuffer:
                self._TimeStamps.append(timeStampedValue.TimeStamp)
                self._SpeedValuesMotor1.append(timeStampedValue.Value[3])
                self._SpeedValuesMotor2.append(timeStampedValue.Value[4])       
        except RuntimeError:
            # We iterate over a queue that is filled by another thread. The correct approach would
            # be to use synchronization. For simplicity we ignore the error.
            # Every so often we get an error of this form:
            # RuntimeError: deque mutated during iteration    
            pass       

    def _DrawPlot(self, maxAgeBuffer, now):
        """ Redraws the plot
        """
        
        #print 'redrawing'
        #print self._TimeStamps
        #print self._Values1
        
        self._Plot.set_xbound(lower=now - maxAgeBuffer.MaximumAge, upper=now)
        self._Plot.set_ybound(lower=-1.1, upper=1.1)


        self._Traces[0].set_xdata(self._TimeStamps)
        self._Traces[0].set_ydata(self._SpeedValuesMotor1)

        self._Traces[1].set_xdata(self._TimeStamps)
        self._Traces[1].set_ydata(self._SpeedValuesMotor2)

#        self.plot_data.set_xdata(np.arange(len(self.data)))
#        self.plot_data.set_ydata(np.array(self.data))
        
        if len(self._TimeStamps) > 0:
            self._FigureCanvas.draw()
 
