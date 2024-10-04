module [
    Message,
    run,
]

import Keys
import pf.Terminal
import pf.Thread
import TerminalRender
import View exposing [View]

Message : [Key Str, Tick F64]

Update m : m, Message -> m

Draw m : m -> View

State m : {
    model : m,
    view : View,
    update : Update m,
    draw : Draw m,
}

run : m, Update m, Draw m -> Task {} {}
run = \model, update, draw ->
    Terminal.clear! {}
    Terminal.setRawMode! Bool.true
    Terminal.setCursorVisible! Bool.false

    view = draw model

    _ = TerminalRender.render! view

    state : State m
    state = { model, view, update, draw }

    Task.loop! state loop

    Terminal.resetBackcolor! {}
    Terminal.resetForecolor! {}
    Terminal.clear! {}
    Terminal.setRawMode! Bool.false
    Terminal.setCursorVisible! Bool.true

    Task.ok {}

updateInput = \model, state, key ->
    # if key != "" then
    state.update model (Key key)
# else
#    model

tick = \model, state, deltaSeconds -> state.update model (Tick deltaSeconds)

loop : State m -> Task.Task [Step (State m), Done {}] {}
loop = \state ->
    # TODO tried adding a fixedDeltaSeconds as input to Run and into State, but compiler kept crashing
    fixedDeltaSeconds : F64
    fixedDeltaSeconds = (1.0 / 30.0)

    # TODO read more than one key
    key = Terminal.getNextKey! {}

    model =
        state.model
        |> updateInput state key
        |> tick state fixedDeltaSeconds

    view = state.draw model

    _ = TerminalRender.renderDelta! state.view view

    # TODO sleep proper amount of time, accounting for how long it took
    # to render the frame.

    _ = Thread.sleepSeconds! fixedDeltaSeconds

    if (key == Keys.q) || (key == Keys.exit) then
        Done {} |> Task.ok
    else
        Step { state & model, view } |> Task.ok
