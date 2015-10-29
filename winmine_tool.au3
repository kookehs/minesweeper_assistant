#include <EditConstants.au3>
#include <FileConstants.au3>
#include <FontConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiToolTip.au3>
#include <ListBoxConstants.au3>
#include <Misc.au3>
#include <NomadMemory.au3>
#include <StaticConstants.au3>
#include <StringConstants.au3>
#include <WindowsConstants.au3>
#include <_PixelGetColor.au3>

Global $pid
Global $gameHandle
Global $processName
Global Const $baseAddress = Dec("01000000")
Global Const $stateOffset = Dec("5160")
Global Const $firstTimeOffset = Dec("579D")
Global Const $secondTimeOffset = Dec("579C")
Global Const $discoveredOffset = Dec("57A4")
Global Const $flagOffset = Dec("5194")
Global Const $columnOffset = Dec("5118")
Global Const $rowOffset = Dec("511C")
Global Const $heightOffset = Dec("5338")
Global Const $widthOffset = Dec("5334")
Global Const $mapOffset = Dec("5361")

Global $GUI = GUICreate("Player / Assistant", 385, 330)
Global $attachButton = GUICtrlCreateButton("Attach", 5, 5, 50, 25)
Global $quitButton = GUICtrlCreateButton("Quit", 55, 5, 50, 25)

Global $offButton = GUICtrlCreateRadio("Off", 5, 35, 220)
Global $playerButton = GUICtrlCreateRadio("Player", 5, 55, 220)
Global $adviserButton = GUICtrlCreateRadio("Assistant", 5, 75, 220)

Global $flagBombCheckbox = GUICtrlCreateCheckbox("Bombs", 5, 100, 220)
Global $clickSafeCheckbox = GUICtrlCreateCheckbox("Safe Spots", 5, 120, 220)
Global $intervalDisplay = GUICtrlCreateLabel("Update Interval", 5, 140, 220, 25, $SS_CENTER)
Global $intervalSlider = GUICtrlCreateSlider(5, 160, 220)

Global $timeDisplay = GUICtrlCreateLabel("Time: 0", 5, 200, 220)
Global $flagDisplay = GUICtrlCreateLabel("Flags: 0", 5, 215, 220)
Global $discoveredDisplay = GUICtrlCreateLabel("Discovered: 0", 5, 230, 220)
Global $selectedDisplay = GUICtrlCreateLabel("Selected: 0, 0", 5, 245, 220)
Global $mapDisplay = GUICtrlCreateEdit("", 230, 5, 150, 320, $ES_CENTER + $ES_READONLY + $WS_VSCROLL)
Global $statusList = GUICtrlCreateList("", 5, 269, 220, 65, $LBS_NOSEL)

GUICtrlSetState($offButton, $GUI_CHECKED)
GUICtrlSetState($offButton, $GUI_DISABLE)
GUICtrlSetState($playerButton, $GUI_DISABLE)
GUICtrlSetState($adviserButton, $GUI_DISABLE)

GUICtrlSetState($flagBombCheckbox, $GUI_HIDE)
GUICtrlSetState($clickSafeCheckbox, $GUI_HIDE)
GUICtrlSetState($intervalSlider, $GUI_HIDE)
GUICtrlSetLimit($intervalSlider, 10000, 1)
GUICtrlSetData($intervalSlider, 1)
GUICtrlSetState($intervalDisplay, $GUI_HIDE)

GUICtrlSetFont($mapDisplay, 8.5, $FW_DONTCARE, 0, "Consolas")
GUISetState(@SW_SHOW)

; 0 = off
; 1 = player
; 2 = adviser
Global $mode = 0
Global $initialClicks = 0
Global $timer = TimerInit()

Func quit()
    Exit
EndFunc

Func pause()
    $mode = 0
EndFunc

Func resume()
    $mode = 1
EndFunc

HotKeySet("{NUMPADMULT}", "quit")
HotKeySet("{NUMPADSUB}", "pause")
HotKeySet("{NUMPADADD}", "resume")
SetPrivilege("SeDebugPrivilege", 1)

Func isRunning()
    If ProcessExists($processName) == 0 Then
        GUICtrlSetData($statusList, "|Minesweeper is not running")
        GUICtrlSetState($attachButton, $GUI_ENABLE)
        Return 0
    EndIf

    Return 1
 EndFunc

Func updateDiscovered()
    GUICtrlSetData($discoveredDisplay, "Discovered: " & _MemoryRead("0x" & Hex($baseAddress + $discoveredOffset), $gameHandle, "BYTE"))
EndFunc

Func updateFlag()
    GUICtrlSetData($flagDisplay, "Flags: " & _MemoryRead("0x" & Hex($baseAddress + $flagOffset), $gameHandle, "BYTE"))
EndFunc

Func updateMap($mapData)
    GUICtrlSetData($mapDisplay, $mapData)
EndFunc

Func updateMode()
    If $mode == 0 Then
        GUICtrlSetState($offButton, $GUI_CHECKED)
    ElseIf $mode == 1 Then
        GUICtrlSetState($playerButton, $GUI_CHECKED)
    ElseIf $mode == 2 Then
        GUICtrlSetState($adviserButton, $GUI_CHECKED)
    Else
        ; Error
    EndIf
EndFunc

Func updateSelected()
    Local $x = _MemoryRead("0x" & Hex($baseAddress + $columnOffset), $gameHandle, "BYTE")
    Local $y = _MemoryRead("0x" & Hex($baseAddress + $rowOffset), $gameHandle, "BYTE")
    GUICtrlSetData($selectedDisplay, "Selected: " & $x & ", " & $y)
EndFunc

Func updateTime()
    Local $firstTime = _MemoryRead("0x" & Hex($baseAddress + $firstTimeOffset), $gameHandle, "BYTE")
    Local $secondTime = _MemoryRead("0x" & Hex($baseAddress + $secondTimeOffset), $gameHandle, "BYTE")
    GUICtrlSetData($timeDisplay, "Time: " & $firstTime * 256 + $secondTime)
EndFunc

Func updateInformation()
    updateDiscovered()
    updateFlag()
    updateMode()
    updateSelected()
    updateTime()
EndFunc

Func dataToTile($data)
    Local $tile = $data

    If $data == 0 Then
        $tile = "C" ; Clicked tile
    ElseIf $data == 11 Then
        $tile = "?" ; Flag no bomb but explosion
    ElseIf $data == 13 Then
        $tile = "?" ; Question mark no bomb
    ElseIf $data == 14 Then
        $tile = "F" ; Flag no bomb
    ElseIf $data == 15 Then
        $tile = "W" ; Unclicked tile
    ElseIf $data == 64 Then
        $tile = "E" ; Empty
    ElseIf $data == 65 Then
        $tile = "1"
    ElseIf $data == 66 Then
        $tile = "2"
    ElseIf $data == 67 Then
        $tile = "3"
    ElseIf $data == 68 Then
        $tile = "4"
    ElseIf $data == 69 Then
        $tile = "5"
    ElseIf $data == 70 Then
        $tile = "6"
    ElseIf $data == 71 Then
        $tile = "7"
    ElseIf $data == 72 Then
        $tile = "8"
    ElseIf $data == 128 Then
        $tile = "!"
    ElseIf $data == 138 Then
        $tile = "B" ; Other bomb
    ElseIf $data == 141 Then
        $tile = "?" ; Question mark
    ElseIf $data == 142 Then
        $tile = "F" ; Flag
    ElseIf $data == 143 Then
        $tile = "@" ; Hidden bomb
    ElseIf $data == 204 Then
        $tile = "!" ; Clicked bomb
    EndIf

    Return $tile
EndFunc

Func saveMap($mapHeight, $mapWidth, $selectedX, $selectedY)
    If $selectedX > $mapWidth Then
        $selectedX = $mapWidth - 1
    EndIf

    If $selectedY > $mapHeight Then
        $selectedY = $mapHeight - 1
    EndIf

    Local $file = FileOpen("map.dat", $FO_OVERWRITE)
    FileWrite($file, $selectedX & @CRLF)
    FileWrite($file, $selectedY & @CRLF)
    FileWrite($file, $mapHeight & @CRLF)
    FileWrite($file, $mapWidth & @CRLF)

    Local $mapData
    Local $data
    Local $tile

    For $i = 0 To $mapHeight - 1 Step 1
        Local $rowAddress = $baseAddress + $mapOffset + $i * 32

        For $j = 0 To $mapWidth - 1 Step 1
            $data = _MemoryRead("0x" & Hex($rowAddress + $j), $gameHandle, "BYTE")

            $mapData = $mapData & dataToTile($data)
            If $j <> $mapWidth - 1 Then
                $mapData = $mapData & " "
            EndIf
        Next
        $mapData = $mapData & @CRLF
    Next
    FileWrite($file, $mapData)
    FileClose($file)
EndFunc

; Global $hDll = DllOpen("gdi32.dll")

Func analyze()
    Local $selectedX = _MemoryRead("0x" & Hex($baseAddress + $columnOffset), $gameHandle, "BYTE")
    Local $selectedY = _MemoryRead("0x" & Hex($baseAddress + $rowOffset), $gameHandle, "BYTE")
    Local $mapHeight = _MemoryRead("0x" & Hex($baseAddress + $heightOffset), $gameHandle, "BYTE")
    Local $mapWidth = _MemoryRead("0x" & Hex($baseAddress + $widthOffset), $gameHandle, "BYTE")
    Local $windowPosition = WinGetPos("[TITLE:Minesweeper]")
    Local $windowX = $windowPosition[0]
    Local $windowY = $windowPosition[1]
    Local $x = $windowX + 23
    Local $y = $windowY + 109
    Local $file = FileOpen("map.dat", $FO_OVERWRITE)
    FileWrite($file, $selectedX & @CRLF)
    FileWrite($file, $selectedY & @CRLF)
    FileWrite($file, $mapHeight & @CRLF)
    FileWrite($file, $mapWidth & @CRLF)

    Local $mapData
    Local $tile

    $vDC = _PixelGetColor_CreateDC($hDll)
    $vRegion = _PixelGetColor_CaptureRegion($vDC, 0, 0, @DesktopWidth, @DesktopHeight, $hDll)

    For $j = 0 To $mapHeight - 1 Step 1
        Local $newY = $y + $j * 16

        For $i = 0 To $mapWidth - 1 Step 1
            Local $newX = $x + $i * 16

            $tile = "Z"
            $color = Dec(_PixelGetColor_GetPixel($vDC, $newX, $newY, $hDll))

            If $color == 12632256 Then
                ; Empty or Wall or 7
                $nextColor = Dec(_PixelGetColor_GetPixel($vDC, $newX, $newY - 6, $hDll))

                If $nextColor == 0 Then
                    ; 7
                    $tile = "7"
                Else
                    $nextColor = Dec(_PixelGetColor_GetPixel($vDC, $newX - 12, $newY - 12, $hDll))

                    If $nextColor == 16777215 Then
                        ; Wall
                        $tile = "W"
                    ElseIf $nextColor == 8421504 Then
                        ; Empty
                        $tile = "E"
                    Else
                        ; Error
                        $tile = "Z"
                    EndIf
                EndIF
            ElseIf $color == 255 Then
                ; 1
                $tile = "1"
            ElseIf $color == 32768 Then
                ; 2
                $tile = "2"
            ElseIf $color == 16711680 Then
                ; 3
                $tile = "3"
            ElseIf $color == 128 Then
                ; 4
                $tile = "4"
            ElseIf $color == 8388608 Then
                ; 5
                $tile = "5"
            ElseIf $color == 32896 Then
                ; 6
                $tile = "6"
            ElseIf $color == 8421504 Then
                ; 8
                $tile = "8"
            ElseIf $color == 0 Then
                ; Bomb or Flag
                $nextColor = Dec(_PixelGetColor_GetPixel($vDC, $newX, $newY - 6, $hDll))

                If $nextcolor == 16711680 Then
                    $tile = "F"
                Else
                    $tile = "B"
                EndIf
            EndIf

            $mapData = $mapData & $tile
            If $j <> $mapWidth - 1 Then
                $mapData = $mapData & " "
            EndIf
        Next

        $mapData = $mapData & @CRLF
    Next

    _PixelGetColor_ReleaseRegion($vRegion)
    _PixelGetColor_ReleaseDC($vDC, $hDll)
    FileWrite($file, $mapData)
    FileClose($file)
EndFunc

Func loadMap()
    If isRunning() == 0 Then
        reset()
        Return
    EndIf

    Local $x = 12
    Local $y = 66
    Local $file = FileOpen("commands.txt", $FO_READ)
    Local $lines = 0

    While True
        If isRunning() == 0 Then
            reset()
            Return -1
        EndIf

        Local $line = FileReadLine($file)
        If @error == -1 Then
            Return $lines
        EndIf

        $lines += 1
        Local $elements = StringSplit($line, @TAB)

        For $i = 0 To $elements[0] Step 1
            $elements[$i] = StringStripWS($elements[$i], $STR_STRIPALL)
            $elements[$i] = StringMid($elements[$i], 2, StringLen($elements[$i]) - 2)
        Next

        Local $neighbors = StringMid($elements[3], 1, 1)
        Local $button = StringMid($elements[2], 1, 1)
        Local $xy = StringSplit($elements[1], ",")
        GUICtrlSetData($mapDisplay, GUICtrlRead($mapDisplay) & "(" & $xy[1] & ", " & $xy[2] & ") " & $button & " " & $neighbors & @CRLF)

        Local $newX = $x + $xy[1] * 16
        Local $newY = $y + $xy[2] * 16

        If $button == "L" Then
            ControlClick("[TITLE:Minesweeper]", "", "", "left", 1, $newX, $newY)
        ElseIf $button == "M" Then
            ControlClick("[TITLE:Minesweeper]", "", "", "middle", 1, $newX, $newY)
        ElseIf $button == "R" Then
            ControlClick("[TITLE:Minesweeper]", "", "", "right", 1, $newX, $newY)
        Else
            ; Error
        EndIf

        updateInformation()
    WEnd

    Return 1
EndFunc

Func reset()
    GUICtrlSetData($timeDisplay, "Time: 0")
    GUICtrlSetData($flagDisplay, "Flags: 0")
    GUICtrlSetData($discoveredDisplay, "Discovered: 0")
    GUICtrlSetData($selectedDisplay, "Selected: 0, 0")
    GUICtrlSetData($mapDisplay, "")
    $intialClicks = 0
EndFunc

Func gameState()
    $gameState = _MemoryRead("0x" & Hex($baseAddress + $stateOffset), $gameHandle, "BYTE")
    Return $gameState
EndFunc

Func obviousBomb($mapHeight, $mapWidth, $selectedX, $selectedY)
    Local $result = 0

    saveMap($mapHeight, $mapWidth, $selectedX, $selectedY)
    ; analyze()
    updateInformation()

    ShellExecuteWait("python", "minesweeperAI.py map.dat obviousBomb", "", "open", @SW_HIDE)
    $result = loadMap()

    return $result
EndFunc

Func obviousSafe($mapHeight, $mapWidth, $selectedX, $selectedY)
    saveMap($mapHeight, $mapWidth, $selectedX, $selectedY)
    ; analyze()
    updateInformation()

    ShellExecuteWait("python", "minesweeperAI.py map.dat obviousSafe", "", "open", @SW_HIDE)
    loadMap()
EndFunc

Func obviousBoth($mapHeight, $mapWidth, $selectedX, $selectedY)
    saveMap($mapHeight, $mapWidth, $selectedX, $selectedY)
    ; analyze()
    updateInformation()

    ShellExecuteWait("python", "minesweeperAI.py map.dat obviousBoth", "", "open", @SW_HIDE)
    $result = loadMap()

    return $result
EndFunc

Global $toolTipExists = False

Func main()
    while True
        Local $event = GUIGetMsg()

        If _IsPressed("01") Or _IsPressed("02") Or _IsPressed("04") Then
            ToolTip("")
            $toolTipExists = False
        EndIf

        If $event <> 0 Then
            Switch $event
               Case $attachButton
                    $processName = InputBox("Minesweeper Tool", "Please enter name of process", "winmine.exe", Default, Default, 125)

                    If @error == 1 Then
                        ContinueLoop
                    EndIf

                    If isRunning() == 0 Then
                        reset()
                        ContinueLoop
                    EndIf

                    $pid = ProcessExists($processName)
                    GUICtrlSetData($statusList, "|Process ID: " & $pid)

                    $gameHandle = _MemoryOpen($pid)
                    GUICtrlSetData($statusList, "Memory Handle: True")

                    $newAddress = _MemoryGetBaseAddress($gameHandle, 1)

                    If $newAddress <> 0 Then
                        $baseAddress = $newAddress
                    EndIf

                    GUICtrlSetData($statusList, "Base Address: 0x" & Hex($baseAddress))

                    $mode = 0
                    updateInformation()
                    GUICtrlSetState($attachButton, $GUI_DISABLE)
                    GUICtrlSetState($offButton, $GUI_ENABLE)
                    GUICtrlSetState($playerButton, $GUI_ENABLE)
                    GUICtrlSetState($adviserButton, $GUI_ENABLE)
                Case $offButton
                    $mode = 0
                    updateMode()
                    GUICtrlSetState($flagBombCheckbox, $GUI_HIDE)
                    GUICtrlSetState($clickSafeCheckbox, $GUI_HIDE)
                    GUICtrlSetState($intervalSlider, $GUI_HIDE)
                    GUICtrlSetState($intervalDisplay, $GUI_HIDE)
                Case $playerButton
                    $mode = 1
                    updateMode()
                    GUICtrlSetState($flagBombCheckbox, $GUI_SHOW)
                    GUICtrlSetState($clickSafeCheckbox, $GUI_SHOW)
                    GUICtrlSetState($intervalSlider, $GUI_SHOW)
                    GUICtrlSetState($intervalDisplay, $GUI_SHOW)
                    GUICtrlSetData($intervalSlider, 1)
                Case $adviserButton
                    $mode = 2
                    updateMode()
                    GUICtrlSetState($flagBombCheckbox, $GUI_SHOW)
                    GUICtrlSetState($clickSafeCheckbox, $GUI_SHOW)
                    GUICtrlSetState($intervalSlider, $GUI_SHOW)
                    GUICtrlSetState($intervalDisplay, $GUI_SHOW)
                    GUICtrlSetData($intervalSlider, 5000)
                Case $quitButton
                    Exit
                Case $GUI_EVENT_CLOSE
                    Exit
            EndSwitch
        Else
            Local $updateInterval = GUICtrlRead($intervalSlider)

            If TimerDiff($timer) > $updateInterval + 250 Then
                $timer = TimerInit()

                If isRunning() == 0 Then
                    reset()
                    $mode = 0
                    updateMode()
                    ContinueLoop
                EndIf
            EndIf

            ; If no tiles have been discovered and playing then reset
            If _MemoryRead("0x" & Hex($baseAddress + $discoveredOffset), $gameHandle, "BYTE") == 0 And TimerDiff($timer) > $updateInterval And gameState() == 0 Then
                $timer = TimerInit()
                GUICtrlSetData($mapDisplay, "")
                $initialClicks = 0
            EndIf

            ; Game ended with player losing
            If gameState() == 2 And TimerDiff($timer) > $updateInterval Then
                $timer = TimerInit()
                $initialClicks = 0
            EndIf

            ; Game ended with player winning
            If gameState() == 3 And TimerDiff($timer) > $updateInterval Then
                $timer = TimerInit()
                $initialClicks = 0
            EndIf

            If $mode == 1 And TimerDiff($timer) > $updateInterval Then
                If isRunning() == 0 Then
                    reset()
                    $mode = 0
                    ContinueLoop
                EndIf

                $timer = TimerInit()
                Local $mapHeight = _MemoryRead("0x" & Hex($baseAddress + $heightOffset), $gameHandle, "BYTE")
                Local $mapWidth = _MemoryRead("0x" & Hex($baseAddress + $widthOffset), $gameHandle, "BYTE")
                Local $selectedX = _MemoryRead("0x" & Hex($baseAddress + $columnOffset), $gameHandle, "BYTE")
                Local $selectedY = _MemoryRead("0x" & Hex($baseAddress + $rowOffset), $gameHandle, "BYTE")

                Local $result = 0

                If GUICtrlRead($flagBombCheckbox) == $GUI_CHECKED And GUICtrlRead($clickSafeCheckbox) == $GUI_CHECKED Then
                    $result = obviousBoth($mapHeight, $mapWidth, $selectedX, $selectedY)
                ElseIf GUICtrlRead($flagBombCheckbox) == $GUI_CHECKED Then
                    $result = obviousBomb($mapHeight, $mapWidth, $selectedX, $selectedY)
                ElseIf GUICtrlRead($clickSafeCheckbox) == $GUI_CHECKED Then
                    obviousSafe($mapHeight, $mapWidth, $selectedX, $selectedY)
                EndIf
            ElseIf $mode == 2 And TimerDiff($timer) > $updateInterval Then
                $timer = TimerInit()

                If $toolTipExists == True Then
                    ContinueLoop
                EndIf

                Local $mapHeight = _MemoryRead("0x" & Hex($baseAddress + $heightOffset), $gameHandle, "BYTE")
                Local $mapWidth = _MemoryRead("0x" & Hex($baseAddress + $widthOffset), $gameHandle, "BYTE")
                Local $selectedX = _MemoryRead("0x" & Hex($baseAddress + $columnOffset), $gameHandle, "BYTE")
                Local $selectedY = _MemoryRead("0x" & Hex($baseAddress + $rowOffset), $gameHandle, "BYTE")

                saveMap($mapHeight, $mapWidth, $selectedX, $selectedY)
                updateInformation()

                If GUICtrlRead($flagBombCheckbox) == $GUI_CHECKED And GUICtrlRead($clickSafeCheckbox) == $GUI_CHECKED Then
                    ShellExecuteWait("python", "minesweeperAI.py map.dat obviousBoth", "", "open", @SW_HIDE)
                ElseIf GUICtrlRead($flagBombCheckbox) == $GUI_CHECKED Then
                    ShellExecuteWait("python", "minesweeperAI.py map.dat obviousBomb", "", "open", @SW_HIDE)
                ElseIf GUICtrlRead($clickSafeCheckbox) == $GUI_CHECKED Then
                    ShellExecuteWait("python", "minesweeperAI.py map.dat obviousSafe", "", "open", @SW_HIDE)
                EndIf

                Local $windowPosition = WinGetPos("[TITLE:Minesweeper]")
                Local $windowX = $windowPosition[0]
                Local $windowY = $windowPosition[1]
                Local $x = $windowX + 23
                Local $y = $windowY + 109
                Local $file = FileOpen("commands.txt", $FO_READ)
                Local $line = FileReadLine($file)

                If @error <> -1 Then
                    Local $elements = StringSplit($line, @TAB)

                    For $i = 0 To $elements[0] Step 1
                        $elements[$i] = StringStripWS($elements[$i], $STR_STRIPALL)
                        $elements[$i] = StringMid($elements[$i], 2, StringLen($elements[$i]) - 2)
                    Next

                    Local $neighbors = StringMid($elements[3], 1, 1)

                    If $neighbors == 0 Then
                        ContinueLoop
                    EndIf

                    Local $button = StringMid($elements[2], 1, 1)
                    Local $xy = StringSplit($elements[1], ",")
                    Local $newX = $x + $xy[1] * 16
                    Local $newY = $y + $xy[2] * 16
                    ToolTip("Consider this one with " & $neighbors & " important tile(s)", $newX + 2, $newY + 2, "Hint", 0, 1)
                    $toolTipExists = True
                EndIf
            EndIf
        EndIf
    WEnd
    ; DllClose($hDll)
EndFunc

main()
