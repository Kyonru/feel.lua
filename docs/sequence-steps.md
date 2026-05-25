# Sequence Steps

Each step is a table with a `kind`. Steps run in order unless a control-flow step changes how child steps are played.

## Animation And Timing

`animate` tweens numeric fields on `target.values`.

```lua
{ kind = "animate", duration = 0.12, to = { x = 12, scale = 1.08 }, ease = "quadout" }
```

Use `from` to set starting values before a tween, `delay` to delay a tween, and `onStart`, `onUpdate`, or `onComplete` hooks for step-local callbacks.

`wait` and `pause` delay the next step until enough `feel.update(dt)` time has passed.

```lua
{ kind = "wait", duration = 0.12 }
```

## Side Effects

`emit` hands a host-owned event to `opts.emit(event, ctx)`.

```lua
{ kind = "emit", event = "burst", payload = { count = 18 } }
```

`audio` hands an audio cue to `opts.audio(event, ctx)`.

```lua
{ kind = "audio", cue = "ui-pop" }
```

`callback` runs arbitrary Lua and then continues.

```lua
{ kind = "callback", callback = function(ctx) combo = combo + 1 end }
```

`log` calls `opts.log(message, ctx)` when provided, otherwise it prints.

## Composition

`play` runs a named or inline child sequence before continuing.

```lua
{ kind = "play", name = "screen.flash" }
```

`parallel` runs child steps or sequences at the same time and continues when all branches finish.

```lua
{
  kind = "parallel",
  steps = {
    { kind = "animate", duration = 0.08, to = { scale = 1.12 } },
    { kind = "emit", event = "camera.shake", payload = { amount = 8 } },
  },
}
```

`repeat` runs a child step or sequence multiple times. `forever = true` loops until `feel.clear()` cancels it.

`random` chooses exactly one weighted child option.

```lua
{
  kind = "random",
  options = {
    { weight = 3, step = { kind = "emit", event = "spark.small" } },
    { weight = 1, step = { kind = "emit", event = "spark.big" } },
  },
}
```
