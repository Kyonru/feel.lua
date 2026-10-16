# Feel Haptics

Feel Haptics is the standalone, dependency-free haptic pattern engine from
[feel.lua](https://github.com/Kyonru/feel.lua). It does not load the Feel runner or LOVE.

Keep the included `feel/` directory in your project and create an engine with a driver for
your platform:

```lua
local Haptics = require("feel.haptics")

local haptics = Haptics.new({
  play = function(pulse)
    platform.rumble(pulse.left, pulse.right, pulse.duration)
    return true
  end,
  stop = function()
    platform.stopRumble()
    return true
  end,
})

haptics:play("success")

function update(dt)
  haptics:update(dt)
end
```

The engine includes semantic and expressive presets, direct pulse sequences, timestamped
continuous/pulse/curve segments, intensity scaling, cancellation, and playback handles.

See the [haptics guide](https://kyonru.github.io/feel.lua/haptics/) for the complete API,
pattern examples, and LOVE controller integration.

The `types/` directory contains the optional LuaLS definition. The library is distributed
under the MIT license in `LICENSE`.
