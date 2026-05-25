---
icon: lucide/download
---

# Installation

## Option 1: Feather

Install the verified Feather package:

```sh
feather package install feel
```

Feather installs the package under `lib/feel`, so require it with:

```lua
local feel = require("lib.feel")
```

## Option 2: Manual Copy

Copy `feel.lua` and the `feel/` directory into your project, then require it:

```lua
local feel = require("feel")
```

The root `feel.lua` file is a small loader shim. The implementation lives in `feel/init.lua`, and `feel/vendor/flux.lua` is bundled.

For LOVE2D helper features, also require the optional adapter:

```lua
local feelLove = require("feel.love")
local fx = feelLove.new()
```

If you installed through Feather and want the LOVE adapter before it is included in your catalog install, copy `feel/love.lua` into your project and require it from the same package root you use for `feel`.

Call `feel.update(dt)` once per frame. If you use the LOVE adapter, call `fx:update(dt)` too.
