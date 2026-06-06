---
icon: lucide/box
---

# g3d Helpers

`feel.g3d` is an optional helper for [groverburger/g3d](https://github.com/groverburger/g3d). It binds `feel.target` values to app-owned g3d models and cameras. It does not load assets, draw models, wrap collisions, or replace g3d controls.

## Setup

Install g3d separately and require both libraries in your LOVE project:

```lua
local feel = require("feel")
local feelG3d = require("feel.g3d")
local g3d = require("g3d")

local g3dfx = feelG3d.new(g3d)
```

If Feather installs `feel.lua` under `lib/feel`, require the helper with the same prefix:

```lua
local feel = require("lib.feel")
local feelG3d = require("lib.feel.g3d")
```

## Model Targets

Register an app-created g3d model and animate the returned target:

```lua
local shipModel = g3d.newModel("assets/ship.obj", "assets/ship.png")
local ship = g3dfx:model("ship", shipModel, {
  values = {
    x = 0, y = 0, z = 0,
    rx = 0, ry = 0, rz = 0,
    scale = 1,
  },
})

feel.define("ship.hit", {
  { kind = "animate", to = { scale = 1.18, rz = 0.16 }, duration = 0.06, ease = "quadout" },
  { kind = "animate", to = { scale = 1, rz = 0 }, duration = 0.22, ease = "backout" },
})

function love.update(dt)
  feel.update(dt)
  g3dfx:update()
end
```

`g3dfx:update()` applies values to g3d:

| Target values | g3d method |
| --- | --- |
| `x`, `y`, `z` | `model:setTranslation(x, y, z)` |
| `rx`, `ry`, `rz` | `model:setRotation(rx, ry, rz)` |
| `sx`, `sy`, `sz` | `model:setScale(sx, sy, sz)` |
| `scale` | Uniform fallback for `sx`, `sy`, and `sz` |

Drawing stays normal g3d code:

```lua
function love.draw()
  shipModel:draw()
end
```

## Camera Targets

Use `mode = "lookAt"` for camera position plus target point:

```lua
local camera = g3dfx:camera({
  mode = "lookAt",
  values = {
    x = 0, y = -8, z = 4,
    tx = 0, ty = 0, tz = 0,
  },
})

feel.define("camera.punch", {
  { kind = "animate", to = { z = 3.5 }, duration = 0.08, ease = "quadout" },
  { kind = "animate", to = { z = 4 }, duration = 0.26, ease = "backout" },
})
```

Use `mode = "direction"` when you want to drive `g3d.camera.lookInDirection`:

```lua
local camera = g3dfx:camera({
  mode = "direction",
  values = { x = 0, y = -8, z = 4, direction = 0, pitch = 0 },
})
```

## Events

Pass `g3dfx:handlers(extra)` to `feel.play` when a sequence should issue direct g3d events:

```lua
feel.define("ship.face.origin", {
  { kind = "emit", event = "g3d.model.lookAt", payload = { name = "ship", x = 0, y = 0, z = 0 } },
})

feel.play("ship.face.origin", ship, g3dfx:handlers({
  emit = function(event)
    print(event.kind)
  end,
}))
```

Supported events:

| Event | Payload |
| --- | --- |
| `g3d.model.lookAt` | `{ name, x, y, z, up? }` |
| `g3d.camera.lookAt` | `{ x, y, z, tx, ty, tz }` |
| `g3d.camera.direction` | `{ x, y, z, direction, pitch }` |
| `g3d.camera.resize` | `{ width, height }` |
| `g3d.camera.shake` | `{ amount, duration, frequency? }` |
| `g3d.camera.fov` | `{ amount, duration, returnDuration? }` |
| `g3d.camera.height` | `{ amount, duration, returnDuration? }` |
| `g3d.camera.yaw` | `{ amount, duration, returnDuration?, radians? }` |
| `g3d.camera.targetOffset` | `{ x, y, z, duration, returnDuration? }` |
| `g3d.camera.reset` | `{ duration? }` |
| `g3d.model.scalePunch` | `{ name, amount, duration, returnDuration? }` |
| `g3d.model.squash` | `{ name, amount, duration, returnDuration? }` |
| `g3d.model.positionShake` | `{ name, amount, duration, frequency? }` |
| `g3d.model.rotationShake` | `{ name, amount, duration, frequency? }` |
| `g3d.model.reset` | `{ name, duration? }` |

Unknown events are ignored by the helper and still forwarded to your `extra.emit` callback.

Camera feedback is applied to g3d camera parameters. Do not use the 2D `feel.love` camera push/pop helpers for a 3D world; bind a g3d camera target and animate fields such as `shakeX`, `heightKick`, `fovKick`, `yawKick`, and `targetOffsetX/Y/Z`.

For higher-level feedback manifests, see [Feedback Authoring](feedbacks.md).
