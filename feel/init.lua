local prefix = ...
if not prefix or prefix == "" then
  prefix = "feel"
elseif prefix:sub(-5) == ".init" then
  prefix = prefix:sub(1, -6)
end

local flux = require(prefix .. ".vendor.flux")
local validator = require(prefix .. ".validate")

---@module "feel"

---@class FeelModule
---@field flux table
---@field fields string[]
---@field normalizeStep fun(step: FeelStepInput): FeelStep?
---@field normalizeSequence fun(value: FeelSequenceInput): FeelStep[]?
---@field target fun(meta?: FeelTargetMeta): FeelTarget
---@field define fun(name: string, sequence: FeelSequenceInput): FeelStep[]?
---@field get fun(name: string): FeelStep[]?
---@field validate fun(sequence: FeelSequenceInput): boolean, string?
---@field play fun(nameOrSequence: FeelSequenceInput, target?: FeelTarget, opts?: FeelPlayOptions): FeelContext?
---@field update fun(dt?: number): boolean
---@field active fun(): FeelActiveRun[]
---@field isPlaying fun(target?: FeelTarget, key?: string|number|table): boolean
---@field clear fun(target?: FeelTarget)
---@field channel fun(): FeelChannel
---@field spring fun(x?: number, stiffness?: number, damping?: number): FeelSpring
---@field stop fun(ctx?: FeelContext)
---@field pause fun(ctx?: FeelContext)
---@field resume fun(ctx?: FeelContext)
---@field pauseAll fun()
---@field resumeAll fun()
---@field isPausedAll fun(): boolean
---@field setTimeScale fun(scale: number): number
---@field timeScale fun(): number
---@field strictAliases fun(on?: boolean): boolean
---@type FeelModule
local Feel = {}

---@class FeelTargetMeta
---@field values? table<string, number>
---@field [string] any

---@class FeelTarget
---@field values table<string, number>
---@field [string] any

---@class FeelContext
---@field target? FeelTarget
---@field trigger string
---@field source any
---@field opts FeelPlayOptions
---@field runner FeelRunner
---@field stop fun(self: FeelContext)
---@field pause fun(self: FeelContext)
---@field resume fun(self: FeelContext)
---@field isPaused fun(self: FeelContext): boolean
---@field isPlaying fun(self: FeelContext): boolean
---@field onComplete fun(self: FeelContext, fn: fun(ctx: FeelContext)): FeelContext
---@field onStop fun(self: FeelContext, fn: fun(ctx: FeelContext)): FeelContext

---@class FeelPlayOptions
---@field trigger? string
---@field emit? fun(event: FeelEvent, ctx: FeelContext)
---@field audio? fun(event: FeelAudioEvent, ctx: FeelContext)
---@field log? fun(message: string, ctx: FeelContext)
---@field markDirty? fun(ctx: FeelContext)
---@field restart? boolean
---@field key? string|number|table
---@field [string] any

---@class FeelEvent
---@field kind string
---@field name? string
---@field trigger string
---@field target? FeelTarget
---@field payload? any
---@field step FeelStep
---@field [string] any

---@class FeelAudioEvent
---@field cue string
---@field kind string
---@field target? FeelTarget
---@field trigger string
---@field step FeelStep

---@class FeelRunner
---@field ctx FeelContext
---@field sequence FeelStep[]
---@field index integer
---@field done? fun(ctx?: FeelContext)
---@field children FeelRunner[]
---@field tweens table[]
---@field parent? FeelRunner
---@field wait? FeelWaitState
---@field elapsed number
---@field cancelled? boolean
---@field finished? boolean
---@field paused? boolean
---@field onComplete? (fun(ctx: FeelContext))[]
---@field onStop? (fun(ctx: FeelContext))[]
---@field restartSlot? table
---@field restartKey? string|number|table

---@class FeelActiveRun
---@field target? FeelTarget
---@field source any
---@field trigger string
---@field key? string|number|table
---@field index integer
---@field count integer
---@field elapsed number
---@field waiting boolean
---@field remaining? number
---@field tweens integer
---@field children integer

---@class FeelWaitState
---@field remaining number
---@field nextStep fun()

---@class FeelAnimateStep
---@field kind "animate"
---@field to? table<string, number>
---@field from? table<string, number>
---@field duration? number
---@field ease? string
---@field delay? number
---@field onStart? fun(values: table<string, number>, ctx: FeelContext)
---@field onUpdate? fun(values: table<string, number>, ctx: FeelContext)
---@field onComplete? fun(values: table<string, number>, ctx: FeelContext)

---@class FeelSpringStep
---@field kind "spring"
---@field to? table<string, number>
---@field pull? table<string, number>
---@field from? table<string, number>
---@field stiffness? number
---@field k? number
---@field damping? number
---@field d? number
---@field settle? number
---@field epsilon? number
---@field duration? number
---@field onStart? fun(values: table<string, number>, ctx: FeelContext)
---@field onUpdate? fun(values: table<string, number>, ctx: FeelContext)
---@field onComplete? fun(values: table<string, number>, ctx: FeelContext)

---@class FeelSpring
---@field x number
---@field v number
---@field target number
---@field k number
---@field d number
---@field update fun(self: FeelSpring, dt: number): number
---@field pull fun(self: FeelSpring, force: number, stiffness?: number, damping?: number): FeelSpring
---@field animate fun(self: FeelSpring, target: number, stiffness?: number, damping?: number): FeelSpring
---@field settled fun(self: FeelSpring, epsilon?: number): boolean

---@class FeelWaitStep
---@field kind "wait"|"pause"
---@field duration? number
---@field time? number

---@class FeelEmitStep
---@field kind "emit"
---@field event? string
---@field name? string
---@field payload? any
---@field [string] any

---@class FeelAudioStep
---@field kind "audio"
---@field cue string
---@field audioKind? string

---@class FeelCallbackStep
---@field kind "callback"
---@field callback? fun(ctx: FeelContext)
---@field fn? fun(ctx: FeelContext)
---@field [integer] any

---@class FeelPlayStep
---@field kind "play"
---@field name? string
---@field sequence? FeelSequenceInput
---@field steps? FeelSequenceInput
---@field step? FeelSequenceInput
---@field feedback? FeelSequenceInput
---@field target? FeelTarget
---@field trigger? string
---@field opts? FeelPlayOptions
---@field [integer] any

---@class FeelParallelStep
---@field kind "parallel"
---@field steps? FeelSequenceInput[]
---@field sequences? FeelSequenceInput[]
---@field target? FeelTarget
---@field trigger? string
---@field opts? FeelPlayOptions
---@field [integer] any

---@class FeelRepeatStep
---@field kind "repeat"
---@field count? integer
---@field times? integer
---@field forever? boolean
---@field name? string
---@field sequence? FeelSequenceInput
---@field steps? FeelSequenceInput
---@field step? FeelSequenceInput
---@field feedback? FeelSequenceInput
---@field target? FeelTarget
---@field trigger? string
---@field opts? FeelPlayOptions
---@field [integer] any

---@class FeelRandomOption
---@field weight? number
---@field chance? number
---@field step? FeelSequenceInput
---@field sequence? FeelSequenceInput
---@field steps? FeelSequenceInput
---@field [integer] any

---@class FeelRandomStep
---@field kind "random"
---@field options? FeelRandomOption[]
---@field target? FeelTarget
---@field trigger? string
---@field opts? FeelPlayOptions
---@field [integer] any

---@class FeelLogStep
---@field kind "log"
---@field message? string
---@field text? string
---@field [integer] any

---@class FeelFeedbackEvent
---@field target? FeelTarget
---@field opts? FeelPlayOptions
---@field payload? any
---@field [string] any

---@alias FeelFeedbackHandler fun(event: FeelFeedbackEvent)

---@class FeelChannel
---@field listeners table<string, FeelFeedbackHandler[]>

---@alias FeelStepKind
---| '"animate"'
---| '"spring"'
---| '"wait"'
---| '"pause"'
---| '"emit"'
---| '"audio"'
---| '"callback"'
---| '"play"'
---| '"parallel"'
---| '"repeat"'
---| '"random"'
---| '"log"'
---@alias FeelSideEffectStep FeelEmitStep|FeelAudioStep|FeelCallbackStep|FeelLogStep
---@alias FeelControlStep FeelPlayStep|FeelParallelStep|FeelRepeatStep|FeelRandomStep
---@alias FeelStep FeelAnimateStep|FeelSpringStep|FeelWaitStep|FeelSideEffectStep|FeelControlStep|table
---@alias FeelStepInput FeelStep|fun(ctx: FeelContext)|string|number|boolean|nil
---@alias FeelSequenceInput string|FeelStepInput|FeelStepInput[]|nil|false

local group = flux.group()
-- Tweens belonging to paused runs are parked here. This group is never updated,
-- so its tweens freeze (keeping progress) until the run resumes and they are
-- moved back into `group`. See pauseRunner/resumeRunner.
local pausedGroup = flux.group()
local registry = {}
local targets = setmetatable({}, { __mode = "k" })
local runners = {}
-- Active `spring` step runs. Unlike `animate` (a flux tween), a spring is a
-- stateful integrator stepped by hand in Feel.update. Each entry is also tracked
-- on its runner (runner.springs) so cancel/clear tears it down with the run.
local springRuns = {}
local restartTargets = setmetatable({}, { __mode = "k" })
local nilRestartSlots = {}
local globalPaused = false
local globalTimeScale = 1
local warnAliases = false
local warnedAliasPairs = {}
local Channel = {}
Channel.__index = Channel
-- Metatable applied to every FeelContext so runs can be controlled via methods
-- (ctx:stop()/:pause()/:resume()/:onComplete(fn) …). Methods are populated near
-- the public API, once the backing free functions exist.
local FeelContext = {}
FeelContext.__index = FeelContext

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
  local result = copyNumericFields(values)
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
  for key, value in pairs(source or {}) do
    if type(value) == "number" then
      target[key] = value
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

-- A damped harmonic oscillator (Hooke's law + viscous damping), integrated with
-- semi-implicit Euler. This is the raw juice primitive: `pull` tugs the value so
-- it bounces around its anchor (impacts), `animate` moves the anchor so the value
-- springs toward a new rest (transitions). See feel.spring and the "spring" step.
local Spring = {}
Spring.__index = Spring

local DEFAULT_STIFFNESS = 150
local DEFAULT_DAMPING = 10
local DEFAULT_SETTLE = 0.01

local function newSpring(x, stiffness, damping)
  return setmetatable({
    x = x or 0,
    target = x or 0,
    v = 0,
    k = stiffness or DEFAULT_STIFFNESS,
    d = damping or DEFAULT_DAMPING,
  }, Spring)
end

---@param dt number
---@return number
function Spring:update(dt)
  local a = -self.k * (self.x - self.target) - self.d * self.v
  self.v = self.v + a * dt
  self.x = self.x + self.v * dt
  return self.x
end

-- Displace the value by `force` (and optionally retune k/d) so it springs back
-- to the unchanged anchor. Use for impact punches.
---@param force number
---@param stiffness? number
---@param damping? number
---@return FeelSpring
function Spring:pull(force, stiffness, damping)
  if stiffness then
    self.k = stiffness
  end
  if damping then
    self.d = damping
  end
  self.x = self.x + force
  return self
end

-- Move the anchor (rest target) so the value springs toward it. Use for
-- transitions. Unlike pull, this changes where the value settles.
---@param target number
---@param stiffness? number
---@param damping? number
---@return FeelSpring
function Spring:animate(target, stiffness, damping)
  if stiffness then
    self.k = stiffness
  end
  if damping then
    self.d = damping
  end
  self.target = target
  return self
end

---@param epsilon? number
---@return boolean
function Spring:settled(epsilon)
  epsilon = epsilon or DEFAULT_SETTLE
  return math.abs(self.x - self.target) < epsilon and math.abs(self.v) < epsilon
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

local validateSequence = validator.new(normalizeStep, function(name)
  return registry[name]
end)

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

local function removeRunnerTween(runner, tween)
  for index = #(runner.tweens or {}), 1, -1 do
    if runner.tweens[index].tween == tween then
      table.remove(runner.tweens, index)
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

local function removeSpringRun(run)
  for index = #springRuns, 1, -1 do
    if springRuns[index] == run then
      table.remove(springRuns, index)
      return
    end
  end
end

local function removeRunnerSpring(runner, run)
  local list = runner.springs
  if not list then
    return
  end
  for index = #list, 1, -1 do
    if list[index] == run then
      table.remove(list, index)
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

-- Fire a list of run-level callbacks (onComplete/onStop). The list is snapshotted
-- first so a handler may safely register/unregister during dispatch.
local function fireCallbacks(list, ctx)
  if not list or #list == 0 then
    return
  end
  local snapshot = {}
  for index = 1, #list do
    snapshot[index] = list[index]
  end
  for index = 1, #snapshot do
    snapshot[index](ctx)
  end
end

-- Emit a one-time deprecation notice for a redundant named field alias. Gated
-- behind feel.strictAliases(true); silent (and deduped) otherwise.
local function warnAlias(canonical, used)
  if not warnAliases or used == canonical then
    return
  end
  local key = canonical .. "<-" .. used
  if warnedAliasPairs[key] then
    return
  end
  warnedAliasPairs[key] = true
  print(string.format("feel: step field '%s' is deprecated; prefer '%s'", used, canonical))
end

-- Canonical field resolvers. Each keeps every historical alias working while
-- defining the precedence in exactly one place. Only redundant *named* aliases
-- warn under strict mode; positional ([1]) and context-natural names do not.
local function stepDuration(step, fallback)
  if step.time ~= nil then
    warnAlias("duration", "time")
  end
  return step.duration or step.time or fallback
end

local function stepCount(step)
  if step.times ~= nil then
    warnAlias("count", "times")
  end
  return step.count or step.times or 1
end

-- Spring tuning resolvers. `k`/`d`/`epsilon` are first-class short forms (common
-- in game-feel code), so they are not treated as deprecated aliases.
local function stepStiffness(step)
  return step.stiffness or step.k or DEFAULT_STIFFNESS
end

local function stepDamping(step)
  return step.damping or step.d or DEFAULT_DAMPING
end

local function stepSettle(step)
  return step.settle or step.epsilon or DEFAULT_SETTLE
end

-- Optional hard cap: force-settle a spring after this many seconds even if it
-- has not reached its threshold. nil means run until settled.
local function stepSpringCap(step)
  return step.duration or step.time
end

local function stepCallback(step)
  if step.fn ~= nil then
    warnAlias("callback", "fn")
  end
  return step.callback or step.fn or step[1]
end

local function parallelChildren(step)
  return step.steps or step.sequences or step[1]
end

local function logMessage(step)
  if step.text ~= nil then
    warnAlias("message", "text")
  end
  return step.message or step.text or step[1] or ""
end

local function optionWeight(option)
  if option.chance ~= nil then
    warnAlias("weight", "chance")
  end
  return option.weight or option.chance or 1
end

local function optionSequence(option)
  return option.step or option.sequence or option.steps or option[1]
end

local function childOptions(ctx, step)
  local result = {}
  local stepOpts = type(step.opts) == "table" and step.opts or nil
  for key, value in pairs(ctx.opts or {}) do
    if key ~= "restart" and key ~= "key" then
      result[key] = value
    end
  end
  for key, value in pairs(stepOpts or {}) do
    result[key] = value
  end
  return result
end

local function restartSlotsFor(target)
  if target == nil then
    return nilRestartSlots
  end

  local slots = restartTargets[target]
  if not slots then
    slots = {}
    restartTargets[target] = slots
  end
  return slots
end

local function clearRestartSlot(runner)
  if runner and runner.restartSlot and runner.restartSlot[runner.restartKey] == runner then
    runner.restartSlot[runner.restartKey] = nil
  end
end

local function copyOptions(base, extra)
  local result = {}
  for key, value in pairs(base or {}) do
    result[key] = value
  end
  for key, value in pairs(extra or {}) do
    result[key] = value
  end
  return result
end

---@param intent string
---@param handler FeelFeedbackHandler
---@return fun()
function Channel:on(intent, handler)
  assert(type(intent) == "string", "intent must be a string")
  assert(type(handler) == "function", "handler must be a function")

  local list = self.listeners[intent]
  if not list then
    list = {}
    self.listeners[intent] = list
  end
  list[#list + 1] = handler

  return function()
    self:off(intent, handler)
  end
end

---@param intent string
---@param handler FeelFeedbackHandler
---@return boolean
function Channel:off(intent, handler)
  local list = self.listeners[intent]
  if not list then
    return false
  end

  for index = #list, 1, -1 do
    if list[index] == handler then
      table.remove(list, index)
      if #list == 0 then
        self.listeners[intent] = nil
      end
      return true
    end
  end

  return false
end

---@param intent string
---@param event? FeelFeedbackEvent
---@return integer
function Channel:emit(intent, event)
  local list = self.listeners[intent]
  if not list then
    return 0
  end

  local snapshot = {}
  for index = 1, #list do
    snapshot[index] = list[index]
  end

  local payload = event or {}
  for index = 1, #snapshot do
    snapshot[index](payload)
  end

  return #snapshot
end

---@param intent string
---@param sequence FeelSequenceInput
---@param defaults? FeelFeedbackEvent
---@return fun()
function Channel:map(intent, sequence, defaults)
  defaults = defaults or {}
  return self:on(intent, function(event)
    event = event or {}
    local target = event.target ~= nil and event.target or defaults.target
    local opts = copyOptions(defaults.opts, event.opts)
    Feel.play(sequence, target, next(opts) and opts or nil)
  end)
end

---@param intent? string
---@return nil
function Channel:clear(intent)
  if intent then
    self.listeners[intent] = nil
    return
  end
  self.listeners = {}
end

local runSequence

local function cancelRunner(runner)
  if not runner or runner.cancelled then
    return
  end

  runner.cancelled = true
  runner.wait = nil

  for _, active in ipairs(runner.tweens or {}) do
    if active.tween and active.tween.stop then
      active.tween:stop()
    end
    if active.state then
      active.state.active = math.max(0, (active.state.active or 1) - 1)
      removeTween(active.state, active.tween)
      if active.state.active == 0 and isIdentity(active.state.values) then
        targets[active.state.target] = nil
      end
    end
  end
  runner.tweens = {}

  for _, run in ipairs(runner.springs or {}) do
    run.done = true
    if run.state then
      run.state.active = math.max(0, (run.state.active or 1) - 1)
      if run.state.active == 0 and isIdentity(run.state.values) then
        targets[run.state.target] = nil
      end
    end
    removeSpringRun(run)
  end
  runner.springs = {}

  for _, child in ipairs(runner.children or {}) do
    cancelRunner(child)
  end
  runner.children = {}

  clearRestartSlot(runner)
  removeChildRunner(runner.parent, runner)
  removeRunner(runner)

  fireCallbacks(runner.onStop, runner.ctx)
end

-- Gather every live tween in a runner's subtree (its own plus all descendants').
local function collectRunnerTweens(runner, acc)
  for _, active in ipairs(runner.tweens or {}) do
    if active.tween then
      acc[#acc + 1] = active.tween
    end
  end
  for _, child in ipairs(runner.children or {}) do
    collectRunnerTweens(child, acc)
  end
  return acc
end

-- Set the paused flag on a runner and its whole subtree so pausing a parent
-- freezes its parallel/play/repeat children too.
local function setSubtreePaused(runner, paused)
  runner.paused = paused
  for _, child in ipairs(runner.children or {}) do
    setSubtreePaused(child, paused)
  end
end

-- Move tweens between flux groups, but only those currently parented to `from`.
-- Note: the vendored flux module returns a wrapper whose dotted remove/add
-- ignore their first argument, so we must call the group methods directly.
local function moveTweens(tweens, from, to)
  for _, tween in ipairs(tweens) do
    if tween.parent == from then
      from:remove(tween)
      to:add(tween)
    end
  end
end

local function isAncestorPaused(runner)
  local parent = runner.parent
  while parent do
    if parent.paused then
      return true
    end
    parent = parent.parent
  end
  return false
end

-- Finish a spring run: snap each field to its exact rest, decrement the target's
-- active count (cleaning up identity targets), drop the run, and advance the
-- sequence. Mirrors the animate tween's oncomplete bookkeeping.
local function settleSpringRun(run)
  if run.done then
    return
  end
  run.done = true

  for _, field in ipairs(run.fields) do
    run.state.values[field.key] = field.rest
  end

  run.state.active = math.max(0, (run.state.active or 1) - 1)
  removeRunnerSpring(run.runner, run)
  removeSpringRun(run)

  if run.step.onComplete then
    run.step.onComplete(run.state.values, run.ctx)
  end
  if run.state.active == 0 and isIdentity(run.state.values) then
    targets[run.state.target] = nil
  end
  if run.opts.markDirty then
    run.opts.markDirty(run.ctx)
  end

  run.nextStep()
end

-- Advance one spring run by dt: integrate every field's spring, write the values
-- back onto the target, and settle once all fields are within threshold (or the
-- optional duration cap is hit).
local function stepSpringRun(run, dt)
  if run.done or run.runner.cancelled then
    return
  end

  if not run.started then
    run.started = true
    if run.step.onStart then
      run.step.onStart(run.state.values, run.ctx)
    end
  end

  run.elapsed = run.elapsed + dt

  local settled = true
  for _, field in ipairs(run.fields) do
    local value = field.spring:update(dt)
    run.state.values[field.key] = value
    if not field.spring:settled(run.settle) then
      settled = false
    end
  end

  if run.step.onUpdate then
    run.step.onUpdate(run.state.values, run.ctx)
  end
  if run.opts.markDirty then
    run.opts.markDirty(run.ctx)
  end

  if settled or (run.cap and run.elapsed >= run.cap) then
    settleSpringRun(run)
  end
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
    local weight = optionWeight(option)
    if weight > 0 then
      total = total + weight
    end
  end

  if total <= 0 then
    return nil
  end

  local pick = math.random() * total
  for _, option in ipairs(options) do
    local weight = optionWeight(option)
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
  runner.finished = true
  clearRestartSlot(runner)
  removeChildRunner(runner.parent, runner)
  removeRunner(runner)

  if runner.done then
    runner.done(runner.ctx)
  end

  fireCallbacks(runner.onComplete, runner.ctx)
end

local function runStep(runner, step, nextStep)
  local ctx = runner.ctx
  local kind = step.kind or "emit"
  local opts = ctx.opts or {}

  if kind == "wait" or kind == "pause" then
    runner.wait = {
      remaining = stepDuration(step, 0),
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
    tween = group:to(state.values, stepDuration(step, 0.16), copyNumericFields(step.to))
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
      removeRunnerTween(runner, tween)
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
    runner.tweens[#runner.tweens + 1] = {
      state = state,
      tween = tween,
    }
    if opts.markDirty then
      opts.markDirty(ctx)
    end
    return
  end

  if kind == "spring" then
    local state = stateFor(ctx.target)
    if step.from then
      applyFields(state.values, step.from)
    end

    local stiffness = stepStiffness(step)
    local damping = stepDamping(step)
    local toMap = copyNumericFields(step.to)
    local pullMap = copyNumericFields(step.pull)

    -- Build one spring per driven field. `to` sets the rest anchor; `pull` is an
    -- instantaneous displacement that springs back toward that anchor (the
    -- current value when there is no `to`).
    local fields = {}
    local seen = {}
    local function addField(key)
      if seen[key] then
        return
      end
      seen[key] = true
      local current = state.values[key]
      if current == nil then
        current = DEFAULTS[key] or 0
      end
      local rest = toMap[key]
      if rest == nil then
        rest = current
      end
      local startX = current + (pullMap[key] or 0)
      local spring = newSpring(startX, stiffness, damping)
      spring.target = rest
      state.values[key] = startX
      fields[#fields + 1] = { key = key, spring = spring, rest = rest }
    end
    for key in pairs(toMap) do
      addField(key)
    end
    for key in pairs(pullMap) do
      addField(key)
    end

    if #fields == 0 then
      nextStep()
      return
    end

    state.active = (state.active or 0) + 1
    local run = {
      runner = runner,
      state = state,
      step = step,
      ctx = ctx,
      opts = opts,
      fields = fields,
      settle = stepSettle(step),
      cap = stepSpringCap(step),
      elapsed = 0,
      started = false,
      nextStep = nextStep,
    }
    runner.springs = runner.springs or {}
    runner.springs[#runner.springs + 1] = run
    springRuns[#springRuns + 1] = run

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
    local children = parallelChildren(step)
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
    local count = stepCount(step)
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
    local sequence = option and optionSequence(option)
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
    local callback = stepCallback(step)
    if type(callback) == "function" then
      callback(ctx)
    end
  elseif kind == "log" then
    local message = logMessage(step)
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
  local restartSlot
  local restartKey
  if opts.restart == true then
    restartKey = opts.key
    if restartKey == nil then
      restartKey = nameOrSequence
    end
    if restartKey ~= nil then
      restartSlot = restartSlotsFor(target)
      cancelRunner(restartSlot[restartKey])
    end
  end

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
    tweens = {},
    elapsed = 0,
    onComplete = {},
    onStop = {},
    restartSlot = restartSlot,
    restartKey = restartKey,
  }
  ctx.runner = runner
  setmetatable(ctx, FeelContext)

  if meta.parent then
    runner.parent = meta.parent
    meta.parent.children[#meta.parent.children + 1] = runner
  end

  runners[#runners + 1] = runner
  if restartSlot and restartKey ~= nil then
    restartSlot[restartKey] = runner
  end

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

---@param meta? FeelTargetMeta
---@return FeelTarget
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

---@param name string
---@param sequence FeelSequenceInput
---@return FeelStep[]?
function Feel.define(name, sequence)
  local normalized = normalizeSequence(sequence)
  registry[name] = normalized
  return normalized
end

---@param name string
---@return FeelStep[]?
function Feel.get(name)
  return registry[name]
end

---@param sequence FeelSequenceInput
---@return boolean ok
---@return string? err
function Feel.validate(sequence)
  return validateSequence(sequence)
end

---@param nameOrSequence FeelSequenceInput
---@param target? FeelTarget
---@param opts? FeelPlayOptions
---@return FeelContext?
function Feel.play(nameOrSequence, target, opts)
  if nameOrSequence == nil or nameOrSequence == false then
    return nil
  end

  return runSequence(nameOrSequence, target, opts)
end

---@param dt? number
---@return boolean
function Feel.update(dt)
  dt = dt or 0
  if globalPaused then
    -- Frozen: report whether work is pending, but advance nothing.
    return #group > 0 or #runners > 0 or #springRuns > 0
  end
  dt = dt * globalTimeScale
  local hadActive = #group > 0 or #runners > 0 or #springRuns > 0
  group:update(dt)

  -- Step springs. Iterate a snapshot: settling a run calls nextStep, which may
  -- start new springs/tweens we should not advance until the next frame.
  if #springRuns > 0 then
    local pending = {}
    for index = 1, #springRuns do
      pending[index] = springRuns[index]
    end
    for index = 1, #pending do
      local run = pending[index]
      if not run.done and not run.runner.cancelled and not run.runner.paused and not isAncestorPaused(run.runner) then
        stepSpringRun(run, dt)
      end
    end
  end

  for index = #runners, 1, -1 do
    local runner = runners[index]
    if runner and not runner.paused then
      runner.elapsed = (runner.elapsed or 0) + dt
      local wait = runner.wait
      if wait then
        wait.remaining = wait.remaining - dt
        if wait.remaining <= 0 then
          runner.wait = nil
          wait.nextStep()
        end
      end
    end
  end

  return hadActive or #group > 0 or #runners > 0 or #springRuns > 0
end

---@return FeelActiveRun[]
function Feel.active()
  local active = {}

  for _, runner in ipairs(runners) do
    if runner and not runner.cancelled then
      local wait = runner.wait
      active[#active + 1] = {
        target = runner.ctx and runner.ctx.target or nil,
        source = runner.ctx and runner.ctx.source or nil,
        trigger = runner.ctx and runner.ctx.trigger or "manual",
        key = runner.restartKey,
        index = runner.index or 0,
        count = #(runner.sequence or {}),
        elapsed = runner.elapsed or 0,
        waiting = wait ~= nil,
        remaining = wait and wait.remaining or nil,
        tweens = #(runner.tweens or {}),
        children = #(runner.children or {}),
      }
    end
  end

  return active
end

---@param target? FeelTarget
---@param key? string|number|table
---@return boolean
function Feel.isPlaying(target, key)
  for _, runner in ipairs(runners) do
    if runner and not runner.cancelled and runner.ctx and runner.ctx.target == target then
      if key == nil or runner.restartKey == key then
        return true
      end
    end
  end

  return false
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
  restartTargets[target] = nil
end

---@param target? FeelTarget
---@return nil
function Feel.clear(target)
  if target then
    clearTarget(target)
    return
  end

  registry = {}

  for index = #group, 1, -1 do
    group:remove(index)
  end
  for index = #pausedGroup, 1, -1 do
    pausedGroup:remove(index)
  end

  for index = #runners, 1, -1 do
    cancelRunner(runners[index])
  end
  runners = {}
  springRuns = {}
  targets = setmetatable({}, { __mode = "k" })
  restartTargets = setmetatable({}, { __mode = "k" })
  nilRestartSlots = {}
  globalPaused = false
  globalTimeScale = 1
end

---@return FeelChannel
function Feel.channel()
  return setmetatable({ listeners = {} }, Channel)
end

-- Create a raw spring you drive yourself (call spring:update(dt) each frame).
-- Use this when you need spring motion outside a sequence; inside sequences use
-- the "spring" step instead, which feel.update advances for you.
---@param x? number
---@param stiffness? number
---@param damping? number
---@return FeelSpring
function Feel.spring(x, stiffness, damping)
  return newSpring(x, stiffness, damping)
end

-- Stop a single run started by feel.play(). Safe to call with nil.
---@param ctx? FeelContext
function Feel.stop(ctx)
  local runner = ctx and ctx.runner
  if not runner or runner.cancelled then
    return
  end
  cancelRunner(runner)
end

-- Pause a single run (and its child subtree). Its tweens are parked and its
-- waits stop counting down until resume(). Safe to call with nil.
---@param ctx? FeelContext
function Feel.pause(ctx)
  local runner = ctx and ctx.runner
  if not runner or runner.cancelled or runner.paused then
    return
  end
  setSubtreePaused(runner, true)
  moveTweens(collectRunnerTweens(runner, {}), group, pausedGroup)
end

-- Resume a previously paused run. Safe to call with nil.
---@param ctx? FeelContext
function Feel.resume(ctx)
  local runner = ctx and ctx.runner
  if not runner or runner.cancelled or not runner.paused then
    return
  end
  setSubtreePaused(runner, false)
  if isAncestorPaused(runner) then
    -- A paused ancestor still owns the parked tweens; they un-park with it.
    return
  end
  moveTweens(collectRunnerTweens(runner, {}), pausedGroup, group)
end

-- Freeze every run globally (feel.update advances nothing until resumeAll()).
function Feel.pauseAll()
  globalPaused = true
end

function Feel.resumeAll()
  globalPaused = false
end

---@return boolean
function Feel.isPausedAll()
  return globalPaused
end

-- Scale the feel clock itself (tweens and waits). Independent of the optional
-- feel.feedbacks time scale, which scales host game logic, not feel's clock.
---@param scale number
---@return number
function Feel.setTimeScale(scale)
  globalTimeScale = math.max(0, tonumber(scale) or 1)
  return globalTimeScale
end

---@return number
function Feel.timeScale()
  return globalTimeScale
end

-- Toggle one-time deprecation warnings for redundant named field aliases.
---@param on? boolean
---@return boolean
function Feel.strictAliases(on)
  if on ~= nil then
    warnAliases = on == true
  end
  return warnAliases
end

function FeelContext:stop()
  Feel.stop(self)
end

function FeelContext:pause()
  Feel.pause(self)
end

function FeelContext:resume()
  Feel.resume(self)
end

---@return boolean
function FeelContext:isPaused()
  local runner = self.runner
  return runner ~= nil and runner.paused == true and not runner.cancelled
end

---@return boolean
function FeelContext:isPlaying()
  local runner = self.runner
  return runner ~= nil and not runner.cancelled
end

-- Run a callback when this run completes. Fires immediately if already done.
---@param fn fun(ctx: FeelContext)
---@return FeelContext
function FeelContext:onComplete(fn)
  local runner = self.runner
  if type(fn) == "function" and runner then
    if runner.finished then
      fn(self)
    elseif not runner.cancelled then
      runner.onComplete[#runner.onComplete + 1] = fn
    end
  end
  return self
end

-- Run a callback when this run is stopped/cancelled (not on normal completion).
---@param fn fun(ctx: FeelContext)
---@return FeelContext
function FeelContext:onStop(fn)
  local runner = self.runner
  if type(fn) == "function" and runner then
    if runner.cancelled and not runner.finished then
      fn(self)
    elseif not runner.cancelled then
      runner.onStop[#runner.onStop + 1] = fn
    end
  end
  return self
end

Feel.flux = flux
Feel.fields = FIELDS
Feel.normalizeStep = normalizeStep
Feel.normalizeSequence = normalizeSequence

return Feel
