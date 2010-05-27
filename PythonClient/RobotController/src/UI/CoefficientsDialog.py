'''
Created on May 26, 2010

@author: Dr. Rainer Hessmer
'''
import wx
import wx.lib.sized_controls as sc

class CoefficientsDialog(sc.SizedDialog):
    def __init__(self, parent, id):
        sc.SizedDialog.__init__(self, None, -1, "Control Coefficients", style=wx.DEFAULT_DIALOG_STYLE | wx.RESIZE_BORDER)
        
        _Pane = self.GetContentsPane()
        _Pane.SetSizerType("form")
        
        # row 1
        wx.StaticText(_Pane, -1, "K1:")
        _K1TextControl = wx.TextCtrl(_Pane, -1, "N/A")
        _K1TextControl.SetSizerProps(expand=True)
        
        # row 2
        wx.StaticText(_Pane, -1, "K2:")
        _K2TextControl = wx.TextCtrl(_Pane, -1, "N/A")
        _K2TextControl.SetSizerProps(expand=True)
        
        # row 3
        wx.StaticText(_Pane, -1, "K3:")
        _K3TextControl = wx.TextCtrl(_Pane, -1, "N/A")
        _K3TextControl.SetSizerProps(expand=True)
        
        # row 4
        wx.StaticText(_Pane, -1, "K4:")
        _K4TextControl = wx.TextCtrl(_Pane, -1, "N/A")
        _K4TextControl.SetSizerProps(expand=True)
        
        # add dialog buttons
        self.SetButtonSizer(self.CreateStdDialogButtonSizer(wx.OK | wx.CANCEL))
        
        # a little trick to make sure that you can't resize the dialog to
        # less screen space than the controls need
        self.Fit()
        self.SetMinSize(self.GetSize())
