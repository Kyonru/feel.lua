local moduleName = ...
local prefix = "feel"
if moduleName and moduleName ~= "" then
  prefix = moduleName:gsub("%.g3d$", "")
end

---@type FeelModule
local feel = require(prefix)

---@module "feel.g3d"

---@class FeelG3dModule
---@field new fun(g3d: FeelG3dModuleLike): FeelG3dAdapter
---@type FeelG3dModule
local FeelG3d = {}

---@class FeelG3dAdapter
---@field g3d FeelG3dModuleLike
---@field modelEntries table<string, FeelG3dModelEntry>
---@field modelOrder string[]
---@field cameraEntry? FeelG3dCameraEntry
local Adapter = {}
Adapter.__index = Adapter

local MODEL_DEFAULTS = {
  x = 0,
  y = 0,
  z = 0,
  rx = 0,
  ry = 0,
  rz = 0,
  scale = 1,
  offsetX = 0,
  offsetY = 0,
  offsetZ = 0,
  shakeX = 0,
  shakeY = 0,
  shakeZ = 0,
  rotationOffsetX = 0,
  rotationOffsetY = 0,
  rotationOffsetZ = 0,
  fxScale = 1,
  fxScaleX = 1,
  fxScaleY = 1,
  fxScaleZ = 1,
}

local CAMERA_DEFAULTS = {
  x = 0,
  y = 0,
  z = 0,
  tx = 1,
  ty = 0,
  tz = 0,
  direction = 0,
  pitch = 0,
  shakeX = 0,
  shakeY = 0,
  shakeZ = 0,
  heightKick = 0,
  yawKick = 0,
  targetOffsetX = 0,
  targetOffsetY = 0,
  targetOffsetZ = 0,
  fovKick = 0,
}

local MODEL_FEEDBACK_RESET = {
  offsetX = 0,
  offsetY = 0,
  offsetZ = 0,
  shakeX = 0,
  shakeY = 0,
  shakeZ = 0,
  rotationOffsetX = 0,
  rotationOffsetY = 0,
  rotationOffsetZ = 0,
  fxScale = 1,
  fxScaleX = 1,
  fxScaleY = 1,
  fxScaleZ = 1,
}

local CAMERA_FEEDBACK_RESET = {
  shakeX = 0,
  shakeY = 0,
  shakeZ = 0,
  heightKick = 0,
  yawKick = 0,
  targetOffsetX = 0,
  targetOffsetY = 0,
  targetOffsetZ = 0,
  fovKick = 0,
}

local function copyMeta(opts, defaults)
  opts = opts or {}
  local meta = {}
  for key, value in pairs(opts) do
    if key ~= "values" then
      meta[key] = value
    end
  end

  local values = {}
  for key, value in pairs(defaults) do
    values[key] = value
  end
  for key, value in pairs(opts.values or {}) do
    values[key] = value
  end
  meta.values = values
  return meta
end

local function eventKind(event)
  return event and (event.kind or event.event or event.name) or nil
end

local function eventPayload(event)
  return event and event.payload or {}
end

local function maybeCall(object, method, ...)
  local fn = object and object[method]
  if type(fn) == "function" then
    fn(object, ...)
    return true
  end
  return false
end

local function targetOptions(payload, key)
  payload = payload or {}
  return {
    restart = payload.restart ~= false,
    key = payload.key or key,
  }
end

local function playTarget(target, sequence, payload, key)
  feel.play(sequence, target, targetOptions(payload, key))
  return true
end

local function radians(value, payload)
  value = value or 0
  if payload and payload.radians then
    return value
  end
  return math.rad(value)
end

local function setNowStep(values)
  return {
    kind = "callback",
    callback = function(ctx)
      local target = ctx and ctx.target
      if not target or not target.values then
        return
      end
      for key, value in pairs(values) do
        target.values[key] = value
      end
    end,
  }
end

local function animateOrSet(values, duration, ease)
  duration = duration or 0
  if duration <= 0 then
    return setNowStep(values)
  end
  return {
    kind = "animate",
    duration = duration,
    ease = ease,
    to = values,
  }
end

local function pulseSequence(values, resetValues, payload)
  payload = payload or {}
  return {
    animateOrSet(values, payload.duration or 0.08, payload.ease or "quadout"),
    animateOrSet(resetValues, payload.returnDuration or 0.18, payload.returnEase or payload.ease or "backout"),
  }
end

local function randomShakeSequence(fields, payload)
  payload = payload or {}
  local amount = payload.amount or 0.1
  local duration = payload.duration or 0.14
  local frequency = payload.frequency or 32
  local count = math.max(1, math.floor(duration * frequency))
  local stepDuration = duration / count
  local sequence = {}
  local reset = {}

  for _, field in ipairs(fields) do
    reset[field.name] = 0
  end

  for _ = 1, count do
    local to = {}
    for _, field in ipairs(fields) do
      local fieldAmount = field.amount or amount
      to[field.name] = (math.random() * 2 - 1) * fieldAmount
    end
    sequence[#sequence + 1] = {
      kind = "animate",
      duration = stepDuration,
      ease = payload.ease or "linear",
      to = to,
    }
  end

  sequence[#sequence + 1] = animateOrSet(
    reset,
    payload.returnDuration or math.min(0.06, stepDuration),
    payload.returnEase or "quadout"
  )
  return sequence
end

local function applyModel(entry)
  local values = entry.target.values
  local scale = values.scale or 1
  local fxScale = values.fxScale or 1
  local sx = (values.sx or scale) * fxScale * (values.fxScaleX or 1)
  local sy = (values.sy or scale) * fxScale * (values.fxScaleY or 1)
  local sz = (values.sz or scale) * fxScale * (values.fxScaleZ or 1)

  maybeCall(
    entry.model,
    "setTranslation",
    (values.x or 0) + (values.offsetX or 0) + (values.shakeX or 0),
    (values.y or 0) + (values.offsetY or 0) + (values.shakeY or 0),
    (values.z or 0) + (values.offsetZ or 0) + (values.shakeZ or 0)
  )
  maybeCall(
    entry.model,
    "setRotation",
    (values.rx or 0) + (values.rotationOffsetX or 0),
    (values.ry or 0) + (values.rotationOffsetY or 0),
    (values.rz or 0) + (values.rotationOffsetZ or 0)
  )
  maybeCall(entry.model, "setScale", sx, sy, sz)
end

local function applyCamera(entry, camera)
  if not camera then
    return false
  end

  local values = entry.target.values
  local x = (values.x or 0) + (values.shakeX or 0)
  local y = (values.y or 0) + (values.shakeY or 0)
  local z = (values.z or 0) + (values.shakeZ or 0) + (values.heightKick or 0)

  if camera.fov ~= nil or values.fovKick ~= 0 then
    camera.fov = (values.fov or entry.baseFov or camera.fov or math.pi / 2) + (values.fovKick or 0)
    if type(camera.updateProjectionMatrix) == "function" then
      camera.updateProjectionMatrix()
    end
  end

  if entry.mode == "direction" then
    if type(camera.lookInDirection) == "function" then
      camera.lookInDirection(
        x,
        y,
        z,
        (values.direction or 0) + (values.yawKick or 0),
        values.pitch or 0
      )
      return true
    end
    return false
  end

  if type(camera.lookAt) == "function" then
    camera.lookAt(
      x,
      y,
      z,
      (values.tx or 0) + (values.targetOffsetX or 0),
      (values.ty or 0) + (values.targetOffsetY or 0),
      (values.tz or 0) + (values.targetOffsetZ or 0)
    )
    return true
  end

  return false
end

---@param g3d FeelG3dModuleLike
---@return FeelG3dAdapter
function FeelG3d.new(g3d)
  assert(type(g3d) == "table", "g3d must be a table")
  return setmetatable({
    g3d = g3d,
    modelEntries = {},
    modelOrder = {},
    cameraEntry = nil,
  }, Adapter)
end

---@param name string
---@param model FeelG3dModelLike
---@param opts? FeelG3dModelOptions
---@return FeelTarget
function Adapter:model(name, model, opts)
  assert(type(name) == "string", "model name must be a string")
  assert(type(model) == "table", "model must be a table")

  local target = feel.target(copyMeta(opts, MODEL_DEFAULTS))
  local entry = {
    name = name,
    model = model,
    target = target,
  }

  if not self.modelEntries[name] then
    self.modelOrder[#self.modelOrder + 1] = name
  end
  self.modelEntries[name] = entry
  applyModel(entry)

  return target
end

---@param opts? FeelG3dCameraOptions
---@return FeelTarget
function Adapter:camera(opts)
  opts = opts or {}
  local target = feel.target(copyMeta(opts, CAMERA_DEFAULTS))
  local entry = {
    mode = opts.mode or "lookAt",
    target = target,
    baseFov = opts.baseFov or opts.fov or (self.g3d.camera and self.g3d.camera.fov),
  }
  self.cameraEntry = entry
  applyCamera(entry, self.g3d.camera)
  return target
end

---@param name string
---@return FeelG3dModelEntry?
function Adapter:get(name)
  return self.modelEntries[name]
end

---@param name? string
---@return boolean
function Adapter:clear(name)
  if name then
    if not self.modelEntries[name] then
      return false
    end
    self.modelEntries[name] = nil
    for index = #self.modelOrder, 1, -1 do
      if self.modelOrder[index] == name then
        table.remove(self.modelOrder, index)
        break
      end
    end
    return true
  end

  local hadEntries = self.cameraEntry ~= nil or next(self.modelEntries) ~= nil
  self.modelEntries = {}
  self.modelOrder = {}
  self.cameraEntry = nil
  return hadEntries
end

---@return FeelG3dAdapter
function Adapter:update()
  for _, name in ipairs(self.modelOrder) do
    local entry = self.modelEntries[name]
    if entry then
      applyModel(entry)
    end
  end

  if self.cameraEntry then
    applyCamera(self.cameraEntry, self.g3d.camera)
  end

  return self
end

---@param event? FeelG3dEvent
---@param ctx? any
---@return boolean
---@return any ctx
function Adapter:emit(event, ctx)
  local kind = eventKind(event)
  local payload = eventPayload(event)

  if kind == "g3d.model.lookAt" then
    local entry = payload.name and self.modelEntries[payload.name] or nil
    if entry and entry.model and type(entry.model.lookAt) == "function" then
      entry.model:lookAt({ payload.x or 0, payload.y or 0, payload.z or 0 }, payload.up)
      return true, ctx
    end
  elseif kind == "g3d.camera.lookAt" then
    local camera = self.g3d.camera
    if camera and type(camera.lookAt) == "function" then
      camera.lookAt(payload.x or 0, payload.y or 0, payload.z or 0, payload.tx or 0, payload.ty or 0, payload.tz or 0)
      return true, ctx
    end
  elseif kind == "g3d.camera.direction" then
    local camera = self.g3d.camera
    if camera and type(camera.lookInDirection) == "function" then
      camera.lookInDirection(
        payload.x,
        payload.y,
        payload.z,
        payload.direction,
        payload.pitch
      )
      return true, ctx
    end
  elseif kind == "g3d.camera.resize" then
    local camera = self.g3d.camera
    if camera and type(camera.resize) == "function" then
      camera.resize(payload.width, payload.height)
      return true, ctx
    end
  elseif kind == "g3d.camera.shake" then
    if self.cameraEntry then
      return playTarget(self.cameraEntry.target, randomShakeSequence({
        { name = "shakeX", amount = payload.xAmount or payload.amount },
        { name = "shakeY", amount = payload.yAmount or payload.amount },
        { name = "shakeZ", amount = payload.zAmount or payload.amount },
      }, payload), payload, "g3d.camera.shake"), ctx
    end
  elseif kind == "g3d.camera.fov" then
    if self.cameraEntry then
      local amount = payload.value or radians(payload.amount or 0, payload)
      local sequence = pulseSequence({ fovKick = amount }, { fovKick = 0 }, payload)
      return playTarget(self.cameraEntry.target, sequence, payload, "g3d.camera.fov"), ctx
    end
  elseif kind == "g3d.camera.height" then
    if self.cameraEntry then
      local amount = payload.value or payload.amount or payload.height or 0
      local sequence = pulseSequence({ heightKick = amount }, { heightKick = 0 }, payload)
      return playTarget(self.cameraEntry.target, sequence, payload, "g3d.camera.height"), ctx
    end
  elseif kind == "g3d.camera.yaw" then
    if self.cameraEntry then
      local amount = payload.value or radians(payload.amount or 0, payload)
      local sequence = pulseSequence({ yawKick = amount }, { yawKick = 0 }, payload)
      return playTarget(self.cameraEntry.target, sequence, payload, "g3d.camera.yaw"), ctx
    end
  elseif kind == "g3d.camera.targetOffset" then
    if self.cameraEntry then
      local values = {
        targetOffsetX = payload.x or payload.offsetX or 0,
        targetOffsetY = payload.y or payload.offsetY or 0,
        targetOffsetZ = payload.z or payload.offsetZ or 0,
      }
      return playTarget(self.cameraEntry.target, pulseSequence(values, {
        targetOffsetX = 0,
        targetOffsetY = 0,
        targetOffsetZ = 0,
      }, payload), payload, "g3d.camera.targetOffset"), ctx
    end
  elseif kind == "g3d.camera.reset" then
    if self.cameraEntry then
      return playTarget(self.cameraEntry.target, {
        animateOrSet(CAMERA_FEEDBACK_RESET, payload.duration or 0, payload.ease),
      }, payload, "g3d.camera.reset"), ctx
    end
  elseif kind == "g3d.model.scalePunch" then
    local entry = payload.name and self.modelEntries[payload.name] or nil
    if entry then
      local scale = payload.scale or (1 + (payload.amount or 0.18))
      local sequence = pulseSequence({ fxScale = scale }, { fxScale = 1 }, payload)
      return playTarget(entry.target, sequence, payload, "g3d.model.scalePunch." .. payload.name), ctx
    end
  elseif kind == "g3d.model.squash" then
    local entry = payload.name and self.modelEntries[payload.name] or nil
    if entry then
      local amount = payload.amount or 0.18
      local values = {
        fxScaleX = payload.sx or payload.xScale or (1 + amount),
        fxScaleY = payload.sy or payload.yScale or (1 + amount),
        fxScaleZ = payload.sz or payload.zScale or (1 - amount),
      }
      return playTarget(entry.target, pulseSequence(values, {
        fxScaleX = 1,
        fxScaleY = 1,
        fxScaleZ = 1,
      }, payload), payload, "g3d.model.squash." .. payload.name), ctx
    end
  elseif kind == "g3d.model.positionShake" then
    local entry = payload.name and self.modelEntries[payload.name] or nil
    if entry then
      return playTarget(entry.target, randomShakeSequence({
        { name = "shakeX", amount = payload.xAmount or payload.amount },
        { name = "shakeY", amount = payload.yAmount or payload.amount },
        { name = "shakeZ", amount = payload.zAmount or payload.amount },
      }, payload), payload, "g3d.model.positionShake." .. payload.name), ctx
    end
  elseif kind == "g3d.model.rotationShake" then
    local entry = payload.name and self.modelEntries[payload.name] or nil
    if entry then
      return playTarget(entry.target, randomShakeSequence({
        { name = "rotationOffsetX", amount = payload.xAmount or payload.amount },
        { name = "rotationOffsetY", amount = payload.yAmount or payload.amount },
        { name = "rotationOffsetZ", amount = payload.zAmount or payload.amount },
      }, payload), payload, "g3d.model.rotationShake." .. payload.name), ctx
    end
  elseif kind == "g3d.model.reset" then
    local entry = payload.name and self.modelEntries[payload.name] or nil
    if entry then
      return playTarget(entry.target, {
        animateOrSet(MODEL_FEEDBACK_RESET, payload.duration or 0, payload.ease),
      }, payload, "g3d.model.reset." .. payload.name), ctx
    end
  end

  return false, ctx
end

---@param extra? FeelG3dHandlers
---@return FeelG3dHandlers
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

return FeelG3d
