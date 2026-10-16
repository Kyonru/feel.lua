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
    assert.are.equal("error", haptics:list()[1])
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
