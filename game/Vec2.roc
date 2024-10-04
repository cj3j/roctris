module [
    Vec2,
    vec2,
    zero,
    one,
    add,
    subtract,
    multiply,
    divide,
    min,
    max,
    midpoint,
    boundsMin,
    boundsMax,
    boundsCenter,
    toStr,
]

import Util

Vec2 : {
    x : I32,
    y : I32,
}

vec2 : Int a, Int b -> Vec2
vec2 = \x, y ->
    { x: Num.toI32 x, y: Num.toI32 y }

zero : Vec2
zero = vec2 0 0

one : Vec2
one = vec2 1 1

Vec2n a : { x : Num a, y : Num a }
Vec2i a : { x : Int a, y : Int a }

add : Vec2n a, Vec2n a -> Vec2n a
add = \a, b ->
    { x: a.x + b.x, y: a.y + b.y }

expect ((add (vec2 0 0) (vec2 0 0)) == (vec2 0 0))
expect ((add (vec2 0 0) (vec2 1 1)) == (vec2 1 1))
expect ((add (vec2 1 1) (vec2 1 1)) == (vec2 2 2))
expect ((add (vec2 1 0) (vec2 0 1)) == (vec2 1 1))
expect ((add (vec2 0 1) (vec2 1 0)) == (vec2 1 1))
expect ((add (vec2 -2 3) (vec2 -2 3)) == (vec2 -4 6))
expect ((add (vec2 -2 3) (vec2 2 -3)) == (vec2 0 0))

subtract : Vec2n a, Vec2n a -> Vec2n a
subtract = \a, b ->
    { x: a.x - b.x, y: a.y - b.y }

expect ((subtract (vec2 0 0) (vec2 0 0)) == (vec2 0 0))
expect ((subtract (vec2 0 0) (vec2 1 1)) == (vec2 -1 -1))
expect ((subtract (vec2 1 1) (vec2 1 1)) == (vec2 0 0))
expect ((subtract (vec2 1 0) (vec2 0 1)) == (vec2 1 -1))
expect ((subtract (vec2 0 1) (vec2 1 0)) == (vec2 -1 1))
expect ((subtract (vec2 -2 3) (vec2 -2 3)) == (vec2 0 0))
expect ((subtract (vec2 -2 3) (vec2 2 -3)) == (vec2 -4 6))

multiply : Vec2n a, Vec2n a -> Vec2n a
multiply = \a, b ->
    { x: a.x * b.x, y: a.y * b.y }

expect ((multiply (vec2 0 0) (vec2 0 0)) == (vec2 0 0))
expect ((multiply (vec2 0 0) (vec2 1 1)) == (vec2 0 0))
expect ((multiply (vec2 1 1) (vec2 1 1)) == (vec2 1 1))
expect ((multiply (vec2 1 0) (vec2 0 1)) == (vec2 0 0))
expect ((multiply (vec2 0 1) (vec2 1 0)) == (vec2 0 0))
expect ((multiply (vec2 -2 3) (vec2 -2 3)) == (vec2 4 9))
expect ((multiply (vec2 -2 3) (vec2 2 -3)) == (vec2 -4 -9))

divide : Vec2i a, Vec2i a -> Vec2i a
divide = \a, b ->
    { x: Num.divTruncChecked a.x b.x |> Result.withDefault 0, y: Num.divTruncChecked a.y b.y |> Result.withDefault 0 }

expect ((divide (vec2 0 0) (vec2 0 0)) == (vec2 0 0))
expect ((divide (vec2 0 0) (vec2 1 1)) == (vec2 0 0))
expect ((divide (vec2 1 1) (vec2 1 1)) == (vec2 1 1))
expect ((divide (vec2 1 0) (vec2 0 1)) == (vec2 0 0))
expect ((divide (vec2 0 1) (vec2 1 0)) == (vec2 0 0))
expect ((divide (vec2 2 4) (vec2 2 2)) == (vec2 1 2))
expect ((divide (vec2 -2 -4) (vec2 2 2)) == (vec2 -1 -2))
expect ((divide (vec2 -2 -4) (vec2 -2 -2)) == (vec2 1 2))

min : Vec2n a, Vec2n a -> Vec2n a
min = \a, b ->
    x = Util.min a.x b.x
    y = Util.min a.y b.y
    { x, y }

expect ((min (vec2 0 0) (vec2 0 0)) == (vec2 0 0))
expect ((min (vec2 0 0) (vec2 1 1)) == (vec2 0 0))
expect ((min (vec2 1 1) (vec2 0 0)) == (vec2 0 0))
expect ((min (vec2 1 0) (vec2 0 1)) == (vec2 0 0))
expect ((min (vec2 0 1) (vec2 1 0)) == (vec2 0 0))

max : Vec2n a, Vec2n a -> Vec2n a
max = \a, b ->
    x = Util.max a.x b.x
    y = Util.max a.y b.y
    { x, y }

expect ((max (vec2 0 0) (vec2 0 0)) == (vec2 0 0))
expect ((max (vec2 0 0) (vec2 1 1)) == (vec2 1 1))
expect ((max (vec2 1 1) (vec2 0 0)) == (vec2 1 1))
expect ((max (vec2 1 0) (vec2 0 1)) == (vec2 1 1))
expect ((max (vec2 0 1) (vec2 1 0)) == (vec2 1 1))

# TODO crashes compiler
# midpoint : Vec2i a, Vec2i a -> Vec2i a
midpoint : Vec2, Vec2 -> Vec2
midpoint = \a, b -> subtract b a |> divide (vec2 2 2) |> add a

expect ((midpoint (vec2 0 0) (vec2 0 0)) == (vec2 0 0))
expect ((midpoint (vec2 0 0) (vec2 1 1)) == (vec2 0 0))
expect ((midpoint (vec2 0 0) (vec2 2 2)) == (vec2 1 1))
expect ((midpoint (vec2 0 0) (vec2 -2 -2)) == (vec2 -1 -1))
expect ((midpoint (vec2 0 0) (vec2 3 3)) == (vec2 1 1))
expect ((midpoint (vec2 0 0) (vec2 -3 -3)) == (vec2 -1 -1))

# TODO wanted to return Result but compiler was crashing
boundsMin : List Vec2 -> Vec2
boundsMin = \list ->
    m = List.first list |> Result.withDefault (vec2 0 0)
    List.walk list m min

expect ((boundsMin [vec2 0 0, vec2 0 0]) == (vec2 0 0))
expect ((boundsMin [vec2 0 0, vec2 1 1]) == (vec2 0 0))
expect ((boundsMin [vec2 -1 -1, vec2 0 0]) == (vec2 -1 -1))
expect ((boundsMin [vec2 1 1, vec2 -1 2]) == (vec2 -1 1))
expect ((boundsMin [vec2 1 -1, vec2 0 1]) == (vec2 0 -1))

# TODO wanted to return Result but compiler was crashing
boundsMax : List Vec2 -> Vec2
boundsMax = \list ->
    m = List.first list |> Result.withDefault (vec2 0 0)
    List.walk list m max

expect ((boundsMax [vec2 0 0, vec2 0 0]) == (vec2 0 0))
expect ((boundsMax [vec2 0 0, vec2 1 1]) == (vec2 1 1))
expect ((boundsMax [vec2 -1 -1, vec2 0 0]) == (vec2 0 0))
expect ((boundsMax [vec2 1 1, vec2 -1 2]) == (vec2 1 2))
expect ((boundsMax [vec2 1 -1, vec2 0 1]) == (vec2 1 1))

# TODO wanted to return Result but compiler was crashing
boundsCenter : List Vec2 -> Vec2
boundsCenter = \list -> midpoint (boundsMin list) (boundsMax list)

expect ((boundsCenter [vec2 0 0, vec2 0 0]) == (vec2 0 0))
expect ((boundsCenter [vec2 0 0, vec2 1 1]) == (vec2 0 0))
expect ((boundsCenter [vec2 0 0, vec2 2 2]) == (vec2 1 1))
expect ((boundsCenter [vec2 -1 -1, vec2 1 1]) == (vec2 0 0))
expect ((boundsCenter [vec2 0 0, vec2 4 0]) == (vec2 2 0))
expect ((boundsCenter [vec2 0 0, vec2 0 4]) == (vec2 0 2))

toStr : Vec2 -> Str
toStr = \v ->
    x = Num.toStr v.x
    y = Num.toStr v.y
    "{x:$(x), y:$(y)}"
