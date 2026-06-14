---
icon: lucide/plug
---

# Writing a Custom Adapter

`feel.love`, `feel.g3d`, and `feel.menori` are all adapters. The core runner only animates
numbers in `target.values` and emits events; an adapter turns those into real side effects
for a specific engine or system. You can write your own for any framework — a custom
renderer, an audio engine, a terminal UI — by following the same small contract.

## The Contract

Every adapter follows the same shape:

| Piece | Responsibility |
| --- | --- |
| `Module.new(...)` | Create the adapter instance (a table with a metatable). |
| Register methods | For each app object, create a `feel.target` and store it in an entry. |
| `adapter:update(dt)` | Apply each entry's animated `target.values` onto the real object. Call once per frame. |
| `adapter:emit(event, ctx)` | Route an emitted event by `kind` to a side effect. Return `handled, ctx`. |
| `adapter:handlers(extra)` | Return an opts table whose `emit` runs `self:emit` first, then the caller's. |

Two conventions make adapters interoperable:

- **Event kind** is read as `event.kind or event.event or event.name`.
- **Payload** defaults to `event.payload or {}`.

`feel.play(sequence, target, adapter:handlers())` wires the adapter into a run: each `emit`
step is delivered to `adapter:emit`, which performs (or schedules) the effect.

## A Minimal Adapter

This "console adapter" binds a `feel.target` to a plain Lua object and routes one custom
event kind, `console.flash`. It runs without LOVE — drop it into the
[core example](core-example.md) loop.

```lua
local feel = require("feel")

local Adapter = {}
Adapter.__index = Adapter

local M = {}

function M.new()
  return setmetatable({ entries = {}, order = {} }, Adapter)
end

-- Register: create a feel.target whose values mirror the object's fields.
function Adapter:bind(name, object)
  local target = feel.target({ values = { x = object.x or 0, glow = 0 } })
  if not self.entries[name] then
    self.order[#self.order + 1] = name
  end
  self.entries[name] = { name = name, object = object, target = target }
  return target
end

-- Apply animated values onto the real object every frame.
function Adapter:update()
  for _, name in ipairs(self.order) do
    local entry = self.entries[name]
    entry.object.x = entry.target.values.x
    entry.object.glow = entry.target.values.glow
  end
  return self
end

-- Route event kinds to side effects. Return handled, ctx.
function Adapter:emit(event, ctx)
  local kind = event and (event.kind or event.event or event.name)
  local payload = (event and event.payload) or {}

  if kind == "console.flash" then
    local entry = self.entries[payload.name]
    if entry then
      feel.play({
        { kind = "animate", duration = payload.duration or 0.2, to = { glow = 1 } },
        { kind = "animate", duration = 0.3, to = { glow = 0 } },
      }, entry.target, { restart = true, key = "console.flash:" .. payload.name })
      return true, ctx
    end
  end

  return false, ctx
end

-- Chain self:emit before the caller's emit; pass other handlers through.
function Adapter:handlers(extra)
  extra = extra or {}
  local adapter = self
  return {
    emit = function(event, ctx)
      adapter:emit(event, ctx)
      if type(extra.emit) == "function" then
        extra.emit(event, ctx)
      end
    end,
    audio = extra.audio,
    log = extra.log,
    markDirty = extra.markDirty,
  }
end

return M
```

Using it:

```lua
local fx = M.new()
local hero = { x = 0, glow = 0 }
fx:bind("hero", hero)

feel.define("hero.hurt", {
  { kind = "emit", event = "console.flash", payload = { name = "hero" } },
})

feel.play("hero.hurt", nil, fx:handlers({
  emit = function(event) end, -- your own emit steps still arrive here
}))

-- Per frame:
--   feel.update(dt)
--   fx:update(dt)
```

## Notes

- Keep the adapter's own animations on its own `feel.target` entries, and use
  `restart = true` plus a stable `key` so repeated events do not stack.
- `handlers(extra)` is what lets adapters compose: pass another adapter's handlers (or your
  own `emit`) as `extra` and both run for each event.
- The real adapters do exactly this at scale — see [LOVE Adapter](love-adapter.md),
  [g3d Helpers](g3d.md), and [Menori Helpers](menori.md) for larger event-routing tables.

## Related Pages

- [Core Runner](core-runner.md) for how `feel.play` delivers events.
- [Sequence Steps](sequence-steps.md) for the `emit` step shape.
- [API](api.md) for `feel.play` options.
