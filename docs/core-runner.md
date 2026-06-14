---
icon: lucide/cpu
---

# Core Runner

The core runner stores named feedback recipes, plays named or inline sequences, advances active work through `feel.update(dt)`, and leaves rendering or side effects to your app.

## Targets

Use `feel.target(meta)` when a sequence needs animated values.

```lua
local button = feel.target({
  label = "Launch",
  values = { x = 0, y = 0, scale = 1, opacity = 1, glow = 0 },
})
```

The default transform fields are `opacity`, `x`, `y`, `scale`, `scaleX`, `scaleY`, and `rotation`. You can also add any numeric field your game wants to animate, such as `glow`, `shake`, `teleportGlow`, or `charge`.

Metadata that is not inside `values` stays available on the target table, but it is not tweened:

```lua
local ship = feel.target({
  kind = "player",
  values = { scale = 1, teleportGlow = 0 },
})
```

## Named Sequences

Use `feel.define(name, sequence)` for reusable recipes.

```lua
feel.define("button.press", {
  { kind = "audio", cue = "press" },
  { kind = "animate", duration = 0.06, to = { scale = 0.92 }, ease = "quadout" },
  { kind = "animate", duration = 0.16, to = { scale = 1 }, ease = "backout" },
})
```

`feel.get(name)` returns the normalized sequence.

Use `feel.validate(sequence)` while authoring or loading recipes to catch common shape problems before playback:

```lua
local ok, err = feel.validate("button.press")
if not ok then
  print(err)
end
```

## Playback

`feel.play(nameOrSequence, target, opts)` accepts a named sequence or inline sequence.

```lua
feel.play("button.press", button, {
  trigger = "click",
  restart = true,
  key = "button.press",
  emit = function(event, ctx) end,
  audio = function(event, ctx) end,
  markDirty = function(ctx) end,
})
```

`target` is optional for event-only recipes. If an animation step runs without a target, the runner creates an internal target.

Use `restart = true` when a new play should cancel the previous active play in the same target/key slot. Named sequences can omit `key`; inline sequences should pass a stable string key.

Without restart, repeated plays stack:

```lua
feel.play("button.press", button)
feel.play("button.press", button)
```

With restart, the second play replaces the first active run for that target/key:

```lua
feel.play("button.press", button, { restart = true })
feel.play("button.press", button, { restart = true })
```

## Feedback Channels

Use `feel.channel()` when gameplay modules should announce feedback intents without importing the sequence module that handles them.

```lua
local feedback = feel.channel()

feedback:on("ship.explode", function(event)
  feel.play("ship.explode", event.target, { restart = true, key = "ship.explode" })
end)

feedback:emit("ship.explode", { target = ship.target })
```

For the common "on this intent, just play this sequence" case, `channel:map` is a shortcut.
`channel:clear(intent)` removes one intent's handlers, or all of them when called with no
argument.

```lua
feedback:map("ship.shoot", "ship.shoot", { opts = { restart = true, key = "ship.shoot" } })
feedback:emit("ship.shoot", { target = ship.target })

feedback:clear("ship.shoot") -- or feedback:clear() to remove every handler
```

Channels are local objects. Create them where they make module boundaries cleaner, and keep gameplay state changes direct.

## Controlling A Run

`feel.play` returns a control handle (the play context). Use it to stop, pause, or resume
just that run, or to react when it ends. This is finer-grained than `feel.clear(target)`,
which stops every run on a target.

```lua
local run = feel.play("ship.charge", ship, { restart = true, key = "charge" })

run:pause()        -- freeze this run (its tweens and waits) ...
run:resume()       -- ... and continue where it left off
run:stop()         -- cancel it outright

if run:isPlaying() then end
if run:isPaused() then end
```

Pausing a parent run also freezes its `parallel`, `play`, and `repeat` children. The same
operations are available as free functions for code that does not keep the handle around:
`feel.stop(ctx)`, `feel.pause(ctx)`, and `feel.resume(ctx)` (all safe to call with `nil`).

Two run-level signals fire once per run and return the handle for chaining:

```lua
feel.play("ship.explode", ship)
  :onComplete(function(ctx) print("explosion done") end)
  :onStop(function(ctx) print("explosion cancelled") end)
```

`onComplete` fires when the whole sequence finishes; `onStop` fires when the run is stopped
or cancelled (including restart eviction and `feel.clear`). A callback registered after the
run already completed fires immediately.

## Global Pause And Time Scale

`feel.pauseAll()` freezes every run; `feel.resumeAll()` continues. `feel.setTimeScale(s)`
scales the feel clock — both tweens and waits — uniformly, and `feel.timeScale()` reads it.

```lua
feel.pauseAll()
feel.resumeAll()

feel.setTimeScale(0.5) -- everything runs at half speed
feel.setTimeScale(1)
```

This core time scale is independent of the optional [`feel.feedbacks`](feedbacks.md) time
scale, which scales your *game* logic while `feel.update` still receives real `dt`. They do
not affect each other; combine them explicitly if you want both.

## Update And Clear

Call `feel.update(dt)` once per frame. It advances tweens, waits, nested sequences, repeat loops, and parallel branches.

Use `feel.active()` and `feel.isPlaying(target, key)` as tiny debug helpers when restart slots, long waits, or nested sequences are hard to reason about:

```lua
for _, run in ipairs(feel.active()) do
  print(run.source, run.key, run.index, run.count, run.remaining)
end

if feel.isPlaying(ship.target, "ship.teleport") then
  print("teleport feedback is still active")
end
```

Use `feel.clear()` to clear all named sequences and active work. Use `feel.clear(target)` to stop active tweens and active sequences for one target.

## Related Pages

- [Sequence Steps](sequence-steps.md) describes every step shape.
- [API](api.md) lists function signatures and option fields.
- [LOVE Adapter](love-adapter.md) shows how emitted events become LOVE side effects.
