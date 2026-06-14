# feel.lua Core-Only Example

A plain-Lua example of the `feel.lua` core runner with **no LOVE and no graphics**. It
shows targets, a named recipe, a feedback channel, `emit`/`log` handlers, a run-level
`onComplete` signal, and a manual fixed-step loop.

Run it from the repository root:

```sh
lua examples/core/main.lua
```

or:

```sh
make core
```

The core needs nothing but standard Lua: `feel.update(dt)` advances tweens and waits,
and your code reads `target.values` to do something with the animated numbers. Here the
"something" is just printing each frame, but in a game it would be your render code.
