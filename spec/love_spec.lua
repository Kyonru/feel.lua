package.path = "./?.lua;./?/init.lua;" .. package.path

local feel = require("feel")
local feelLove = require("feel.love")

describe("feel.love", function()
  local previousLove
  local calls

  local function source(name)
    return {
      play = function()
        calls[#calls + 1] = { "play", name }
      end,
      stop = function()
        calls[#calls + 1] = { "stop", name }
      end,
      pause = function()
        calls[#calls + 1] = { "pause", name }
      end,
      setVolume = function(_, value)
        calls[#calls + 1] = { "setVolume", name, value }
      end,
      setPitch = function(_, value)
        calls[#calls + 1] = { "setPitch", name, value }
      end,
      setPosition = function(_, x, y, z)
        calls[#calls + 1] = { "setPosition", name, x, y, z }
      end,
    }
  end

  local function countCalls(method)
    local count = 0
    for _, call in ipairs(calls) do
      if call[1] == method then
        count = count + 1
      end
    end
    return count
  end

  local function hasCall(method, name)
    for _, call in ipairs(calls) do
      if call[1] == method and call[2] == name then
        return true
      end
    end
    return false
  end

  before_each(function()
    feel.clear()
    previousLove = _G.love
    calls = {}
    _G.love = {
      graphics = {
        getDimensions = function()
          return 320, 180
        end,
        push = function()
          calls[#calls + 1] = { "push" }
        end,
        pop = function()
          calls[#calls + 1] = { "pop" }
        end,
        translate = function(x, y)
          calls[#calls + 1] = { "translate", x, y }
        end,
        rotate = function(value)
          calls[#calls + 1] = { "rotate", value }
        end,
        scale = function(value)
          calls[#calls + 1] = { "scale", value }
        end,
        setColor = function(r, g, b, a)
          calls[#calls + 1] = { "setColor", r, g, b, a }
        end,
        rectangle = function(mode, x, y, w, h)
          calls[#calls + 1] = { "rectangle", mode, x, y, w, h }
        end,
      },
    }
  end)

  after_each(function()
    _G.love = previousLove
    feel.clear()
  end)

  it("handlers forwards camera shake events into adapter state", function()
    local fx = feelLove.new()
    local handlers = fx:handlers()

    handlers.emit({
      kind = "camera.shake",
      payload = { amount = 12, duration = 0.4, frequency = 30 },
    })

    assert.are.equal(12, fx.shake.amount)
    assert.are.equal(0.4, fx.shake.remaining)
    assert.are.equal(30, fx.shake.frequency)
  end)

  it("handlers still calls extra emit callbacks", function()
    local fx = feelLove.new()
    local seen = {}
    local handlers = fx:handlers({
      emit = function(event)
        seen[#seen + 1] = event.kind
      end,
    })

    handlers.emit({ kind = "camera.shake", payload = { amount = 4 } })
    handlers.emit({ kind = "burst", payload = {} })

    assert.are.same({ "camera.shake", "burst" }, seen)
    assert.are.equal(4, fx.shake.amount)
  end)

  it("registers sounds and handlers play audio cues", function()
    local fx = feelLove.new()
    local seen = {}
    local hit = source("hit")

    fx:sound("hit", hit)
    calls = {}
    local handlers = fx:handlers({
      audio = function(event)
        seen[#seen + 1] = event.cue
      end,
    })
    handlers.audio({ cue = "hit" })

    assert.are.same({ "stop", "hit" }, calls[1])
    assert.are.same({ "play", "hit" }, calls[#calls])
    assert.are.same({ "hit" }, seen)
  end)

  it("chooses one alternate sound source from a registered list", function()
    local fx = feelLove.new()

    fx:sound("hit", { source("a"), source("b") })
    calls = {}
    local handlers = fx:handlers()
    handlers.audio({ cue = "hit" })

    assert.are.equal(1, countCalls("play"))
    assert.are.equal(1, countCalls("stop"))
  end)

  it("does not restart a cue when restart is false", function()
    local fx = feelLove.new()

    fx:sound("loop", source("loop"), { restart = false })
    calls = {}
    fx:audio({ cue = "loop" })

    assert.are.equal(1, countCalls("play"))
    assert.are.equal(0, countCalls("stop"))
  end)

  it("handles sound play stop pause and resume emit events", function()
    local fx = feelLove.new()
    local hit = source("hit")

    fx:sound("hit", hit)
    calls = {}
    fx:emit({ kind = "sound.play", payload = { cue = "hit" } })
    fx:emit({ kind = "sound.pause", payload = { cue = "hit" } })
    fx:emit({ kind = "sound.resume", payload = { cue = "hit" } })
    fx:emit({ kind = "sound.stop", payload = { cue = "hit" } })

    assert.are.equal(2, countCalls("play"))
    assert.are.equal(2, countCalls("stop"))
    assert.are.equal(1, countCalls("pause"))
  end)

  it("stops all registered sounds", function()
    local fx = feelLove.new()

    fx:sounds({
      hit = source("hit"),
      ui = source("ui"),
    })
    calls = {}
    fx:stopSounds()

    assert.are.equal(2, countCalls("stop"))
    assert.is_true(hasCall("stop", "hit"))
    assert.is_true(hasCall("stop", "ui"))
  end)

  it("tweens sound volume pitch and pan through feel.update", function()
    local fx = feelLove.new()
    local hit = source("hit")

    fx:sound("hit", hit)
    calls = {}
    fx:emit({ kind = "sound.volume", payload = { cue = "hit", volume = 0.25, duration = 0.1 } })
    fx:emit({ kind = "sound.pitch", payload = { cue = "hit", pitch = 1.5, duration = 0.1 } })
    fx:emit({ kind = "sound.pan", payload = { cue = "hit", pan = -0.4, duration = 0.1 } })
    feel.update(0.1)

    assert.are.equal(0.25, fx.soundEntries.hit.target.values.volume)
    assert.are.equal(1.5, fx.soundEntries.hit.target.values.pitch)
    assert.are.equal(-0.4, fx.soundEntries.hit.target.values.pan)
    assert.are.same({ "setVolume", "hit", 0.25 }, calls[#calls - 2])
    assert.are.same({ "setPitch", "hit", 1.5 }, calls[#calls - 1])
    assert.are.same({ "setPosition", "hit", -0.4, 0, 0 }, calls[#calls])
  end)

  it("update decays shake and flash over time", function()
    local fx = feelLove.new()

    fx:emit({ kind = "camera.shake", payload = { amount = 10, duration = 1, frequency = 10 } })
    fx:emit({ kind = "screen.flash", payload = { amount = 0.8, duration = 1 } })
    fx:update(0.25)

    assert.are.equal(0.75, fx.shake.remaining)
    assert.is_true(math.abs(fx.shake.x) > 0 or math.abs(fx.shake.y) > 0)
    assert.is_true(math.abs(fx.flash.alpha - 0.6) < 0.000001)

    fx:update(1)
    assert.are.equal(0, fx.shake.x)
    assert.are.equal(0, fx.shake.y)
    assert.are.equal(0, fx.flash.alpha)
  end)

  it("camera zoom and move tween through feel.update", function()
    local fx = feelLove.new()

    fx:emit({ kind = "camera.zoom", payload = { scale = 1.5, duration = 0.1 } })
    fx:emit({ kind = "camera.move", payload = { x = 20, y = -10, duration = 0.1 } })
    feel.update(0.1)

    assert.are.equal(1.5, fx.camera.scale)
    assert.are.equal(20, fx.camera.x)
    assert.are.equal(-10, fx.camera.y)
  end)

  it("reset clears camera and screen state", function()
    local fx = feelLove.new()

    fx:emit({ kind = "camera.shake", payload = { amount = 10, duration = 1 } })
    fx:emit({ kind = "camera.zoom", payload = { scale = 2, duration = 1 } })
    fx:emit({ kind = "screen.flash", payload = { amount = 0.8, duration = 1 } })
    feel.update(0.5)
    fx:reset()
    feel.update(1)

    assert.are.equal(0, fx.camera.x)
    assert.are.equal(0, fx.camera.y)
    assert.are.equal(1, fx.camera.scale)
    assert.are.equal(0, fx.camera.rotation)
    assert.are.equal(0, fx.shake.remaining)
    assert.are.equal(0, fx.flash.alpha)
    assert.are.equal(0, fx.fade.alpha)
  end)

  it("push pop and drawOverlay call love graphics helpers", function()
    local fx = feelLove.new({ x = 5, y = 6, scale = 1.25, rotation = 0.1 })

    fx:emit({ kind = "screen.flash", payload = { amount = 0.5, duration = 1 } })
    fx:push()
    fx:pop()
    fx:drawOverlay()

    assert.are.same({ "push" }, calls[1])
    assert.are.same({ "translate", 5, 6 }, calls[2])
    assert.are.same({ "rotate", 0.1 }, calls[3])
    assert.are.same({ "scale", 1.25 }, calls[4])
    assert.are.same({ "pop" }, calls[5])
    assert.are.same({ "setColor", 1, 1, 1, 0.5 }, calls[6])
    assert.are.same({ "rectangle", "fill", 0, 0, 320, 180 }, calls[7])
  end)
end)
