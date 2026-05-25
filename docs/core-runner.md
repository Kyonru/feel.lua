# Core Runner

The core runner stores named feedback recipes, plays named or inline sequences, advances active work through `feel.update(dt)`, and leaves rendering or side effects to your app.

## Targets

Use `feel.target(meta)` when a sequence needs animated values.

```lua
local button = feel.target({
  label = "Launch",
  values = { x = 0, y = 0, scale = 1, opacity = 1 },
})
```

The default animated fields are `opacity`, `x`, `y`, `scale`, `scaleX`, `scaleY`, and `rotation`. You can still attach any metadata you want to the target table.

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
  emit = function(event, ctx) end,
  audio = function(event, ctx) end,
  markDirty = function(ctx) end,
})
```

`target` is optional for event-only recipes. If an animation step runs without a target, the runner creates an internal target.

## Update And Clear

Call `feel.update(dt)` once per frame. It advances tweens, waits, nested sequences, repeat loops, and parallel branches.

Use `feel.clear()` to clear all named sequences and active work. Use `feel.clear(target)` to stop active tweens and active sequences for one target.
