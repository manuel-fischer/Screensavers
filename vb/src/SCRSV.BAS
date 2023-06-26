Attribute VB_Name = "modScreenSaver"
Option Explicit

Public Const SCR_PAUSED = 1
Public Const SCR_SHOW_TIME = 2

Public Const SCR_INITIAL_FLAGS = SCR_SHOW_TIME

Public Type ScreenSaverConfig
    Flags As Integer
End Type


