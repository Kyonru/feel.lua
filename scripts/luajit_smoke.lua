package.path = "./?.lua;./?/init.lua;" .. package.path

local calls = {}
local currentShader

local function record(...)
  calls[#calls + 1] = { ... }
end

local function fail(message)
  error(message, 2)
end

local function assertEqual(actual, expected, label)
  if actual ~= expected then
    fail(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
  end
end

local function findCall(method, name)
  local match
  for _, call in ipairs(calls) do
    if call[1] == method and (name == nil or call[2] == name) then
      match = call
    end
  end
  return match
end

local function assertCall(method, name)
  local call = findCall(method, name)
  if not call then
    local suffix = name and (" for " .. name) or ""
    fail("Expected " .. method .. suffix)
  end
  return call
end

local function source(name)
  return {
    play = function()
      record("play", name)
    end,
    stop = function()
      record("stop", name)
    end,
    pause = function()
      record("pause", name)
    end,
    setVolume = function(_, value)
      record("setVolume", name, value)
    end,
    setPitch = function(_, value)
      record("setPitch", name, value)
    end,
    setPosition = function(_, x, y, z)
      record("setPosition", name, x, y, z)
    end,
  }
end

local function particle(name)
  return {
    setPosition = function(_, x, y)
      record("setParticlePosition", name, x, y)
    end,
    emit = function(_, count)
      record("emitParticle", name, count)
    end,
    update = function(_, dt)
      record("updateParticle", name, dt)
    end,
  }
end

local function shader(name)
  return {
    send = function(_, uniform, value)
      record("sendShader", name, uniform, value)
    end,
  }
end

local function joystick(name)
  return {
    isVibrationSupported = function()
      return true
    end,
    setVibration = function(_, left, right, duration)
      record("setVibration", name, left, right, duration)
    end,
  }
end

_G.love = {
  graphics = {
    getDimensions = function()
      return 320, 180
    end,
    setShader = function(value)
      currentShader = value
      record("setShader", value)
    end,
    getShader = function()
      return currentShader
    end,
    push = function()
      record("push")
    end,
    pop = function()
      record("pop")
    end,
    translate = function(x, y)
      record("translate", x, y)
    end,
    rotate = function(value)
      record("rotate", value)
    end,
    scale = function(value)
      record("scale", value)
    end,
    setColor = function(r, g, b, a)
      record("setColor", r, g, b, a)
    end,
    rectangle = function(mode, x, y, w, h)
      record("rectangle", mode, x, y, w, h)
    end,
    draw = function(value)
      record("draw", value)
    end,
  },
  system = {
    vibrate = function(duration)
      record("systemVibrate", duration)
    end,
  },
}

local feel = require("feel")
local feelLove = require("feel.love")

feel.clear()

local fx = feelLove.new({ width = 320, height = 180 })
fx:sound("hit", source("hit"))
fx:particle("spark", particle("spark"), { x = 1, y = 2 })
fx:shader("flash", shader("flash"), { uniforms = { strength = 0.25 } })
fx:haptic("pad", joystick("pad"), { duration = 0.12 })

calls = {}

local seenEmit = {}
local seenAudio = {}
local handlers = fx:handlers({
  emit = function(event)
    seenEmit[#seenEmit + 1] = event.kind
  end,
  audio = function(event)
    seenAudio[#seenAudio + 1] = event.cue
  end,
})

feel.define("luajit.love.smoke", {
  { kind = "emit", event = "camera.shake", payload = { amount = 9, duration = 0.2, frequency = 12 } },
  { kind = "emit", event = "screen.flash", payload = { amount = 0.7, duration = 0.1, color = { 1, 0, 0, 1 } } },
  { kind = "audio", cue = "hit" },
  { kind = "emit", event = "sound.pitch", payload = { cue = "hit", pitch = 1.25 } },
  { kind = "emit", event = "particle.emit", payload = { name = "spark", count = 4, x = 12, y = 14 } },
  { kind = "emit", event = "haptic.play", payload = { name = "pad", left = 0.6, right = 0.3, duration = 0.05, system = false } },
  { kind = "emit", event = "shader.send", payload = { name = "flash", uniform = "strength", value = 0.8 } },
})

local ctx = feel.play("luajit.love.smoke", nil, handlers)
if not ctx then
  fail("Expected feel.play to return a context")
end

assertEqual(seenEmit[1], "camera.shake", "first routed event")
assertEqual(seenEmit[2], "screen.flash", "second routed event")
assertEqual(seenEmit[3], "sound.pitch", "third routed event")
assertEqual(seenEmit[4], "particle.emit", "fourth routed event")
assertEqual(seenEmit[5], "haptic.play", "fifth routed event")
assertEqual(seenEmit[6], "shader.send", "sixth routed event")
assertEqual(seenAudio[1], "hit", "routed audio cue")

assertEqual(fx.shake.amount, 9, "camera shake amount")
assertEqual(fx.shake.remaining, 0.2, "camera shake duration")
assertEqual(fx.flash.alpha, 0.7, "screen flash alpha")
assertEqual(assertCall("play", "hit")[2], "hit", "sound play cue")
assertEqual(assertCall("setPitch", "hit")[3], 1.25, "sound pitch")
assertEqual(assertCall("emitParticle", "spark")[3], 4, "particle count")
assertEqual(assertCall("setVibration", "pad")[3], 0.6, "haptic left value")
assertEqual(assertCall("sendShader", "flash")[4], 0.8, "shader value")

fx:update(1 / 60)
fx:push()
fx:drawOverlay()
fx:pop()

assertCall("updateParticle", "spark")
assertCall("push")
assertCall("translate")
assertCall("scale")
assertCall("pop")

local spring = feel.spring(0, 160, 18)
spring:animate(10)
local before = spring.x
spring:update(1 / 60)
if spring.x == before then
  fail("Expected spring to advance under LuaJIT")
end

feel.clear()
