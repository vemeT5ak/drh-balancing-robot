'''
Created on May 26, 2010

@author: Dr. Rainer Hessmer
'''
import wx
import wx.lib.sized_controls as sc

class SpeedControllerSettingsDialog(sc.SizedDialog):
    def __init__(self, parent, mainModel):
        sc.SizedDialog.__init__(self, parent, -1, "Speed Controller", style=wx.DEFAULT_DIALOG_STYLE | wx.RESIZE_BORDER)
        
        self._MainModel = mainModel
        speedControlParams = mainModel.SpeedControlParams
        
        _Pane = self.GetContentsPane()
        _Pane.SetSizerType("form")
        
        # row 1
        wx.StaticText(_Pane, -1, "P:")
        self._PTextControl = wx.TextCtrl(_Pane, -1, str(speedControlParams['P']))
        self._PTextControl.SetSizerProps(expand=True)
        
        # row 2
        wx.StaticText(_Pane, -1, "I:")
        self._ITextControl = wx.TextCtrl(_Pane, -1, str(speedControlParams['I']))
        self._ITextControl.SetSizerProps(expand=True)
        
        # row 3
        wx.StaticText(_Pane, -1, "D:")
        self._DTextControl = wx.TextCtrl(_Pane, -1, str(speedControlParams['D']))
        self._DTextControl.SetSizerProps(expand=True)
        
        # add dialog buttons
        #self.SetButtonSizer(self.CreateStdDialogButtonSizer(wx.OK | wx.CANCEL))
        
        # final row
        # since we want to use a custom button layout, we won't use the 
        # CreateStdDialogBtnSizer here, we'll just create our own panel with
        # a horizontal layout and add the buttons to that.
        buttonPanel = sc.SizedPanel(_Pane, -1)
        buttonPanel.SetSizerType("horizontal")
        buttonPanel.SetSizerProps(expand=True)

        self._ApplyButton = wx.Button(buttonPanel, wx.ID_APPLY | wx.ALIGN_RIGHT)
        self._CancelButton = wx.Button(buttonPanel, wx.ID_CANCEL | wx.ALIGN_RIGHT)

        self._ApplyButton.Bind(wx.EVT_BUTTON, self._OnApply)
        self._CancelButton.Bind(wx.EVT_BUTTON, self._OnCancel)
 
        
        # a little trick to make sure that you can't resize the dialog to
        # less screen space than the controls need
        self.Fit()
        self.SetMinSize(self.GetSize())

    def _OnCancel(self, e):
        self.Close(True)  # Close the frame.

    def _OnApply(self, e):
        pidParams = (self._PTextControl.Value, self._ITextControl.Value, self._DTextControl.Value)
        self._MainModel.SetSpeedControlParams(pidParams)
