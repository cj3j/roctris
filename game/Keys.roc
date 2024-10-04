module [
    d,
    q,
    r,
    s,
    up,
    down,
    left,
    right,
    ctrlUp,
    spacebar,
    exit,
]

up = "KeyEvent { code: Up, modifiers: NONE }"
down = "KeyEvent { code: Down, modifiers: NONE }"
left = "KeyEvent { code: Left, modifiers: NONE }"
right = "KeyEvent { code: Right, modifiers: NONE }"

ctrlUp = "KeyEvent { code: Up, modifiers: CONTROL }"

d = "KeyEvent { code: Char('d'), modifiers: NONE }"
q = "KeyEvent { code: Char('q'), modifiers: NONE }"
r = "KeyEvent { code: Char('r'), modifiers: NONE }"
s = "KeyEvent { code: Char('s'), modifiers: NONE }"

spacebar = "KeyEvent { code: Char(' '), modifiers: NONE }"

exit = "KeyEvent { code: Char('c'), modifiers: CONTROL }"
