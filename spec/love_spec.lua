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

  local function particle(name)
    return {
      setPosition = function(_, x, y)
        calls[#calls + 1] = { "setPosition", name, x, y }
      end,
      emit = function(_, count)
        calls[#calls + 1] = { "emit", name, count }
      end,
      start = function()
        calls[#calls + 1] = { "start", name }
      end,
      stop = function()
        calls[#calls + 1] = { "stop", name }
      end,
      reset = function()
        calls[#calls + 1] = { "reset", name }
      end,
      update = function(_, dt)
        calls[#calls + 1] = { "update", name, dt }
      end,
    }
  end

  local function shader(name)
    return {
      name = name,
      send = function(_, uniform, value)
        calls[#calls + 1] = { "send", name, uniform, value }
      end,
    }
  end

  local function joystick(name, supported)
    return {
      isVibrationSupported = function()
        return supported ~= false
      end,
      setVibration = function(_, left, right, duration)
        calls[#calls + 1] = { "setVibration", name, left, right, duration }
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

  local function findCall(method, name)
    for _, call in ipairs(calls) do
      if call[1] == method and call[2] == name then
        return call
      end
    end
    return nil
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
        newCanvas = function(width, height)
          local canvas = { width = width, height = height, id = "canvas-" .. tostring(#calls + 1) }
          calls[#calls + 1] = { "newCanvas", width, height, canvas }
          return canvas
        end,
        newShader = function(source)
          local value = shader("post-" .. tostring(#calls + 1))
          value.source = source
          calls[#calls + 1] = { "newShader", source, value }
          return value
        end,
        setCanvas = function(value)
          _G.love.graphics.currentCanvas = value
          calls[#calls + 1] = { "setCanvas", value }
        end,
        clear = function(r, g, b, a)
          calls[#calls + 1] = { "clear", r, g, b, a }
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
        draw = function(system)
          calls[#calls + 1] = { "draw", system }
        end,
        setShader = function(value)
          _G.love.graphics.currentShader = value
          calls[#calls + 1] = { "setShader", value }
        end,
        getShader = function()
          return _G.love.graphics.currentShader
        end,
      },
      system = {
        vibrate = function(duration)
          calls[#calls + 1] = { "vibrate", duration }
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

  it("registers haptics and plays simple values across all targets", function()
    local fx = feelLove.new()
    local p1 = joystick("p1")
    local p2 = joystick("p2")

    fx:haptic("p1", p1)
    fx:haptics({ p2 = p2 })
    calls = {}
    fx:emit({ kind = "haptic.play", payload = { value = 0.6, duration = 0.2 } })

    assert.are.same({ "setVibration", "p1", 0.6, 0.6, 0.2 }, findCall("setVibration", "p1"))
    assert.are.same({ "setVibration", "p2", 0.6, 0.6, 0.2 }, findCall("setVibration", "p2"))
    assert.are.equal(2, countCalls("setVibration"))
    assert.are.same({ "vibrate", 0.2 }, calls[#calls])
  end)

  it("targets named haptics and supports left right overrides", function()
    local fx = feelLove.new()

    fx:haptic("p1", joystick("p1"))
    fx:haptic("p2", joystick("p2"), { duration = 0.3 })
    calls = {}
    fx:emit({ kind = "haptic.play", payload = { name = "p2", value = 0.25, left = 1.4, right = -0.2, system = false } })

    assert.are.same({ "setVibration", "p2", 1, 0, 0.3 }, calls[1])
    assert.are.equal(1, #calls)
  end)

  it("ignores unsupported haptic joysticks", function()
    local fx = feelLove.new()

    fx:haptic("p1", joystick("p1", false))
    calls = {}
    fx:emit({ kind = "haptic.play", payload = { name = "p1", value = 0.7, system = false } })

    assert.are.equal(0, #calls)
  end)

  it("stops haptic targets and system vibration", function()
    local fx = feelLove.new()

    fx:haptic("p1", joystick("p1"))
    fx:haptic("p2", { joystick("p2a"), joystick("p2b") })
    calls = {}
    fx:stopHaptic("p1")
    fx:emit({ kind = "haptic.stop", payload = { name = "p2" } })
    fx:stopHaptics()

    assert.are.same({ "setVibration", "p1", nil, nil, nil }, calls[1])
    assert.are.same({ "setVibration", "p2a", nil, nil, nil }, calls[2])
    assert.are.same({ "setVibration", "p2b", nil, nil, nil }, calls[3])
    assert.are.same({ "vibrate", 0 }, calls[4])
    assert.are.equal(6, countCalls("setVibration"))
  end)

  it("can explicitly vibrate the system device", function()
    local fx = feelLove.new()

    calls = {}
    fx:vibrate(0.15)
    fx:emit({ kind = "haptic.vibrate", payload = { duration = 0.25 } })

    assert.are.same({ "vibrate", 0.15 }, calls[1])
    assert.are.same({ "vibrate", 0.25 }, calls[2])
  end)

  it("haptic handlers still call extra emit callbacks", function()
    local fx = feelLove.new()
    local seen = {}

    fx:haptic("p1", joystick("p1"))
    calls = {}
    local handlers = fx:handlers({
      emit = function(event)
        seen[#seen + 1] = event.kind
      end,
    })
    handlers.emit({ kind = "haptic.play", payload = { name = "p1", value = 0.4, system = false } })
    handlers.emit({ kind = "haptic.play", payload = { name = "missing", value = 0.4, system = false } })
    handlers.emit({ kind = "haptic.unknown", payload = {} })

    assert.are.same({ "setVibration", "p1", 0.4, 0.4, 0.12 }, calls[1])
    assert.are.same({ "haptic.play", "haptic.play", "haptic.unknown" }, seen)
  end)

  it("sets enables disables and clears post effects", function()
    local fx = feelLove.new()

    assert.is_true(fx:setPost("bloom", { intensity = 0.8, threshold = 0.6 }))
    assert.is_true(fx.post.effects.bloom.enabled)
    assert.are.equal(0.8, fx.post.effects.bloom.target.values.intensity)
    assert.are.equal(0.6, fx.post.effects.bloom.target.values.threshold)

    fx:emit({ kind = "post.disable", payload = { effect = "bloom" } })
    assert.is_false(fx.post.effects.bloom.enabled)

    fx:emit({ kind = "post.enable", payload = { effect = "bloom" } })
    assert.is_true(fx.post.effects.bloom.enabled)

    fx:emit({ kind = "post.weight", payload = { value = 0.4 } })
    assert.are.equal(0.4, fx.post.effects.volume.target.values.weight)

    fx:emit({ kind = "post.clear", payload = {} })
    assert.is_false(fx.post.effects.bloom.enabled)
    assert.are.equal(0, fx.post.effects.bloom.target.values.intensity)
    assert.are.equal(1, fx.post.effects.volume.target.values.weight)
  end)

  it("tweens post effect values through feel.update", function()
    local fx = feelLove.new()

    fx:emit({ kind = "post.tween", payload = { effect = "grade", values = { saturation = 0.4, contrast = 1.5 }, duration = 0.1 } })
    feel.update(0.1)

    assert.is_true(fx.post.effects.grade.enabled)
    assert.are.equal(0.4, fx.post.effects.grade.target.values.saturation)
    assert.are.equal(1.5, fx.post.effects.grade.target.values.contrast)
  end)

  it("drawPost captures and renders through post resources", function()
    local fx = feelLove.new()
    local drew = false

    fx:setPost("vignette", { intensity = 0.8 })
    calls = {}
    local result = fx:drawPost(function()
      drew = true
      calls[#calls + 1] = { "scene" }
    end)

    assert.is_true(result)
    assert.is_true(drew)
    assert.is_true(countCalls("newCanvas") > 0)
    assert.is_true(countCalls("newShader") > 0)
    assert.is_true(countCalls("setCanvas") > 0)
    assert.is_true(countCalls("setShader") > 0)
    assert.is_true(countCalls("draw") > 0)
  end)

  it("drawPost falls back to direct drawing without canvas or shader support", function()
    local fx = feelLove.new()
    local drew = false

    _G.love.graphics.newCanvas = nil
    fx:setPost("vignette", { intensity = 0.8 })
    calls = {}
    local result = fx:drawPost(function()
      drew = true
      calls[#calls + 1] = { "scene" }
    end)

    assert.is_false(result)
    assert.is_true(drew)
    assert.are.equal(0, countCalls("setCanvas"))
  end)

  it("post handlers still call extra emit callbacks", function()
    local fx = feelLove.new()
    local seen = {}

    calls = {}
    local handlers = fx:handlers({
      emit = function(event)
        seen[#seen + 1] = event.kind
      end,
    })
    handlers.emit({ kind = "post.set", payload = { effect = "lens", values = { distortion = 0.35 } } })
    handlers.emit({ kind = "post.unknown", payload = {} })

    assert.are.equal(0.35, fx.post.effects.lens.target.values.distortion)
    assert.are.same({ "post.set", "post.unknown" }, seen)
  end)

  it("registers particles and emits them with optional position", function()
    local fx = feelLove.new()

    fx:particle("spark", particle("spark"))
    calls = {}
    fx:emit({ kind = "particle.emit", payload = { name = "spark", count = 12, x = 20, y = 30 } })
    fx:emit({ kind = "particle.emit", payload = { name = "spark" } })

    assert.are.same({ "setPosition", "spark", 20, 30 }, calls[1])
    assert.are.same({ "emit", "spark", 12 }, calls[2])
    assert.are.same({ "emit", "spark", 1 }, calls[3])
  end)

  it("handles particle start stop reset and move events", function()
    local fx = feelLove.new()

    fx:particle("smoke", particle("smoke"))
    calls = {}
    fx:emit({ kind = "particle.start", payload = { name = "smoke", x = 1, y = 2 } })
    fx:emit({ kind = "particle.move", payload = { name = "smoke", x = 3, y = 4 } })
    fx:emit({ kind = "particle.stop", payload = { name = "smoke" } })
    fx:emit({ kind = "particle.reset", payload = { name = "smoke" } })

    assert.are.same({ "setPosition", "smoke", 1, 2 }, calls[1])
    assert.are.same({ "start", "smoke" }, calls[2])
    assert.are.same({ "setPosition", "smoke", 3, 4 }, calls[3])
    assert.are.same({ "stop", "smoke" }, calls[4])
    assert.are.same({ "reset", "smoke" }, calls[5])
  end)

  it("bulk registers particles, updates them, and draws in registration order", function()
    local fx = feelLove.new()
    local spark = particle("spark")
    local smoke = particle("smoke")

    fx:particles({
      { name = "spark", system = spark },
      { name = "smoke", system = smoke },
    })
    calls = {}
    fx:update(0.2)
    fx:drawParticles()

    assert.are.same({ "update", "spark", 0.2 }, calls[1])
    assert.are.same({ "update", "smoke", 0.2 }, calls[2])
    assert.are.same({ "setColor", 1, 1, 1, 1 }, calls[3])
    assert.are.same({ "draw", spark }, calls[4])
    assert.are.same({ "draw", smoke }, calls[5])
  end)

  it("particle handlers still call extra emit callbacks", function()
    local fx = feelLove.new()
    local seen = {}

    fx:particle("spark", particle("spark"))
    calls = {}
    local handlers = fx:handlers({
      emit = function(event)
        seen[#seen + 1] = event.kind
      end,
    })
    handlers.emit({ kind = "particle.emit", payload = { name = "spark" } })
    handlers.emit({ kind = "particle.emit", payload = { name = "missing" } })

    assert.are.same({ "emit", "spark", 1 }, calls[1])
    assert.are.same({ "particle.emit", "particle.emit" }, seen)
  end)

  it("registers shaders and sends uniforms", function()
    local fx = feelLove.new()
    local glow = shader("glow")

    fx:shader("glow", glow, { uniforms = { amount = 0.2 } })
    fx:shaders({ scan = shader("scan") })
    fx:emit({ kind = "shader.send", payload = { name = "glow", uniform = "amount", value = 0.75 } })

    assert.are.same({ "send", "glow", "amount", 0.2 }, calls[1])
    assert.are.same({ "send", "glow", "amount", 0.75 }, calls[2])
    assert.is_not_nil(fx.shaderEntries.scan)
  end)

  it("tweens numeric shader uniforms through feel.update", function()
    local fx = feelLove.new()

    fx:shader("glow", shader("glow"), { uniforms = { amount = 0 } })
    calls = {}
    fx:emit({ kind = "shader.tween", payload = { name = "glow", uniform = "amount", value = 1, duration = 0.1 } })
    feel.update(0.1)

    assert.are.equal(1, fx.shaderEntries.glow.values.amount)
    assert.are.same({ "send", "glow", "amount", 1 }, calls[#calls])
  end)

  it("applies clears and restores shaders", function()
    local fx = feelLove.new()
    local base = shader("base")
    local glow = shader("glow")

    fx:shader("glow", glow)
    calls = {}
    fx:emit({ kind = "shader.apply", payload = { name = "glow" } })
    fx:emit({ kind = "shader.clear", payload = {} })
    _G.love.graphics.currentShader = base
    fx:pushShader("glow")
    fx:popShader()

    assert.are.same({ "setShader", glow }, calls[1])
    assert.are.same({ "setShader", nil }, calls[2])
    assert.are.same({ "setShader", glow }, calls[3])
    assert.are.same({ "setShader", base }, calls[4])
  end)

  it("shader handlers still call extra emit callbacks", function()
    local fx = feelLove.new()
    local seen = {}

    fx:shader("glow", shader("glow"))
    calls = {}
    local handlers = fx:handlers({
      emit = function(event)
        seen[#seen + 1] = event.kind
      end,
    })
    handlers.emit({ kind = "shader.send", payload = { name = "glow", uniform = "amount", value = 0.4 } })
    handlers.emit({ kind = "shader.send", payload = { name = "missing", uniform = "amount", value = 0.4 } })
    handlers.emit({ kind = "shader.unknown", payload = { name = "glow" } })

    assert.are.same({ "send", "glow", "amount", 0.4 }, calls[1])
    assert.are.same({ "shader.send", "shader.send", "shader.unknown" }, seen)
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
