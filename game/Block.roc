module [
    Block,
    empty,
    min,
    max,
    size,
    center,
    translate,
    rotateClockwise,
    rotateCounterClockwise,
    intersects,
    intersectsList,
]

import Color exposing [Color]
import Vec2 exposing [Vec2, vec2]

Block : {
    color : Color,
    points : List Vec2,
}

empty : Block
empty = { color: Color.white, points: [] }

min : Block -> Vec2
min = \block -> Vec2.boundsMin block.points

max : Block -> Vec2
max = \block -> Vec2.boundsMax block.points

size : Block -> Vec2
size = \block -> Vec2.subtract (max block) (min block) |> Vec2.add (vec2 1 1)

center : Block -> Vec2
center = \block -> Vec2.boundsCenter block.points

translate : Block, Vec2 -> Block
translate = \block, translation ->
    points = List.map block.points (\p -> Vec2.add p translation)
    { block & points }

rotate : Block, I32, I32 -> Block
rotate = \block, xScale, yScale ->
    rotateLocal = \p ->
        x = p.y * xScale
        y = p.x * yScale
        { p & x, y }

    rotatedPoints = List.map block.points rotateLocal
    oldCenter = Vec2.boundsCenter block.points
    newCenter = Vec2.boundsCenter rotatedPoints
    error = Vec2.subtract oldCenter newCenter
    points = List.map rotatedPoints (\p -> Vec2.add p error)
    { block & points }

rotateClockwise : Block -> Block
rotateClockwise = \block -> rotate block -1 1

rotateCounterClockwise : Block -> Block
rotateCounterClockwise = \block -> rotate block 1 -1

intersects : Block, Block -> Bool
intersects = \a, b ->
    List.walkUntil
        a.points
        Bool.false
        (\_, p ->
            if List.contains b.points p then
                Break Bool.true
            else
                Continue Bool.false)

intersectsList : Block, List Block -> Bool
intersectsList = \block, blocks ->
    List.walkUntil
        blocks
        Bool.false
        (\_, otherBlock ->
            if intersects block otherBlock then
                Break Bool.true
            else
                Continue Bool.false)
