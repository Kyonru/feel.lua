---
icon: lucide/scan-heart
---

# feel.lua Docs

## What Is feel.lua?

`feel.lua` is a small feedback sequencing library for Löve. It lets you describe moment-to-moment game feel as reusable Lua recipes: tween these values, wait, play these steps in parallel, emit this particle/sound/shake event, then settle back.

The core does not own your rendering, audio, particles, shaders, models, or game objects. You keep those in your app. `feel.lua` owns the timing and target values, then hands side effects back to you through callbacks or optional adapters.

Use it when an action should read better: a button press, player hit, reward reveal, camera punch, UI pulse, shader sweep, sound cue, haptic tick, or a named feedback stack that combines several of those at once.

## Structure

`feel.lua` is split into a tiny core recipe runner and opt-in LOVE helpers. These docs group related features together so you can read the layer you are working in.

## What To Read First

1. [Installation](installation.md): add the core module and, optionally, the LOVE adapter.
2. [Getting Started](getting-started.md): build a minimal LOVE loop with one animated target and one sequence.
3. [Sequence Steps](sequence-steps.md): learn the table shapes that make up a recipe.
4. [LOVE Adapter](love-adapter.md): connect recipe events to sounds, haptics, particles, shaders, camera, screen, and post effects.
5. [LOVE Examples](love-examples.md): run the showcase or the Asteroidz example.

## Guides

| Page                                  | Use it for                                                                                                                        |
| ------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| [Core Runner](core-runner.md)         | Targets, named sequences, playback, updates, clearing, and callback context.                                                      |
| [Sequence Steps](sequence-steps.md)   | `animate`, `emit`, `audio`, `wait`, `play`, `parallel`, `repeat`, `random`, `callback`, and `log`.                                |
| [API](api.md)                         | Compact function signatures, options, and exported helpers.                                                                       |
| [Autocomplete](autocomplete.md)       | LuaLS setup, local definition files, LOVE2D types, and custom target values.                                                      |
| [LOVE Adapter](love-adapter.md)       | Registered sound cues, haptics, particle systems, shaders, post-processing, camera events, screen overlays, and adapter handlers. |
| [Post Processing](post-processing.md) | Built-in LOVE canvas effects, parameters, and recipes.                                                                            |
| [g3d Helpers](g3d.md)                 | Optional helpers for binding `feel.target` values to groverburger/g3d models and cameras.                                         |
| [Menori Helpers](menori.md)           | Optional helpers for binding `feel.target` values to Menori nodes, cameras, animations, and uniforms.                             |
| [LOVE Examples](love-examples.md)     | Showcase scenes and feature-specific examples.                                                                                    |
| [Asteroidz Walkthrough](asteroidz.md) | A small game showing sequences, post-processing, UI juice, and adapter events together.                                           |

<!-- feel:feature-gif-gallery -->

## Feature GIFs

| Feature         | Preview                                                                                                                                 |
| --------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| Getting Started | ![Animated GIF showing a Feel.lua button press sequence with glow and sparks.](assets/feature-gifs/getting-started.gif)                 |
| Animate         | ![Animated GIF showing Feel.lua animate steps moving and scaling a card.](assets/feature-gifs/animate.gif)                              |
| Easing          | ![Animated GIF comparing linear, quadout, sineinout, backout, elasticout, and bounceout easing motion.](assets/feature-gifs/easing.gif) |
| Sequence        | ![Animated GIF showing Feel.lua steps running one after another.](assets/feature-gifs/sequence.gif)                                     |
| Parallel        | ![Animated GIF showing parallel Feel.lua branches animating together.](assets/feature-gifs/parallel.gif)                                |
| Repeat          | ![Animated GIF showing a repeated Feel.lua step ticking three times.](assets/feature-gifs/repeat.gif)                                   |
| Random          | ![Animated GIF showing a deterministic random branch choosing one weighted result.](assets/feature-gifs/random.gif)                     |
| Callbacks       | ![Animated GIF showing emit, audio, callback, and log events landing in an event stream.](assets/feature-gifs/callbacks.gif)            |
| Pulse           | ![Animated GIF showing a target pulse with scale and glow feedback.](assets/feature-gifs/pulse.gif)                                     |
| Shake           | ![Animated GIF showing Feel.lua camera shake applied to a small game scene.](assets/feature-gifs/shake.gif)                             |
| Flash           | ![Animated GIF showing a screen flash overlay after an impact.](assets/feature-gifs/flash.gif)                                          |
| Sound           | ![Animated GIF showing sound volume, pitch, and pan feedback meters.](assets/feature-gifs/sound.gif)                                    |
| Haptics         | ![Animated GIF showing left and right haptic rumble meters driven by feedback.](assets/feature-gifs/haptics.gif)                        |
| Particles       | ![Animated GIF showing particle bursts emitted from a Feel.lua event.](assets/feature-gifs/particles.gif)                               |
| Shader          | ![Animated GIF showing a shader uniform pulse around an actor.](assets/feature-gifs/shader.gif)                                         |
| Post Processing | ![Animated GIF showing bloom and chromatic post-processing feedback on a scene.](assets/feature-gifs/post-processing.gif)               |
| Feedbacks       | ![Animated GIF showing one named feedback stack triggering camera, flash, post, and model cues.](assets/feature-gifs/feedbacks.gif)     |
| LOVE2D          | ![Animated GIF showing Feel.lua driving a compact LOVE2D mini-scene.](assets/feature-gifs/love2d.gif)                                   |
| g3d             | ![Animated GIF showing Feel.lua g3d helper-style model and camera feedback in a 3D scene.](assets/feature-gifs/g3d.gif)                 |
| Menori          | ![Animated GIF showing Feel.lua Menori helper-style node, camera, animation, and uniform feedback.](assets/feature-gifs/menori.gif)     |

<!-- /feel:feature-gif-gallery -->
