hosted PlatformTasks
    exposes [
        stdoutLine,
        stdoutPut,
        terminalSetRawMode,
        terminalClear,
        terminalSetCursorVisible,
        terminalGoto,
        terminalGetNextKey,
        terminalSetForecolor,
        terminalResetForecolor,
        terminalSetBackcolor,
        terminalResetBackcolor,
        sleepSeconds,
    ]
    imports []

stdoutLine : Str -> Task {} {}
stdoutPut : Str -> Task {} {}

terminalSetRawMode : Bool -> Task {} {}
terminalClear : {} -> Task {} {}
terminalSetCursorVisible : Bool -> Task {} {}
terminalGoto : U16, U16 -> Task {} {}

# TODO would be nice to pass back a proper key struct instead of a string
# KeyType : [Char, Ctrl]
# Key : {text:Str, type:KeyType}
terminalGetNextKey : {} -> Task Str {}
terminalSetForecolor : U8, U8, U8 -> Task {} {}
terminalResetForecolor : {} -> Task {} {}
terminalSetBackcolor : U8, U8, U8 -> Task {} {}
terminalResetBackcolor : {} -> Task {} {}

sleepSeconds : F64 -> Task {} {}
