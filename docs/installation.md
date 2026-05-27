---
icon: lucide/download
---

# Installation

`feel.lua` can be installed as a package or copied directly into a LOVE project. The core runner and LOVE adapter share the same package root.

## Option 1: [Feather](https://kyonru.github.io/feather/installation/)

Install the verified [Feather package](https://kyonru.github.io/feather/packages/#feather-package-install-name-name2):

```sh
feather package install feel
```

Feather installs the package under `lib/feel`, so require it with:

```lua
local feel = require("lib.feel")
local feelLove = require("lib.feel.love")
```

## Option 2: Manual Copy

Copy `feel.lua` and the `feel/` directory into your project, then require it:

```lua
local feel = require("feel")
local feelLove = require("feel.love")
```

The root `feel.lua` file is a small loader shim. The implementation lives in `feel/init.lua`, and `feel/vendor/flux.lua` is bundled.

Create the LOVE adapter only when you need registered side effects:

```lua
local fx = feelLove.new()
```

## Update Loop

Call `feel.update(dt)` once per frame. If you use the LOVE adapter, call `fx:update(dt)` too.

```lua
function love.update(dt)
  feel.update(dt)
  fx:update(dt)
end
```

If you are using only the core runner, omit the adapter require and `fx:update(dt)`.
