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

Channels are local objects. Create them where they make module boundaries cleaner, and keep gameplay state changes direct.

## Update And Clear

Call `feel.update(dt)` once per frame. It advances tweens, waits, nested sequences, repeat loops, and parallel branches.

Use `feel.clear()` to clear all named sequences and active work. Use `feel.clear(target)` to stop active tweens and active sequences for one target.

## Related Pages

- [Sequence Steps](sequence-steps.md) describes every step shape.
- [API](api.md) lists function signatures and option fields.
- [LOVE Adapter](love-adapter.md) shows how emitted events become LOVE side effects.
