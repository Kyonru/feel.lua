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

function Adapter:reset()
  feel.clear(self.cameraTarget)

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

function Adapter:update(dt)
  dt = dt or 0

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
  end

  return false, ctx
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
    },
    shake = {},
    flash = {},
    fade = {},
  }, Adapter)

  adapter:reset()
  return adapter
end

return FeelLove
