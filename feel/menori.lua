local moduleName = ...
local prefix = "feel"
if moduleName and moduleName ~= "" then
  prefix = moduleName:gsub("%.menori$", "")
end

---@type FeelModule
local feel = require(prefix)

---@module "feel.menori"

local unpack = table.unpack or unpack

---@class FeelMenoriModule
---@field new fun(menori: FeelMenoriModuleLike, opts?: FeelMenoriNewOptions): FeelMenoriAdapter
---@type FeelMenoriModule
local FeelMenori = {}

---@class FeelMenoriAdapter
---@field menori FeelMenoriModuleLike
---@field defaultCamera? FeelMenoriCameraLike
---@field defaultEnvironment? FeelMenoriEnvironmentLike
---@field nodeEntries table<string, FeelMenoriNodeEntry>
---@field nodeOrder string[]
---@field animationEntries table<string, FeelMenoriAnimationEntry>
---@field animationOrder string[]
---@field uniformEntries table<string, FeelMenoriUniformEntry>
---@field uniformOrder string[]
---@field cameraEntry? FeelMenoriCameraEntry
local Adapter = {}
Adapter.__index = Adapter

local NODE_DEFAULTS = {
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
  tx = 0,
  ty = 0,
  tz = 0,
  upX = 0,
  upY = 1,
  upZ = 0,
  yaw = 0,
  pitch = 0,
  roll = 0,
  direction = 0,
  distance = 1,
  shakeX = 0,
  shakeY = 0,
  shakeZ = 0,
  heightKick = 0,
  yawKick = 0,
  targetOffsetX = 0,
  targetOffsetY = 0,
  targetOffsetZ = 0,
  fovKick = 0,
  distanceKick = 0,
}

local ANIMATION_DEFAULTS = {
  speed = 1,
  playing = 1,
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
  distanceKick = 0,
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
  for key, value in pairs(defaults or {}) do
    values[key] = value
  end
  for key, value in pairs(opts.values or {}) do
    values[key] = value
  end
  meta.values = values
  return meta
end

local function copyValues(values)
  local result = {}
  for key, value in pairs(values or {}) do
    result[key] = value
  end
  return result
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

local function mlOf(menori)
  return (menori and menori.ml) or {}
end

local function newVec3(menori, x, y, z)
  local vec3 = mlOf(menori).vec3
  if type(vec3) == "function" then
    return vec3(x or 0, y or 0, z or 0)
  end
  return { x = x or 0, y = y or 0, z = z or 0 }
end

local function newVec4(menori, x, y, z, w)
  local vec4 = mlOf(menori).vec4
  if type(vec4) == "function" then
    return vec4(x or 0, y or 0, z or 0, w or 0)
  end
  return { x = x or 0, y = y or 0, z = z or 0, w = w or 0 }
end

local function setVectorField(object, field, menori, x, y, z)
  local current = object and object[field]
  if current and type(current.set) == "function" then
    current:set(x or 0, y or 0, z or 0)
    return current
  end
  local value = newVec3(menori, x, y, z)
  if object then
    object[field] = value
  end
  return value
end

local function menoriQuatFromEuler(menori, rx, ry, rz)
  local quat = mlOf(menori).quat
  if quat and type(quat.from_euler_angles) == "function" then
    return quat.from_euler_angles(rz or 0, ry or 0, rx or 0)
  end

  local cy = math.cos((rz or 0) * 0.5)
  local sy = math.sin((rz or 0) * 0.5)
  local cp = math.cos((ry or 0) * 0.5)
  local sp = math.sin((ry or 0) * 0.5)
  local cr = math.cos((rx or 0) * 0.5)
  local sr = math.sin((rx or 0) * 0.5)

  return {
    x = sr * cp * cy - cr * sp * sy,
    y = cr * sp * cy + sr * cp * sy,
    z = cr * cp * sy - sr * sp * cy,
    w = cr * cp * cy + sr * sp * sy,
  }
end

local function vectorLength(x, y, z)
  return math.sqrt(x * x + y * y + z * z)
end

local function normalize(x, y, z)
  local length = vectorLength(x, y, z)
  if length == 0 then
    return 0, 0, 1
  end
  return x / length, y / length, z / length
end

local function directionFromYawPitch(yaw, pitch)
  local cp = math.cos(pitch or 0)
  return math.sin(yaw or 0) * cp, math.sin(pitch or 0), math.cos(yaw or 0) * cp
end

local function orbitOffset(yaw, pitch, distance)
  local dx, dy, dz = directionFromYawPitch(yaw, pitch)
  distance = distance or 1
  return dx * distance, dy * distance, dz * distance
end

local function rolledUpVector(forwardX, forwardY, forwardZ, roll)
  if not roll or roll == 0 then
    return 0, 1, 0
  end

  local fx, fy, fz = normalize(forwardX, forwardY, forwardZ)
  local ux, uy, uz = 0, 1, 0
  local c = math.cos(roll)
  local s = math.sin(roll)
  local dot = fx * ux + fy * uy + fz * uz
  local cx = fy * uz - fz * uy
  local cy = fz * ux - fx * uz
  local cz = fx * uy - fy * ux

  return
    ux * c + cx * s + fx * dot * (1 - c),
    uy * c + cy * s + fy * dot * (1 - c),
    uz * c + cz * s + fz * dot * (1 - c)
end

local function looksLikeCamera(value)
  return type(value) == "table"
    and (value.eye ~= nil or value.center ~= nil or value.m_projection ~= nil or type(value.update_view_matrix) == "function")
end

local function looksLikeEnvironment(value)
  return type(value) == "table" and value.camera ~= nil and not looksLikeCamera(value)
end

local function resolveCameraArgs(adapter, cameraOrEnvironment, opts)
  local camera
  local environment

  if looksLikeEnvironment(cameraOrEnvironment) then
    environment = cameraOrEnvironment
    camera = environment.camera
    opts = opts or {}
  elseif looksLikeCamera(cameraOrEnvironment) then
    camera = cameraOrEnvironment
    opts = opts or {}
  else
    opts = cameraOrEnvironment or opts or {}
  end

  environment = opts.environment or environment or adapter.defaultEnvironment
  camera = opts.camera or camera or adapter.defaultCamera or (environment and environment.camera)
  return camera, environment, opts
end

local function updateProjection(entry, camera, values, force)
  if not camera then
    return false
  end

  local fov = values.fov or entry.baseFov
  local aspect = values.aspect or entry.aspect
  local near = values.near or entry.near
  local far = values.far or entry.far

  if not fov or not aspect or not near or not far then
    return false
  end

  fov = fov + (values.fovKick or 0)

  if not force
    and entry.lastFov == fov
    and entry.lastAspect == aspect
    and entry.lastNear == near
    and entry.lastFar == far then
    return false
  end

  entry.lastFov = fov
  entry.lastAspect = aspect
  entry.lastNear = near
  entry.lastFar = far

  if camera.m_projection and type(camera.m_projection.perspective_RH_NO) == "function" then
    camera.m_projection:perspective_RH_NO(fov, aspect, near, far)
    if type(camera.m_projection.clone) == "function" then
      camera.m_inv_projection = camera.m_projection:clone()
      if camera.m_inv_projection and type(camera.m_inv_projection.inverse) == "function" then
        camera.m_inv_projection:inverse()
      end
    end
    return true
  end

  camera.fov = fov
  camera.aspect = aspect
  camera.near = near
  camera.far = far
  return true
end

local function applyNode(adapter, entry)
  local values = entry.target.values
  local scale = values.scale or 1
  local fxScale = values.fxScale or 1
  local sx = (values.sx or scale) * fxScale * (values.fxScaleX or 1)
  local sy = (values.sy or scale) * fxScale * (values.fxScaleY or 1)
  local sz = (values.sz or scale) * fxScale * (values.fxScaleZ or 1)

  maybeCall(
    entry.node,
    "set_position",
    (values.x or 0) + (values.offsetX or 0) + (values.shakeX or 0),
    (values.y or 0) + (values.offsetY or 0) + (values.shakeY or 0),
    (values.z or 0) + (values.offsetZ or 0) + (values.shakeZ or 0)
  )
  maybeCall(
    entry.node,
    "set_rotation",
    menoriQuatFromEuler(
      adapter.menori,
      (values.rx or 0) + (values.rotationOffsetX or 0),
      (values.ry or 0) + (values.rotationOffsetY or 0),
      (values.rz or 0) + (values.rotationOffsetZ or 0)
    )
  )
  maybeCall(entry.node, "set_scale", sx, sy, sz)
end

local function applyCamera(entry, camera, menori)
  if not camera then
    return false
  end

  local values = entry.target.values
  updateProjection(entry, camera, values, entry.forceProjection)
  entry.forceProjection = false

  local eyeX = (values.x or 0) + (values.shakeX or 0)
  local eyeY = (values.y or 0) + (values.shakeY or 0) + (values.heightKick or 0)
  local eyeZ = (values.z or 0) + (values.shakeZ or 0)
  local centerX = (values.tx or 0) + (values.targetOffsetX or 0)
  local centerY = (values.ty or 0) + (values.targetOffsetY or 0)
  local centerZ = (values.tz or 0) + (values.targetOffsetZ or 0)
  local upX = values.upX or 0
  local upY = values.upY or 1
  local upZ = values.upZ or 0

  if entry.mode == "orbit" then
    local distance = (values.distance or 1) + (values.distanceKick or 0)
    local yaw = (values.yaw or values.direction or 0) + (values.yawKick or 0)
    local pitch = values.pitch or 0
    local ox, oy, oz = orbitOffset(yaw, pitch, distance)
    eyeX = centerX + ox
    eyeY = centerY + oy + (values.heightKick or 0)
    eyeZ = centerZ + oz
    upX, upY, upZ = rolledUpVector(-ox, -oy, -oz, values.roll or 0)
  elseif entry.mode == "direction" then
    local yaw = (values.direction or values.yaw or 0) + (values.yawKick or 0)
    local pitch = values.pitch or 0
    local dx, dy, dz = directionFromYawPitch(yaw, pitch)
    centerX = eyeX + dx + (values.targetOffsetX or 0)
    centerY = eyeY + dy + (values.targetOffsetY or 0)
    centerZ = eyeZ + dz + (values.targetOffsetZ or 0)
    upX, upY, upZ = rolledUpVector(dx, dy, dz, values.roll or 0)
  end

  setVectorField(camera, "eye", menori, eyeX, eyeY, eyeZ)
  setVectorField(camera, "center", menori, centerX, centerY, centerZ)
  setVectorField(camera, "up", menori, upX, upY, upZ)
  maybeCall(camera, "update_view_matrix")

  if entry.environment and entry.viewPositionUniform and type(entry.environment.set_vector) == "function" then
    entry.environment:set_vector(entry.viewPositionUniform, camera.eye)
  end

  return true
end

local function applyAnimation(entry, dt)
  local animations = entry.animations
  if not animations then
    return false
  end

  local values = entry.target.values
  if values.actionIndex and values.actionIndex ~= entry.actionIndex and type(animations.set_action) == "function" then
    animations:set_action(values.actionIndex)
    entry.actionIndex = values.actionIndex
  end

  if entry.driveTime then
    if values.time ~= nil then
      animations.accumulator = values.time
    end
    if type(animations.update) == "function" then
      animations:update(0)
    end
    return true
  end

  if dt and dt ~= 0 and values.playing ~= 0 and type(animations.update) == "function" then
    animations:update(dt * (values.speed or 1))
    return true
  end
  return false
end

local function inferUniformDefaults(opts)
  opts = opts or {}
  local method = opts.method
  if opts.type == "color" then
    method = "set_color"
  elseif opts.type == "vector" then
    method = "set_vector"
  end

  if method == "set_color" then
    return { r = 1, g = 1, b = 1, a = 1 }
  elseif method == "set_vector" then
    return { x = 0, y = 0, z = 0 }
  end
  return { value = 0 }
end

local function inferUniformKeys(entry)
  local opts = entry.opts or {}
  if opts.keys then
    return opts.keys
  end
  if entry.method == "set_color" then
    return { "r", "g", "b", "a" }
  elseif entry.method == "set_vector" then
    local values = entry.target.values
    if values.w ~= nil then
      return { "x", "y", "z", "w" }
    elseif values.z ~= nil then
      return { "x", "y", "z" }
    end
    return { "x", "y" }
  end
  return { "value" }
end

local function collectValues(values, keys)
  local result = {}
  for index, key in ipairs(keys) do
    result[index] = values[key]
  end
  return result
end

local function makeVector(menori, values)
  if #values >= 4 then
    return newVec4(menori, values[1], values[2], values[3], values[4])
  elseif #values == 2 and type(mlOf(menori).vec2) == "function" then
    return mlOf(menori).vec2(values[1], values[2])
  end
  return newVec3(menori, values[1], values[2], values[3])
end

local function normalizeUniformMethod(opts)
  opts = opts or {}
  if opts.type == "color" then
    return "set_color"
  elseif opts.type == "vector" then
    return "set_vector"
  elseif opts.type == "matrix" then
    return "set_matrix"
  end
  return opts.method or "set"
end

local function applyUniform(adapter, entry)
  local object = entry.object
  if not object then
    return false
  end

  local keys = entry.keys or inferUniformKeys(entry)
  entry.keys = keys
  local values = collectValues(entry.target.values, keys)

  if entry.method == "set_color" then
    if type(object.set_color) == "function" then
      object:set_color(entry.uniform, unpack(values))
      return true
    end
  elseif entry.method == "set_vector" then
    if type(object.set_vector) == "function" then
      object:set_vector(entry.uniform, makeVector(adapter.menori, values))
      return true
    end
  elseif entry.method == "set_matrix" then
    local matrix = entry.opts and entry.opts.matrix
    if matrix and type(object.set_matrix) == "function" then
      object:set_matrix(entry.uniform, matrix)
      return true
    end
  elseif type(object.set) == "function" then
    if #keys == 1 and keys[1] == "value" then
      object:set(entry.uniform, values[1])
    else
      object:set(entry.uniform, values)
    end
    return true
  end

  return false
end

local function setAnimationAction(entry, payload)
  local animations = entry and entry.animations
  if not animations then
    return false
  end

  local action = payload.action or payload.actionName
  local index = payload.index or payload.actionIndex
  if type(action) == "string" and type(animations.set_action_by_name) == "function" then
    animations:set_action_by_name(action)
    entry.actionName = action
  elseif type(index) == "number" and type(animations.set_action) == "function" then
    animations:set_action(index)
    entry.actionIndex = index
    entry.target.values.actionIndex = index
  else
    return false
  end

  if payload.reset ~= false then
    animations.accumulator = payload.time or 0
    if entry.target.values.time ~= nil then
      entry.target.values.time = animations.accumulator
    end
  end
  return true
end

local function applyNodeLookAt(adapter, entry, payload)
  local node = entry and entry.node
  if not node or type(node.set_rotation) ~= "function" then
    return false
  end

  local values = entry.target.values
  local x = payload.fromX or values.x or (node.position and node.position.x) or 0
  local y = payload.fromY or values.y or (node.position and node.position.y) or 0
  local z = payload.fromZ or values.z or (node.position and node.position.z) or 0
  local tx = payload.x or payload.tx or 0
  local ty = payload.y or payload.ty or 0
  local tz = payload.z or payload.tz or 0
  local dx, dy, dz = normalize(tx - x, ty - y, tz - z)
  local quat = mlOf(adapter.menori).quat

  if quat and type(quat.from_direction) == "function" then
    local up = payload.up or newVec3(adapter.menori, payload.upX or 0, payload.upY or 1, payload.upZ or 0)
    node:set_rotation(quat.from_direction(newVec3(adapter.menori, dx, dy, dz), up))
    return true
  end

  local yaw = math.atan2 and math.atan2(dx, dz) or math.atan(dx, dz)
  local pitch = math.asin(dy)
  node:set_rotation(menoriQuatFromEuler(adapter.menori, pitch, yaw, 0))
  return true
end

local function applyCameraPayload(adapter, mode, payload)
  local entry = adapter.cameraEntry
  local camera = entry and entry.camera or adapter.defaultCamera
  if not camera then
    return false
  end

  if mode == "lookAt" then
    setVectorField(camera, "eye", adapter.menori, payload.x or 0, payload.y or 0, payload.z or 0)
    setVectorField(camera, "center", adapter.menori, payload.tx or 0, payload.ty or 0, payload.tz or 0)
    setVectorField(camera, "up", adapter.menori, payload.upX or 0, payload.upY or 1, payload.upZ or 0)
    maybeCall(camera, "update_view_matrix")
    return true
  elseif mode == "orbit" then
    local tx = payload.tx or payload.x or 0
    local ty = payload.ty or payload.y or 0
    local tz = payload.tz or payload.z or 0
    local distance = payload.distance or 1
    local ox, oy, oz = orbitOffset(payload.yaw or payload.direction or 0, payload.pitch or 0, distance)
    setVectorField(camera, "eye", adapter.menori, tx + ox, ty + oy, tz + oz)
    setVectorField(camera, "center", adapter.menori, tx, ty, tz)
    setVectorField(camera, "up", adapter.menori, rolledUpVector(-ox, -oy, -oz, payload.roll or 0))
    maybeCall(camera, "update_view_matrix")
    return true
  elseif mode == "projection" then
    entry = entry or {
      baseFov = payload.fov or 60,
      aspect = payload.aspect or 1.6666667,
      near = payload.near or payload.nclip or 0.1,
      far = payload.far or payload.fclip or 2048.0,
    }
    return updateProjection(entry, camera, {
      fov = payload.fov,
      aspect = payload.aspect,
      near = payload.near or payload.nclip,
      far = payload.far or payload.fclip,
      fovKick = 0,
    }, true)
  end

  return false
end

---@param menori FeelMenoriModuleLike
---@param opts? FeelMenoriNewOptions
---@return FeelMenoriAdapter
function FeelMenori.new(menori, opts)
  assert(type(menori) == "table", "menori must be a table")
  opts = opts or {}
  return setmetatable({
    menori = menori,
    defaultCamera = opts.camera or (opts.environment and opts.environment.camera),
    defaultEnvironment = opts.environment,
    nodeEntries = {},
    nodeOrder = {},
    animationEntries = {},
    animationOrder = {},
    uniformEntries = {},
    uniformOrder = {},
    cameraEntry = nil,
  }, Adapter)
end

---@param name string
---@param node FeelMenoriNodeLike
---@param opts? FeelMenoriNodeOptions
---@return FeelTarget
function Adapter:node(name, node, opts)
  assert(type(name) == "string", "node name must be a string")
  assert(type(node) == "table", "node must be a table")

  local target = feel.target(copyMeta(opts, NODE_DEFAULTS))
  local entry = {
    name = name,
    node = node,
    target = target,
  }

  if not self.nodeEntries[name] then
    self.nodeOrder[#self.nodeOrder + 1] = name
  end
  self.nodeEntries[name] = entry
  applyNode(self, entry)

  return target
end

Adapter.model = Adapter.node

---@param cameraOrEnvironment? FeelMenoriCameraLike|FeelMenoriEnvironmentLike|FeelMenoriCameraOptions
---@param opts? FeelMenoriCameraOptions
---@return FeelTarget
function Adapter:camera(cameraOrEnvironment, opts)
  local camera, environment
  camera, environment, opts = resolveCameraArgs(self, cameraOrEnvironment, opts)
  assert(type(camera) == "table", "camera must be a table")

  local target = feel.target(copyMeta(opts, CAMERA_DEFAULTS))
  local values = target.values
  local entry = {
    mode = opts.mode or "lookAt",
    camera = camera,
    environment = environment,
    target = target,
    baseFov = opts.baseFov or opts.fov or values.fov or camera.fov or 60,
    aspect = opts.aspect or values.aspect or camera.aspect or 1.6666667,
    near = opts.near or opts.nclip or values.near or values.nclip or camera.near or 0.1,
    far = opts.far or opts.fclip or values.far or values.fclip or camera.far or 2048.0,
    viewPositionUniform = opts.viewPositionUniform == false and false or (opts.viewPositionUniform or "view_position"),
    forceProjection = opts.forceProjection == true or opts.fov ~= nil or opts.aspect ~= nil or opts.near ~= nil or opts.far ~= nil,
  }

  self.defaultCamera = camera
  self.defaultEnvironment = environment or self.defaultEnvironment
  self.cameraEntry = entry
  applyCamera(entry, camera, self.menori)
  return target
end

---@param name string
---@param animations FeelMenoriAnimationsLike
---@param opts? FeelMenoriAnimationOptions
---@return FeelTarget
function Adapter:animation(name, animations, opts)
  assert(type(name) == "string", "animation name must be a string")
  assert(type(animations) == "table", "animations must be a table")
  opts = opts or {}

  local target = feel.target(copyMeta(opts, ANIMATION_DEFAULTS))
  local entry = {
    name = name,
    animations = animations,
    target = target,
    driveTime = opts.driveTime == true or (opts.values and opts.values.time ~= nil) or false,
  }

  if opts.action then
    setAnimationAction(entry, { action = opts.action, reset = opts.resetAction })
  elseif opts.actionIndex then
    setAnimationAction(entry, { index = opts.actionIndex, reset = opts.resetAction })
  end

  if not self.animationEntries[name] then
    self.animationOrder[#self.animationOrder + 1] = name
  end
  self.animationEntries[name] = entry
  applyAnimation(entry, 0)
  return target
end

---@param name string
---@param object FeelMenoriUniformListLike
---@param uniform string
---@param opts? FeelMenoriUniformOptions
---@return FeelTarget
function Adapter:uniform(name, object, uniform, opts)
  assert(type(name) == "string", "uniform name must be a string")
  assert(type(object) == "table", "uniform object must be a table")
  assert(type(uniform) == "string", "uniform key must be a string")
  opts = opts or {}

  local method = normalizeUniformMethod(opts)
  local target = feel.target(copyMeta(opts, inferUniformDefaults({ method = method, type = opts.type })))
  local entry = {
    name = name,
    object = object,
    uniform = uniform,
    method = method,
    opts = opts,
    target = target,
  }
  entry.keys = inferUniformKeys(entry)
  entry.resetValues = copyValues(target.values)

  if not self.uniformEntries[name] then
    self.uniformOrder[#self.uniformOrder + 1] = name
  end
  self.uniformEntries[name] = entry
  applyUniform(self, entry)
  return target
end

---@param name string
---@return FeelMenoriNodeEntry|FeelMenoriAnimationEntry|FeelMenoriUniformEntry?
function Adapter:get(name)
  return self.nodeEntries[name] or self.animationEntries[name] or self.uniformEntries[name]
end

---@param name? string
---@return boolean
function Adapter:clear(name)
  if name then
    local hadEntry = self.nodeEntries[name] ~= nil
      or self.animationEntries[name] ~= nil
      or self.uniformEntries[name] ~= nil

    self.nodeEntries[name] = nil
    self.animationEntries[name] = nil
    self.uniformEntries[name] = nil

    for index = #self.nodeOrder, 1, -1 do
      if self.nodeOrder[index] == name then
        table.remove(self.nodeOrder, index)
        break
      end
    end
    for index = #self.animationOrder, 1, -1 do
      if self.animationOrder[index] == name then
        table.remove(self.animationOrder, index)
        break
      end
    end
    for index = #self.uniformOrder, 1, -1 do
      if self.uniformOrder[index] == name then
        table.remove(self.uniformOrder, index)
        break
      end
    end
    return hadEntry
  end

  local hadEntries = self.cameraEntry ~= nil
    or next(self.nodeEntries) ~= nil
    or next(self.animationEntries) ~= nil
    or next(self.uniformEntries) ~= nil

  self.nodeEntries = {}
  self.nodeOrder = {}
  self.animationEntries = {}
  self.animationOrder = {}
  self.uniformEntries = {}
  self.uniformOrder = {}
  self.cameraEntry = nil
  return hadEntries
end

---@param dt? number
---@return FeelMenoriAdapter
function Adapter:update(dt)
  for _, name in ipairs(self.nodeOrder) do
    local entry = self.nodeEntries[name]
    if entry then
      applyNode(self, entry)
    end
  end

  if self.cameraEntry then
    applyCamera(self.cameraEntry, self.cameraEntry.camera, self.menori)
  end

  for _, name in ipairs(self.uniformOrder) do
    local entry = self.uniformEntries[name]
    if entry then
      applyUniform(self, entry)
    end
  end

  for _, name in ipairs(self.animationOrder) do
    local entry = self.animationEntries[name]
    if entry then
      applyAnimation(entry, dt or 0)
    end
  end

  return self
end

---@param event? FeelMenoriEvent
---@param ctx? any
---@return boolean
---@return any ctx
function Adapter:emit(event, ctx)
  local kind = eventKind(event)
  local payload = eventPayload(event)

  if kind == "menori.node.lookAt" then
    local entry = payload.name and self.nodeEntries[payload.name] or nil
    if entry then
      return applyNodeLookAt(self, entry, payload), ctx
    end
  elseif kind == "menori.node.visible" then
    local entry = payload.name and self.nodeEntries[payload.name] or nil
    if entry then
      local visible = payload.visible
      if visible == nil then
        visible = payload.enabled
      end
      entry.node.render_flag = visible ~= false
      return true, ctx
    end
  elseif kind == "menori.node.scalePunch" then
    local entry = payload.name and self.nodeEntries[payload.name] or nil
    if entry then
      local scale = payload.scale or (1 + (payload.amount or 0.18))
      local sequence = pulseSequence({ fxScale = scale }, { fxScale = 1 }, payload)
      return playTarget(entry.target, sequence, payload, "menori.node.scalePunch." .. payload.name), ctx
    end
  elseif kind == "menori.node.squash" then
    local entry = payload.name and self.nodeEntries[payload.name] or nil
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
      }, payload), payload, "menori.node.squash." .. payload.name), ctx
    end
  elseif kind == "menori.node.positionShake" then
    local entry = payload.name and self.nodeEntries[payload.name] or nil
    if entry then
      return playTarget(entry.target, randomShakeSequence({
        { name = "shakeX", amount = payload.xAmount or payload.amount },
        { name = "shakeY", amount = payload.yAmount or payload.amount },
        { name = "shakeZ", amount = payload.zAmount or payload.amount },
      }, payload), payload, "menori.node.positionShake." .. payload.name), ctx
    end
  elseif kind == "menori.node.rotationShake" then
    local entry = payload.name and self.nodeEntries[payload.name] or nil
    if entry then
      return playTarget(entry.target, randomShakeSequence({
        { name = "rotationOffsetX", amount = payload.xAmount or payload.amount },
        { name = "rotationOffsetY", amount = payload.yAmount or payload.amount },
        { name = "rotationOffsetZ", amount = payload.zAmount or payload.amount },
      }, payload), payload, "menori.node.rotationShake." .. payload.name), ctx
    end
  elseif kind == "menori.node.reset" then
    local entry = payload.name and self.nodeEntries[payload.name] or nil
    if entry then
      return playTarget(entry.target, {
        animateOrSet(MODEL_FEEDBACK_RESET, payload.duration or 0, payload.ease),
      }, payload, "menori.node.reset." .. payload.name), ctx
    end
  elseif kind == "menori.camera.lookAt" then
    return applyCameraPayload(self, "lookAt", payload), ctx
  elseif kind == "menori.camera.orbit" then
    return applyCameraPayload(self, "orbit", payload), ctx
  elseif kind == "menori.camera.projection" then
    return applyCameraPayload(self, "projection", payload), ctx
  elseif kind == "menori.camera.shake" then
    if self.cameraEntry then
      return playTarget(self.cameraEntry.target, randomShakeSequence({
        { name = "shakeX", amount = payload.xAmount or payload.amount },
        { name = "shakeY", amount = payload.yAmount or payload.amount },
        { name = "shakeZ", amount = payload.zAmount or payload.amount },
      }, payload), payload, "menori.camera.shake"), ctx
    end
  elseif kind == "menori.camera.fov" then
    if self.cameraEntry then
      local amount = payload.value or payload.amount or 0
      local sequence = pulseSequence({ fovKick = amount }, { fovKick = 0 }, payload)
      return playTarget(self.cameraEntry.target, sequence, payload, "menori.camera.fov"), ctx
    end
  elseif kind == "menori.camera.height" then
    if self.cameraEntry then
      local amount = payload.value or payload.amount or payload.height or 0
      local sequence = pulseSequence({ heightKick = amount }, { heightKick = 0 }, payload)
      return playTarget(self.cameraEntry.target, sequence, payload, "menori.camera.height"), ctx
    end
  elseif kind == "menori.camera.yaw" then
    if self.cameraEntry then
      local amount = payload.value or radians(payload.amount or 0, payload)
      local sequence = pulseSequence({ yawKick = amount }, { yawKick = 0 }, payload)
      return playTarget(self.cameraEntry.target, sequence, payload, "menori.camera.yaw"), ctx
    end
  elseif kind == "menori.camera.distance" then
    if self.cameraEntry then
      local amount = payload.value or payload.amount or 0
      local sequence = pulseSequence({ distanceKick = amount }, { distanceKick = 0 }, payload)
      return playTarget(self.cameraEntry.target, sequence, payload, "menori.camera.distance"), ctx
    end
  elseif kind == "menori.camera.targetOffset" then
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
      }, payload), payload, "menori.camera.targetOffset"), ctx
    end
  elseif kind == "menori.camera.reset" then
    if self.cameraEntry then
      return playTarget(self.cameraEntry.target, {
        animateOrSet(CAMERA_FEEDBACK_RESET, payload.duration or 0, payload.ease),
      }, payload, "menori.camera.reset"), ctx
    end
  elseif kind == "menori.animation.action" then
    local entry = payload.name and self.animationEntries[payload.name] or nil
    if entry then
      return setAnimationAction(entry, payload), ctx
    end
  elseif kind == "menori.animation.play" then
    local entry = payload.name and self.animationEntries[payload.name] or nil
    if entry then
      entry.target.values.playing = 1
      if payload.speed then
        entry.target.values.speed = payload.speed
      end
      setAnimationAction(entry, payload)
      return true, ctx
    end
  elseif kind == "menori.animation.pause" then
    local entry = payload.name and self.animationEntries[payload.name] or nil
    if entry then
      entry.target.values.playing = 0
      return true, ctx
    end
  elseif kind == "menori.animation.stop" then
    local entry = payload.name and self.animationEntries[payload.name] or nil
    if entry then
      entry.target.values.playing = 0
      if entry.target.values.time ~= nil then
        entry.target.values.time = 0
      end
      entry.animations.accumulator = 0
      return true, ctx
    end
  elseif kind == "menori.animation.seek" then
    local entry = payload.name and self.animationEntries[payload.name] or nil
    if entry then
      local time = payload.time or payload.value or 0
      entry.animations.accumulator = time
      if entry.target.values.time ~= nil then
        entry.target.values.time = time
      end
      if payload.apply ~= false and type(entry.animations.update) == "function" then
        entry.animations:update(0)
      end
      return true, ctx
    end
  elseif kind == "menori.animation.speed" then
    local entry = payload.name and self.animationEntries[payload.name] or nil
    if entry then
      local values = { speed = payload.speed or payload.value or 1 }
      return playTarget(entry.target, {
        animateOrSet(values, payload.duration or 0, payload.ease),
      }, payload, "menori.animation.speed." .. payload.name), ctx
    end
  elseif kind == "menori.uniform.set" then
    local entry = payload.name and self.uniformEntries[payload.name] or nil
    if entry then
      local values = payload.values or {}
      if not payload.values then
        for _, key in ipairs(entry.keys or inferUniformKeys(entry)) do
          if payload[key] ~= nil then
            values[key] = payload[key]
          end
        end
      end
      return playTarget(entry.target, {
        animateOrSet(values, payload.duration or 0, payload.ease),
      }, payload, "menori.uniform.set." .. payload.name), ctx
    end
  elseif kind == "menori.uniform.pulse" then
    local entry = payload.name and self.uniformEntries[payload.name] or nil
    if entry then
      local values = payload.values or {}
      if not payload.values then
        for _, key in ipairs(entry.keys or inferUniformKeys(entry)) do
          if payload[key] ~= nil then
            values[key] = payload[key]
          end
        end
      end
      return playTarget(entry.target, pulseSequence(values, entry.resetValues, payload), payload, "menori.uniform.pulse." .. payload.name), ctx
    end
  elseif kind == "menori.uniform.reset" then
    local entry = payload.name and self.uniformEntries[payload.name] or nil
    if entry then
      return playTarget(entry.target, {
        animateOrSet(entry.resetValues, payload.duration or 0, payload.ease),
      }, payload, "menori.uniform.reset." .. payload.name), ctx
    end
  end

  return false, ctx
end

---@param extra? FeelMenoriHandlers
---@return FeelMenoriHandlers
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

return FeelMenori
