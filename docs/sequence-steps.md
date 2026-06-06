---
icon: lucide/list-tree
---

# Sequence Steps

Each step is a table with a `kind`. Steps run in order unless a control-flow step changes how child steps are played.

## Step Reference

| Kind | Main fields | Purpose |
| --- | --- | --- |
| `animate` | `to`, `from`, `duration`, `ease`, `delay` | Tween numeric fields on `target.values`. |
| `wait`, `pause` | `duration` or `time` | Delay the next step. |
| `emit` | `event`, `name`, `payload` | Send a host-owned event to `opts.emit`. |
| `audio` | `cue`, `audioKind` | Send an audio cue to `opts.audio`. |
| `callback` | `callback` or `fn` | Run Lua code and continue. |
| `log` | `message` or `text` | Log through `opts.log` or `print`. |
| `play` | `name`, `sequence`, `steps`, `step`, `feedback` | Run one child sequence before continuing. |
| `parallel` | `steps` or `sequences` | Run child sequences together, then continue. |
| `repeat` | `count`, `times`, `forever`, plus child sequence fields | Run a child sequence repeatedly. |
| `random` | `options` | Pick one weighted child option. |

## Animation And Timing

`animate` tweens numeric fields on `target.values`, including custom fields:

```lua
{ kind = "animate", duration = 0.12, to = { x = 12, scale = 1.08, teleportGlow = 1 }, ease = "quadout" }
```

Use `from` to set starting values before a tween, `delay` to delay a tween, and `onStart`, `onUpdate`, or `onComplete` hooks for step-local callbacks.

Supported string eases are `linear`, plus `in`, `out`, and `inout` variants for `quad`, `cubic`, `quart`, `quint`, `expo`, `sine`, `circ`, `back`, `elastic`, and `bounce`. For example: `quadout`, `backout`, `bounceout`, or `bounceinout`.

Custom easing functions can be registered on the exposed Flux easing table. An easing receives progress `p` from `0` to `1` and should return the adjusted progress.

```lua
local feel = require("feel")

feel.flux.easing.pop = function(p)
  return math.sin(p * math.pi * 0.5) ^ 0.7
end

feel.define("button.pop", {
  { kind = "animate", duration = 0.18, to = { scale = 1.24 }, ease = "pop" },
  { kind = "animate", duration = 0.16, to = { scale = 1 }, ease = "backout" },
})
```

Keep custom easing functions deterministic and numeric. Flux will raise an error if a sequence references an easing name that is not registered.

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

Use [LOVE Adapter](love-adapter.md) events when emitted events should control registered LOVE sounds, particles, shaders, camera, screen overlays, or post-processing.
