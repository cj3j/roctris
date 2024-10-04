module [
    log,
    min,
    max,
    clamp,
    sign,
    intToStr,
]

log = \logs, items -> List.append logs (Str.joinWith items ", ")

min : Num a, Num a -> Num a
min = \a, b -> if a <= b then a else b

expect min 0 0 == 0
expect min 1 1 == 1
expect min 0 1 == 0
expect min 1 0 == 0
expect min 0 -1 == -1
expect min -1 0 == -1

max : Num a, Num a -> Num a
max = \a, b -> if a >= b then a else b

expect max 0 0 == 0
expect max 1 1 == 1
expect max 0 1 == 1
expect max 1 0 == 1
expect max 0 -1 == 0
expect max -1 0 == 0

clamp : Num a, Num a, Num a -> Num a
clamp = \num, numMin, numMax -> min num numMax |> max numMin

expect ((clamp 0 0 0) == 0)
expect ((clamp 1 0 0) == 0)
expect ((clamp 1 -1 1) == 1)
expect ((clamp 1 -1 2) == 1)
expect ((clamp 5 -1 1) == 1)
expect ((clamp -5 -1 1) == -1)

# sign : Num a -> Num a
sign = \num ->
    if num == 0 then
        0
    else if num > 0 then
        1
    else
        -1

expect ((sign 0) == 0)
expect ((sign -1) == -1)
expect ((sign 1) == 1)
expect ((sign -2) == -1)
expect ((sign 2) == 1)

# TODO Num.toStr crashes for numbers > 9
intToStr : Int a -> Str
intToStr = \num ->
    loop = \s, n ->
        if n < 10 then
            Str.concat s (Num.toStr n)
        else
            base = n // 10
            remainder = n - (base * 10)
            loop s base |> loop remainder
    loop "" num

expect ((intToStr 0) == "0")
expect ((intToStr 1) == "1")
expect ((intToStr 9) == "9")
expect ((intToStr 10) == "10")
expect ((intToStr 11) == "11")
expect ((intToStr -1) == "-1")
expect ((intToStr -9) == "-9")
expect ((intToStr -10) == "-10")
expect ((intToStr -11) == "-11")
