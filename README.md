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
  values = { scale = 1, y = 0 },
})

feel.define("button.press", {
  { kind = "animate", duration = 0.06, to = { scale = 0.92, y = 3 }, ease = "quadout" },
  { kind = "wait", duration = 0.03 },
  { kind = "animate", duration = 0.16, to = { scale = 1, y = 0 }, ease = "backout" },
})

function love.update(dt)
  feel.update(dt)
end

function love.mousepressed()
  feel.play("button.press", button, { restart = true })
end
```

## Docs

- [Installation](docs/installation.md)
- [Getting Started](docs/getting-started.md)
- [API](docs/api.md)
- [Core Runner](docs/core-runner.md)
- [Sequence Steps](docs/sequence-steps.md)
- [LOVE Adapter](docs/love-adapter.md)
- [Post Processing](docs/post-processing.md)
- [LOVE Examples](docs/love-examples.md)

## How does it work?

It wraps a vendored copy of [flux](https://github.com/rxi/flux) by [rxi](https://github.com/rxi) so you can describe game feel as small Lua recipes: animation, timing, emitted effects, audio cues, callbacks, random choices, loops, and grouped steps.

The core stays small and table-driven. LOVE-specific work lives in optional adapters or user callbacks.

## Tests

```sh
busted spec
```
