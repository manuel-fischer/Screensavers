VERSION 4.00
Begin VB.Form frmScreenSaver 
   BackColor       =   &H00000000&
   BorderStyle     =   0  'None
   Caption         =   "ScreenSaver"
   ClientHeight    =   6030
   ClientLeft      =   1095
   ClientTop       =   1515
   ClientWidth     =   6720
   ForeColor       =   &H00FFFFFF&
   Height          =   6435
   Left            =   1035
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   MouseIcon       =   "SCRSV.frx":0000
   MousePointer    =   99  'Custom
   ScaleHeight     =   402
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   448
   ShowInTaskbar   =   0   'False
   Top             =   1170
   Width           =   6840
   WindowState     =   2  'Maximized
   Begin VB.PictureBox picDraw 
      BackColor       =   &H00000000&
      BorderStyle     =   0  'None
      ClipControls    =   0   'False
      Enabled         =   0   'False
      ForeColor       =   &H00FFFFFF&
      Height          =   1815
      Left            =   2160
      ScaleHeight     =   121
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   113
      TabIndex        =   0
      Top             =   2040
      Width           =   1695
   End
   Begin VB.Timer tmrUpdate 
      Interval        =   33
      Left            =   240
      Top             =   1440
   End
End
Attribute VB_Name = "frmScreenSaver"
Attribute VB_Creatable = False
Attribute VB_Exposed = False
Option Explicit

Dim state As ScreenSaverState
Dim initialized As Boolean
Dim needsRedraw As Boolean

Dim prevWindowState As Integer
Dim Config As ScreenSaverConfig


Private Sub CheckInitialized()
    If Not initialized Then
        ScreenSaver_Init state, picDraw
        needsRedraw = True
        initialized = True
    End If
End Sub

Private Sub TickRedraw()
    CheckInitialized
    ScreenSaver_TickRedraw state, picDraw, needsRedraw, Config
End Sub

Private Sub Form_KeyDown(KeyCode As Integer, Shift As Integer)
    Select Case KeyCode
        Case vbKeyEscape
            End
        Case vbKeySpace
            Config.Flags = Config.Flags Xor SCR_PAUSED
        Case vbKeyT
            Config.Flags = Config.Flags Xor SCR_SHOW_TIME
        Case vbKeyF5
            needsRedraw = True
    End Select
End Sub

Private Sub Form_Load()
    Caption = SCREEN_SAVER_NAME
    Config.Flags = SCR_INITIAL_FLAGS
End Sub

Private Sub Form_Resize()
    needsRedraw = True
    With picDraw
        .Left = 0
        .Top = 0
        .Width = ScaleWidth
        .Height = ScaleHeight
    End With
End Sub

Private Sub picDraw_Paint()
    needsRedraw = True
End Sub

Private Sub tmrUpdate_Timer()
    TickRedraw
End Sub
