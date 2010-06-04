'''
Created on May 26, 2010

@author: Dr. Rainer Hessmer
'''
import wx
import wx.lib.sized_controls as sc

class CoefficientsDialog(sc.SizedDialog):
    def __init__(self, parent, mainModel):
        sc.SizedDialog.__init__(self, parent, -1, "Control Coefficients", style=wx.DEFAULT_DIALOG_STYLE | wx.RESIZE_BORDER)

        self._MainModel = mainModel
        balancerParams = mainModel.BalancerParams
        print("CoefficientsDialog load:")
        print(balancerParams)

        pane = self.GetContentsPane()
        pane.SetSizerType("form")
        
        # row 1
        wx.StaticText(pane, -1, "K1:")
        self._K1TextControl = wx.TextCtrl(pane, -1, str(balancerParams['K1']))
        self._K1TextControl.SetSizerProps(expand=True)
        
        # row 2
        wx.StaticText(pane, -1, "K2:")
        self._K2TextControl = wx.TextCtrl(pane, -1, str(balancerParams['K2']))
        self._K2TextControl.SetSizerProps(expand=True)
        
        # row 3
        wx.StaticText(pane, -1, "K3:")
        self._K3TextControl = wx.TextCtrl(pane, -1, str(balancerParams['K3']))
        self._K3TextControl.SetSizerProps(expand=True)
        
        # row 4
        wx.StaticText(pane, -1, "K4:")
        self._K4TextControl = wx.TextCtrl(pane, -1, str(balancerParams['K4']))
        self._K4TextControl.SetSizerProps(expand=True)

        wx.StaticText(pane, -1, '')

        self._ApplyButton = wx.Button(pane, -1, 'Apply')
        self._ApplyButton.Bind(wx.EVT_BUTTON, self._OnApply)
        
        # a little trick to make sure that you can't resize the dialog to
        # less screen space than the controls need
        self.Fit()
        self.SetMinSize(self.GetSize())

    def _OnApply(self, e):
        balancerParams = (self._K1TextControl.Value, self._K2TextControl.Value, self._K3TextControl.Value, self._K4TextControl.Value)
        self._MainModel.SetBalancerParams(balancerParams)
