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
| `feel.play(nameOrSequence, target, opts)` | Plays a named or inline sequence. |
| `feel.update(dt)` | Advances active tweens, waits, and child runners. |
| `feel.clear(target)` | Clears all work, or only work attached to one target. |
| `feel.channel()` | Creates a local feedback command channel. |

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

## Exposed Tables

| Export | Purpose |
| --- | --- |
| `feel.fields` | Default transform fields. |
| `feel.flux` | Vendored Flux module. |
| `feel.normalizeStep` | Step normalization helper. |
| `feel.normalizeSequence` | Sequence normalization helper. |

See [Core Runner](core-runner.md) for lifecycle details and [Sequence Steps](sequence-steps.md) for sequence table shapes.
