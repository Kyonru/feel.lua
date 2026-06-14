-- Luacheck configuration for feel.lua
-- The runtime target is Lua 5.1 / LuaJIT (LOVE2D); actual cross-version
-- correctness is enforced by the test matrix in .github/workflows/spec.yml.
-- Luacheck here focuses on real defects (typos, unused locals, shadowing),
-- so we use the permissive `max` std and let the matrix own version checks.

std = "max"
max_line_length = 160
codes = true
unused_args = false       -- LOVE callbacks and `self`-less methods legitimately ignore args

-- LOVE apps define callbacks on the `love` table (love.load/update/draw/conf),
-- so it must be writable rather than read-only.
globals = { "love" }

-- The lint job covers the shipped library (feel/), its tests (spec/), and the
-- doc tooling (scripts/). Vendored third-party code, generated trees, LuaLS
-- stubs, and the demonstration games under examples/ (which intentionally
-- extend stdlib tables and use wide layout/draw calls) are excluded.
exclude_files = {
  "feel/vendor/",       -- bundled flux (upstream rxi)
  "examples/",          -- demonstration games (extend math.*, wide draw calls)
  "types/",             -- LuaLS ---@meta stubs: bodies are intentionally empty
  ".venv/",
  "path/",              -- stray local virtualenv
  ".cache/",
  "site/",
}

-- Busted DSL globals for the test suite; specs also stub love and math.random.
files["spec/"] = {
  std = "max+busted",
  globals = { "love", "math" },
}

-- Doc-gif tooling is a LOVE app + helper scripts with wide data/draw lines.
files["scripts/"] = {
  globals = { "love", "arg" },
  max_line_length = 240,
}
