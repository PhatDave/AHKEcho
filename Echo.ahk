#NoEnv
#Warn
SendMode Input
SetWorkingDir %A_ScriptDir%
#SingleInstance force
#Persistent

ih := InputHook("B")
ih.KeyOpt("{All}", "NV")
ih.OnKeyDown := Func("OnKeyDown")
ih.OnKeyUp := Func("OnKeyUp")
ih.Start()

global enabledWindows := Array()
enabledWindows.Push(Array())
enabledWindows.Push(Array())

global keyLog := {}
global whitelistKeys := {}

OnKeyDown(InputHook, VK, SC) {
	key := GetKeyName(Format("vk{:x}sc{:x}", VK, SC))
    if (whitelistKeys.HasKey(key)) {
        for k, v in enabledWindows[1] {
            ControlSend,, {%key% down}, ahk_pid %v%
        }
    }
    if (!keyLog.HasKey(key)) {
        keyLog[key] := SC,
    }
    ; ControlSend,, v, ahk_pid 16736
    ; Tooltip, %key%
}

OnKeyUp(InputHook, VK, SC) {
	key := GetKeyName(Format("vk{:x}sc{:x}", VK, SC))
    if (whitelistKeys.HasKey(key)) {
        for k, v in enabledWindows[1] {
            ControlSend,, {%key% up}, ahk_pid %v%
        }
    }
}

WinGetAll() {
    PIDs := Array()
    winTitles := Array()
    output := Array()
    WinGet, all, list
    Loop, %all%
    {
        WinGet, PID, PID, % "ahk_id " all%A_Index%
        WinGetTitle, WTitle, % "ahk_id " all%A_Index%
        if (WTitle != "") {
            PIDs.Push(PID)
            winTitles.Push(WTitle)
        }
    }
    output.Push(PIDs)
    output.Push(winTitles)
    return output
}

AllWindowsToString() {
    allWindows := WinGetAll()
    output := ""
    for k, v in allWindows[1] {
        output .= allWindows[1][k]
        output .= ", "
        output .= allWindows[2][k]
        output .= "|"
    }
    StringTrimRight, output, output, 1
    return output
}

HasVal(arr, val) {
    for k, v in arr {
        if (v == val) {
            return k
        }
    }
    return 0
}

EnableWindows(istring) {
    while (enabledWindows.Length() > 0) {
        enabledWindows.Pop()
    }
    enabledWindows.Push(Array())
    enabledWindows.Push(Array())
    if (InStr(istring, "|") == 0) {
        ostring := StrSplit(istring, ", ")
        if (!HasVal(enabledWindows[1], (ostring[1]))) {
            enabledWindows[1].Push(ostring[1])
            enabledWindows[2].Push(ostring[2])
        }
    } else {
        ostring := StrSplit(istring, "|")
        for k, v in ostring {
            ostring2 := StrSplit(v, ", ")
            if (!HasVal(enabledWindows[1], (ostring2[1]))) {
                enabledWindows[1].Push(ostring2[1])
                enabledWindows[2].Push(ostring2[2])
            }
        }
    }
    ; TODO: Remove all non selected windows
}

GuiSelectActiveWindows(allWindows) {
    output := Array()
    for k, v in allWindows[1] {
        if (HasVal(enabledWindows[1], "" v)) {
            ; GuiControl, Choose, WindowListGUI, k
            output.Push(k)
        }
    }
    return output
}

MakeUI() {
    Gui, Destroy
    string := AllWindowsToString()
    Gui, Add, ListBox, Multi w500 vWindowListGUI r10, %string%
    Gui, Add, Button, Default, OK
    Gui, Show
    for k, v in GuiSelectActiveWindows(WinGetAll()) {
        ; See what's wrong with choose, maybe it doesn't like to be called many times though just that is being done on forum guy
        GuiControl, Choose, WindowListGUI, v
    }
}

KeyLogToString() {
    output := ""
    for k, v in keyLog {
        output .= k
        output .= " "
        output .= v
        output .= "|"
    }
    StringTrimRight, output, output, 1
    return output
}

WhitelistButtonUI() {
    Gui, Destroy
    string := KeyLogToString()
    Gui, Add, ListBox, Multi w500 vKeyLogUI r10, %string%
    Gui, Add, Button, Default, Save
    Gui, Show
    for k, v in GuiSelectActiveWindows(WinGetAll()) {
        ; See what's wrong with choose, maybe it doesn't like to be called many times though just that is being done on forum guy
        GuiControl, Choose, WindowListGUI, v
    }
}

WhitelistKeys(string) {
    for k, v in StrSplit(string, "|") {
        whitelistKeys[v] := true
    }
}

F3::
    MakeUI()
return

F4::
    WhitelistButtonUI()
return

ButtonSave:
    Gui, Submit
    WhitelistKeys(KeyLogUI)
return

ButtonOK:
    Gui, Submit
    EnableWindows(WindowListGUI)
return

F5::reload