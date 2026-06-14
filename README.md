# feel.lua

`feel.lua` is a tiny LOVE2D-first feedback sequencing library for making actions feel good.

## What It Does

- Defines reusable named feedback sequences with `feel.define`.
- Plays named or inline sequences with `feel.play`.
- Animates lightweight target values.
- Emits host-owned events for particles, camera shake, flashes, sounds, haptics, shaders, and more.
- Runs steps in order, including waits, nested sequences, repeats, random branches, and parallel groups.
- Controls individual runs (stop, pause, resume, completion signals) and the whole clock (global pause, time scale).
- Routes gameplay intents to feedback with lightweight `feel.channel()` pub/sub.
- Optionally groups adapter events into named feedback stacks with `feel.feedbacks`.

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

## Controlling A Run

`feel.play` returns a control handle, so you can stop, pause, resume, or react to a single run:

```lua
local run = feel.play("ship.charge", ship, { restart = true, key = "charge" })
run:pause()
run:resume()
run:onComplete(function() print("charged") end)

feel.pauseAll()        -- freeze everything
feel.setTimeScale(0.5) -- or run the whole feel clock at half speed
```

## Routing With Channels

Decouple "what happened" in gameplay from "what feedback plays" with a channel:

```lua
local feedback = feel.channel()

feedback:on("enemy.killed", function(event)
  feel.play("ship.hit", event.target, { restart = true, key = "ship.hit" })
end)

feedback:emit("enemy.killed", { target = ship })
```

There is also a no-LOVE [core example](examples/core): `lua examples/core/main.lua`.

## Docs

- [Guides](https://kyonru.github.io/feel.lua)
- [Changelog](CHANGELOG.md)

## Optional Feedback Authoring

`feel.feedbacks` lets gameplay call one named feedback while a feedback module owns the actual camera, post, sound, time, and 3D adapter events:

```lua
local Feedbacks = require("lib.feel.feedbacks").new({ love = fx, g3d = g3dfx })

Feedbacks.define("hit.heavy", {
  { kind = "time.freeze", duration = 0.04 },
  { kind = "screen.flash", amount = 0.3, duration = 0.08 },
  { kind = "g3d.camera.shake", amount = 0.14, duration = 0.16 },
})

Feedbacks.play("hit.heavy", { x = enemy.x, y = enemy.y, z = enemy.z })
```

## Optional g3d Helpers

`feel.g3d` can bind animated target values to app-owned [g3d](https://github.com/groverburger/g3d) models and cameras:

```lua
local feel = require("lib.feel")
local feelG3d = require("lib.feel.g3d")
local g3d = require("g3d")

local g3dfx = feelG3d.new(g3d)
local shipModel = g3d.newModel("ship.obj", "ship.png")
local ship = g3dfx:model("ship", shipModel, {
  values = { x = 0, y = 0, z = 0, rz = 0, scale = 1 },
})

feel.define("ship.hit", {
  { kind = "animate", to = { scale = 1.2, rz = 0.15 }, duration = 0.06 },
  { kind = "animate", to = { scale = 1, rz = 0 }, duration = 0.22, ease = "backout" },
})

function love.update(dt)
  feel.update(dt)
  g3dfx:update()
end
```

## Optional Menori Helpers

`feel.menori` can bind animated target values to app-owned [Menori](https://github.com/rozenmad/Menori) nodes, cameras, glTF animations, and uniforms:

```lua
local feel = require("lib.feel")
local feelMenori = require("lib.feel.menori")
local menori = require("menori")

local menorifx = feelMenori.new(menori, { environment = environment })
local ship = menorifx:node("ship", shipNode, {
  values = { x = 0, y = 0, z = 0, rz = 0, scale = 1 },
})

feel.define("ship.hit", {
  { kind = "emit", event = "menori.node.scalePunch", payload = { name = "ship", amount = 0.2, duration = 0.06 } },
  { kind = "emit", event = "menori.camera.shake", payload = { amount = 0.06, duration = 0.14 } },
})

feel.play("ship.hit", ship, menorifx:handlers())

function love.update(dt)
  feel.update(dt)
  menorifx:update(dt)
end
```

## How does it work?

It wraps a vendored copy of [flux](https://github.com/rxi/flux) by [rxi](https://github.com/rxi) so you can describe game feel as small Lua recipes: animation, timing, emitted effects, audio cues, callbacks, random choices, loops, and grouped steps.

The core stays small and table-driven. LOVE-specific work lives in optional adapters or user callbacks.

## Tests

```sh
make test   # busted spec
make lint   # luacheck .
make core   # run the no-LOVE core example
```
