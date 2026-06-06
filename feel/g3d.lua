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

local function applyModel(entry)
  local values = entry.target.values
  local scale = values.scale or 1
  local sx = values.sx or scale
  local sy = values.sy or scale
  local sz = values.sz or scale

  maybeCall(entry.model, "setTranslation", values.x or 0, values.y or 0, values.z or 0)
  maybeCall(entry.model, "setRotation", values.rx or 0, values.ry or 0, values.rz or 0)
  maybeCall(entry.model, "setScale", sx, sy, sz)
end

local function applyCamera(entry, camera)
  if not camera then
    return false
  end

  local values = entry.target.values
  if entry.mode == "direction" then
    if type(camera.lookInDirection) == "function" then
      camera.lookInDirection(
        values.x or 0,
        values.y or 0,
        values.z or 0,
        values.direction or 0,
        values.pitch or 0
      )
      return true
    end
    return false
  end

  if type(camera.lookAt) == "function" then
    camera.lookAt(values.x or 0, values.y or 0, values.z or 0, values.tx or 0, values.ty or 0, values.tz or 0)
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
