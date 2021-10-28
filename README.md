# Echoes keyboard events to selectable windows

Mainly used (and made) for World of Warcraft but it might have it's other uses

F3 brings up UI which allows the user to select 1 or more applications to echo **all** keyboard events to

In the current state ALL events are echoed, ~~customizability is planned~~

## 1.1.x

Keys can now be whitelisted and only whitelisted keys will be echoed

The whitelist menu can be accessed by pressing F4 and only keys pressed since the start of the program will be shown, user can then pick as many as they please to whitelist and only those the user picks will be echoed to other windows

## 1.1.2

Keys can now be whitelisted by using hotkeys

Pressing

`Ctrl + Alt + A`

Will add the next hit key to the whitelist

`Ctrl + Alt + R`

Will remove the next hit key from the whitelist

## 1.1.3

Windows can now be added to the echo list using `Ctrl+Alt+S` and `Ctrl+Alt+D` where S adds the **current** window and D removes the **current** window

## 1.1.4

For some reason the keyboard hook sometimes gives up

Added option to re-hook keyboard on `F5`