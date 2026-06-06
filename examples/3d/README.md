# feel.lua + g3d Demo

Small LOVE project showing `feel.g3d` with [groverburger/g3d](https://github.com/groverburger/g3d).

Run it from the repository root:

```sh
love examples/3d
```

Controls:

- `Space` / left click: play model wobble, rock bounce, and camera punch sequences.
- `L`: cycle the ship through look-at objectives: right rock, rear rock, left rock, then main pose.
- `R`: reset animated targets.
- `Esc`: quit.

The demo keeps g3d ownership intact: geometry is generated in Lua, models draw through g3d, and `feel.g3d` only applies animated target values to g3d model and camera methods.
