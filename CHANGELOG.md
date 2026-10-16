# Changelog

## Unreleased

- Added a standalone, core-independent `feel.haptics` module with its own update clock, a hardware-independent driver API, an expanded expressive preset catalog, reusable timed pulse patterns, a Pulsar-inspired timeline composer with continuous/pulse/curve segments and overlap resolution, playback handles, defensive pattern discovery, master intensity and enable controls, per-target restart/cancellation, generated-pulse safety limits, and editor type definitions. The LOVE adapter now delegates its haptic API to this engine and adds safe device replacement/removal and reset-time vibration cleanup.
- Added a practical Recipes guide with copyable UI, combat, pickup, loop, transition, channel, and preset patterns.
- Fixed cancellation of parallel runs so stopping or restarting a parent reliably cancels every child branch, and target-specific clear now cancels the owning run tree instead of stranding its parent.
- Made nested pause state compositional: children remain effectively paused while an ancestor is paused, and independently paused branches stay paused when a parent resumes.
- Stabilized raw and sequenced springs across large frame deltas by internally substepping integration.
- Fixed `feel.feedbacks` support for core `spring` steps and nested named feedbacks.
- Added cycle detection for named sequence validation and richer `feel.active()` spring/pause diagnostics.
- Improved LuaLS definitions for Menori methods, LOVE adapter reset, raw springs, and the now-documented preset module.
- Avoided redundant g3d projection matrix updates when the applied field of view has not changed.

## v1.3.0 - 2026-06-14

All changes are additive and backward compatible.

- Per-run control: `feel.play` returns a handle with `stop`, `pause`, `resume`, `isPlaying`,
  and `isPaused`, plus the matching free functions `feel.stop/pause/resume(ctx)`. Pausing a
  run freezes its tweens and waits (and its `parallel`/`play`/`repeat` subtree) and resumes
  exactly where it left off.
- Run-level signals: `run:onComplete(fn)` and `run:onStop(fn)` (chainable; late
  registration on a finished run fires immediately).
- Global controls: `feel.pauseAll`, `feel.resumeAll`, `feel.isPausedAll`, and
  `feel.setTimeScale` / `feel.timeScale` (independent of the `feel.feedbacks` time scale).
- Field aliases centralized; `feel.strictAliases(true)` opts into one-time deprecation
  warnings for redundant named aliases (`time`, `fn`, `times`, `chance`, `text`). `animate`
  now also accepts `time` as a `duration` alias.
- CI now tests Lua 5.1, 5.2, 5.3, 5.4, and LuaJIT, and runs Luacheck (`.luacheckrc` added).
- New docs: Core Example (no-LOVE), Writing a Custom Adapter, Best Practices, and
  Troubleshooting; channel usage surfaced in Getting Started and the Core Runner guide.
- New `examples/core` plain-Lua example (`make core`).
- New `spring` step kind: drive `target.values` with a damped harmonic oscillator
  instead of a fixed-duration tween. `to` moves the rest anchor (transitions);
  `pull` applies an instantaneous impulse that springs back to the anchor
  (impact punches). Tunable via `stiffness`/`k`, `damping`/`d`, `settle`/`epsilon`,
  and an optional `duration` cap; supports `from`/`onStart`/`onUpdate`/`onComplete`
  like `animate`, and pauses/resumes/clears with its run.
- New `feel.spring(x, stiffness, damping)` primitive: a raw spring you drive
  yourself with `spring:update(dt)`, `spring:pull(force)`, `spring:animate(target)`,
  and `spring:settled(epsilon)` — for spring motion outside a sequence.

## v1.2.1 - 2026-06-12

- `animate` steps now apply custom numeric value fields from `from`, matching the
  `copyNumericFields` policy already used by targets and the `to` table. Restarted
  sequences snap custom fields (e.g. hit-flash values) back to their `from` value.

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
