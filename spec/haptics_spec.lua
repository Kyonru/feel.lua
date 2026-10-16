package.path = "./?.lua;./?/init.lua;" .. package.path

local Haptics = require("feel.haptics")

describe("feel.haptics", function()
  local played
  local stopped

  local function engine(opts)
    return Haptics.new({
      play = function(payload)
        played[#played + 1] = payload
        return true
      end,
      stop = function(stopOpts)
        stopped[#stopped + 1] = stopOpts
        return true
      end,
    }, opts)
  end

  before_each(function()
    played = {}
    stopped = {}
  end)

  it("normalizes pulses and applies the master intensity scale", function()
    local haptics = engine({ scale = 0.5, duration = 0.2 })

    assert.is_true(haptics:trigger({ intensity = 0.8, left = 2, right = -1, target = "player" }))

    assert.are.equal(0.4, played[1].value)
    assert.are.equal(0.5, played[1].left)
    assert.are.equal(0, played[1].right)
    assert.are.equal(0.2, played[1].duration)
    assert.are.equal("player", played[1].target)
  end)

  it("ships discoverable presets without sharing mutable pattern tables", function()
    local haptics = engine()

    assert.is_not_nil(haptics:get("success"))
    assert.is_not_nil(haptics:get("warning"))
    assert.is_not_nil(haptics:get("error"))
    assert.is_not_nil(haptics:get("heartbeat"))

    local tap = haptics:get("tap")
    tap[1].value = 0
    assert.is_true(haptics:get("tap")[1].value > 0)
    assert.are.equal("alarm", haptics:list()[1])
    assert.is_not_nil(haptics:get("crescendo"))
    assert.is_not_nil(haptics:get("siren"))
    assert.is_not_nil(haptics:get("thunder"))
  end)

  it("composes named multi-pulse patterns on its independent clock", function()
    local haptics = engine()
    haptics:define("double", {
      { value = 0.25, duration = 0.05, gap = 0.02 },
      { left = 1, right = 0.4, duration = 0.1 },
    })

    local ctx = haptics:play("double", { target = "player", system = false })
    assert.is_truthy(ctx)
    assert.are.equal(0.25, played[1].value)
    assert.are.equal("player", played[1].target)

    haptics:update(0.069)
    assert.are.equal(1, #played)
    haptics:update(0.002)
    assert.are.equal(1, played[2].left)
    assert.are.equal(0.4, played[2].right)
  end)

  it("passes custom pulse metadata through to hardware drivers", function()
    local haptics = engine()
    haptics:play({ { value = 0.4, duration = 0.05, actuator = "trigger" } })
    assert.are.equal("trigger", played[1].actuator)
    assert.is_nil(played[1].gap)
  end)

  it("compiles timestamped and overlapping continuous segments", function()
    local haptics = engine({ presets = false })
    local pattern = haptics:compile({
      { type = "continuous", at = 0.1, duration = 0.1, intensity = 0.4 },
      { type = "continuous", at = 0.15, duration = 0.1, intensity = 0.8 },
    })

    assert.are.equal(2, #pattern)
    assert.are.equal(0.1, pattern[1].delay)
    assert.are.near(0.05, pattern[1].duration, 0.000001)
    assert.are.equal(0.4, pattern[1].value)
    assert.are.near(0.1, pattern[2].duration, 0.000001)
    assert.are.equal(0.8, pattern[2].value)
  end)

  it("generates pulse trains from intensity and frequency", function()
    local haptics = engine({ presets = false })
    local pattern = haptics:compile({
      { type = "pulse", duration = 0.5, intensity = 0.6, frequency = 0.9 },
    })

    assert.is_true(#pattern > 2)
    assert.are.equal(0.6, pattern[1].value)
    assert.is_true(pattern[2].delay > 0)
  end)

  it("samples line intensity and frequency envelopes", function()
    local haptics = engine({ presets = false })
    local pattern = haptics:compile({
      {
        type = "line",
        duration = 0.8,
        intensity = { { time = 0, value = 0.1 }, { time = 0.8, value = 1 } },
        frequency = { { time = 0, value = 0.2 }, { time = 0.8, value = 0.95 } },
      },
    })

    assert.is_true(#pattern > 1)
    assert.is_true(pattern[1].value < pattern[#pattern].value)
    assert.is_true(pattern[2].delay > 0)
  end)

  it("honors an initial timeline delay during playback", function()
    local haptics = engine({ presets = false })
    haptics:play({ { type = "continuous", at = 0.2, duration = 0.05, intensity = 0.7 } }, { system = false })

    assert.are.equal(0, #played)
    haptics:update(0.199)
    assert.are.equal(0, #played)
    haptics:update(0.002)
    assert.are.equal(0.7, played[1].value)
    assert.is_false(played[1].system)
  end)

  it("caps generated pattern complexity", function()
    local haptics = engine({ presets = false, maxGeneratedPulses = 2 })
    assert.has_error(function()
      haptics:compile({ { type = "pulse", duration = 2, intensity = 0.1, frequency = 1 } })
    end, "haptic pattern exceeds maxGeneratedPulses")
  end)

  it("rejects ambiguous mixes of sequential and timeline timing", function()
    local haptics = engine({ presets = false })
    assert.has_error(function()
      haptics:compile({
        { type = "continuous", duration = 0.1 },
        { value = 0.5, duration = 0.1 },
      })
    end, "cannot mix sequential pulses with timeline segments")
  end)

  it("restarts the same pattern and can cancel a target", function()
    local haptics = engine()
    haptics:define("long", {
      { value = 0.3, duration = 0.1 },
      { value = 0.9, duration = 0.1 },
    })

    local first = haptics:play("long", { target = "player" })
    local second = haptics:play("long", { target = "player" })
    assert.is_false(first:isPlaying())
    assert.is_true(second:isPlaying())
    assert.is_true(haptics:stopTarget("player", { system = false }))

    haptics:update(1)
    assert.are.equal(2, #played)
    assert.are.equal("player", stopped[1].target)
    assert.is_false(stopped[1].system)
  end)

  it("tracks overlapping runs when restart is disabled", function()
    local haptics = engine()
    haptics:define("long", { { value = 0.4, duration = 1 } })

    local first = haptics:play("long", { target = "player", restart = false })
    local second = haptics:play("long", { target = "player", restart = false })
    assert.is_true(first:isPlaying())
    assert.is_true(second:isPlaying())

    assert.is_true(haptics:stop("long", "player"))
    assert.is_false(first:isPlaying())
    assert.is_false(second:isPlaying())
    assert.is_nil(next(haptics.runs))
  end)

  it("provides standalone pause completion and stop controls", function()
    local haptics = engine()
    local completed = false
    local run = haptics:play({ { value = 0.5, duration = 0.1 } })
    run:onComplete(function()
      completed = true
    end)

    run:pause()
    haptics:update(1)
    assert.is_true(run:isPlaying())
    assert.is_true(run:isPaused())

    run:resume()
    haptics:update(0.1)
    assert.is_true(completed)
    assert.is_false(run:isPlaying())

    local stoppedRun = haptics:play("heartbeat", { target = "player", system = false })
    stoppedRun:stop()
    assert.are.equal("player", stopped[#stopped].target)
    assert.is_false(stopped[#stopped].system)
  end)

  it("stops active output when disabled or scaled to zero", function()
    local haptics = engine()
    haptics:play("heartbeat")

    assert.is_false(haptics:setEnabled(false))
    assert.are.equal(1, #stopped)
    assert.is_false(haptics:trigger({ value = 1 }))

    assert.is_true(haptics:setEnabled(true))
    haptics:play("heartbeat")
    assert.are.equal(0, haptics:setScale(0))
    assert.are.equal(2, #stopped)
  end)

  it("can start without built-in presets", function()
    local haptics = engine({ presets = false })
    assert.are.same({}, haptics:list())
    assert.is_false(haptics:play("tap"))
  end)
end)
