---
icon: lucide/play
---

# LOVE Examples

Run the showcase from the repository root:

```sh
love examples/love2d
```

The showcase uses left and right arrows to move between feature scenes. Each scene keeps its own sequences, targets, adapter instance, and local state.

Run the standalone Asteroidz example:

```sh
love examples/asteroidz
```

Asteroidz is a small arcade game that uses `feel` sequences for thrust, shooting, asteroid hits, ship explosions, teleport bloom, HUD pulses, camera shake, screen flash, post-processing, and procedural audio cues. See the [Asteroidz Walkthrough](asteroidz.md) for how those pieces fit together.

Run the standalone g3d example:

```sh
love examples/3d
```

The g3d demo uses `feel.g3d` to bind animated target values to app-owned g3d models and camera state. It shows a model wobble, camera punch, and `g3d.model.lookAt` event without wrapping rendering or assets.

## Scenes

- `scenes/feedback_stack.lua`: a full recipe stack with animation, audio, emit events, callbacks, particles, beams, shake, and flash.
- `scenes/restart.lua`: side-by-side core playback showing stacked plays versus `restart = true`.
- `scenes/sound_controls.lua`: registered LOVE cue alternates plus `sound.volume`, `sound.pitch`, and `sound.pan`.
- `scenes/particles.lua`: registered LOVE `ParticleSystem`s driven by `particle.emit`, `particle.start`, `particle.stop`, `particle.reset`, and `particle.move`.
- `scenes/shaders.lua`: registered LOVE `Shader`s driven by `shader.send`, `shader.tween`, `shader.apply`, and `shader.clear`.
- `scenes/post_processing.lua`: canvas-backed post effects driven by `post.set`, `post.tween`, `post.weight`, and `post.clear`.
- `scenes/haptics.lua`: registered joystick rumble plus mobile/system vibration driven by `haptic.play`, `haptic.stop`, and `haptic.vibrate`.
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
