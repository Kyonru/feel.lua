---
icon: lucide/book-open
---

# API

## Core Functions

| Function | Purpose |
| --- | --- |
| `feel.target(meta)` | Creates a target table with a tweenable `values` table. |
| `feel.define(name, sequence)` | Stores a named sequence and returns the normalized sequence. |
| `feel.get(name)` | Returns a previously defined sequence. |
| `feel.validate(sequence)` | Checks a sequence and returns `ok, err`. |
| `feel.play(nameOrSequence, target, opts)` | Plays a named or inline sequence. |
| `feel.update(dt)` | Advances active tweens, waits, and child runners. |
| `feel.active()` | Returns debug snapshots for active sequence runners. |
| `feel.isPlaying(target, key)` | Returns whether a target/key slot is currently active. |
| `feel.clear(target)` | Clears all work, or only work attached to one target. |
| `feel.channel()` | Creates a local feedback command channel. |
| `feel.stop/pause/resume(ctx)` | Control a single run by its play context. |
| `feel.pauseAll/resumeAll()` | Freeze or resume every run at once. |
| `feel.setTimeScale(s)` / `feel.timeScale()` | Scale (and read) the feel clock. |
| `feel.strictAliases(on)` | Toggle deprecation warnings for redundant field aliases. |

For More Mountains-style named feedback stacks, use the optional [`feel.feedbacks`](feedbacks.md) authoring layer on top of these core functions.

## `feel.target(meta)`

Creates a target table with a `values` table ready for animation.

```lua
local target = feel.target({
  values = { scale = 1, opacity = 1, teleportGlow = 0 },
})
```

`values` may contain any numeric field. The built-in defaults are `opacity`, `x`, `y`, `scale`, `scaleX`, `scaleY`, and `rotation`; custom numeric fields like `teleportGlow` are preserved and can be tweened by `animate` steps.

## `feel.define(name, sequence)`

Stores a named sequence and returns its normalized form.

```lua
feel.define("hit.strong", {
  { kind = "emit", event = "shake", payload = { amount = 10 } },
})
```

## `feel.get(name)`

Returns a previously defined sequence.

```lua
local sequence = feel.get("hit.strong")
```

## `feel.validate(sequence)`

Checks a named or inline sequence without playing it. It returns `true` when the sequence looks valid, or `false, err` with the first authoring problem it finds.

```lua
local ok, err = feel.validate({
  { kind = "animate", to = { scale = 1.2 }, duration = 0.08 },
  { kind = "audio", cue = "hit" },
})

if not ok then
  print(err)
end
```

Validation catches common mistakes: unknown step kinds, non-numeric animation fields, malformed `parallel.steps`, empty `random.options`, missing audio cues, missing child sequences, and unknown named sequences.

## `feel.play(nameOrSequence, target, opts)`

Plays a named sequence or an inline sequence.

```lua
feel.play("hit.strong", target, {
  trigger = "attack",
  restart = true,
  key = "player.hit",
  emit = function(event, ctx) end,
  audio = function(event, ctx) end,
  markDirty = function(ctx) end,
})
```

| Option | Purpose |
| --- | --- |
| `trigger` | Label copied into emitted events and context. Defaults to `"manual"` unless inherited by child steps. |
| `restart` | Cancels the previous active run in the same target/key slot before starting. |
| `key` | Restart slot key. Named sequences can omit it; inline restartable sequences should pass one. |
| `emit(event, ctx)` | Receives `emit` steps. |
| `audio(event, ctx)` | Receives `audio` steps. |
| `log(message, ctx)` | Receives `log` steps. |
| `markDirty(ctx)` | Called by animation updates when provided. |

`target` is optional for event-only sequences. If an animation step runs without a target, `feel.lua` creates an internal target.

Without restart, repeated plays stack. With restart, the second play replaces the first active run for that target/key:

```lua
feel.play("hit.strong", target, { restart = true, key = "player.hit" })
feel.play("hit.strong", target, { restart = true, key = "player.hit" })
```

## `feel.update(dt)`

Advances active tweens, waits, and child sequence runners. Call this once per frame.

```lua
feel.update(dt)
```

Returns whether there was active work before or after the update.

## `feel.active()`

Returns a snapshot array for debugging active runners. The returned tables are copies, so changing them does not change the scheduler.

```lua
for _, run in ipairs(feel.active()) do
  print(run.source, run.key, run.index, run.count, run.remaining)
end
```

| Field | Purpose |
| --- | --- |
| `target` | Target attached to the run, when any. |
| `source` | Named sequence string or inline sequence value passed to `feel.play`. |
| `trigger` | Current trigger label. |
| `key` | Restart key, when the run was started with `restart = true`. |
| `index` / `count` | Current step index and total normalized steps. |
| `elapsed` | Seconds since this runner started. |
| `waiting` / `remaining` | Whether the runner is in a wait step, and seconds left when it is. |
| `tweens` / `children` | Number of active tweens and child runners owned by this runner. |

## `feel.isPlaying(target, key)`

Returns `true` when an active runner matches `target` and, when provided, `key`.

```lua
if feel.isPlaying(ship.target, "ship.teleport") then
  -- avoid stacking a manual teleport effect
end
```

## `feel.clear(target)`

Clears registered sequences, active tween state, waits, nested sequences, repeats, and parallel branches. When given a target, it stops that target's active tweens and cancels active sequences using that target.

```lua
feel.clear()
feel.clear(target)
```

## `feel.channel()`

Creates a local feedback command channel. Channels let gameplay code announce named feedback intents while another module maps those intents to `feel.play`, adapter events, targets, or app-specific side effects.

```lua
local feedback = feel.channel()

feedback:on("ship.shoot", function(event)
  feel.play("ship.shoot", event.target, { restart = true, key = "ship.shoot" })
end)

feedback:emit("ship.shoot", { target = ship.target })
```

| Method | Purpose |
| --- | --- |
| `channel:on(intent, handler)` | Register a handler and return an unsubscribe function. |
| `channel:off(intent, handler)` | Remove one handler. |
| `channel:emit(intent, event)` | Call handlers for one intent and return the number called. |
| `channel:map(intent, sequence, defaults)` | Register a simple handler that plays a sequence. |
| `channel:clear(intent)` | Clear one intent, or all handlers when `intent` is omitted. |

Channels are intentionally small and local. They are for feedback routing, not general app state, entity messaging, networking, replay, or gameplay architecture.

## Run Control

`feel.play` returns a control handle (the play context). These work as methods on the
handle or as free functions taking the handle; both forms are equivalent and the free
functions tolerate `nil`.

```lua
local run = feel.play("ship.charge", ship, { restart = true, key = "charge" })

run:pause(); run:resume(); run:stop()
-- or: feel.pause(run); feel.resume(run); feel.stop(run)

run:onComplete(function(ctx) end):onStop(function(ctx) end)
```

| Method / function | Purpose |
| --- | --- |
| `run:stop()` / `feel.stop(run)` | Cancel the run (and its child subtree). |
| `run:pause()` / `feel.pause(run)` | Freeze the run's tweens and waits. |
| `run:resume()` / `feel.resume(run)` | Continue a paused run from where it stopped. |
| `run:isPlaying()` | `true` while the run is active. |
| `run:isPaused()` | `true` while the run is paused. |
| `run:onComplete(fn)` | Run `fn` when the sequence finishes. Fires immediately if already done. Returns the handle. |
| `run:onStop(fn)` | Run `fn` when the run is stopped/cancelled. Returns the handle. |

## Global Pause And Time Scale

```lua
feel.pauseAll()        -- freeze every run
feel.resumeAll()
feel.isPausedAll()     -- boolean

feel.setTimeScale(0.5) -- scale tweens and waits; returns the clamped value
feel.timeScale()       -- read it
```

`setTimeScale` clamps to `>= 0`. This core time scale is independent of the optional
[`feel.feedbacks`](feedbacks.md) time scale.

## `feel.strictAliases(on)`

Field names accept historical aliases (`time` for `duration`, `fn` for `callback`, `times`
for `count`, `chance` for `weight`, `text` for `message`). All keep working. Call
`feel.strictAliases(true)` during development to print a one-time deprecation notice the
first time each redundant named alias is used. It is off by default and returns the current
setting.

## Exposed Tables

| Export | Purpose |
| --- | --- |
| `feel.fields` | Default transform fields. |
| `feel.flux` | Vendored Flux module. Add custom easing functions through `feel.flux.easing`. |
| `feel.normalizeStep` | Step normalization helper. |
| `feel.normalizeSequence` | Sequence normalization helper. |

See [Core Runner](core-runner.md) for lifecycle details and [Sequence Steps](sequence-steps.md) for sequence table shapes.
