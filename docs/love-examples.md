# LOVE Examples

Run the showcase from the repository root:

```sh
love examples/love2d
```

The showcase uses left and right arrows to move between feature scenes. Each scene keeps its own sequences, targets, adapter instance, and local state.

## Scenes

- `scenes/feedback_stack.lua`: a full recipe stack with animation, audio, emit events, callbacks, particles, beams, shake, and flash.
- `scenes/sound_controls.lua`: registered LOVE cue alternates plus `sound.volume`, `sound.pitch`, and `sound.pan`.
- `scenes/camera_screen.lua`: `camera.shake`, `camera.move`, `camera.zoom`, `camera.reset`, `screen.flash`, `screen.fade`, and `screen.clear`.

## Adding A Scene

Create a module in `examples/love2d/scenes/` that returns a table with a `title`, `summary`, and any callbacks it needs:

```lua
local Scene = {
  title = "New Feature",
  summary = "Short description.",
}

function Scene.load(ctx) end
function Scene.update(ctx, dt) end
function Scene.draw(ctx) end
function Scene.keypressed(ctx, key) end

return Scene
```

Add the module to the `scenes` list in `examples/love2d/main.lua`.
