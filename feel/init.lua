local prefix = ...
if not prefix or prefix == "" then
  prefix = "feel"
elseif prefix:sub(-5) == ".init" then
  prefix = prefix:sub(1, -6)
end

local flux = require(prefix .. ".vendor.flux")

local Feel = {}

local group = flux.group()
local registry = {}
local targets = setmetatable({}, { __mode = "k" })

local FIELDS = {
  "opacity",
  "x",
  "y",
  "scale",
  "scaleX",
  "scaleY",
  "rotation",
}

local DEFAULTS = {
  opacity = 1,
  x = 0,
  y = 0,
  scale = 1,
  scaleX = 1,
  scaleY = 1,
  rotation = 0,
}

local function copyNumericFields(source)
  local result = {}
  source = source or {}
  for key, value in pairs(source) do
    if type(value) == "number" then
      result[key] = value
    end
  end
  return result
end

local function subject(values)
  local result = {}
  values = values or {}
  for key, value in pairs(DEFAULTS) do
    result[key] = values[key] ~= nil and values[key] or value
  end
  return result
end

local function applyFields(target, source)
  for _, key in ipairs(FIELDS) do
    if source and source[key] ~= nil then
      target[key] = source[key]
    end
  end
end

local function isIdentity(values)
  values = values or {}
  for key, value in pairs(DEFAULTS) do
    if (values[key] or value) ~= value then
      return false
    end
  end
  return true
end

local function isArray(value)
  return type(value) == "table" and value[1] ~= nil
end

local function normalizeStep(step)
  if type(step) == "function" then
    return {
      kind = "callback",
      callback = step,
    }
  end

  if type(step) ~= "table" then
    return {
      kind = "emit",
      event = tostring(step),
    }
  end

  if step.kind ~= nil then
    return step
  end

  if step.to or step.from or step.duration or step.ease then
    local copy = {}
    for key, value in pairs(step) do
      copy[key] = value
    end
    copy.kind = "animate"
    return copy
  end

  return step
end

local function normalizeSequence(value)
  if value == nil or value == false then
    return nil
  end

  if type(value) == "string" then
    return registry[value]
  end

  if type(value) == "function" then
    return { normalizeStep(value) }
  end

  if type(value) ~= "table" then
    return { normalizeStep(value) }
  end

  if value.kind or value.to or value.from or value.duration or value.ease then
    return { normalizeStep(value) }
  end

  if isArray(value) then
    local sequence = {}
    for index, step in ipairs(value) do
      sequence[index] = normalizeStep(step)
    end
    return sequence
  end

  return { normalizeStep(value) }
end

local function stateFor(target)
  target = target or Feel.target()
  local state = targets[target]
  if not state then
    state = {
      target = target,
      values = target.values or subject(target.values),
      active = 0,
      tweens = {},
    }
    target.values = state.values
    targets[target] = state
  end
  return state
end

local function removeTween(state, tween)
  for index = #state.tweens, 1, -1 do
    if state.tweens[index] == tween then
      table.remove(state.tweens, index)
      return
    end
  end
end

local function emit(opts, name, event, ctx)
  local handler = opts and opts[name]
  if type(handler) == "function" then
    handler(event, ctx)
  end
end

local function runStep(ctx, step, nextStep)
  local kind = step.kind or "emit"
  local opts = ctx.opts or {}

  if kind == "animate" then
    local state = stateFor(ctx.target)
    if step.from then
      applyFields(state.values, step.from)
    end

    state.active = (state.active or 0) + 1
    local tween
    tween = group:to(state.values, step.duration or 0.16, copyNumericFields(step.to))
    if step.ease then
      tween:ease(step.ease)
    end
    if step.delay then
      tween:delay(step.delay)
    end
    if step.onStart then
      tween:onstart(function()
        step.onStart(state.values, ctx)
      end)
    end
    tween:onupdate(function()
      if step.onUpdate then
        step.onUpdate(state.values, ctx)
      end
      if opts.markDirty then
        opts.markDirty(ctx)
      end
    end)
    tween:oncomplete(function()
      state.active = math.max(0, (state.active or 1) - 1)
      removeTween(state, tween)
      if step.onComplete then
        step.onComplete(state.values, ctx)
      end
      if state.active == 0 and isIdentity(state.values) then
        targets[state.target] = nil
      end
      if opts.markDirty then
        opts.markDirty(ctx)
      end
      nextStep()
    end)
    state.tweens[#state.tweens + 1] = tween
    if opts.markDirty then
      opts.markDirty(ctx)
    end
    return
  end

  if kind == "audio" and step.cue then
    emit(opts, "audio", {
      cue = step.cue,
      kind = step.audioKind or "feedback",
      target = ctx.target,
      trigger = ctx.trigger,
      step = step,
    }, ctx)
  elseif kind == "emit" then
    local event = {
      kind = step.event or step.name or ctx.trigger or "feedback",
      name = step.name,
      trigger = ctx.trigger,
      target = ctx.target,
      payload = step.payload,
      step = step,
    }
    for key, value in pairs(step) do
      if event[key] == nil and key ~= "kind" then
        event[key] = value
      end
    end
    emit(opts, "emit", event, ctx)
  elseif kind == "callback" then
    local callback = step.callback or step.fn or step[1]
    if type(callback) == "function" then
      callback(ctx)
    end
  end

  nextStep()
end

function Feel.target(meta)
  meta = meta or {}
  local target = {}
  for key, value in pairs(meta) do
    target[key] = value
  end
  target.values = subject(meta.values)
  targets[target] = {
    target = target,
    values = target.values,
    active = 0,
    tweens = {},
  }
  return target
end

function Feel.define(name, sequence)
  local normalized = normalizeSequence(sequence)
  registry[name] = normalized
  return normalized
end

function Feel.get(name)
  return registry[name]
end

function Feel.play(nameOrSequence, target, opts)
  if nameOrSequence == nil or nameOrSequence == false then
    return nil
  end

  local sequence = normalizeSequence(nameOrSequence)
  if not sequence then
    return nil
  end

  opts = opts or {}
  local ctx = {
    target = target,
    trigger = opts.trigger or "manual",
    source = nameOrSequence,
    opts = opts,
  }

  local index = 0
  local function nextStep()
    index = index + 1
    local step = sequence[index]
    if not step then
      return
    end
    runStep(ctx, step, nextStep)
  end

  nextStep()
  return ctx
end

function Feel.update(dt)
  local hadActive = #group > 0
  group:update(dt or 0)
  return hadActive or #group > 0
end

local function clearTarget(target)
  local state = target and targets[target]
  if not state then
    return
  end

  for _, tween in ipairs(state.tweens or {}) do
    if tween.stop then
      tween:stop()
    end
  end
  targets[target] = nil
end

function Feel.clear(target)
  registry = {}
  if target then
    clearTarget(target)
    return
  end

  for index = #group, 1, -1 do
    group:remove(index)
  end

  targets = setmetatable({}, { __mode = "k" })
end

Feel.flux = flux
Feel.fields = FIELDS
Feel.normalizeStep = normalizeStep
Feel.normalizeSequence = normalizeSequence

return Feel
