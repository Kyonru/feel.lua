---
icon: lucide/scan-heart
---

# feel.lua Docs

`feel.lua` is split into a tiny core recipe runner and opt-in LOVE helpers. These docs group related features together so you can read the layer you are working in.

## What To Read First

1. [Installation](installation.md): add the core module and, optionally, the LOVE adapter.
2. [Getting Started](getting-started.md): build a minimal LOVE loop with one animated target and one sequence.
3. [Sequence Steps](sequence-steps.md): learn the table shapes that make up a recipe.
4. [LOVE Adapter](love-adapter.md): connect recipe events to sounds, haptics, particles, shaders, camera, screen, and post effects.
5. [LOVE Examples](love-examples.md): run the showcase or the Asteroidz example.

## Guides

| Page | Use it for |
| --- | --- |
| [Core Runner](core-runner.md) | Targets, named sequences, playback, updates, clearing, and callback context. |
| [Sequence Steps](sequence-steps.md) | `animate`, `emit`, `audio`, `wait`, `play`, `parallel`, `repeat`, `random`, `callback`, and `log`. |
| [API](api.md) | Compact function signatures, options, and exported helpers. |
| [Autocomplete](autocomplete.md) | LuaLS setup, local definition files, LOVE2D types, and custom target values. |
| [LOVE Adapter](love-adapter.md) | Registered sound cues, haptics, particle systems, shaders, post-processing, camera events, screen overlays, and adapter handlers. |
| [Post Processing](post-processing.md) | Built-in LOVE canvas effects, parameters, and recipes. |
| [g3d Helpers](g3d.md) | Optional helpers for binding `feel.target` values to groverburger/g3d models and cameras. |
| [LOVE Examples](love-examples.md) | Showcase scenes and feature-specific examples. |
| [Asteroidz Walkthrough](asteroidz.md) | A small game showing sequences, post-processing, UI juice, and adapter events together. |
