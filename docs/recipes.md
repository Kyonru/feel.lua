---
icon: lucide/cooking-pot
---

# Recipes

Copyable starting points for common game-feel problems. Each recipe is intentionally small:
change the fields, timings, and emitted events to match your game.

All examples assume the core is loaded and advanced once per frame:

```lua
local feel = require("feel")

function love.update(dt)
  feel.update(dt)
end
```

## Snappy Button Press

Use a quick compression followed by a slightly slower spring-backed release. `restart`
keeps rapid clicks from stacking competing animations.

```lua
local button = feel.target({ values = { scale = 1, glow = 0 } })

feel.define("ui.button.press", {
  { kind = "animate", to = { scale = 0.92, glow = 1 }, duration = 0.05, ease = "quadout" },
  { kind = "spring", to = { scale = 1, glow = 0 }, stiffness = 220, damping = 18 },
})

local function pressButton()
  feel.play("ui.button.press", button, {
    restart = true,
    key = "press",
  })
end
```

Draw the control using `button.values.scale` and `button.values.glow`.

## Damage Flash

Custom numeric fields are useful for shader uniforms, sprite tinting, and overlay opacity.
Setting `from` makes every restarted flash begin at full strength.

```lua
local enemy = feel.target({ values = { damageFlash = 0 } })

feel.define("enemy.damage-flash", {
  {
    kind = "animate",
    from = { damageFlash = 1 },
    to = { damageFlash = 0 },
    duration = 0.18,
    ease = "quadout",
  },
})

feel.play("enemy.damage-flash", enemy, {
  restart = true,
  key = "damage-flash",
})
```

## Impact Punch With Sound And Particles

Run independent feedback at the same time with `parallel`. Rendering, audio, and particles
remain host-owned; the recipe only coordinates them.

```lua
feel.define("enemy.hit", {
  {
    kind = "parallel",
    steps = {
      { kind = "spring", pull = { scale = 0.22 }, stiffness = 240, damping = 16 },
      { kind = "emit", event = "camera.shake", payload = { amount = 8, duration = 0.12 } },
      { kind = "emit", event = "particles.burst", payload = { count = 18 } },
      { kind = "audio", cue = "hit" },
    },
  },
})

feel.play("enemy.hit", enemy, {
  restart = true,
  key = "hit",
  emit = function(event)
    if event.kind == "camera.shake" then
      camera:shake(event.payload.amount, event.payload.duration)
    elseif event.kind == "particles.burst" then
      particles:burst(enemy.x, enemy.y, event.payload.count)
    end
  end,
  audio = function(event)
    sounds:play(event.cue)
  end,
})
```

## Pickup Celebration

Compose named recipes when several moments should share the same building blocks.

```lua
feel.define("pickup.pop", {
  { kind = "spring", pull = { scale = 0.35 }, stiffness = 190, damping = 13 },
})

feel.define("pickup.celebrate", {
  {
    kind = "parallel",
    steps = {
      { kind = "play", name = "pickup.pop" },
      {
        kind = "repeat",
        count = 3,
        sequence = {
          { kind = "emit", event = "spark.ring" },
          { kind = "wait", duration = 0.06 },
        },
      },
      { kind = "audio", cue = "pickup" },
    },
  },
})
```

## Varied Footsteps

Use weighted random branches to avoid playing exactly the same feedback every time.

```lua
feel.define("player.footstep", {
  {
    kind = "random",
    options = {
      { weight = 4, step = { kind = "audio", cue = "step-1" } },
      { weight = 4, step = { kind = "audio", cue = "step-2" } },
      { weight = 1, step = { kind = "audio", cue = "step-heavy" } },
    },
  },
  { kind = "emit", event = "dust.puff" },
})
```

Keep gameplay-relevant randomness outside feedback recipes. These branches should change
presentation, not damage, movement, or other simulation state.

## Looping Attention Pulse

Keep the returned run handle for effects that intentionally continue until UI state changes.
The wait prevents a tight loop and controls the rhythm.

```lua
local pulse = feel.play({
  {
    kind = "repeat",
    forever = true,
    sequence = {
      { kind = "animate", to = { glow = 1 }, duration = 0.25, ease = "sineinout" },
      { kind = "animate", to = { glow = 0 }, duration = 0.35, ease = "sineinout" },
      { kind = "wait", duration = 0.2 },
    },
  },
}, button)

-- When the notification is acknowledged:
pulse:stop()
```

## Slide A Panel On And Off Screen

Use stable restart keys when opposite transitions can interrupt one another.

```lua
local panel = feel.target({ values = { x = -360, opacity = 0 } })

feel.define("panel.open", {
  { kind = "animate", to = { x = 0, opacity = 1 }, duration = 0.22, ease = "backout" },
})

feel.define("panel.close", {
  { kind = "animate", to = { x = -360, opacity = 0 }, duration = 0.16, ease = "quadin" },
})

local function setPanelOpen(open)
  feel.play(open and "panel.open" or "panel.close", panel, {
    restart = true,
    key = "panel.transition",
  })
end
```

## Route Gameplay Intents Through A Channel

Channels keep gameplay code unaware of recipe names and tuning details.

```lua
local feedback = feel.channel()

feedback:map("enemy.hit", "enemy.hit", {
  opts = { restart = true, key = "hit" },
})

-- Gameplay code only announces what happened:
feedback:emit("enemy.hit", { target = enemy })
```

Keep the unsubscribe function returned by `channel:on` when a scene or entity owns a
temporary handler.

## Start From A Feedback Preset

The optional authoring layer and presets provide a fast starting point for multi-adapter
impact feedback:

```lua
local Feedbacks = require("feel.feedbacks").new({ love = fx, g3d = g3dfx })
local presets = require("feel.presets")

Feedbacks.define("enemy.hit-heavy", presets.hitHeavy({
  name = "enemy",
  shake = 0.1,
  freeze = 0.04,
}))

Feedbacks.play("enemy.hit-heavy", { name = "enemy" })
```

Available factories are `hitLight`, `hitHeavy`, `cameraPunch`, and `modelImpact`. Their
results are ordinary manifest tables, so copy or extend them when the effect needs to grow.

## Bomb: Tick, Tick, Boom

Build anticipation with two increasingly strong ticks, then release sound, controller
rumble, flash, camera shake, and particles together. The haptic rumble uses the timeline
composer so the initial impact can decay into a rough tail.

```lua
-- Register app-owned assets first. Substitute your own sources and particle system.
fx:sounds({
  bombTick = tickSource,
  bombBoom = boomSource,
})
fx:particle("bomb", explosionParticles)

fx:hapticPattern("bomb.rumble", {
  { type = "continuous", at = 0, duration = 0.16, intensity = 1 },
  {
    type = "line",
    at = 0.12,
    duration = 0.65,
    intensity = { { time = 0, value = 0.75 }, { time = 0.65, value = 0.2 } },
    frequency = { { time = 0, value = 0.3 }, { time = 0.65, value = 0.7 } },
  },
})

feel.define("bomb.tick-tick-boom", {
  {
    kind = "parallel",
    steps = {
      { kind = "audio", cue = "bombTick" },
      { kind = "emit", event = "haptic.play", payload = { value = 0.3, duration = 0.035, system = false } },
      { kind = "emit", event = "screen.flash", payload = { amount = 0.08, duration = 0.05 } },
    },
  },
  { kind = "wait", duration = 0.4 },
  {
    kind = "parallel",
    steps = {
      { kind = "audio", cue = "bombTick" },
      { kind = "emit", event = "haptic.play", payload = { value = 0.55, duration = 0.05, system = false } },
      { kind = "emit", event = "screen.flash", payload = { amount = 0.14, duration = 0.06 } },
    },
  },
  { kind = "wait", duration = 0.34 },
  {
    kind = "parallel",
    steps = {
      { kind = "audio", cue = "bombBoom" },
      { kind = "emit", event = "haptic.pattern", payload = { pattern = "bomb.rumble", system = false } },
      { kind = "emit", event = "screen.flash", payload = { amount = 0.8, duration = 0.16 } },
      { kind = "emit", event = "camera.shake", payload = { amount = 14, duration = 0.45 } },
      { kind = "emit", event = "particle.emit", payload = { name = "bomb", count = 48 } },
    },
  },
})

feel.play("bomb.tick-tick-boom", nil, fx:handlers({
  restart = true,
  key = "bomb.countdown",
}))
```

If your game needs a real fuse timer, keep that timing in gameplay code and trigger this
recipe only for presentation. Feedback sequences should not decide when damage occurs.

## Heartbeat Haptic Pattern

The standalone haptics module includes a `heartbeat` preset. The LOVE adapter advances it
from `fx:update(dt)`:

```lua
feel.define("player.heartbeat", {
  {
    kind = "emit",
    event = "haptic.pattern",
    payload = { pattern = "heartbeat", name = "p1", system = false },
  },
})
```

Use `fx:setHapticScale(playerSettings.haptics)` for controller intensity preferences and
`fx:setHapticsEnabled(false)` to stop and suppress haptics entirely. Define a custom pattern
with `fx.hapticEngine:define(name, pulses)` when the built-in rhythm does not fit.

## Cleanup Checklist

- Use `restart = true` and a stable `key` for effects that can be triggered rapidly.
- Store run handles for intentional loops and stop them when their owner disappears.
- Call `feel.clear(target)` when an entity is destroyed or returned to a pool.
- Call `feel.validate(recipe)` during development for recipes built dynamically.
- Call `feel.clear()` during a full scene reset, then define that scene's named recipes again.

See [Sequence Steps](sequence-steps.md) for every available field and
[Best Practices](best-practices.md) for organization and lifecycle guidance.
