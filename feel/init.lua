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
local runners = {}

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

local function removeRunner(runner)
  for index = #runners, 1, -1 do
    if runners[index] == runner then
      table.remove(runners, index)
      return
    end
  end
end

local function removeChildRunner(parent, child)
  if not parent or not parent.children then
    return
  end

  for index = #parent.children, 1, -1 do
    if parent.children[index] == child then
      table.remove(parent.children, index)
      return
    end
  end
end

local function mergeOptions(base, extra)
  if type(extra) ~= "table" then
    return base
  end

  local result = {}
  for key, value in pairs(base or {}) do
    result[key] = value
  end
  for key, value in pairs(extra) do
    result[key] = value
  end
  return result
end

local runSequence

local function cancelRunner(runner)
  if not runner or runner.cancelled then
    return
  end

  runner.cancelled = true
  runner.wait = nil

  for _, child in ipairs(runner.children or {}) do
    cancelRunner(child)
  end
  runner.children = {}

  removeChildRunner(runner.parent, runner)
  removeRunner(runner)
end

local function childOptions(ctx, step)
  return mergeOptions(ctx.opts, step.opts)
end

local function childTarget(ctx, step)
  if step.target ~= nil then
    return step.target
  end
  return ctx.target
end

local function childTrigger(ctx, step)
  return step.trigger or ctx.trigger
end

local function childSequence(step)
  return step.sequence or step.steps or step.step or step.feedback or step.name or step[1]
end

local function selectedRandomOption(options)
  if type(options) ~= "table" or #options == 0 then
    return nil
  end

  local total = 0
  for _, option in ipairs(options) do
    local weight = option.weight or option.chance or 1
    if weight > 0 then
      total = total + weight
    end
  end

  if total <= 0 then
    return nil
  end

  local pick = math.random() * total
  for _, option in ipairs(options) do
    local weight = option.weight or option.chance or 1
    if weight > 0 then
      pick = pick - weight
      if pick <= 0 then
        return option
      end
    end
  end

  return options[#options]
end

local function finishRunner(runner)
  if runner.cancelled then
    return
  end

  runner.cancelled = true
  removeChildRunner(runner.parent, runner)
  removeRunner(runner)

  if runner.done then
    runner.done(runner.ctx)
  end
end

local function runStep(runner, step, nextStep)
  local ctx = runner.ctx
  local kind = step.kind or "emit"
  local opts = ctx.opts or {}

  if kind == "wait" or kind == "pause" then
    runner.wait = {
      remaining = step.duration or step.time or 0,
      nextStep = nextStep,
    }
    if runner.wait.remaining <= 0 then
      runner.wait = nil
      nextStep()
    end
    return
  end

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
      if runner.cancelled then
        return
      end
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

  if kind == "play" then
    local sequence = childSequence(step)
    if sequence == nil or sequence == false then
      nextStep()
      return
    end

    runSequence(sequence, childTarget(ctx, step), childOptions(ctx, step), nextStep, {
      parent = runner,
      trigger = childTrigger(ctx, step),
      source = sequence,
    })
    return
  end

  if kind == "parallel" then
    local children = step.steps or step.sequences or step[1]
    if type(children) ~= "table" or #children == 0 then
      nextStep()
      return
    end

    local remaining = #children
    local function childDone()
      if runner.cancelled then
        return
      end
      remaining = remaining - 1
      if remaining <= 0 then
        nextStep()
      end
    end

    for _, child in ipairs(children) do
      runSequence(child, childTarget(ctx, step), childOptions(ctx, step), childDone, {
        parent = runner,
        trigger = childTrigger(ctx, step),
        source = child,
      })
    end
    return
  end

  if kind == "repeat" then
    local sequence = childSequence(step)
    local count = step.count or step.times or 1
    if sequence == nil or sequence == false or (not step.forever and count <= 0) then
      nextStep()
      return
    end

    local played = 0
    local function playAgain()
      if runner.cancelled then
        return
      end
      if not step.forever then
        played = played + 1
        if played > count then
          nextStep()
          return
        end
      end
      runSequence(sequence, childTarget(ctx, step), childOptions(ctx, step), playAgain, {
        parent = runner,
        trigger = childTrigger(ctx, step),
        source = sequence,
      })
    end

    playAgain()
    return
  end

  if kind == "random" then
    local option = selectedRandomOption(step.options or step[1])
    local sequence = option and (option.step or option.sequence or option.steps or option[1])
    if sequence == nil or sequence == false then
      nextStep()
      return
    end

    runSequence(sequence, childTarget(ctx, step), childOptions(ctx, step), nextStep, {
      parent = runner,
      trigger = childTrigger(ctx, step),
      source = sequence,
    })
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
  elseif kind == "log" then
    local message = step.message or step.text or step[1] or ""
    if type(opts.log) == "function" then
      opts.log(message, ctx)
    else
      print(message)
    end
  end

  nextStep()
end

runSequence = function(nameOrSequence, target, opts, done, meta)
  local sequence = normalizeSequence(nameOrSequence)
  if not sequence then
    if done then
      done()
    end
    return nil
  end

  opts = opts or {}
  meta = meta or {}
  local ctx = {
    target = target,
    trigger = meta.trigger or opts.trigger or "manual",
    source = meta.source or nameOrSequence,
    opts = opts,
  }

  local runner = {
    ctx = ctx,
    sequence = sequence,
    index = 0,
    done = done,
    children = {},
  }
  ctx.runner = runner

  if meta.parent then
    runner.parent = meta.parent
    meta.parent.children[#meta.parent.children + 1] = runner
  end

  runners[#runners + 1] = runner

  local function nextStep()
    if runner.cancelled then
      return
    end

    runner.index = runner.index + 1
    local step = runner.sequence[runner.index]
    if not step then
      finishRunner(runner)
      return
    end

    runStep(runner, step, nextStep)
  end

  nextStep()
  return ctx
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

  return runSequence(nameOrSequence, target, opts)
end

function Feel.update(dt)
  dt = dt or 0
  local hadActive = #group > 0 or #runners > 0
  group:update(dt or 0)

  for index = #runners, 1, -1 do
    local runner = runners[index]
    local wait = runner and runner.wait
    if wait then
      wait.remaining = wait.remaining - dt
      if wait.remaining <= 0 then
        runner.wait = nil
        wait.nextStep()
      end
    end
  end

  return hadActive or #group > 0 or #runners > 0
end

local function clearTarget(target)
  local state = target and targets[target]
  if state then
    for _, tween in ipairs(state.tweens or {}) do
      if tween.stop then
        tween:stop()
      end
    end
    targets[target] = nil
  end

  for index = #runners, 1, -1 do
    local runner = runners[index]
    if runner and runner.ctx and runner.ctx.target == target then
      cancelRunner(runner)
    end
  end
end

function Feel.clear(target)
  if target then
    clearTarget(target)
    return
  end

  registry = {}

  for index = #group, 1, -1 do
    group:remove(index)
  end

  for index = #runners, 1, -1 do
    cancelRunner(runners[index])
  end
  runners = {}
  targets = setmetatable({}, { __mode = "k" })
end

Feel.flux = flux
Feel.fields = FIELDS
Feel.normalizeStep = normalizeStep
Feel.normalizeSequence = normalizeSequence

return Feel
