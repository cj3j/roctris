app [main] {
    pf: platform "../platform/main.roc",
    random: "https://github.com/JanCVanB/roc-random/releases/download/v0.1.3/YfNiz9trKhsdZ7w_MdzfxW0U01Pw2iSzbrRfcIXhYPM.tar.br",
}

import Block exposing [Block]
import Color
import GameLoop
import Keys
import random.Random
import Timer
import Util
import Vec2 exposing [Vec2, vec2]
import View exposing [View]

###############################################
# Configuration
###############################################

# width and height of the playable area
playSize = vec2 10 20

# min and max of the playable area
playMin = vec2 0 0
playMax = Vec2.subtract playSize (vec2 1 1)

# The terminal font is twice as tall as it is wide.
# To draw a square it needs to be two spaces.
# This converts from play size to render size
playToRenderScale = vec2 2 1

playToRenderPosition = \p -> Vec2.multiply p playToRenderScale

# width and height of the viewport
viewportSize = playSize |> playToRenderPosition |> Vec2.add (vec2 20 1)

# score to give for clearing N rows at once
scoreForRowsCleared = \level, rows ->
    base =
        when rows is
            4 -> 1200
            3 -> 300
            2 -> 100
            _ -> 40
    level * base

# score to give for each row that the player fast-drops
scoreForEachRowTeleported = 1

# how many total rows a player has to have cleared to achieve the given level
rowsRequiredForLevel = \level ->
    rowsRequiredForLevelLoop = \lvl, count ->
        if lvl <= 0 then
            count
        else
            rowsRequiredForLevelLoop (lvl - 1) (count + (lvl * 10))

    rowsRequiredForLevelLoop level 0

# increase the rate of the automove timer as level increases
moveTimerRateForLevel : U64 -> F64
moveTimerRateForLevel = \level ->
    maxRate = 10
    levelForMaxRate = 10
    incPerLevel = maxRate / levelForMaxRate
    Util.min (1 + ((Num.toF64 (level - 1)) * incPerLevel)) maxRate

makeBlock = \color, x0, y0, x1, y1, x2, y2, x3, y3 ->
    points = [
        vec2 x0 y0,
        vec2 x1 y1,
        vec2 x2 y2,
        vec2 x3 y3,
    ]
    { color, points }

blockPool = [
    # Stick
    makeBlock (Color.rgb8 0 245 245) 0 0 1 0 2 0 3 0,
    # Left L
    makeBlock (Color.rgb8 0 0 245) 0 0 0 1 1 1 2 1,
    # Right L
    makeBlock (Color.rgb8 245 100 0) 0 1 1 1 2 1 2 0,
    # Square
    makeBlock (Color.rgb8 245 245 0) 0 0 0 1 1 0 1 1,
    # Left Z
    makeBlock (Color.rgb8 0 245 0) 1 0 2 0 0 1 1 1,
    # Right Z
    makeBlock (Color.rgb8 245 0 0) 0 0 1 0 1 1 2 1,
    # T
    makeBlock (Color.rgb8 245 0 245) 1 0 0 1 1 1 2 1,
]

###############################################
# Util
###############################################

down : Vec2
down = vec2 0 1

left : Vec2
left = vec2 -1 0

right : Vec2
right = vec2 1 0

###############################################
# Model
###############################################

PlayerInput : {
    move : Vec2,
    rotate : I32,
    teleportDown : Bool,
}

emptyPlayerInput = { move: Vec2.zero, rotate: 0, teleportDown: Bool.false }

State : [Intro, Playing, GameOver]

Model : {
    randState : Random.State U32,
    state : State,
    input : PlayerInput,
    teleportDown : Bool,
    moveTimer : Timer.Timer,
    block : Block,
    debris : List Block,
    rowsToDrop : List I32,
    rowsCleared : U64,
    level : U64,
    score : U64,
}

###############################################
# Systems
###############################################

newGame = \randState ->
    state = Intro
    input = emptyPlayerInput
    teleportDown = Bool.false
    moveTimer = Timer.create 1
    block = Block.empty
    debris = []
    rowsToDrop = []
    rowsCleared = 0
    level = 1
    score = 0
    { randState, state, input, teleportDown, moveTimer, block, debris, rowsToDrop, rowsCleared, level, score }

moveInput = \key ->
    # TODO couldn't match on Keys, has to use if+else "pattern is malformed"
    if key == Keys.right then
        right
    else if key == Keys.left then
        left
    else if key == Keys.down then
        down
        else

    Vec2.zero

updatePlayerInput : Model, Str -> Model
updatePlayerInput = \model, key ->
    move = moveInput key

    # TODO had to specify I32 to prevent compiler crash
    rotate : I32
    rotate = if key == Keys.up then 1 else 0

    teleportDown : Bool
    teleportDown = if key == Keys.spacebar then Bool.true else Bool.false

    input = { move, rotate, teleportDown }

    { model & input }

updateCheatLevel : Model, Str -> Model
updateCheatLevel = \model, key ->
    if key == Keys.ctrlUp then
        level = model.level + 1
        { model & level }
    else
        model

updateNewGame : Model, Str -> Model
updateNewGame = \model, key ->
    if key == Keys.r then
        newGame model.randState
    else
        model

updateStartGame : Model, Str -> Model
updateStartGame = \model, key ->
    if key == Keys.spacebar then
        state = Playing
        { model & state }
    else
        model

processInput : Model, Str -> Model
processInput = \model, key ->
    when model.state is
        Intro ->
            model
            |> updateStartGame key

        Playing ->
            model
            |> updateCheatLevel key
            |> updatePlayerInput key

        GameOver ->
            model
            |> updateNewGame key

updateSpawnBlock : Model -> Model
updateSpawnBlock = \model ->
    if model.block == Block.empty then
        lastIdx = (List.len blockPool) - 1 |> Num.toU32

        randRange = Random.u32 0 lastIdx
        randResult = randRange model.randState
        randState = randResult.state
        randNum = randResult.value

        template = List.get blockPool (Num.toU64 randNum) |> Result.withDefault Block.empty
        blockSize = Block.size template
        halfBlockWidth = (blockSize.x + 1) // 2
        halfPlayWidth = playSize.x // 2
        x = playMin.x + halfPlayWidth - halfBlockWidth
        y = playMin.y

        block = Block.translate template { x, y }

        result = { model & block, randState }

        if blockIntersectsDebris block model.debris then
            { result & state: GameOver }
        else
            result
    else
        model

updateTeleportDown : Model -> Model
updateTeleportDown = \model ->
    teleportState =
        if model.input.teleportDown then
            { model & teleportDown: Bool.true }
        else
            model

    if teleportState.teleportDown then
        score = teleportState.score + scoreForEachRowTeleported
        movedState = moveBlock teleportState down
        { movedState & score }
    else
        teleportState

blockIntersectsPlayBounds = \block ->
    min = Block.min block
    max = Block.max block
    min.x < 0 || min.y < 0 || max.x > playMax.x || max.y > playMax.y

blockIntersectsDebris = \block, debris -> Block.intersectsList block debris

blockIntersectsWorld = \block, model ->
    blockIntersectsPlayBounds block
    ||
    blockIntersectsDebris block model.debris

safeRotateBlock = \model, oldBlock, operation ->
    clampBlockToPlayBounds = \block ->
        blockMin = Block.min block
        blockMax = Block.max block
        dxMin = if blockMin.x < playMin.x then playMin.x - blockMin.x else 0
        dxMax = if blockMax.x > playMax.x then playMax.x - blockMax.x else 0
        dyMin = if blockMin.y < playMin.y then playMin.y - blockMin.y else 0
        # no dyMin, we don't want to move blocks up
        x = dxMin + dxMax
        y = dyMin
        Block.translate block { x, y }

    rotated = operation oldBlock
    clamped = clampBlockToPlayBounds rotated
    if blockIntersectsWorld clamped model then
        oldBlock
    else
        clamped

updateRotateBlock : Model -> Model
updateRotateBlock = \model ->
    block =
        when model.input.rotate is
            # TODO can't do +1
            1 -> safeRotateBlock model model.block Block.rotateClockwise
            -1 -> safeRotateBlock model model.block Block.rotateCounterClockwise
            _ -> model.block
    { model & block }

dropRow = \debris, y ->
    dropRowFromBlock = \block ->
        points =
            block.points
            |> List.keepIf (\p -> p.y != y)
            |> List.map (\p -> if p.y < y then Vec2.add p down else p)
        { block & points }

    hasPoints = \block -> (List.len block.points) > 0

    List.map debris dropRowFromBlock
    |> List.keepIf hasPoints

updateRowsToDrop : Model -> Model
updateRowsToDrop = \model ->
    # TODO List.pop could be nice
    row = List.last model.rowsToDrop
    when row is
        Ok r ->
            debris = dropRow model.debris r
            newlen = (List.len model.rowsToDrop) - 1
            rowsToDrop = List.takeFirst model.rowsToDrop newlen
            { model & debris, rowsToDrop }

        _ ->
            model

countPointsInRow = \debris, y ->
    List.walk
        debris
        0
        (\c, b ->
            List.walk
                b.points
                c
                (\c2, p ->
                    if p.y == y then (c2 + 1) else c2))

addBlockToDebris : Model -> Model
addBlockToDebris = \model ->
    debris = List.append model.debris model.block
    miny = (Block.min model.block).y
    maxy = (Block.max model.block).y
    # TODO List.range documentation says "including both of the given numbers" but that's not correct
    rows = List.range { start: At miny, end: At (maxy + 1) }
    rowsToDrop =
        List.keepIf rows (\y -> (countPointsInRow debris y) == playSize.x)
        |> List.reverse
    dropCount = List.len rowsToDrop
    score =
        if dropCount > 0 then
            model.score + (scoreForRowsCleared model.level dropCount)
        else
            model.score
    rowsCleared = model.rowsCleared + dropCount
    level =
        if rowsCleared >= (rowsRequiredForLevel model.level) then
            model.level + 1
        else
            model.level
    teleportDown = Bool.false
    { model & debris, block: Block.empty, teleportDown, rowsToDrop, score, rowsCleared, level }

moveBlock : Model, Vec2 -> Model
moveBlock = \model, move ->
    min = Block.min model.block
    max = Block.max model.block
    clampedMove =
        if min.x <= playMin.x then
            { x: Util.max move.x 0, y: move.y }
        else if max.x >= playMax.x then
            { x: Util.min move.x 0, y: move.y }
            else

        { x: move.x, y: move.y }

    block = Block.translate model.block clampedMove

    if Block.intersectsList block model.debris then
        if move.y > 0 then
            addBlockToDebris model
        else
            model
    else
        newMax = Block.max block
        if newMax.y > playMax.y then
            addBlockToDebris model
        else
            { model & block }

updatePlayerMove : Model -> Model
updatePlayerMove = \model -> moveBlock model model.input.move

updateMoveTimer : Model, F64 -> Model
updateMoveTimer = \model, deltaSeconds ->
    moveTimer =
        if model.input.move.y > 0 then
            Timer.reset model.moveTimer
        else
            Timer.update model.moveTimer (deltaSeconds * (moveTimerRateForLevel model.level))

    newModel = { model & moveTimer }

    if moveTimer.lapsed then
        moveBlock newModel down
    else
        newModel

update : Model, GameLoop.Message -> Model
update = \model, message ->
    when message is
        Key key ->
            processInput model key

        Tick deltaSeconds ->
            when model.state is
                Intro -> model
                Playing ->
                    model
                    |> updateSpawnBlock
                    |> updateRowsToDrop
                    |> updateTeleportDown
                    |> updateRotateBlock
                    |> updatePlayerMove
                    |> updateMoveTimer deltaSeconds

                GameOver ->
                    model

###############################################
# View
###############################################

draw : Model -> View
draw = \model ->
    border = playToRenderScale
    renderPlayMin = playMin |> playToRenderPosition |> Vec2.add border
    renderPlayMax = playMax |> playToRenderPosition |> Vec2.add border
    renderPlaySize = playSize |> playToRenderPosition
    renderPlayCenter = Vec2.midpoint playMin playMax |> playToRenderPosition |> Vec2.add border

    drawBlock = \v, block ->
        # TODO compiler crashes if we try to use renderPlayMin
        points = List.map block.points (\p -> p |> playToRenderPosition |> Vec2.add playToRenderScale)
        View.points v "  " Color.black block.color points

    drawBlocks = \v, blocks -> List.walk blocks v drawBlock

    scoreX = renderPlayMax.x + 4
    scorey = renderPlayMin.y

    drawIntro = \v ->
        v
        |> View.string 2 1 "Roctris!" Color.white Color.black
        |> View.string 2 3 "move sideways: left/right arrows" Color.gray Color.black
        |> View.string 2 4 "       rotate: up arrow" Color.gray Color.black
        |> View.string 2 5 "    drop slow: down arrow" Color.gray Color.black
        |> View.string 2 6 "    drop fast: spacebar" Color.gray Color.black
        |> View.string 2 7 "         quit: q" Color.gray Color.black
        |> View.string 2 9 "press spacebar to start" Color.white Color.black

    drawGameOver = \v, state ->
        when state is
            GameOver ->
                bgwidth = renderPlaySize.x * 2
                bgheight = 5
                bgx = renderPlayMin.x
                bgy = renderPlayCenter.y - 2
                gameoverx = renderPlayMin.x + 5
                gameovery = renderPlayCenter.y - 1
                resumex = 1
                resumey = renderPlayCenter.y + 1

                View.rect v { x: bgx, y: bgy, w: bgwidth, h: bgheight } "  " Color.black Color.black
                |> View.string gameoverx gameovery "GAME OVER" Color.white Color.black
                |> View.string resumex resumey "press r to restart" Color.gray Color.black

            _ -> v

    drawScore = \v, score ->
        scoreStr = Util.intToStr score
        View.string v scoreX scorey "Score: $(scoreStr)" Color.white Color.black

    drawRowsCleared = \v, rows ->
        rowsStr = Util.intToStr rows
        View.string v scoreX (scorey + 2) "Lines: $(rowsStr)" Color.white Color.black

    drawLevel = \v, level ->
        levelStr = Util.intToStr level
        View.string v scoreX (scorey + 4) "Level: $(levelStr)" Color.white Color.black

    view = View.init (Num.toU64 viewportSize.x) (Num.toU64 viewportSize.y) " " Color.black Color.black

    when model.state is
        Intro -> drawIntro view
        _ ->
            view
            |> View.rect { x: renderPlayMin.x, y: renderPlayMin.y, w: renderPlaySize.x, h: renderPlaySize.y } " " Color.black (Color.rgb8 32 32 32)
            |> drawBlock model.block
            |> drawBlocks model.debris
            |> drawGameOver model.state
            |> drawScore model.score
            |> drawRowsCleared model.rowsCleared
            |> drawLevel model.level

###############################################
# Main
###############################################

main : Task {} {}
main = # \seed ->
    # TODO random was never returning from host
    randState = Random.seed32 500
    model = newGame randState
    # GameLoop.run! model update draw
    GameLoop.run model update draw
