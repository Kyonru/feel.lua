# feel.lua

`feel.lua` is a tiny LOVE2D-first feedback sequencing library for making actions feel good. It wraps a vendored copy of `flux` so you can describe a piece of game feel as one recipe: animation, timing, emitted effects, audio cues, callbacks, random choices, loops, and grouped steps.

It is a feedback recipe runner, not a Unity Feel clone. The core stays small and table-driven; engine-specific work belongs in LOVE helpers, adapters, or user callbacks.

## What it does

- Defines reusable named feedback sequences with `feel.define`.
- Plays named or inline sequences with `feel.play`.
- Animates common transform-style values on lightweight targets.
- Emits host-owned events for particles, shake, flashes, beams, sounds, or anything else.
- Runs sequenced steps in order, waiting for animation, pause, nested, repeated, or parallel steps to complete before continuing.
- Chooses weighted random branches and repeats child recipes.

## Install

Copy `feel.lua` and the `feel/` directory into your project, then require it:

```lua
local feel = require("feel")
```

The root `feel.lua` file is a small loader shim. The implementation lives in `feel/init.lua`, and `feel/vendor/flux.lua` is bundled.

## Docs

Feature guides live in [`docs/`](docs/):

- [Core Runner](docs/core-runner.md)
- [Sequence Steps](docs/sequence-steps.md)
- [LOVE Adapter](docs/love-adapter.md)
- [LOVE Examples](docs/love-examples.md)

## Quick Start

```lua
local feel = require("feel")

local button = feel.target({
  label = "Launch",
  values = { scale = 1, x = 0, y = 0, opacity = 1 },
})

feel.define("button.press", {
  { kind = "audio", cue = "press" },
  {
    kind = "parallel",
    steps = {
      { kind = "emit", event = "burst", payload = { count = 18 } },
      { kind = "animate", duration = 0.06, to = { scale = 0.92, y = 3 }, ease = "quadout" },
    },
  },
  { kind = "wait", duration = 0.03 },
  { kind = "animate", duration = 0.16, to = { scale = 1, y = 0 }, ease = "backout" },
})

feel.play("button.press", button, {
  trigger = "click",
  audio = function(event)
    playSound(event.cue)
  end,
  emit = function(event)
    spawnParticles(event.payload.count)
  end,
})

function love.update(dt)
  feel.update(dt)
end

function love.draw()
  local v = button.values
  love.graphics.push()
  love.graphics.translate(120 + v.x, 80 + v.y)
  love.graphics.scale(v.scale)
  love.graphics.print(button.label, 0, 0)
  love.graphics.pop()
end
```

## Sequence Steps

Each step is a table with a `kind`.

### Animate

```lua
{ kind = "animate", duration = 0.12, to = { x = 12, scale = 1.08 }, ease = "quadout" }
```

Animation steps tween numeric fields on `target.values`. Supported default fields are:

```lua
opacity, x, y, scale, scaleX, scaleY, rotation
```

Useful fields:

- `from`: values to apply before the tween starts.
- `to`: numeric values to tween.
- `duration`: tween duration in seconds. Defaults to `0.16`.
- `delay`: optional tween delay.
- `ease`: any easing name supported by Flux.
- `onStart`, `onUpdate`, `onComplete`: per-step hooks.

### Emit

```lua
{ kind = "emit", event = "shake", payload = { amount = 8 } }
```

Emit steps call `opts.emit(event, ctx)`. `feel.lua` does not create particles, shake the camera, or flash the screen itself; it hands your app an event so your app can do the rendering or side effect.

### Audio

```lua
{ kind = "audio", cue = "ui-pop" }
```

Audio steps call `opts.audio(event, ctx)` with `event.cue`.

### Callback

```lua
{
  kind = "callback",
  callback = function(ctx)
    combo = combo + 1
  end,
}
```

Callback steps run arbitrary Lua code and then continue to the next step.

### Wait / Pause

```lua
{ kind = "wait", duration = 0.12 }
```

Wait and pause steps delay the next step. They advance through `feel.update(dt)`.

### Play

```lua
{ kind = "play", name = "screen.flash" }
```

Play steps run a named or inline child sequence before continuing. Child sequences inherit the current `target`, `trigger`, and `opts` unless the step provides overrides.

```lua
{ kind = "play", sequence = {
  { kind = "emit", event = "camera.shake", payload = { amount = 6 } },
} }
```

### Parallel

```lua
{
  kind = "parallel",
  steps = {
    { kind = "animate", duration = 0.08, to = { scale = 1.12 } },
    { kind = "emit", event = "camera.shake", payload = { amount = 8 } },
    { kind = "wait", duration = 0.12 },
  },
}
```

Parallel steps run child sequences at the same time and continue after every branch finishes.

### Repeat

```lua
{
  kind = "repeat",
  count = 3,
  step = { kind = "emit", event = "spark" },
}
```

Repeat steps run a child step or sequence multiple times. `forever = true` is supported for loops that should run until `feel.clear()` cancels them.

### Random

```lua
{
  kind = "random",
  options = {
    { weight = 3, step = { kind = "emit", event = "spark.small" } },
    { weight = 1, step = { kind = "emit", event = "spark.big" } },
  },
}
```

Random steps choose exactly one weighted child step or sequence.

### Log

```lua
{ kind = "log", message = "played launch feedback" }
```

Log steps call `opts.log(message, ctx)` when provided, otherwise they print the message.

## API

### `feel.target(meta)`

Creates a target table with a `values` table ready for animation.

```lua
local target = feel.target({ values = { scale = 1 } })
```

### `feel.define(name, sequence)`

Stores a named sequence and returns its normalized form.

```lua
feel.define("hit.strong", {
  { kind = "emit", event = "shake", payload = { amount = 10 } },
})
```

### `feel.get(name)`

Returns a previously defined sequence.

### `feel.play(nameOrSequence, target, opts)`

Plays a named sequence or an inline sequence.

```lua
feel.play("hit.strong", target, {
  trigger = "attack",
  emit = function(event, ctx) end,
  audio = function(event, ctx) end,
  markDirty = function(ctx) end,
})
```

`target` is optional for event-only sequences. If an animation step runs without a target, `feel.lua` creates an internal target.

### `feel.update(dt)`

Advances active tweens, waits, and child sequence runners. Call this once per frame.

```lua
feel.update(dt)
```

Returns whether there were active tweens before or after the update.

### `feel.clear(target)`

Clears registered sequences, active tween state, waits, nested sequences, repeats, and parallel branches. When given a target, it stops that target's active tweens and cancels active sequences using that target.

```lua
feel.clear()
feel.clear(target)
```

## LOVE Example

Run the demo from the repository root with LOVE:

```sh
love examples/love2d
```

The showcase uses left and right arrows to move between feature scenes for the full feedback stack, sound controls, and camera/screen adapter behavior.

## LOVE Sound, Camera + Screen Adapter

`feel.love` is an optional LOVE2D adapter for sound, camera, and screen feedback. It plays registered audio cues, handles adapter `emit` events, keeps the state, and gives you small draw helpers.

```lua
local feel = require("feel")
local feelLove = require("feel.love")
local fx = feelLove.new()

fx:sounds({
  hit = love.audio.newSource("hit.wav", "static"),
  ui = love.audio.newSource("ui.wav", "static"),
})

feel.define("hit", {
  { kind = "audio", cue = "hit" },
  { kind = "emit", event = "camera.shake", payload = { amount = 8, duration = 0.2 } },
  { kind = "emit", event = "screen.flash", payload = { amount = 0.35 } },
})

function love.update(dt)
  feel.update(dt)
  fx:update(dt)
end

function love.draw()
  fx:push()
  drawWorld()
  fx:pop()
  fx:drawOverlay()
end

function hit()
  feel.play("hit", nil, fx:handlers())
end
```

Register one cue with `fx:sound(name, sourceOrSources, opts)` or many cues with `fx:sounds(map)`. A cue may be one LOVE `Source` or an array of alternate `Source`s. Playback restarts a selected source by default; pass `{ restart = false }` when registering a cue to let LOVE continue an already-playing source.

`fx:handlers(extra)` plays `{ kind = "audio", cue = "hit" }` steps automatically, then calls `extra.audio(event, ctx)` if provided. Unknown cues are ignored by the adapter, so user callbacks can still handle them.

Supported adapter events are `sound.play`, `sound.stop`, `sound.pause`, `sound.resume`, `sound.volume`, `sound.pitch`, `sound.pan`, `camera.shake`, `camera.zoom`, `camera.move`, `camera.reset`, `screen.flash`, `screen.fade`, and `screen.clear`.

```lua
feel.define("slow.hit", {
  { kind = "emit", event = "sound.pitch", payload = { cue = "hit", pitch = 0.8, duration = 0.15 } },
  { kind = "audio", cue = "hit" },
  { kind = "emit", event = "sound.pitch", payload = { cue = "hit", pitch = 1, duration = 0.2 } },
})
```

Timed sound controls let you author fades, ducking, pitch bends, and pan sweeps as regular sequences. See [LOVE Adapter](docs/love-adapter.md#sound-effect-recipes) for examples.

Use `fx:stopSound(name)` to stop one cue and `fx:stopSounds()` to stop all registered cues.

## Design Direction

`feel.lua` is LOVE-first, but the core should stay a tiny recipe runner. Current core primitives are `animate`, `emit`, `audio`, `callback`, `wait`, `play`, `parallel`, `repeat`, `random`, and `log`.

LOVE-first helpers should build on those primitives instead of expanding the core into one component per effect. `sound`, `camera`, and `screen` are adapter-backed families today; good future helper families include `particle`, `text`, `sprite`, `time`, `spring`, and `shake`.

For example, the LOVE adapter can translate this:

```lua
{ kind = "emit", event = "camera.shake", payload = { amount = 8, duration = 0.2 } }
```

into draw-time camera motion through `fx:push()` and `fx:pop()`.

## Tests

The specs are written with Busted:

```sh
busted spec
```

## Notes

- `feel.lua` owns sequencing and tween values, but your app owns rendering and side effects.
- LOVE-specific effects should be implemented as small handlers or adapters around `emit` and `audio`.
- `feel.fields` exposes the default transform fields.
- `feel.flux` exposes the vendored Flux module if you need direct access.
- `feel.normalizeStep` and `feel.normalizeSequence` are exposed for inspection or advanced tooling.
