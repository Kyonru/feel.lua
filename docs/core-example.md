---
icon: lucide/terminal
---

# Core Example

The core runner has no LOVE dependency. This example runs on a plain Lua interpreter and
shows the whole core loop without any graphics: a target, a named recipe, a feedback
channel, `emit`/`log` handlers, a run-level `onComplete` signal, and a manual fixed-step
loop reading `target.values`.

Run it from the repository root:

```sh
lua examples/core/main.lua
```

or:

```sh
make core
```

## The Program

```lua
package.path = "?.lua;?/init.lua;../../?.lua;../../?/init.lua;" .. package.path

local feel = require("feel")

-- 1. A target is just a Lua table with a tweenable `values` table.
local ship = feel.target({
  label = "Ship",
  values = { x = 0, scale = 1, glow = 0 },
})

-- 2. A named recipe: punch in, emit a "spark" intent, settle back, then log.
feel.define("ship.hit", {
  { kind = "animate", duration = 0.08, to = { scale = 1.4, glow = 1 }, ease = "quadout" },
  { kind = "emit", event = "spark.burst", payload = { count = 8 } },
  { kind = "animate", duration = 0.2, to = { scale = 1, glow = 0 }, ease = "backout" },
  { kind = "log", message = "ship.hit finished" },
})

-- 3. A channel decouples "what happened" (an intent) from "what feedback runs".
local feedback = feel.channel()

feedback:on("enemy.killed", function(event)
  local run = feel.play("ship.hit", event.target, {
    restart = true,
    key = "ship.hit",
    emit = function(emitted)
      if emitted.kind == "spark.burst" then
        print(string.format("  emit  -> %d sparks", emitted.payload.count))
      end
    end,
    log = function(message)
      print("  log   -> " .. message)
    end,
  })

  -- 4. A run-level signal fires once when the whole recipe completes.
  run:onComplete(function()
    print(string.format("  done  -> scale=%.2f glow=%.2f", ship.values.scale, ship.values.glow))
  end)
end)

-- 5. Announce the intent. There is no direct feel.play here; the channel routes it.
feedback:emit("enemy.killed", { target = ship })

-- 6. A manual fixed-step loop. feel.update(dt) returns true while work is active.
local dt = 1 / 60
local frame = 0
while feel.update(dt) do
  frame = frame + 1
  print(string.format("frame %2d  scale=%.3f  glow=%.3f", frame, ship.values.scale, ship.values.glow))
end

print("idle after " .. frame .. " frames")
```

## What To Notice

- **No LOVE.** The core only needs `feel.update(dt)` to advance and `target.values` to
  read. Anything that draws or plays sound is your job — here it is just `print`.
- **`feel.update(dt)` returns a boolean** that is true while any run is active, which is
  why the loop ends on its own once the recipe finishes.
- **The channel inverts control.** Gameplay code emits an intent (`enemy.killed`); the
  feedback module decides what plays. See [Core Runner](core-runner.md#feedback-channels).
- **`run:onComplete(fn)`** is one of the run-level signals on the value returned by
  `feel.play`. See [Controlling A Run](core-runner.md#controlling-a-run).

## Related Pages

- [Core Runner](core-runner.md) for targets, playback, channels, and run control.
- [Sequence Steps](sequence-steps.md) for every step shape.
- [LOVE Examples](love-examples.md) for the graphical showcase and Asteroidz.
