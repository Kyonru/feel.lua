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
vibration API. Feel supports both direct pulse sequences and higher-level timestamped
segments that compile to hardware-friendly pulses.

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

The expressive collection also includes `softTap`, `doubleTap`, `tripleTap`, `longPress`,
`rumble`, `drone`, `flutter`, `trill`, `alert`, `reject`, `alarm`, `waltz`, `warDrum`,
`thunder`, `finale`, `drumroll`, `crescendo`, `morse`, `siren`, `shudder`, `windup`, and
`unwind`.

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

## Timeline Composer

For more expressive feedback, define timestamped `continuous`, `pulse`, or `line` segments.
Times are in seconds, and overlapping segments are combined using the strongest value for
each motor.

```lua
haptics:define("power-up", {
  {
    type = "line",
    at = 0,
    duration = 1.2,
    intensity = {
      { time = 0, value = 0.1 },
      { time = 0.8, value = 0.6 },
      { time = 1.2, value = 1.0 },
    },
    frequency = {
      { time = 0, value = 0.2 },
      { time = 1.2, value = 0.95 },
    },
  },
  { type = "continuous", at = 1.25, duration = 0.18, intensity = 1 },
})
```

- `continuous` holds one intensity for its duration.
- `pulse` generates a pulse train. Intensity controls motor strength and pulse length;
  frequency controls the spacing between pulses.
- `line` and its `curve` alias interpolate intensity and frequency control points over time.
- `at` and `timestamp` are aliases.

Keep sequential pulse entries and timeline segments in separate patterns; the two timing
models cannot be mixed implicitly.

Use `haptics:compile(pattern)` to inspect the resulting discrete pulses. Tune generation with
`minPulse`, `maxPulse`, `minGap`, and `maxGap` when constructing the engine.

## Performance

Named patterns compile once in `define`, including built-in presets during engine creation.
Playback does not resample curves or resolve overlaps; it only stores the compiled pulse list
and dispatches pulses as `update(dt)` crosses their timestamps.

The practical costs are:

- Compilation: proportional to generated intervals and their overlap boundaries. This is
  normally sub-millisecond for UI/game patterns and happens outside the frame loop.
- Playback: constant work on frames without a pulse, then one driver call per pulse crossed.
- Memory: one small table per compiled pulse plus one lightweight table per active playback.

`maxGeneratedPulses` defaults to `2048` and rejects pathological patterns before they can
produce unbounded work. Anonymous timeline patterns compile when played, so define frequently
reused or complex patterns by name.

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

The composer approximates continuous amplitude/frequency envelopes as discrete pulses because
that is the common capability across targets. Prefer controller-only patterns (`system =
false`) when precise intensity and timing matter.
