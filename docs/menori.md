---
icon: lucide/cuboid
---

# Menori Helpers

`feel.menori` is an optional helper for [rozenmad/Menori](https://github.com/rozenmad/Menori). It binds `feel.target` values to app-owned Menori nodes, perspective cameras, glTF animation controllers, and `UniformList` objects. It does not load assets, own scenes, render nodes, or replace Menori controls.

For a runnable LOVE project, see `examples/menori`.

## Setup

Install Menori separately and require both libraries in your LOVE project:

```lua
local feel = require("feel")
local feelMenori = require("feel.menori")
local menori = require("menori")

local menorifx = feelMenori.new(menori)
```

If Feather installs `feel.lua` under `lib/feel`, require the helper with the same prefix:

```lua
local feel = require("lib.feel")
local feelMenori = require("lib.feel.menori")
```

## Node Targets

Register any app-created `menori.Node` or `menori.ModelNode` and animate the returned target:

```lua
local ship = menorifx:node("ship", shipNode, {
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
  menorifx:update(dt)
  scene:update_nodes(root_node, environment)
end
```

`menorifx:update(dt)` applies values to Menori:

| Target values | Menori method |
| --- | --- |
| `x`, `y`, `z` | `node:set_position(x, y, z)` |
| `rx`, `ry`, `rz` | `node:set_rotation(quat.from_euler_angles(rz, ry, rx))` |
| `sx`, `sy`, `sz` | `node:set_scale(sx, sy, sz)` |
| `scale` | Uniform fallback for `sx`, `sy`, and `sz` |

Use `menorifx:model(...)` as an alias when the bound node is a `ModelNode`.

## Camera Targets

Bind a `menori.PerspectiveCamera` or its `menori.Environment`. Passing the environment lets the adapter keep a `view_position` uniform in sync for lighting shaders:

```lua
local camera = menori.PerspectiveCamera(60, width / height, 0.5, 1024)
local environment = menori.Environment(camera)

local cameraTarget = menorifx:camera(environment, {
  mode = "lookAt",
  fov = 60,
  aspect = width / height,
  near = 0.5,
  far = 1024,
  values = {
    x = 0, y = 1.5, z = 5,
    tx = 0, ty = 0.8, tz = 0,
  },
})
```

Use `mode = "orbit"` for Menori-style orbital cameras:

```lua
local orbit = menorifx:camera(environment, {
  mode = "orbit",
  values = {
    tx = 0, ty = 0.5, tz = 0,
    distance = 4,
    yaw = 0,
    pitch = math.rad(12),
  },
})
```

Use `mode = "direction"` when you want an eye position plus yaw/pitch direction. Camera rotations use radians. FOV values and FOV feedback amounts use Menori's degree-based projection API.

## Animations

Bind a Menori `glTFAnimations` controller so `menorifx:update(dt)` advances it with feedback-controlled speed and play state:

```lua
local animation = menorifx:animation("hero", animations, {
  action = "Idle",
  values = { speed = 1, playing = 1 },
})

feel.define("hero.hitstop", {
  { kind = "emit", event = "menori.animation.speed", payload = { name = "hero", speed = 0.15, duration = 0.04 } },
  { kind = "emit", event = "menori.animation.speed", payload = { name = "hero", speed = 1, duration = 0.1 } },
})

feel.play("hero.hitstop", nil, menorifx:handlers())
```

For cutscenes or authored timelines, pass `driveTime = true` and animate `time`; the adapter will set `animations.accumulator` and apply the pose with `animations:update(0)`.

## Uniforms

Bind Menori `UniformList` objects such as `Environment`, materials, or custom lights:

```lua
local tint = menorifx:uniform("ship.tint", shipNode.material, "baseColor", {
  keys = { "r", "g", "b", "a" },
  values = { r = 0.85, g = 0.95, b = 1, a = 1 },
})

feel.define("ship.flash", {
  {
    kind = "emit",
    event = "menori.uniform.pulse",
    payload = { name = "ship.tint", values = { r = 1, g = 0.25, b = 0.15 }, duration = 0.04 },
  },
})

feel.play("ship.flash", nil, menorifx:handlers())
```

Use the default `set` mode with `keys` for material vector uniforms such as `baseColor`, `type = "vector"` for `set_vector`, and `type = "color"` only when you explicitly want Menori's `set_color` path.

## Feedbacks

`feel.feedbacks` can route Menori shorthand events when you pass the adapter:

```lua
local Feedbacks = require("feel.feedbacks").new({
  menori = menorifx,
})

Feedbacks.define("hit.heavy", {
  { kind = "menori.camera.shake", amount = 0.08, duration = 0.14 },
  { kind = "menori.camera.fov", amount = 4, duration = 0.05, returnDuration = 0.18 },
  { kind = "menori.node.scalePunch", name = "enemy", amount = 0.2, duration = 0.06 },
})
```

When combining Menori with `feel.love` post-processing, render the Menori scene into a color canvas with a depth attachment first, then pass that finished image through `fx:drawPost(...)`. The runnable `examples/menori` project does this so post effects do not remove depth testing from the 3D pass.

## Events

Supported events:

| Event | Payload |
| --- | --- |
| `menori.node.lookAt` | `{ name, x, y, z, up? }` |
| `menori.node.visible` | `{ name, visible }` |
| `menori.node.scalePunch` | `{ name, amount, duration, returnDuration? }` |
| `menori.node.squash` | `{ name, amount, duration, returnDuration? }` |
| `menori.node.positionShake` | `{ name, amount, duration, frequency? }` |
| `menori.node.rotationShake` | `{ name, amount, duration, frequency? }` |
| `menori.node.reset` | `{ name, duration? }` |
| `menori.camera.lookAt` | `{ x, y, z, tx, ty, tz, upX?, upY?, upZ? }` |
| `menori.camera.orbit` | `{ x, y, z, distance, yaw, pitch?, roll? }` |
| `menori.camera.projection` | `{ fov, aspect, near, far }` |
| `menori.camera.shake` | `{ amount, duration, frequency? }` |
| `menori.camera.fov` | `{ amount, duration, returnDuration? }` |
| `menori.camera.height` | `{ amount, duration, returnDuration? }` |
| `menori.camera.yaw` | `{ amount, duration, returnDuration?, radians? }` |
| `menori.camera.distance` | `{ amount, duration, returnDuration? }` |
| `menori.camera.targetOffset` | `{ x, y, z, duration, returnDuration? }` |
| `menori.camera.reset` | `{ duration? }` |
| `menori.animation.action` | `{ name, action? }` or `{ name, actionIndex? }` |
| `menori.animation.play` | `{ name, action?, actionIndex?, speed? }` |
| `menori.animation.pause` | `{ name }` |
| `menori.animation.stop` | `{ name }` |
| `menori.animation.seek` | `{ name, time }` |
| `menori.animation.speed` | `{ name, speed, duration? }` |
| `menori.uniform.set` | `{ name, values, duration? }` |
| `menori.uniform.pulse` | `{ name, values, duration, returnDuration? }` |
| `menori.uniform.reset` | `{ name, duration? }` |

Unknown events are ignored by the helper and still forwarded to your `extra.emit` callback.
