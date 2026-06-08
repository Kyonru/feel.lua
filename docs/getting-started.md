---
icon: lucide/rocket
---

# Getting Started

<!-- feel:feature-gif getting-started -->
![Animated GIF showing a Feel.lua button press sequence with glow and sparks.](assets/feature-gifs/getting-started.gif)
<!-- /feel:feature-gif getting-started -->

Define feedback as small Lua tables, then play those recipes from normal game code. This page builds a complete minimal LOVE example with one animated target and one host-owned side effect.

## Minimal LOVE Loop

```lua
local feel = require("feel")

local button = feel.target({
  label = "Launch",
  values = {
    x = 120,
    y = 90,
    scale = 1,
    glow = 0,
  },
})

local sparks = {}

feel.define("button.press", {
  {
    kind = "parallel",
    steps = {
      { kind = "emit", event = "spark.burst", payload = { count = 18 } },
      { kind = "animate", duration = 0.06, to = { scale = 0.92, glow = 1 }, ease = "quadout" },
    },
  },
  { kind = "wait", duration = 0.03 },
  { kind = "animate", duration = 0.18, to = { scale = 1, glow = 0 }, ease = "backout" },
})

local function spawnSparks(count)
  for _ = 1, count do
    sparks[#sparks + 1] = {
      x = button.values.x,
      y = button.values.y,
      life = 0.35,
    }
  end
end

function love.update(dt)
  feel.update(dt)

  for i = #sparks, 1, -1 do
    sparks[i].life = sparks[i].life - dt
    if sparks[i].life <= 0 then
      table.remove(sparks, i)
    end
  end
end

function love.mousepressed()
  feel.play("button.press", button, {
    restart = true,
    key = "button.press",
    emit = function(event)
      if event.kind == "spark.burst" then
        spawnSparks(event.payload.count)
      end
    end,
  })
end

function love.draw()
  local v = button.values

  for _, spark in ipairs(sparks) do
    love.graphics.setColor(1, 0.72, 0.2, spark.life)
    love.graphics.circle("fill", spark.x, spark.y, 4)
  end

  love.graphics.push()
  love.graphics.translate(v.x, v.y)
  love.graphics.scale(v.scale)
  love.graphics.setColor(0.08, 0.86, 1, 0.18 * v.glow)
  love.graphics.circle("fill", 24, 8, 38)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(button.label, 0, 0)
  love.graphics.pop()
end
```

`feel.target` creates a table with a `values` table. `animate` steps tween numeric fields in that table, including custom fields like `glow`. Your draw code decides what those values mean visually.

## Where To Go Next

- [Sequence Steps](sequence-steps.md) lists every step kind and its fields.
- [Core Runner](core-runner.md) explains restart behavior, nested sequences, and clearing.
- [LOVE Adapter](love-adapter.md) handles registered sounds, particles, shaders, haptics, camera, screen overlays, and post-processing.
