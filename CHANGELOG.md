# Changelog

## v1.2.0 - 2026-06-11

- Added the optional Menori adapter for binding `feel.target` values to Menori nodes, cameras, animation controls, material uniforms, and feedback handlers.
- Added generated documentation GIFs for the feature gallery and representative guide pages, including refreshed polished GIF assets.
- Added project funding metadata and removed hardcoded funding configuration from the docs/site setup.
- Added the project `LICENSE`.
- Added a GitHub release workflow that packages the `feel.lua` library archive for tagged releases.

## v1.0.0 - 2026-06-07

Initial stable release of `feel.lua`.

- Core sequence runner: `define`, `play`, `update`, `clear`, waits, callbacks, emits, audio cues, nested play, parallel steps, repeats, random choices, restart keys, validation, and debug introspection.
- Tweenable targets with custom numeric values for gameplay/UI juice.
- LOVE adapter for screen flash/fade, camera feedback, sounds, haptics, particles, shaders, and canvas-backed post-processing.
- Optional feedback authoring layer with named feedback stacks, context values, shorthand adapter events, and explicit time scale feedback.
- Optional g3d helper for animating model transforms and camera feedback without owning rendering or game state.
- LuaLS annotations, docs, and runnable examples including Asteroidz and the 3D g3d demo.
