# Getting Started

Define feedback as small Lua tables, then play them from your game code.

```lua
local feel = require("feel")

local button = feel.target({
  label = "Launch",
  values = { scale = 1, x = 0, y = 0, opacity = 1 },
})

feel.define("button.press", {
  { kind = "audio", cue = "press" },
  {
    kind = "parallel",
    steps = {
      { kind = "emit", event = "burst", payload = { count = 18 } },
      { kind = "animate", duration = 0.06, to = { scale = 0.92, y = 3 }, ease = "quadout" },
    },
  },
  { kind = "wait", duration = 0.03 },
  { kind = "animate", duration = 0.16, to = { scale = 1, y = 0 }, ease = "backout" },
})

feel.play("button.press", button, {
  trigger = "click",
  audio = function(event)
    playSound(event.cue)
  end,
  emit = function(event)
    spawnParticles(event.payload.count)
  end,
})
```

In LOVE2D, update the runner and draw using the animated target values:

```lua
function love.update(dt)
  feel.update(dt)
end

function love.draw()
  local v = button.values
  love.graphics.push()
  love.graphics.translate(120 + v.x, 80 + v.y)
  love.graphics.scale(v.scale)
  love.graphics.print(button.label, 0, 0)
  love.graphics.pop()
end
```

Use the LOVE adapter when you want registered sound cues, particles, shaders, post-processing, haptics, camera motion, or screen overlays.
