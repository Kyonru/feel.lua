---
icon: lucide/vibrate
---

# Haptics

`feel.haptics` is a small, hardware-independent haptic pattern engine. It turns named
patterns into timed pulses on its own clock, provides useful presets, and centralizes
intensity, enable/disable, restart, and cancellation behavior.

It does not load or depend on the Feel runner. You can use it with the rest of Feel, require
only `feel.haptics`, or copy `feel/haptics.lua` into another project as `haptics.lua`.

The module takes inspiration from [Pulsar](https://github.com/software-mansion/pulsar):
haptic feedback is treated as reusable design material rather than scattered calls to a
vibration API. Feel keeps the model deliberately small for game runtimes—each pattern is a
sequence of motor pulses separated by optional gaps.

## Use It with LOVE

The LOVE adapter creates an engine for you and exposes it as `fx.hapticEngine`:

```lua
local feel = require("feel")
local feelLove = require("feel.love")

local fx = feelLove.new({ hapticScale = 0.8 })
fx:haptic("p1", love.joystick.getJoysticks()[1])

fx.hapticEngine:play("success", {
  target = "p1",
  system = false,
})

function love.update(dt)
  feel.update(dt)
  fx:update(dt)
end
```

The adapter's existing helpers are aliases around the same engine, so this remains valid:

```lua
fx:hapticPattern("charge", {
  { value = 0.2, duration = 0.04, gap = 0.06 },
  { value = 0.5, duration = 0.06, gap = 0.04 },
  { value = 1.0, duration = 0.12 },
})

fx:playHapticPattern("charge", { name = "p1", system = false })
```

## Built-in Presets

Every engine includes these presets by default:

| Preset | Intended use |
| --- | --- |
| `tap` | General button confirmation |
| `selection` | Moving between choices |
| `impactLight` | Small collision or hit |
| `impactMedium` | Normal collision or hit |
| `impactHeavy` | Large collision or hit |
| `success` | Completed or accepted action |
| `warning` | Attention without failure |
| `error` | Failed or rejected action |
| `heartbeat` | Urgency or low health |

Use `haptics:list()` to discover registered patterns and `haptics:get(name)` to receive a
copy safe to inspect or modify. Pass `{ presets = false }` to `new` for an empty engine.

## Compose Patterns

A pulse accepts `value` (or its `intensity` alias), independent `left` and `right` motor
strengths, `duration`, an optional silent `gap`, and adapter-specific fields such as `system`.
Strength values are clamped to the `0`–`1` range.

```lua
local haptics = fx.hapticEngine

haptics:define("engine.start", {
  { left = 0.25, right = 0.1, duration = 0.06, gap = 0.05 },
  { left = 0.55, right = 0.3, duration = 0.08, gap = 0.04 },
  { left = 1.0, right = 0.7, duration = 0.14 },
})

haptics:defineAll({
  menuOpen = { 0.25, 0.5 },
  menuClose = { 0.5, 0.25 },
})
```

Numbers are shorthand for `{ value = number }`. `play` also accepts an anonymous pattern:

```lua
haptics:play({
  { intensity = 0.4, duration = 0.04, gap = 0.03 },
  { intensity = 0.8, duration = 0.08 },
}, { target = "p1", system = false })
```

Starting the same named pattern on the same target restarts it by default. Pass
`restart = false` to allow both runs.

## Control and Cancellation

```lua
haptics:stop("heartbeat", "p1")
haptics:stopTarget("p1")
haptics:stopAll()

haptics:setScale(0.5)
haptics:setEnabled(false) -- stops active output immediately
```

A scale of zero also stops output. For accessibility, persist both intensity and the enabled
setting with the rest of the player's preferences.

## Use Another Runtime

The engine only requires a driver with `play` and `stop` functions:

```lua
local Haptics = require("feel.haptics")

local haptics = Haptics.new({
  play = function(pulse)
    platform.rumble(pulse.left, pulse.right, pulse.duration, pulse.target)
    return true
  end,
  stop = function(opts)
    platform.stopRumble(opts.target)
    return true
  end,
})

function update(dt)
  haptics:update(dt)
end
```

Return `true` from a driver function when hardware accepted the operation. Call
`haptics:update(dt)` once per frame to advance gaps and later pulses. Playback handles support
`stop`, `pause`, `resume`, `isPlaying`, `isPaused`, `onComplete`, and `onStop`.

When using `feel.love`, `fx:update(dt)` advances `fx.hapticEngine` automatically.

## Platform Limits

LOVE controller vibration accepts left/right strengths and a duration. A controller with one
motor uses the larger strength. System vibration is Android/iOS-only, and iOS ignores the
requested duration in favor of a fixed vibration. See LOVE's
[`Joystick:setVibration`](https://love2d.org/wiki/Joystick%3AsetVibration) and
[`love.system.vibrate`](https://love2d.org/wiki/love.system.vibrate) documentation.

Those limits are why the composer uses discrete pulses rather than promising continuous
amplitude/frequency envelopes on every target. Prefer controller-only patterns
(`system = false`) when precise timing matters.
