module [
    setRawMode,
    clear,
    setCursorVisible,
    goto,
    getNextKey,
    setForecolor,
    resetForecolor,
    setBackcolor,
    resetBackcolor,
    setColors,
]

import PlatformTasks

setRawMode = PlatformTasks.terminalSetRawMode
clear = PlatformTasks.terminalClear
setCursorVisible = PlatformTasks.terminalSetCursorVisible
goto = PlatformTasks.terminalGoto
getNextKey = PlatformTasks.terminalGetNextKey
setForecolor = PlatformTasks.terminalSetForecolor
resetForecolor = PlatformTasks.terminalResetForecolor
setBackcolor = PlatformTasks.terminalSetBackcolor
resetBackcolor = PlatformTasks.terminalResetBackcolor

setColors = \fr, fg, fb, br, bg, bb ->
    setForecolor! fr fg fb
    setBackcolor! br bg bb
