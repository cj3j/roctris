module [
    Color,
    Rgbf,
    Rgb8,
    rgb8,
    toRgb8,
    black,
    blue,
    gray,
    green,
    orange,
    purple,
    red,
    teal,
    white,
    yellow,
]

Rgbf : {
    r : F32,
    g : F32,
    b : F32,
}

Rgb8 : {
    r : U8,
    g : U8,
    b : U8,
}

# TODO would be nice to change color to Rgbf but hard to track down what causes the compiler crash
# Color : Rgbf
Color : Rgb8

rgb8 = \r, g, b -> { r, g, b }

toRgb8 : Color -> Rgb8
toRgb8 = \c -> c

black = rgb8 0 0 0
blue = rgb8 0 0 255
gray = rgb8 128 128 128
green = rgb8 0 255 0
orange = rgb8 255 128 0
purple = rgb8 255 0 255
red = rgb8 255 0 0
teal = rgb8 0 255 255
white = rgb8 255 255 255
yellow = rgb8 255 255 0
