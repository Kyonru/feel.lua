---
icon: lucide/life-buoy
---

# Troubleshooting

Common questions and gotchas, grounded in how the runner actually behaves.

## Nothing animates

`feel.lua` only advances when you drive it. Make sure you call `feel.update(dt)` once per
frame, and — if you use an adapter — its `update` too:

```lua
function love.update(dt)
  feel.update(dt)
  fx:update(dt) -- e.g. feel.love / feel.g3d / feel.menori
end
```

## Values change but nothing shows on screen

`feel.lua` never draws. It animates numbers in `target.values`; your draw code reads them
and decides what they mean:

```lua
local v = button.values
love.graphics.scale(v.scale)
```

## A custom field like `glow` isn't tweened

Animated fields must be **numeric** and live inside `values`. Non-numeric fields and fields
outside `values` are ignored by tweens:

```lua
local ship = feel.target({ kind = "player", values = { scale = 1, glow = 0 } })
```

## The second play stacks instead of restarting

Without `restart`, repeated plays stack on purpose. To replace the previous run, pass
`restart = true` and a key:

```lua
feel.play("button.press", button, { restart = true, key = "button.press" })
```

## `restart` does nothing for an inline sequence

A named sequence can omit `key` (it falls back to the name), but an **inline** sequence has
no stable name, so give it an explicit `key`. Otherwise each call is treated as a different
slot and nothing is restarted:

```lua
feel.play({ { kind = "animate", to = { scale = 1.2 } } }, button, {
  restart = true,
  key = "button.bounce",
})
```

## How do I cancel or pause just one run?

`feel.play` returns a control handle. Use it instead of `feel.clear(target)` (which stops
**every** run on a target):

```lua
local run = feel.play("ship.charge", ship, { restart = true, key = "charge" })
run:pause()
run:resume()
run:stop()
if run:isPlaying() then end
```

There are also global controls: `feel.pauseAll()` / `feel.resumeAll()` and
`feel.setTimeScale(0.5)` to slow every run at once.

## My `emit` handler never fires

The handler key must be `emit` (or `audio` / `log`) on the opts table, and the step kind
must match. If you use an adapter, pass `fx:handlers({ ... })` rather than a bare opts
table, or the adapter's routing is skipped:

```lua
feel.play("hit", target, fx:handlers({
  emit = function(event) end,
}))
```

## `log` steps print to stdout unexpectedly

With no `log` handler, `log` steps fall back to `print`. Provide a handler to capture them:

```lua
feel.play(seq, target, { log = function(message, ctx) end })
```

## How do I check what's running?

Use `feel.isPlaying(target, key)` and iterate `feel.active()` for restart-slot and
long-wait debugging:

```lua
for _, run in ipairs(feel.active()) do
  print(run.source, run.key, run.index, run.count, run.remaining)
end
```

## Validate recipes before they play

`feel.validate(sequence)` returns `ok, err` and catches unknown kinds, non-numeric animate
fields, malformed `parallel.steps`, empty `random.options`, missing audio cues, and unknown
named sequences:

```lua
local ok, err = feel.validate("button.press")
if not ok then print(err) end
```

## `feel.clear()` wiped my recipes

`feel.clear()` with no argument resets named-sequence definitions **and** active work (and
global pause / time scale). To stop one target without dropping definitions, pass it:

```lua
feel.clear(ship) -- stops this target's runs; keeps feel.define() recipes
```

## Lua 5.1 / LuaJIT / LOVE notes

The library targets Lua 5.1 (`.luarc.json`) and runs under stock `lua`, `luajit`, or LOVE.
The core has no LOVE dependency — see the [Core Example](core-example.md), which runs with
`lua examples/core/main.lua`.

## Related Pages

- [Core Runner](core-runner.md) for playback, restart, channels, and run control.
- [API](api.md) for full signatures.
