---
icon: lucide/crosshair
---

# Asteroidz Walkthrough

Asteroidz is a standalone LOVE example that uses `feel.lua` for moment-to-moment game feel: ship squash, thrust trails, procedural audio, camera shake, screen flash, post-processing, and HUD pulses.

Run it from the repository root:

```sh
love examples/asteroidz
```

## Shape Of The Example

| File | Role |
| --- | --- |
| `examples/asteroidz/main.lua` | LOVE callbacks, world update, collision checks, drawing, HUD feedback. |
| `examples/asteroidz/sequences.lua` | Named feedback recipes and adapter handlers. |
| `examples/asteroidz/feedback.lua` | A local `feel.channel()` for feedback intents. |
| `examples/asteroidz/ship.lua` | Ship state, shooting, damage, and ship drawing. |
| `examples/asteroidz/state.lua` | Shared game state and wave spawning. |
| `examples/asteroidz/effects.lua` | Simple particles and procedural tones. |

The game keeps simulation code direct and uses sequences when something should feel like an event: fire, hit, explode, wrap, score, or wave clear.

## Sequences As Game Feel

`ship.thrust` emits a trail event and briefly scales the ship target:

```lua
feel.define("ship.thrust", {
  { kind = "emit", event = "ship.trail" },
  { kind = "animate", duration = 0.05, to = { scale = 1.08 }, ease = "quadout" },
  { kind = "animate", duration = 0.1, to = { scale = 1 }, ease = "quadout" },
})
```

`sequences.play` wraps `feel.play` with `constants.fx:handlers(...)`, so adapter-owned events such as `screen.flash`, `camera.shake`, `post.tween`, and `audio` cues can live beside app-owned events such as `ship.trail` and `spark`.

## Feedback Intents

Asteroidz uses a local feedback channel so gameplay modules do not need to import the sequence module directly.

```lua
-- feedback.lua
local feel = require("feel")

return feel.channel()
```

`ship.lua` announces what happened:

```lua
feedback:emit("ship.shoot", { target = self.target })
feedback:emit("ship.explode", { target = self.target })
```

`sequences.lua` owns the mapping from those intents to recipes:

```lua
feedback:on("ship.shoot", function(event)
  play_sequence("ship.shoot", event.target, { restart = true, key = "ship.shoot" })
end)
```

This keeps gameplay state direct while decoupling feedback routing from ship logic.

## Teleport Bloom And Glow

When the ship wraps around the screen, `main.lua` plays `ship.teleport` against `ship.target`:

```lua
sequences.play("ship.teleport", ship.target, { restart = true, key = "ship.teleport" })
```

The sequence combines post-processing and target animation:

```lua
feel.define("ship.teleport", {
  { kind = "emit", event = "post.set", payload = { effect = "bloom", values = { intensity = 10, threshold = 0.52, softness = 0.18, passes = 3 } } },
  {
    kind = "parallel",
    steps = {
      { kind = "emit", event = "post.tween", payload = { effect = "lens", values = { distortion = 1.5 }, duration = 0.1, ease = "quadout" } },
      { kind = "emit", event = "post.tween", payload = { effect = "bloom", values = { intensity = 10 }, duration = 0.1, ease = "quadout" } },
      { kind = "animate", duration = 0.06, to = { teleportGlow = 1 }, ease = "quadout" },
    },
  },
})
```

`teleportGlow` is a custom numeric target value. The ship draw code turns it into filled cyan and pink glow shapes behind the normal line-art ship. That gives bloom real pixels to blur, while `passes = 3` widens the haze.

## Post-Processed World, Crisp HUD

Asteroidz wraps the world draw in `constants.fx:drawPost(...)`, then draws the overlay and HUD afterward:

```lua
constants.fx:drawPost(function()
  constants.fx:push()
  background:draw()
  drawBulletsAsteroidsParticlesAndShip()
  constants.fx:pop()
end)

constants.fx:drawOverlay()
drawHud()
```

This keeps bloom, lens distortion, and chromatic effects focused on the game world. The HUD stays readable and uses normal target animations for juice.

## UI Juice

The HUD uses small `feel.target`s in `main.lua`:

```lua
local ui = {
  score = feel.target({ values = { scale = 1, glow = 0 } }),
  lives = feel.target({ values = { scale = 1, glow = 0 } }),
  wave = feel.target({ values = { scale = 1, glow = 0 } }),
}
```

When score, lives, or wave changes, `pulseUi` plays a short scale/glow animation. This is the same pattern as ship feedback: store simple values in a target, animate those values with a sequence, and let drawing decide how the values look.

## What To Reuse

- Put reusable feedback in named sequences, not inside collision or input branches.
- Pass a target when the recipe animates values; omit it for event-only recipes.
- Use `restart = true` for feedback that should replace itself, such as thrust, teleport, and HUD pulses.
- Draw bloomable source shapes inside `fx:drawPost(...)`; draw HUD afterward when it should stay sharp.

See [Post Processing](post-processing.md) for bloom parameters and [LOVE Adapter](love-adapter.md) for the full event list.
