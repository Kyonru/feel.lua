-- Core-only feel.lua example. No LOVE, no graphics: just the recipe runner
-- driven by a manual fixed-step loop. Run it from the repository root with:
--
--   lua examples/core/main.lua      (or: make core)
--
package.path = "?.lua;?/init.lua;../../?.lua;../../?/init.lua;" .. package.path

local feel = require("feel")

-- 1. A target is just a Lua table with a tweenable `values` table.
local ship = feel.target({
  label = "Ship",
  values = { x = 0, scale = 1, glow = 0 },
})

-- 2. A named recipe: punch in, emit a "spark" intent, settle back, then log.
feel.define("ship.hit", {
  { kind = "animate", duration = 0.08, to = { scale = 1.4, glow = 1 }, ease = "quadout" },
  { kind = "emit", event = "spark.burst", payload = { count = 8 } },
  { kind = "animate", duration = 0.2, to = { scale = 1, glow = 0 }, ease = "backout" },
  { kind = "log", message = "ship.hit finished" },
})

-- 3. A channel decouples "what happened" (an intent) from "what feedback runs".
local feedback = feel.channel()

feedback:on("enemy.killed", function(event)
  local run = feel.play("ship.hit", event.target, {
    restart = true,
    key = "ship.hit",
    emit = function(emitted)
      if emitted.kind == "spark.burst" then
        print(string.format("  emit  -> %d sparks", emitted.payload.count))
      end
    end,
    log = function(message)
      print("  log   -> " .. message)
    end,
  })

  -- 4. A run-level signal fires once when the whole recipe completes.
  run:onComplete(function()
    print(string.format("  done  -> scale=%.2f glow=%.2f", ship.values.scale, ship.values.glow))
  end)
end)

-- 5. Announce the intent. There is no direct feel.play here; the channel routes it.
feedback:emit("enemy.killed", { target = ship })

-- 6. A manual fixed-step loop. feel.update(dt) returns true while work is active,
--    so the loop ends on its own once the recipe has finished.
local dt = 1 / 60
local frame = 0
while feel.update(dt) do
  frame = frame + 1
  print(string.format("frame %2d  scale=%.3f  glow=%.3f", frame, ship.values.scale, ship.values.glow))
end

print("idle after " .. frame .. " frames")
