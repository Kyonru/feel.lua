---
icon: lucide/wand-sparkles
---

# Autocomplete

`feel.lua` ships LuaCATS annotations for [LuaLS](https://luals.github.io/wiki/). The repository includes a `.luarc.json` that loads the compact definition files in `types/`, so editors that use LuaLS can infer the public API from:

```lua
local feel = require("feel")
local feelLove = require("feel.love")
local feelG3d = require("feel.g3d")

local target = feel.target({ values = { scale = 1, teleportGlow = 0 } })
local fx = feelLove.new()
local g3dfx = feelG3d.new(g3d)
```

## What Should Complete

- `feel.target`, `feel.define`, `feel.play`, `feel.update`, and `feel.clear`.
- `feelLove.new`.
- Adapter methods on `fx`, including `sound`, `particle`, `shader`, `emit`, `setPost`, and `drawPost`.
- Optional g3d helper methods on `g3dfx`, including `model`, `camera`, `update`, `emit`, and `handlers`.
- Common adapter event payloads such as `post.tween`, `screen.flash`, `camera.shake`, `particle.emit`, and `sound.volume`.
- Post-processing values, including bloom `intensity`, `threshold`, `softness`, and `passes`.
- Custom numeric target values such as `teleportGlow`, `glow`, or `charge`.

Custom target fields autocomplete best when they are declared in `values` when the target is created:

```lua
local ship = feel.target({
  values = {
    scale = 1,
    teleportGlow = 0,
  },
})

feel.play({
  { kind = "animate", to = { teleportGlow = 1 }, duration = 0.08 },
}, ship)
```

## LOVE2D Types

The project config declares `love` as a known global, but it does not vendor LOVE2D API definitions. For richer `love.graphics`, `love.audio`, and `love.joystick` completion, install external definitions such as [LuaCATS/love2d](https://github.com/LuaCATS/love2d), then add that definition directory to your own LuaLS `workspace.library`.

Example local override:

```json
{
  "workspace.library": [
    "types",
    "../love2d/library"
  ]
}
```

Use the path that matches where you installed the LOVE2D definitions.

## Checking Diagnostics

If `lua-language-server` is installed, use its check/diagnostic command against the workspace to validate annotations. If it is not installed, the source still remains valid Lua and the annotations are ignored at runtime.
