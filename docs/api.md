# API

## `feel.target(meta)`

Creates a target table with a `values` table ready for animation.

```lua
local target = feel.target({ values = { scale = 1 } })
```

The default animated fields are `opacity`, `x`, `y`, `scale`, `scaleX`, `scaleY`, and `rotation`.

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

`target` is optional for event-only sequences. If an animation step runs without a target, `feel.lua` creates an internal target.

Pass `restart = true` to cancel the previous active run in the same target/key slot before starting the new one. `key` is optional for named sequences; inline sequences should pass a stable string key when they need restart behavior.

Without restart, repeated plays stack:

```lua
feel.play("hit.strong", target)
feel.play("hit.strong", target)
```

With restart, the second play replaces the first active run:

```lua
feel.play("hit.strong", target, { restart = true })
feel.play("hit.strong", target, { restart = true })
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

## Exposed Tables

- `feel.fields`: default transform fields.
- `feel.flux`: vendored Flux module.
- `feel.normalizeStep`: step normalization helper.
- `feel.normalizeSequence`: sequence normalization helper.
