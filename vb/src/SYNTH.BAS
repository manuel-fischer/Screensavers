Attribute VB_Name = "modLines"
Option Explicit

Public Const SCREEN_SAVER_NAME = "Synthwave"
Public Const GRID_SCALE_Z = 0.3
Public Const GRID_SCALE_Z_I = 1 / GRID_SCALE_Z
Public Const GRID_SCALE_X = 0.3

Private Const SPEED = 0.005

Type ScreenSaverState
    ZOffset As Single
    GridScans() As Integer
    Width As Integer
    Height As Integer
    TimeStr As String * 8
End Type

Public Sub ScreenSaver_Init(ByRef s As ScreenSaverState, _
                            ByRef B As PictureBox)
    'ScreenSaver_Resize s, b
    s.ZOffset = 0
End Sub

Public Sub ScreenSaver_Resize(ByRef s As ScreenSaverState, _
                              ByRef B As PictureBox)
With s
    .Width = B.ScaleWidth
    .Height = B.ScaleHeight
    Dim Y0 As Integer, Y1 As Integer
    Y0 = CInt(.Height / 2)
    Y1 = CInt(.Height)
    ReDim .GridScans(Y0 To Y1)
    B.BackColor = &H0
    
    ScreenSaver_Refresh s, B
End With
End Sub

Private Function SkyColor(ByRef s As ScreenSaverState, _
                          sY As Integer)
With s
    'SkyColor = RGB(255& * sY / LBound(.GridScans), 0, 64& - 64& * sY / LBound(.GridScans))
    SkyColor = RGB(255& * sY / LBound(.GridScans), 0, 167& - 128& * sY / LBound(.GridScans))
    SkyColor = RGB(64& * sY / LBound(.GridScans), 0, 80& - 64& * sY / LBound(.GridScans))
End With
End Function

Private Function GridColor(Luminance As Integer)
    GridColor = RGB(Luminance * 0.5, Luminance, 0)
    'GridColor = RGB(Luminance, Luminance, 32 + 0.75 * Luminance)
    'GridColor = RGB(0.5 * Luminance, 0, 32 + 0.75 * Luminance)
End Function


Private Function GridLuminance(Distance As Single) As Single
    GridLuminance = Exp(-0.15 * Distance)
End Function



Public Sub ScreenSaver_Refresh(ByRef s As ScreenSaverState, _
                               ByRef B As PictureBox)
With s
    Dim sY As Integer
    Dim Color As Long
    Dim CX As Integer, CY As Integer, R As Integer
    CX = .Width / 2: CY = .Height / 2
    R = .Height * 0.1
    
    For sY = 0 To LBound(.GridScans) - 1
        DrawScan B, 0, .Width, sY, SkyColor(s, sY)
    Next sY
    
    For sY = 0 To R
        Color = RGB(255, 127 + sY * 128 / R, 0)
        Dim RR As Integer
        RR = Sqr(R * R - sY * sY)
        DrawScan B, CX - RR, CX + RR, CY - sY, Color
    Next sY

    Dim H As Integer: H = UBound(.GridScans) - LBound(.GridScans) + 1
    For sY = LBound(.GridScans) To UBound(.GridScans)
        Dim G As Integer, Y As Single
        Y = sY / H - 1
        If Y < 0.0001 Then Y = 0.0001
        G = Single2Byte(GridLuminance(1 / Y))
        .GridScans(sY) = G
        Color = GridColor(G)

        DrawScan B, 0, .Width, sY, Color
    Next sY
End With
End Sub

Public Sub ScreenSaver_TickRedraw(ByRef s As ScreenSaverState, _
                                  ByRef B As PictureBox, _
                                  ByRef refresh As Boolean, _
                                  ByRef Config As ScreenSaverConfig)
With s
    If .Width <> B.ScaleWidth Or _
       .Height <> B.ScaleHeight Then
        ScreenSaver_Resize s, B
        refresh = False
    End If

    If refresh Then
        ScreenSaver_Refresh s, B
        refresh = False
    End If

    If Not Config.Flags And SCR_PAUSED Then
        .ZOffset = .ZOffset + SPEED
        If .ZOffset > GRID_SCALE_Z Then
            .ZOffset = .ZOffset - GRID_SCALE_Z
        End If
    End If

    
    #If False Then
    B.DrawMode = vbCopyPen
    B.Line (0, 0)-(.Width / 2, .Height), &HFFFFFF, BF
    #End If
    
    ' Draw text
    DrawTime s, B, Config
    
    ' Update grid
    Dim sY As Integer
    Dim H As Integer: H = UBound(.GridScans) - LBound(.GridScans) + 1
    For sY = LBound(.GridScans) To UBound(.GridScans)
        Dim G As Integer, Y As Single
        Y = sY / H - 1
        If Y < 0.0001 Then Y = 0.0001
        G = Single2Byte(GridScanFunc(s, Y))
        If .GridScans(sY) <> G Then
            .GridScans(sY) = G
            Dim Color As Long
            Color = GridColor(G)
            
            Dim CX As Single
            Dim DX As Single, DX0 As Single, DX1 As Single
            CX = .Width / 2
            DX = .Height * GRID_SCALE_X * Y
            DX0 = DX * 0.05
            DX1 = DX * 0.95
            
            Dim CXOffset As Integer
            'CXOffset = 0
            CXOffset = -0.04 * H / Y
            'CXOffset = -0.09 * H / Y
            'CXOffset = 30 * (1 + Sin(Y * 20))
            CX = CX + CXOffset
            
            If DX < 20 Then
                DrawScan B, 0, .Width, sY, Color
            Else
                Dim X0 As Single
                X0 = -DX / 2
                X0 = 0
                While 2 * X0 < .Width + 2 * Abs(CXOffset)
                    DrawScan B, CX + X0 + DX0, CX + X0 + DX1, sY, Color
                    DrawScan B, CX - X0 - DX1, CX - X0 - DX0, sY, Color
                    X0 = X0 + DX
                Wend
            End If
        End If
    Next sY
End With
End Sub

Private Sub DrawScan(ByRef B As PictureBox, X0 As Integer, X1 As Integer, Y As Integer, Color As Long)
    ' Draw dithered rectangle
    'Dim oldMode As Integer
    'oldMode = B.DrawMode
    B.DrawMode = vbCopyPen
    B.Line (X0, Y)-(X1, Y), 0, BF
    B.DrawMode = vbXorPen
    B.Line (X0 - 1, Y - 1)-(X1 + 1, Y + 1), Color, B
    B.Line (X0 - 1, Y - 1)-(X1 + 1, Y + 1), Color, BF
    'B.DrawMode = oldMode
End Sub

Private Function GridScanFunc(ByRef s As ScreenSaverState, _
                             Y As Single) As Single
With s
    Dim Z As Single, DZ As Single

    DZ = 1 / Y
    Z = DZ + .ZOffset
    Z = Z * GRID_SCALE_Z_I
    
    Dim F As Single
    F = Z - Int(Z)
    
    Dim Lum As Single
    Lum = GridLuminance(DZ)

    Const MippedLum = 0.55
    Const InnerLum = 0.35
    Const MipStartY = 0.23
    Const MipEndY = 0.45
    Const MipScaleY = 1 / (MipEndY - MipStartY)
    
    Dim MipFactor As Single
    MipFactor = Switch( _
        Y < MipStartY, 1, _
        Y < MipEndY, (MipEndY - Y) * MipScaleY, _
        True, 0 _
    )

    Dim MipFactor2 As Single
    MipFactor2 = MipFactor * MipFactor * MipFactor

    Dim Grid As Single
    Grid = IIf(F < 0.2 + MipFactor2 * 0.8, 1 - MipFactor * (1 - MippedLum), InnerLum)
    
    GridScanFunc = Lum * Grid
End With
End Function


Private Function Single2Byte(C As Single) As Integer
    Single2Byte = C * 255
    If Single2Byte < 0 Then Single2Byte = 0
    If Single2Byte > 255 Then Single2Byte = 255
End Function







Private Sub DrawTime(ByRef s As ScreenSaverState, _
                     ByRef B As PictureBox, _
                     ByRef Config As ScreenSaverConfig)
With s
    B.FontName = "Courier New"
    'B.FontName = "Fixedsys"
    'B.FontName = "System"
    'B.FontName = "Terminal"
    B.ForeColor = vbCyan
    B.FontSize = .Height / 12
    B.FontBold = True

    Dim TimeStr As String * 8
    
    If Config.Flags And SCR_SHOW_TIME Then
        Dim CurTime As Date
        CurTime = Time
        Dim iHour As Integer, iMin As Integer, iSec As Integer
        iHour = Hour(CurTime): iMin = Minute(CurTime): iSec = Second(CurTime)
        
        Dim sHour As String, sMin As String, sSec As String
        sHour = IIf(iHour < 10, "0", "") & iHour
        sMin = IIf(iMin < 10, "0", "") & iMin
        sSec = IIf(iSec < 10, "0", "") & iSec
        
        Dim Frac As Single
        Frac = Timer: Frac = Frac - Int(Frac)
        Dim C1 As String, C2 As String
        C1 = IIf(iSec And 1, ":", " ")
        C2 = IIf(Frac > 0.5, ":", " ")
        
        
        TimeStr = sHour & C1 & sMin & C2 & sSec
    Else
        TimeStr = "        "
    End If

    If TimeStr <> .TimeStr Then
        Dim TW As Integer, TH As Integer, TX As Integer, TY As Integer
        TW = B.TextWidth(TimeStr)
        TH = B.TextHeight(TimeStr)
    
        TX = (.Width - B.TextWidth(TimeStr)) / 2
        TY = (.Height / 2 - B.TextHeight(TimeStr)) / 2

        Dim CW As Integer: CW = TW / 8

        Dim CharPos As Integer
        For CharPos = 1 To 8
            Dim OldChar As String * 1, NewChar As String * 1
            OldChar = Mid(.TimeStr, CharPos, 1)
            NewChar = Mid(TimeStr, CharPos, 1)
            If OldChar <> " " And OldChar <> NewChar Then
                Dim sY As Integer
                Dim Y0 As Integer, Y1 As Integer
                
                Y0 = TH * IIf(OldChar = ":", 0.35, 0.17)
                Y1 = TH * 0.75
                
                
                For sY = TY + Y0 To TY + Y1
                    Dim sX As Integer: sX = TX + (CharPos - 1) * CW
                    Dim Color As Long
                    DrawScan B, sX, sX + CW, sY, SkyColor(s, sY)
                Next sY
            End If
        Next CharPos

        If TimeStr <> "        " Then
            B.CurrentX = TX
            B.CurrentY = TY
            B.Print TimeStr
        End If
        
        .TimeStr = TimeStr
    End If
End With
End Sub
