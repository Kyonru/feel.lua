local moduleName = ...
local prefix = "feel"
if moduleName and moduleName ~= "" then
  prefix = moduleName:gsub("%.love$", "")
end

local feel = require(prefix)

local FeelLove = {}
local Adapter = {}
Adapter.__index = Adapter

local DEFAULT_FLASH = { 1, 1, 1, 1 }
local DEFAULT_FADE = { 0, 0, 0, 1 }
local SOUND_SETTERS = {
  volume = "setVolume",
  pitch = "setPitch",
  pan = "setPosition",
}

local function copyColor(color, fallback)
  color = color or fallback
  return {
    color[1] or fallback[1],
    color[2] or fallback[2],
    color[3] or fallback[3],
    color[4] or fallback[4] or 1,
  }
end

local function viewportSize(opts)
  if opts and opts.width and opts.height then
    return opts.width, opts.height
  end
  if love and love.graphics and love.graphics.getDimensions then
    return love.graphics.getDimensions()
  end
  return 0, 0
end

local function drawOverlay(overlay)
  if not love or not love.graphics or not love.graphics.setColor or not love.graphics.rectangle then
    return
  end

  local alpha = overlay.alpha or 0
  if alpha <= 0 then
    return
  end

  local color = overlay.color
  love.graphics.setColor(color[1], color[2], color[3], alpha * (color[4] or 1))
  love.graphics.rectangle("fill", 0, 0, overlay.width, overlay.height)
end

local function isSourceList(value)
  return type(value) == "table" and type(value.play) ~= "function" and #value > 0
end

local function collectSources(sourceOrSources)
  if sourceOrSources == nil then
    return {}
  end
  if isSourceList(sourceOrSources) then
    local sources = {}
    for _, source in ipairs(sourceOrSources) do
      if source then
        sources[#sources + 1] = source
      end
    end
    return sources
  end
  return { sourceOrSources }
end

local function isJoystickList(value)
  return type(value) == "table" and type(value.setVibration) ~= "function" and #value > 0
end

local function collectJoysticks(joystickOrJoysticks)
  if joystickOrJoysticks == nil then
    return {}
  end
  if isJoystickList(joystickOrJoysticks) then
    local joysticks = {}
    for _, joystick in ipairs(joystickOrJoysticks) do
      if joystick then
        joysticks[#joysticks + 1] = joystick
      end
    end
    return joysticks
  end
  return { joystickOrJoysticks }
end

local function callSource(source, method, ...)
  local fn = source and source[method]
  if type(fn) == "function" then
    fn(source, ...)
  end
end

local function applySourceValue(source, name, value)
  if value == nil then
    return
  end

  if name == "pan" then
    callSource(source, SOUND_SETTERS.pan, value, 0, 0)
    return
  end

  callSource(source, SOUND_SETTERS[name], value)
end

local function applySoundValues(entry)
  if not entry then
    return
  end

  local values = entry.target.values
  for _, source in ipairs(entry.sources) do
    applySourceValue(source, "volume", values.volume)
    applySourceValue(source, "pitch", values.pitch)
    applySourceValue(source, "pan", values.pan)
  end
end

local function selectedSource(entry)
  if not entry or #entry.sources == 0 then
    return nil
  end
  if #entry.sources == 1 then
    return entry.sources[1]
  end
  return entry.sources[math.random(#entry.sources)]
end

local function setSoundValue(entry, name, value, duration, ease)
  if not entry or value == nil then
    return false
  end

  if not duration or duration <= 0 then
    entry.target.values[name] = value
    applySoundValues(entry)
    return true
  end

  feel.play({
    kind = "animate",
    duration = duration,
    ease = ease,
    to = { [name] = value },
    onUpdate = function()
      applySoundValues(entry)
    end,
    onComplete = function()
      applySoundValues(entry)
    end,
  }, entry.target)
  return true
end

local function playSound(entry, payload)
  local source = selectedSource(entry)
  if not source then
    return false
  end

  payload = payload or {}
  setSoundValue(entry, "volume", payload.volume)
  setSoundValue(entry, "pitch", payload.pitch)
  setSoundValue(entry, "pan", payload.pan)

  if entry.restart then
    callSource(source, "stop")
  end
  applySoundValues(entry)
  callSource(source, "play")
  return true
end

local function stopSources(entry)
  if not entry then
    return false
  end
  for _, source in ipairs(entry.sources) do
    callSource(source, "stop")
  end
  return true
end

local function pauseSources(entry)
  if not entry then
    return false
  end
  for _, source in ipairs(entry.sources) do
    callSource(source, "pause")
  end
  return true
end

local function resumeSources(entry)
  if not entry then
    return false
  end
  for _, source in ipairs(entry.sources) do
    callSource(source, "play")
  end
  return true
end

local function clamp01(value, fallback)
  if value == nil then
    value = fallback or 0
  end
  if value < 0 then
    return 0
  end
  if value > 1 then
    return 1
  end
  return value
end

local function supportsVibration(joystick)
  local fn = joystick and joystick.isVibrationSupported
  if type(fn) ~= "function" then
    return true
  end
  return fn(joystick) == true
end

local function canSetVibration(joystick)
  return type(joystick and joystick.setVibration) == "function" and supportsVibration(joystick)
end

local function vibrateSystem(duration)
  if not love or not love.system or type(love.system.vibrate) ~= "function" then
    return false
  end
  love.system.vibrate(duration)
  return true
end

local function playHapticEntry(entry, payload, defaultDuration)
  if not entry then
    return false
  end

  payload = payload or {}
  local value = payload.value ~= nil and payload.value or 1
  local left = clamp01(payload.left, value)
  local right = clamp01(payload.right, value)
  local duration = payload.duration or entry.duration or defaultDuration
  local played = false

  for _, joystick in ipairs(entry.joysticks) do
    if canSetVibration(joystick) then
      callSource(joystick, "setVibration", left, right, duration)
      played = true
    end
  end
  return played
end

local function stopHapticEntry(entry)
  if not entry then
    return false
  end

  local stopped = false
  for _, joystick in ipairs(entry.joysticks) do
    if canSetVibration(joystick) then
      callSource(joystick, "setVibration")
      stopped = true
    end
  end
  return stopped
end

local function setParticlePosition(entry, payload)
  if not entry or not payload then
    return
  end
  if payload.x ~= nil and payload.y ~= nil then
    callSource(entry.system, "setPosition", payload.x, payload.y)
  end
end

local function particleEntry(adapter, payload)
  return adapter.particleEntries[payload and payload.name]
end

local function emitParticle(entry, payload)
  if not entry then
    return false
  end
  payload = payload or {}
  setParticlePosition(entry, payload)
  callSource(entry.system, "emit", payload.count or 1)
  return true
end

local function startParticle(entry, payload)
  if not entry then
    return false
  end
  setParticlePosition(entry, payload)
  callSource(entry.system, "start")
  return true
end

local function stopParticle(entry)
  if not entry then
    return false
  end
  callSource(entry.system, "stop")
  return true
end

local function resetParticle(entry)
  if not entry then
    return false
  end
  callSource(entry.system, "reset")
  return true
end

local function shaderEntry(adapter, payloadOrName)
  if type(payloadOrName) == "table" then
    return adapter.shaderEntries[payloadOrName.name]
  end
  return adapter.shaderEntries[payloadOrName]
end

local function sendShaderValue(entry, uniform, value)
  if not entry or not uniform or value == nil then
    return false
  end
  entry.values[uniform] = value
  callSource(entry.shader, "send", uniform, value)
  return true
end

local function tweenShaderValue(entry, uniform, value, duration, ease)
  if not entry or not uniform or type(value) ~= "number" then
    return false
  end

  if entry.values[uniform] == nil then
    entry.values[uniform] = 0
  end
  entry.target.values[uniform] = entry.values[uniform]

  if not duration or duration <= 0 then
    return sendShaderValue(entry, uniform, value)
  end

  feel.play({
    kind = "animate",
    duration = duration,
    ease = ease,
    to = { [uniform] = value },
    onUpdate = function(values)
      sendShaderValue(entry, uniform, values[uniform])
    end,
    onComplete = function(values)
      sendShaderValue(entry, uniform, values[uniform])
    end,
  }, entry.target)
  return true
end

local function applyShader(adapter, entry)
  if not entry or not love or not love.graphics or not love.graphics.setShader then
    return false
  end
  love.graphics.setShader(entry.shader)
  adapter.activeShader = entry.shader
  return true
end

function Adapter:reset()
  feel.clear(self.cameraTarget)
  for _, entry in pairs(self.soundEntries) do
    feel.clear(entry.target)
  end
  for _, entry in pairs(self.shaderEntries) do
    feel.clear(entry.target)
  end
  self.shaderStack = {}
  self.activeShader = nil

  self.camera.x = self.defaults.x
  self.camera.y = self.defaults.y
  self.camera.scale = self.defaults.scale
  self.camera.rotation = self.defaults.rotation

  self.shake.amount = 0
  self.shake.duration = 0
  self.shake.remaining = 0
  self.shake.frequency = self.defaults.shakeFrequency
  self.shake.time = 0
  self.shake.x = 0
  self.shake.y = 0

  self.flash.alpha = 0
  self.flash.amount = 0
  self.flash.duration = 0
  self.flash.remaining = 0
  self.flash.color = copyColor(nil, DEFAULT_FLASH)

  self.fade.alpha = 0
  self.fade.amount = 0
  self.fade.duration = 0
  self.fade.remaining = 0
  self.fade.color = copyColor(nil, DEFAULT_FADE)
end

function Adapter:sound(name, sourceOrSources, opts)
  if not name then
    return self
  end

  opts = opts or {}
  local target = feel.target()
  target.values.volume = opts.volume ~= nil and opts.volume or 1
  target.values.pitch = opts.pitch ~= nil and opts.pitch or 1
  target.values.pan = opts.pan ~= nil and opts.pan or 0

  self.soundEntries[name] = {
    sources = collectSources(sourceOrSources),
    restart = opts.restart ~= false,
    target = target,
  }
  applySoundValues(self.soundEntries[name])
  return self
end

function Adapter:sounds(map)
  for name, sourceOrSources in pairs(map or {}) do
    self:sound(name, sourceOrSources)
  end
  return self
end

function Adapter:stopSound(name)
  return stopSources(self.soundEntries[name])
end

function Adapter:stopSounds()
  for _, entry in pairs(self.soundEntries) do
    stopSources(entry)
  end
  return true
end

function Adapter:haptic(name, joystickOrJoysticks, opts)
  if not name then
    return self
  end

  opts = opts or {}
  self.hapticEntries[name] = {
    name = name,
    joysticks = collectJoysticks(joystickOrJoysticks),
    duration = opts.duration,
  }
  return self
end

function Adapter:haptics(map)
  for name, joystickOrJoysticks in pairs(map or {}) do
    self:haptic(name, joystickOrJoysticks)
  end
  return self
end

function Adapter:stopHaptic(name)
  return stopHapticEntry(self.hapticEntries[name])
end

function Adapter:stopHaptics()
  for _, entry in pairs(self.hapticEntries) do
    stopHapticEntry(entry)
  end
  return true
end

function Adapter:vibrate(duration)
  return vibrateSystem(duration)
end

function Adapter:particle(name, system, opts)
  if not name then
    return self
  end

  if not self.particleEntries[name] then
    self.particleOrder[#self.particleOrder + 1] = name
  end

  opts = opts or {}
  self.particleEntries[name] = {
    name = name,
    system = system,
  }
  setParticlePosition(self.particleEntries[name], opts)
  return self
end

function Adapter:particles(map)
  map = map or {}
  for _, entry in ipairs(map) do
    if type(entry) == "table" then
      self:particle(entry.name or entry[1], entry.system or entry[2], entry.opts or entry.options)
    end
  end
  for name, system in pairs(map) do
    if type(name) ~= "number" then
      self:particle(name, system)
    end
  end
  return self
end

function Adapter:shader(name, shader, opts)
  if not name then
    return self
  end

  opts = opts or {}
  local target = feel.target()
  local entry = {
    name = name,
    shader = shader,
    target = target,
    values = {},
  }

  for uniform, value in pairs(opts.uniforms or opts.values or {}) do
    entry.values[uniform] = value
    if type(value) == "number" then
      target.values[uniform] = value
    end
    callSource(shader, "send", uniform, value)
  end

  self.shaderEntries[name] = entry
  return self
end

function Adapter:shaders(map)
  for name, shader in pairs(map or {}) do
    self:shader(name, shader)
  end
  return self
end

function Adapter:pushShader(name)
  local entry = shaderEntry(self, name)
  if not entry or not love or not love.graphics or not love.graphics.setShader then
    return false
  end

  local previous
  if love.graphics.getShader then
    previous = love.graphics.getShader()
  end
  self.shaderStack[#self.shaderStack + 1] = { shader = previous }
  love.graphics.setShader(entry.shader)
  self.activeShader = entry.shader
  return true
end

function Adapter:popShader()
  if not love or not love.graphics or not love.graphics.setShader then
    return false
  end

  local frame = self.shaderStack[#self.shaderStack]
  self.shaderStack[#self.shaderStack] = nil
  local previous = frame and frame.shader or nil
  love.graphics.setShader(previous)
  self.activeShader = previous
  return true
end

function Adapter:update(dt)
  dt = dt or 0

  for _, name in ipairs(self.particleOrder) do
    local entry = self.particleEntries[name]
    callSource(entry and entry.system, "update", dt)
  end

  if self.shake.remaining > 0 then
    self.shake.remaining = math.max(0, self.shake.remaining - dt)
    self.shake.time = self.shake.time + dt

    local duration = self.shake.duration > 0 and self.shake.duration or 1
    local strength = self.shake.amount * (self.shake.remaining / duration)
    local phase = self.shake.time * self.shake.frequency * math.pi * 2
    self.shake.x = math.sin(phase) * strength
    self.shake.y = math.cos(phase * 0.87) * strength * 0.55
  else
    self.shake.x = 0
    self.shake.y = 0
  end

  if self.flash.remaining > 0 then
    self.flash.remaining = math.max(0, self.flash.remaining - dt)
    local duration = self.flash.duration > 0 and self.flash.duration or 1
    self.flash.alpha = self.flash.amount * (self.flash.remaining / duration)
  else
    self.flash.alpha = 0
  end

  if self.fade.remaining > 0 then
    self.fade.remaining = math.max(0, self.fade.remaining - dt)
    local duration = self.fade.duration > 0 and self.fade.duration or 1
    self.fade.alpha = self.fade.amount * (self.fade.remaining / duration)
  elseif self.fade.duration > 0 then
    self.fade.alpha = 0
  end
end

function Adapter:emit(event, ctx)
  local kind = event and (event.kind or event.event or event.name)
  local payload = event and event.payload or {}

  if kind == "camera.shake" then
    self.shake.amount = math.max(self.shake.amount, payload.amount or self.defaults.shakeAmount)
    self.shake.duration = payload.duration or self.defaults.shakeDuration
    self.shake.remaining = self.shake.duration
    self.shake.frequency = payload.frequency or self.defaults.shakeFrequency
    self.shake.time = 0
    return true
  elseif kind == "camera.zoom" then
    feel.play({
      kind = "animate",
      duration = payload.duration or self.defaults.tweenDuration,
      ease = payload.ease,
      to = { scale = payload.scale or self.defaults.scale },
    }, self.cameraTarget)
    return true
  elseif kind == "camera.move" then
    feel.play({
      kind = "animate",
      duration = payload.duration or self.defaults.tweenDuration,
      ease = payload.ease,
      to = {
        x = payload.x or self.defaults.x,
        y = payload.y or self.defaults.y,
      },
    }, self.cameraTarget)
    return true
  elseif kind == "camera.reset" then
    feel.play({
      kind = "animate",
      duration = payload.duration or self.defaults.tweenDuration,
      ease = payload.ease,
      to = {
        x = self.defaults.x,
        y = self.defaults.y,
        scale = self.defaults.scale,
        rotation = self.defaults.rotation,
      },
    }, self.cameraTarget)
    self.shake.remaining = 0
    self.shake.x = 0
    self.shake.y = 0
    return true
  elseif kind == "screen.flash" then
    self.flash.color = copyColor(payload.color, DEFAULT_FLASH)
    self.flash.amount = payload.amount or payload.alpha or self.defaults.flashAmount
    self.flash.duration = payload.duration or self.defaults.flashDuration
    self.flash.remaining = self.flash.duration
    self.flash.alpha = self.flash.amount
    return true
  elseif kind == "screen.fade" then
    self.fade.color = copyColor(payload.color, DEFAULT_FADE)
    self.fade.amount = payload.alpha or payload.amount or self.defaults.fadeAmount
    self.fade.duration = payload.duration or self.defaults.fadeDuration
    self.fade.remaining = self.fade.duration
    self.fade.alpha = self.fade.amount
    return true
  elseif kind == "screen.clear" then
    self.flash.alpha = 0
    self.flash.remaining = 0
    self.fade.alpha = 0
    self.fade.remaining = 0
    return true
  elseif kind == "sound.play" then
    return playSound(self.soundEntries[payload.cue], payload)
  elseif kind == "sound.stop" then
    if payload.cue then
      return self:stopSound(payload.cue)
    end
    return self:stopSounds()
  elseif kind == "sound.pause" then
    return pauseSources(self.soundEntries[payload.cue])
  elseif kind == "sound.resume" then
    return resumeSources(self.soundEntries[payload.cue])
  elseif kind == "sound.volume" then
    return setSoundValue(self.soundEntries[payload.cue], "volume", payload.volume, payload.duration, payload.ease)
  elseif kind == "sound.pitch" then
    return setSoundValue(self.soundEntries[payload.cue], "pitch", payload.pitch, payload.duration, payload.ease)
  elseif kind == "sound.pan" then
    return setSoundValue(self.soundEntries[payload.cue], "pan", payload.pan, payload.duration, payload.ease)
  elseif kind == "haptic.play" then
    local played = false
    local systemDuration = payload.duration or self.defaults.hapticDuration
    if payload.name then
      local entry = self.hapticEntries[payload.name]
      if entry then
        systemDuration = payload.duration or entry.duration or self.defaults.hapticDuration
      end
      played = playHapticEntry(entry, payload, self.defaults.hapticDuration)
    else
      for _, entry in pairs(self.hapticEntries) do
        played = playHapticEntry(entry, payload, self.defaults.hapticDuration) or played
      end
    end
    if payload.system ~= false then
      played = vibrateSystem(systemDuration) or played
    end
    return played
  elseif kind == "haptic.stop" then
    local stopped
    if payload.name then
      stopped = self:stopHaptic(payload.name)
    else
      stopped = self:stopHaptics()
    end
    if payload.system ~= false then
      stopped = vibrateSystem(0) or stopped
    end
    return stopped
  elseif kind == "haptic.vibrate" then
    return vibrateSystem(payload.duration)
  elseif kind == "particle.emit" then
    return emitParticle(particleEntry(self, payload), payload)
  elseif kind == "particle.start" then
    return startParticle(particleEntry(self, payload), payload)
  elseif kind == "particle.stop" then
    return stopParticle(particleEntry(self, payload))
  elseif kind == "particle.reset" then
    return resetParticle(particleEntry(self, payload))
  elseif kind == "particle.move" then
    local entry = particleEntry(self, payload)
    setParticlePosition(entry, payload)
    return entry ~= nil
  elseif kind == "shader.send" then
    return sendShaderValue(shaderEntry(self, payload), payload.uniform, payload.value)
  elseif kind == "shader.tween" then
    return tweenShaderValue(shaderEntry(self, payload), payload.uniform, payload.value, payload.duration, payload.ease)
  elseif kind == "shader.apply" then
    return applyShader(self, shaderEntry(self, payload))
  elseif kind == "shader.clear" then
    if love and love.graphics and love.graphics.setShader then
      love.graphics.setShader()
      self.activeShader = nil
      self.shaderStack = {}
      return true
    end
    return false
  end

  return false, ctx
end

function Adapter:audio(event)
  return playSound(self.soundEntries[event and event.cue], event)
end

function Adapter:handlers(extra)
  extra = extra or {}
  local opts = {}
  for key, value in pairs(extra) do
    opts[key] = value
  end

  opts.emit = function(event, ctx)
    self:emit(event, ctx)
    if type(extra.emit) == "function" then
      extra.emit(event, ctx)
    end
  end

  opts.audio = function(event, ctx)
    self:audio(event)
    if type(extra.audio) == "function" then
      extra.audio(event, ctx)
    end
  end

  return opts
end

function Adapter:push()
  if not love or not love.graphics then
    return
  end

  if love.graphics.push then
    love.graphics.push()
  end
  if love.graphics.translate then
    love.graphics.translate(self.camera.x + self.shake.x, self.camera.y + self.shake.y)
  end
  if love.graphics.rotate then
    love.graphics.rotate(self.camera.rotation)
  end
  if love.graphics.scale then
    love.graphics.scale(self.camera.scale)
  end
end

function Adapter:pop()
  if love and love.graphics and love.graphics.pop then
    love.graphics.pop()
  end
end

function Adapter:drawOverlay()
  local width, height = viewportSize(self.opts)
  self.flash.width = width
  self.flash.height = height
  self.fade.width = width
  self.fade.height = height

  drawOverlay(self.fade)
  drawOverlay(self.flash)
end

function Adapter:drawParticles()
  if not love or not love.graphics or not love.graphics.draw then
    return
  end
  if love.graphics.setColor then
    love.graphics.setColor(1, 1, 1, 1)
  end
  for _, name in ipairs(self.particleOrder) do
    local entry = self.particleEntries[name]
    if entry and entry.system then
      love.graphics.draw(entry.system)
    end
  end
end

function FeelLove.new(opts)
  opts = opts or {}
  local cameraTarget = feel.target({
    values = {
      x = opts.x or 0,
      y = opts.y or 0,
      scale = opts.scale or 1,
      rotation = opts.rotation or 0,
    },
  })

  local adapter = setmetatable({
    opts = opts,
    cameraTarget = cameraTarget,
    camera = cameraTarget.values,
    defaults = {
      x = opts.x or 0,
      y = opts.y or 0,
      scale = opts.scale or 1,
      rotation = opts.rotation or 0,
      shakeAmount = opts.shakeAmount or 6,
      shakeDuration = opts.shakeDuration or 0.22,
      shakeFrequency = opts.shakeFrequency or 42,
      flashAmount = opts.flashAmount or 0.5,
      flashDuration = opts.flashDuration or 0.18,
      fadeAmount = opts.fadeAmount or 1,
      fadeDuration = opts.fadeDuration or 0.35,
      tweenDuration = opts.duration or 0.16,
      hapticDuration = opts.hapticDuration or 0.12,
    },
    shake = {},
    flash = {},
    fade = {},
    soundEntries = {},
    hapticEntries = {},
    particleEntries = {},
    particleOrder = {},
    shaderEntries = {},
    shaderStack = {},
  }, Adapter)

  adapter:reset()
  return adapter
end

return FeelLove
