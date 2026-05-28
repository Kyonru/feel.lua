# feel.lua

`feel.lua` is a tiny LOVE2D-first feedback sequencing library for making actions feel good.

## What It Does

- Defines reusable named feedback sequences with `feel.define`.
- Plays named or inline sequences with `feel.play`.
- Animates lightweight target values.
- Emits host-owned events for particles, camera shake, flashes, sounds, haptics, shaders, and more.
- Runs steps in order, including waits, nested sequences, repeats, random branches, and parallel groups.

https://github.com/user-attachments/assets/6b15a87f-5a11-42f6-922b-ccf8bd0627f7

## Install

Install with [Feather](https://kyonru.github.io/feather/installation/):

```sh
feather package install feel
```

Feather installs the package under `lib/feel`:

```lua
local feel = require("lib.feel")
```

## Quick Start

```lua
local feel = require("lib.feel")

local button = feel.target({
  label = "PRESS ME",
  x = 320,
  y = 240,
  w = 180,
  h = 54,
  values = { scale = 1, y = 0, glow = 0 },
})

feel.define("button.press", {
  { kind = "emit", event = "sound", payload = { cue = "click" } },
  { kind = "animate", duration = 0.06, to = { scale = 0.92, y = 3 }, ease = "quadout" },
  { kind = "parallel", steps = {
    {
      { kind = "animate", duration = 0.16, to = { scale = 1, y = 0 }, ease = "backout" },
    },
    {
      { kind = "animate", duration = 0.08, to = { glow = 1 }, ease = "quadout" },
      { kind = "animate", duration = 0.22, to = { glow = 0 }, ease = "quadout" },
    },
  } },
})

local function insideButton(x, y)
  return x >= button.x - button.w / 2
    and x <= button.x + button.w / 2
    and y >= button.y - button.h / 2
    and y <= button.y + button.h / 2
end

function love.update(dt)
  feel.update(dt)
end

function love.mousepressed(x, y)
  if insideButton(x, y) then
    feel.play("button.press", button, {
      restart = true,
      key = "button.press",
      emit = function(event)
        print(event.kind, event.payload and event.payload.cue)
      end,
    })
  end
end

function love.draw()
  local v = button.values
  local x = button.x
  local y = button.y + v.y

  love.graphics.clear(0.08, 0.09, 0.11)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.scale(v.scale)

  love.graphics.setColor(0.2, 0.8, 1, 0.18 * v.glow)
  love.graphics.rectangle("fill", -button.w / 2 - 14, -button.h / 2 - 14, button.w + 28, button.h + 28, 12)

  love.graphics.setColor(0.12, 0.14, 0.18)
  love.graphics.rectangle("fill", -button.w / 2, -button.h / 2, button.w, button.h, 8)

  love.graphics.setColor(0.2, 0.8, 1)
  love.graphics.rectangle("line", -button.w / 2, -button.h / 2, button.w, button.h, 8)

  love.graphics.setColor(1, 1, 1)
  love.graphics.printf(button.label, -button.w / 2, -7, button.w, "center")
  love.graphics.pop()
end
```

## Docs

- [Guides](https://kyonru.github.io/feel.lua)

## How does it work?

It wraps a vendored copy of [flux](https://github.com/rxi/flux) by [rxi](https://github.com/rxi) so you can describe game feel as small Lua recipes: animation, timing, emitted effects, audio cues, callbacks, random choices, loops, and grouped steps.

The core stays small and table-driven. LOVE-specific work lives in optional adapters or user callbacks.

## Tests

```sh
busted spec
```
