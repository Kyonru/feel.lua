local moduleName = ...
local prefix = "feel"
if moduleName and moduleName ~= "" then
  prefix = moduleName:gsub("%.feedbacks$", "")
end

---@type FeelModule
local feel = require(prefix)

---@module "feel.feedbacks"

---@class FeelFeedbacksModule
---@field new fun(opts?: FeelFeedbacksOptions): FeelFeedbacks
---@type FeelFeedbacksModule
local FeelFeedbacks = {}

---@class FeelFeedbacks
---@field define fun(name: string, steps: FeelFeedbackManifest): FeelFeedbackManifest
---@field get fun(name: string): FeelFeedbackManifest?
---@field play fun(nameOrSteps: any, context?: table, opts?: FeelFeedbackPlayOptions): FeelContext?
---@field clear fun(name?: string)
---@field timeScale fun(): number
---@field timeTarget fun(): FeelTarget

local CORE_KINDS = {
  animate = true,
  wait = true,
  pause = true,
  emit = true,
  audio = true,
  callback = true,
  play = true,
  parallel = true,
  ["repeat"] = true,
  random = true,
  log = true,
}

local SCALAR_RANGE_FIELDS = {
  amount = true,
  alpha = true,
  contrast = true,
  direction = true,
  duration = true,
  exposure = true,
  force = true,
  frequency = true,
  fov = true,
  height = true,
  hueShift = true,
  intensity = true,
  pan = true,
  pitch = true,
  radius = true,
  returnDuration = true,
  rotation = true,
  saturation = true,
  scale = true,
  softness = true,
  speed = true,
  threshold = true,
  volume = true,
  x = true,
  y = true,
  z = true,
}

local PRESERVE_FUNCTION_KEYS = {
  audio = true,
  callback = true,
  emit = true,
  fn = true,
  log = true,
  markDirty = true,
  onComplete = true,
  onStart = true,
  onUpdate = true,
}

local PRESERVE_TABLE_KEYS = {
  key = true,
  target = true,
}

local SHORTHAND_EXCLUDED_KEYS = {
  event = true,
  kind = true,
  opts = true,
  payload = true,
  target = true,
  trigger = true,
}

local function isArray(value)
  return type(value) == "table" and value[1] ~= nil
end

local function isNumericRange(value)
  if type(value) ~= "table" or value[1] == nil or value[2] == nil or value[3] ~= nil then
    return false
  end
  if type(value[1]) ~= "number" or type(value[2]) ~= "number" then
    return false
  end
  for key in pairs(value) do
    if key ~= 1 and key ~= 2 then
      return false
    end
  end
  return true
end

local function readPath(context, path)
  if path == "" then
    return context
  end

  local current = context
  for part in path:gmatch("[^%.]+") do
    if type(current) ~= "table" then
      return nil
    end
    current = current[part]
  end
  return current
end

local resolveValue

resolveValue = function(value, context, key)
  local valueType = type(value)

  if valueType == "string" and value:sub(1, 1) == "$" then
    return readPath(context or {}, value:sub(2))
  end

  if valueType == "function" and not PRESERVE_FUNCTION_KEYS[key] then
    return resolveValue(value(context or {}), context, key)
  end

  if valueType ~= "table" then
    return value
  end

  if PRESERVE_TABLE_KEYS[key] then
    return value
  end

  if SCALAR_RANGE_FIELDS[key] and isNumericRange(value) then
    return value[1] + (value[2] - value[1]) * math.random()
  end

  local result = {}
  for childKey, childValue in pairs(value) do
    result[childKey] = resolveValue(childValue, context, childKey)
  end
  return result
end

local function copyOptions(source, context)
  local result = {}
  for key, value in pairs(source or {}) do
    if key ~= "target" then
      result[key] = resolveValue(value, context, key)
    end
  end
  return result
end

local compileSequence

local function compileChild(instance, value, context)
  if type(value) == "table" and not value.kind and isArray(value) then
    return compileSequence(instance, value, context)
  end
  return compileSequence(instance, value, context)
end

local function compileOptions(instance, options, context)
  if type(options) ~= "table" then
    return options
  end

  local compiled = {}
  for index, option in ipairs(options) do
    local copy = {}
    for key, value in pairs(option) do
      if key == "step" or key == "sequence" or key == "steps" then
        copy[key] = compileChild(instance, value, context)
      elseif key == 1 then
        copy[key] = compileChild(instance, value, context)
      else
        copy[key] = resolveValue(value, context, key)
      end
    end
    compiled[index] = copy
  end
  return compiled
end

local function compileCoreStep(instance, step, context)
  local result = {}
  for key, value in pairs(step) do
    if key == "steps" or key == "sequences" then
      local children = {}
      for index, child in ipairs(value or {}) do
        children[index] = compileChild(instance, child, context)
      end
      result[key] = children
    elseif key == "options" then
      result[key] = compileOptions(instance, value, context)
    elseif key == "step" or key == "sequence" or key == "feedback" then
      result[key] = compileChild(instance, value, context)
    elseif key == "opts" then
      result[key] = copyOptions(value, context)
    elseif key == 1 and (step.kind == "parallel" or step.kind == "random") then
      if step.kind == "random" then
        result[key] = compileOptions(instance, value, context)
      else
        local children = {}
        for index, child in ipairs(value or {}) do
          children[index] = compileChild(instance, child, context)
        end
        result[key] = children
      end
    else
      result[key] = resolveValue(value, context, key)
    end
  end
  return result
end

local function setTimeScaleStep(instance, scale, duration, ease)
  duration = duration or 0
  if duration <= 0 then
    return {
      kind = "callback",
      callback = function()
        instance._timeTarget.values.scale = scale
      end,
    }
  end

  return {
    kind = "animate",
    duration = duration,
    ease = ease,
    to = { scale = scale },
  }
end

local function compileTimeStep(instance, step, context)
  local kind = step.kind
  local scale = resolveValue(step.scale, context, "scale")
  local duration = resolveValue(step.duration, context, "duration") or 0
  local returnDuration = resolveValue(step.returnDuration, context, "returnDuration") or 0
  local ease = resolveValue(step.ease, context, "ease")
  local returnEase = resolveValue(step.returnEase or step.ease, context, "returnEase")
  local restoreScale = resolveValue(step.restoreScale, context, "scale")
    or instance._timeTarget.values.scale
    or 1

  if kind == "time.freeze" then
    scale = 0
  elseif kind == "time.slow" then
    scale = scale or 0.25
  elseif kind == "time.restore" then
    return {
      kind = "play",
      target = instance._timeTarget,
      opts = { restart = true, key = "feedbacks.time" },
      sequence = {
        setTimeScaleStep(instance, 1, duration, ease),
      },
    }
  end

  return {
    kind = "play",
    target = instance._timeTarget,
    opts = { restart = true, key = "feedbacks.time" },
    sequence = {
      setTimeScaleStep(
        instance,
        scale,
        resolveValue(step.inDuration or step.attack, context, "duration") or 0,
        ease
      ),
      { kind = "wait", duration = duration },
      setTimeScaleStep(instance, restoreScale, returnDuration, returnEase),
    },
  }
end

local function compileShorthandStep(step, context)
  local payload = {}
  local resolvedPayload = resolveValue(step.payload, context, "payload")

  if type(resolvedPayload) == "table" then
    for key, value in pairs(resolvedPayload) do
      payload[key] = value
    end
  elseif resolvedPayload ~= nil then
    payload.value = resolvedPayload
  end

  for key, value in pairs(step) do
    if not SHORTHAND_EXCLUDED_KEYS[key] then
      payload[key] = resolveValue(value, context, key)
    end
  end

  return {
    kind = "emit",
    event = step.event or step.kind,
    payload = payload,
  }
end

local function compileStep(instance, step, context)
  if type(step) ~= "table" then
    return resolveValue(step, context)
  end

  local kind = step.kind
  if kind == "time.freeze" or kind == "time.slow" or kind == "time.restore" then
    return compileTimeStep(instance, step, context)
  end

  if kind and CORE_KINDS[kind] then
    return compileCoreStep(instance, step, context)
  end

  if kind then
    return compileShorthandStep(step, context)
  end

  if step.to or step.from or step.duration or step.ease then
    local copy = compileCoreStep(instance, step, context)
    copy.kind = "animate"
    return copy
  end

  return compileCoreStep(instance, step, context)
end

compileSequence = function(instance, value, context)
  if value == nil or value == false then
    return nil
  end

  if type(value) == "string" then
    local manifest = instance._registry[value]
    if manifest then
      return compileSequence(instance, manifest, context)
    end
    return value
  end

  if type(value) ~= "table" then
    return { compileStep(instance, value, context) }
  end

  if value.kind or value.to or value.from or value.duration or value.ease then
    return { compileStep(instance, value, context) }
  end

  if isArray(value) then
    local sequence = {}
    for index, step in ipairs(value) do
      sequence[index] = compileStep(instance, step, context)
    end
    return sequence
  end

  return { compileStep(instance, value, context) }
end

local function routeEmit(instance, event, playCtx, userEmit)
  if instance._love and type(instance._love.emit) == "function" then
    instance._love:emit(event, playCtx)
  end
  if instance._g3d and type(instance._g3d.emit) == "function" then
    instance._g3d:emit(event, playCtx)
  end
  if type(instance._emit) == "function" then
    instance._emit(event, playCtx)
  end
  if type(userEmit) == "function" then
    userEmit(event, playCtx)
  end
end

local function routeAudio(instance, event, playCtx, userAudio)
  if instance._love and type(instance._love.audio) == "function" then
    instance._love:audio(event, playCtx)
  end
  if type(instance._audio) == "function" then
    instance._audio(event, playCtx)
  end
  if type(userAudio) == "function" then
    userAudio(event, playCtx)
  end
end

local function makePlayOptions(instance, context, opts, source)
  opts = opts or {}
  local playOpts = copyOptions(opts, context)
  local userEmit = opts.emit
  local userAudio = opts.audio
  local userLog = opts.log
  local userMarkDirty = opts.markDirty

  playOpts.feedback = context
  playOpts.trigger = playOpts.trigger or (type(source) == "string" and source or "feedback")
  playOpts.emit = function(event, playCtx)
    routeEmit(instance, event, playCtx, userEmit)
  end
  playOpts.audio = function(event, playCtx)
    routeAudio(instance, event, playCtx, userAudio)
  end
  playOpts.log = function(message, playCtx)
    if type(instance._log) == "function" then
      instance._log(message, playCtx)
    end
    if type(userLog) == "function" then
      userLog(message, playCtx)
    end
  end
  playOpts.markDirty = function(playCtx)
    if type(instance._markDirty) == "function" then
      instance._markDirty(playCtx)
    end
    if type(userMarkDirty) == "function" then
      userMarkDirty(playCtx)
    end
  end

  return playOpts
end

---@param opts? FeelFeedbacksOptions
---@return FeelFeedbacks
function FeelFeedbacks.new(opts)
  opts = opts or {}
  local instance = {
    _registry = {},
    _love = opts.love,
    _g3d = opts.g3d,
    _emit = opts.emit,
    _audio = opts.audio,
    _log = opts.log,
    _markDirty = opts.markDirty,
    _timeTarget = feel.target({ values = { scale = 1 } }),
  }

  return {
    define = function(name, steps)
      assert(type(name) == "string", "feedback name must be a string")
      instance._registry[name] = steps
      return steps
    end,
    get = function(name)
      return instance._registry[name]
    end,
    play = function(nameOrSteps, context, playOpts)
      context = context or {}
      local manifest = nameOrSteps
      if type(nameOrSteps) == "string" and instance._registry[nameOrSteps] then
        manifest = instance._registry[nameOrSteps]
      end

      local sequence = compileSequence(instance, manifest, context)
      if not sequence then
        return nil
      end

      playOpts = playOpts or {}
      local target = playOpts.target or context.target
      return feel.play(sequence, target, makePlayOptions(instance, context, playOpts, nameOrSteps))
    end,
    clear = function(name)
      if name then
        instance._registry[name] = nil
        return
      end
      instance._registry = {}
      feel.clear(instance._timeTarget)
      instance._timeTarget.values.scale = 1
    end,
    timeScale = function()
      return instance._timeTarget.values.scale or 1
    end,
    timeTarget = function()
      return instance._timeTarget
    end,
  }
end

return FeelFeedbacks
