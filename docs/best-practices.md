---
icon: lucide/sparkles
---

# Best Practices

Patterns that keep feedback readable, tunable, and cheap as a project grows.

## Keep recipes small and named

Define short, single-purpose recipes and compose them with `play`, `parallel`, and
`repeat` rather than writing one giant sequence. Small recipes are easier to validate,
reuse, and tune.

```lua
feel.define("hit.flash", { { kind = "animate", to = { glow = 1 }, duration = 0.05 } })
feel.define("hit.shake", { { kind = "emit", event = "shake", payload = { amount = 8 } } })
feel.define("hit", {
  { kind = "parallel", steps = { { kind = "play", name = "hit.flash" }, { kind = "play", name = "hit.shake" } } },
})
```

## A duration & easing cheat sheet

Game feel is mostly two animate steps: a fast punch in, then a slower settle.

| Phase | Duration | Easing |
| --- | --- | --- |
| Punch in | 0.04–0.08 s | `quadout` |
| Settle | 0.15–0.30 s | `backout`, `elasticout` |
| Subtle pulse | 0.10–0.20 s | `sineinout` |

Start there, then adjust by feel. All Flux easings are available; add your own via
`feel.flux.easing`.

## Use restart + a stable key for spammable actions

Anything the player can trigger rapidly (jump, shoot, button mash) should restart its own
slot so runs do not stack:

```lua
feel.play("ship.shoot", ship, { restart = true, key = "ship.shoot" })
```

Prefer a `feel.isPlaying(target, key)` guard or the run handle's `isPlaying()` over ad-hoc
boolean flags.

## Put animated fields in `values`; keep metadata out

Only numeric fields inside `values` are tweened. Keep identifiers, labels, and references
on the target table but outside `values`:

```lua
local ship = feel.target({ id = 42, kind = "player", values = { scale = 1, glow = 0 } })
```

## Separate concerns: channels, adapters, draw code

- **Channels** route intents from gameplay to feedback ([Core Runner](core-runner.md#feedback-channels)).
- **Adapters** turn emitted events into side effects ([Writing a Custom Adapter](custom-adapter.md)).
- **Your draw code** owns rendering and reads `target.values`.

This keeps gameplay logic free of feedback details and makes feedback easy to swap or mute.

## Validate at startup, tune while running

Run `feel.validate` over your recipes during load or in a test, and use `feel.active()`
while tuning to see what is running, where, and for how long.

## Reset discipline

- `feel.clear(target)` when an entity dies or is recycled.
- `feel.clear()` on a scene change (it also drops named definitions and resets global
  pause / time scale).

## Related Pages

- [Core Runner](core-runner.md)
- [Sequence Steps](sequence-steps.md)
- [Troubleshooting](troubleshooting.md)
