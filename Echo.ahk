#NoEnv
#Warn
SendMode Input
SetWorkingDir %A_ScriptDir%
#SingleInstance force
#Persistent

SetKeyDelay, -1
SetControlDelay, -1

ih := InputHook("B")
ih.KeyOpt("{All}", "NV")
ih.OnKeyDown := Func("OnKeyDown")
ih.OnKeyUp := Func("OnKeyUp")
ih.Start()

global addNext := 0
global removeNext := 0

global enabledWindows := Array()
enabledWindows.Push(Array())
enabledWindows.Push(Array())

global keyLog := Array()
global whitelistKeys := Array()

global paused := 0

SetTimer, ResetHook, -60000

whitelistKeys["q"] := 1
whitelistKeys["e"] := 1
whitelistKeys[1] := 1
whitelistKeys[2] := 1
whitelistKeys[3] := 1
whitelistKeys[4] := 1
whitelistKeys[5] := 1
whitelistKeys["LShift"] := 1
whitelistKeys["LControl"] := 1
whitelistKeys["g"] := 1
whitelistKeys["v"] := 1
whitelistKeys["r"] := 1
whitelistKeys["f"] := 1
whitelistKeys["c"] := 1
whitelistKeys["y"] := 1

OnKeyDown(InputHook, VK, SC) {
    if (!paused) {
        key := GetKeyName(Format("vk{:x}sc{:x}", VK, SC))
        if (addNext) {
            if (!whitelistKeys.HasKey(Key)) {
                whitelistKeys[key] := 1
                sstring := "Added "
                sstring .= key
                ShowTooltip(sstring)
                addNext := 0
            } else {
                sstring := "Key already exists"
                ShowTooltip(sstring)
                addNext := 0
            }
            return
        }
        if (removeNext) {
            if (whitelistKeys.HasKey(Key)) {
                whitelistKeys.Remove(key)
                sstring := "Removed "
                sstring .= key
                ShowTooltip(sstring)
                removeNext := 0
            } else {
                sstring := "Key not found"
                ShowTooltip(sstring)
                removeNext := 0
            }
            return
        }
        if (whitelistKeys.HasKey(key)) {
            for k, v in enabledWindows[1] {
                ControlSend,, {%key% down}, ahk_pid %v%
            }
        }
        if (!keyLog.HasKey(key)) {
            keyLog[key] := SC,
        }
    }
}

ShowTooltip(text) {
    ToolTip, %text%
    SetTimer, RemoveToolTip, -800
}

RemoveToolTip:
    ToolTip
return

OnKeyUp(InputHook, VK, SC) {
    if (!paused) {
        key := GetKeyName(Format("vk{:x}sc{:x}", VK, SC))
        if (whitelistKeys.HasKey(key)) {
            for k, v in enabledWindows[1] {
                ControlSend,, {%key% up}, ahk_pid %v%
            }
        }
    }
}

; Not really mine at all
SortArray(Array, Order="A") {
    ;Order A: Ascending, D: Descending, R: Reverse
    MaxIndex := ObjMaxIndex(Array)
    If (Order = "R") {
        count := 0
        Loop, % MaxIndex
            ObjInsert(Array, ObjRemove(Array, MaxIndex - count++))
        Return
    }
    Partitions := "|" ObjMinIndex(Array) "," MaxIndex
    Loop {
        comma := InStr(this_partition := SubStr(Partitions, InStr(Partitions, "|", False, 0)+1), ",")
        spos := pivot := SubStr(this_partition, 1, comma-1) , epos := SubStr(this_partition, comma+1)    
        if (Order = "A") {    
            Loop, % epos - spos {
                if (Array[pivot] > Array[A_Index+spos])
                    ObjInsert(Array, pivot++, ObjRemove(Array, A_Index+spos))    
            }
        } else {
            Loop, % epos - spos {
                if (Array[pivot] < Array[A_Index+spos])
                    ObjInsert(Array, pivot++, ObjRemove(Array, A_Index+spos))    
            }
        }
        Partitions := SubStr(Partitions, 1, InStr(Partitions, "|", False, 0)-1)
        if (pivot - spos) > 1    ;if more than one elements
            Partitions .= "|" spos "," pivot-1        ;the left partition
        if (epos - pivot) > 1    ;if more than one elements
            Partitions .= "|" pivot+1 "," epos        ;the right partition
    } Until !Partitions
}

WinGetAll() {
    PIDs := Array()
    winTitles := Array()
    output := Array()
    WinGet, all, list
    Loop, %all%
    {
        WinGet, PID, PID, % "ahk_id " all%A_Index%
        WinGet, name, ProcessName, % "ahk_id " all%A_Index%
        if (name != "") {
            PIDs.Push(PID)
            winTitles.Push(name)
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

Find(arr, val) {
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
        if (!Find(enabledWindows[1], (ostring[1]))) {
            enabledWindows[1].Push(ostring[1])
            enabledWindows[2].Push(ostring[2])
        }
    } else {
        ostring := StrSplit(istring, "|")
        for k, v in ostring {
            ostring2 := StrSplit(v, ", ")
            if (!Find(enabledWindows[1], (ostring2[1]))) {
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
        if (Find(enabledWindows[1], "" v)) {
            ; GuiControl, Choose, WindowListGUI, k
            output.Push(k)
        }
    }
    return output
}

MakeUI() {
    Gui, Destroy
    string := AllWindowsToString()
    Gui, Add, ListBox, Multi h600 w800 vWindowListGUI, %string%
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
        output .= "|"
    }
    StringTrimRight, output, output, 1
    return output
}

WhitelistButtonUI() {
    Gui, Destroy
    SortArray(keyLog)
    string := KeyLogToString()
    Gui, Add, ListBox, Multi h600 w800 vKeyLogUI, %string%
    Gui, Add, Button, Default, Save
    Gui, Show
    for k, v in GuiSelectActiveWindows(WinGetAll()) {
        ; See what's wrong with choose, maybe it doesn't like to be called many times though just that is being done on forum guy
        GuiControl, Choose, WindowListGUI, v
    }
}

WhitelistKeys(string) {
    whitelistKeys := Array()
    for k, v in StrSplit(string, "|") {
        whitelistKeys[v] := 1
    }
}

AddCurrentWindow() {
    WinGet, activePID, PID, A
    if (!Find(enabledWindows[1], activePID)) {
        WinGet, activeName, ProcessName, A
        enabledWindows[1].Insert(activePID)
        enabledWindows[2].Insert(activeName)
        sstring := "Added "
        sstring .= activePID
        sstring .= " ("
        sstring .= activeName
        sstring .= ") to echo list"
        ShowTooltip(sstring)
    }
}

RemoveCurrentWindow() {
    WinGet, activePID, PID, A
    if (Find(enabledWindows[1], activePID)) {
        WinGet, activeName, ProcessName, A
        enabledWindows[1].RemoveAt(Find(enabledWindows[1], activePID))
        enabledWindows[2].RemoveAt(Find(enabledWindows[2], activeName))
        sstring := "Removed "
        sstring .= activePID
        sstring .= " ("
        sstring .= activeName
        sstring .= ") from echo list"
        ShowTooltip(sstring)
    }
}

ResetHook:
    ih.Stop()
    ih := InputHook("B")
    ih.KeyOpt("{All}", "NV")
    ih.OnKeyDown := Func("OnKeyDown")
    ih.OnKeyUp := Func("OnKeyUp")
    ih.Start()
    ; Tooltip, WIN
    SetTimer, ResetHook, -30000
return

TogglePause() {
    if (paused) {
        ShowTooltip("Unpaused")
        paused := 0
        return
    }
    ShowTooltip("Paused")
    paused := 1
    return
}


F5::
    ih.Stop()
    ih := InputHook("B")
    ih.KeyOpt("{All}", "NV")
    ih.OnKeyDown := Func("OnKeyDown")
    ih.OnKeyUp := Func("OnKeyUp")
    ih.Start()
return

F3::
    MakeUI()
return

^!A::
    ShowTooltip("Adding key")
    addNext := 1
return

^!S::
    ShowTooltip("Adding window")
    AddCurrentWindow()
return

^!D::
    ShowTooltip("Removing window")
    RemoveCurrentWindow()
return

^!R::
    ShowTooltip("Removing key")
    removeNext := 1
return

F4::
    WhitelistButtonUI()
return

F6::
    TogglePause()
return

ButtonSave:
    Gui, Submit
    WhitelistKeys(KeyLogUI)
return

ButtonOK:
    Gui, Submit
    EnableWindows(WindowListGUI)
return

; F5::reload