---@module "feel.haptics"

---@class FeelHapticsModule
---@field presets table<string, FeelHapticPulse[]>
---@field new fun(driver?: FeelHapticsDriver, opts?: FeelHapticsOptions): FeelHaptics
local Haptics = {}

---@class FeelHapticsDriver
---@field play? fun(payload: FeelHapticPayload, ctx: FeelHapticsDriverContext): boolean
---@field stop? fun(opts?: FeelHapticStopOptions): boolean

---@class FeelHapticsDriverContext
---@field durationExplicit boolean

---@class FeelHapticsOptions
---@field enabled? boolean
---@field scale? number
---@field duration? number
---@field presets? boolean Load the built-in presets. Defaults to true.

---@class FeelHapticPulse
---@field value? number
---@field intensity? number Alias for value.
---@field left? number
---@field right? number
---@field duration? number
---@field gap? number
---@field system? boolean
---@field [string] any

---@class FeelHapticPlayOptions
---@field target? string
---@field name? string Alias for target.
---@field system? boolean
---@field restart? boolean Defaults to true for the same pattern and target.
---@field [string] any

---@class FeelHapticPayload: FeelHapticPlayOptions
---@field value? number
---@field intensity? number
---@field left? number
---@field right? number
---@field duration? number

---@class FeelHapticStopOptions
---@field target? string
---@field name? string Alias for target.
---@field system? boolean
---@field pattern? string
---@field [string] any

---@class FeelHaptics
---@field driver FeelHapticsDriver
---@field patterns table<string, FeelHapticPulse[]>
---@field runs table<integer, FeelHapticRun>
---@field defaultDuration number
local Engine = {}
Engine.__index = Engine

---@class FeelHapticRun
---@field name string
---@field target? string
---@field stop fun(self: FeelHapticRun): FeelHapticRun
---@field pause fun(self: FeelHapticRun): FeelHapticRun
---@field resume fun(self: FeelHapticRun): FeelHapticRun
---@field isPaused fun(self: FeelHapticRun): boolean
---@field isPlaying fun(self: FeelHapticRun): boolean
---@field onComplete fun(self: FeelHapticRun, callback: fun(run: FeelHapticRun)): FeelHapticRun
---@field onStop fun(self: FeelHapticRun, callback: fun(run: FeelHapticRun)): FeelHapticRun
local Run = {}
Run.__index = Run

local BUILTIN_PRESETS = {
  tap = {
    { value = 0.55, duration = 0.035 },
  },
  selection = {
    { value = 0.32, duration = 0.025 },
  },
  impactLight = {
    { value = 0.38, duration = 0.045 },
  },
  impactMedium = {
    { value = 0.65, duration = 0.065 },
  },
  impactHeavy = {
    { value = 1, duration = 0.1 },
  },
  success = {
    { value = 0.42, duration = 0.045, gap = 0.045 },
    { value = 0.8, duration = 0.085 },
  },
  warning = {
    { value = 0.72, duration = 0.075, gap = 0.055 },
    { value = 0.72, duration = 0.075 },
  },
  error = {
    { value = 0.9, duration = 0.07, gap = 0.04 },
    { value = 0.9, duration = 0.07, gap = 0.04 },
    { value = 0.9, duration = 0.1 },
  },
  heartbeat = {
    { value = 0.5, duration = 0.055, gap = 0.055 },
    { value = 0.9, duration = 0.085, gap = 0.22 },
    { value = 0.5, duration = 0.055, gap = 0.055 },
    { value = 0.9, duration = 0.085 },
  },
}

local function clamp01(value, fallback)
  value = tonumber(value)
  if value == nil then
    value = tonumber(fallback) or 0
  end
  return math.max(0, math.min(1, value))
end

local function shallowCopy(value)
  local result = {}
  for key, item in pairs(value or {}) do
    result[key] = item
  end
  return result
end

local function copyPattern(pattern)
  local result = {}
  for index, pulse in ipairs(pattern or {}) do
    result[index] = type(pulse) == "table" and shallowCopy(pulse) or pulse
  end
  return result
end

local function callCallbacks(callbacks, run)
  for _, callback in ipairs(callbacks) do
    callback(run)
  end
end

local function removeRun(engine, run)
  if run._id and engine.runs[run._id] == run then
    engine.runs[run._id] = nil
  end
end

local function stopRun(run, stopOutput)
  if not run._playing then
    return
  end
  run._playing = false
  removeRun(run._engine, run)
  if stopOutput and type(run._engine.driver.stop) == "function" then
    run._engine.driver.stop({
      pattern = run.name,
      target = run.target,
      name = run.target,
      system = run._system,
    })
  end
  callCallbacks(run._stopCallbacks, run)
end

function Run:stop()
  if self._playing then
    stopRun(self, true)
  end
  return self
end

function Run:pause()
  if self._playing then
    self._paused = true
  end
  return self
end

function Run:resume()
  if self._playing then
    self._paused = false
  end
  return self
end

function Run:isPaused()
  return self._paused == true
end

function Run:isPlaying()
  return self._playing == true
end

function Run:onComplete(callback)
  if type(callback) == "function" then
    self._completeCallbacks[#self._completeCallbacks + 1] = callback
  end
  return self
end

function Run:onStop(callback)
  if type(callback) == "function" then
    self._stopCallbacks[#self._stopCallbacks + 1] = callback
  end
  return self
end

local function completeRun(run)
  if not run._playing then
    return
  end
  run._playing = false
  removeRun(run._engine, run)
  callCallbacks(run._completeCallbacks, run)
end

local function cancelRuns(engine, predicate)
  local pending = {}
  for key, run in pairs(engine.runs) do
    if predicate(run) then
      pending[#pending + 1] = { key = key, run = run }
    end
  end
  for _, item in ipairs(pending) do
    engine.runs[item.key] = nil
    stopRun(item.run, false)
  end
  return #pending > 0
end

---@param name string
---@param pattern FeelHapticPulse[]
---@return FeelHaptics
function Engine:define(name, pattern)
  assert(type(name) == "string", "haptic pattern name must be a string")
  assert(type(pattern) == "table", "haptic pattern must be a table")
  self.patterns[name] = copyPattern(pattern)
  return self
end

---@param patterns? table<string, FeelHapticPulse[]>
---@return FeelHaptics
function Engine:defineAll(patterns)
  for name, pattern in pairs(patterns or {}) do
    self:define(name, pattern)
  end
  return self
end

---@param name string
---@return FeelHapticPulse[]?
function Engine:get(name)
  local pattern = self.patterns[name]
  return pattern and copyPattern(pattern) or nil
end

---@return string[]
function Engine:list()
  local names = {}
  for name in pairs(self.patterns) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

---@param name string
---@return boolean
function Engine:remove(name)
  if self.patterns[name] == nil then
    return false
  end
  self:stop(name)
  self.patterns[name] = nil
  return true
end

---@param payload? FeelHapticPayload
---@return boolean
function Engine:trigger(payload)
  if not self._enabled or self._scale <= 0 or type(self.driver.play) ~= "function" then
    return false
  end
  payload = shallowCopy(payload)
  local durationExplicit = payload.duration ~= nil
  local value = payload.value
  if value == nil then
    value = payload.intensity
  end
  value = clamp01(value, 1)
  payload.value = clamp01(value * self._scale)
  payload.intensity = payload.value
  payload.left = clamp01(payload.left, value) * self._scale
  payload.right = clamp01(payload.right, value) * self._scale
  payload.left = clamp01(payload.left)
  payload.right = clamp01(payload.right)
  payload.duration = math.max(0, tonumber(payload.duration) or self.defaultDuration)
  return self.driver.play(payload, { durationExplicit = durationExplicit }) == true
end

---@param nameOrPattern string|FeelHapticPulse[]
---@param opts? FeelHapticPlayOptions
---@return FeelHapticRun|false
function Engine:play(nameOrPattern, opts)
  if not self._enabled or self._scale <= 0 then
    return false
  end
  opts = opts or {}
  local name = type(nameOrPattern) == "string" and nameOrPattern or "<anonymous>"
  local pattern = type(nameOrPattern) == "string" and self.patterns[nameOrPattern] or nameOrPattern
  if type(pattern) ~= "table" or #pattern == 0 then
    return false
  end

  local target = opts.target or opts.name
  if opts.restart ~= false then
    cancelRuns(self, function(run)
      return run.name == name and run.target == target
    end)
  end

  local pulses = {}
  for _, item in ipairs(pattern) do
    local pulse = type(item) == "number" and { value = item } or item
    if type(pulse) == "table" then
      local payload = shallowCopy(opts)
      for key, value in pairs(pulse) do
        payload[key] = value
      end
      payload.target = target
      payload.name = target
      payload.duration = math.max(0, tonumber(pulse.duration) or self.defaultDuration)
      payload.gap = nil
      payload.restart = nil
      pulses[#pulses + 1] = {
        payload = payload,
        delay = payload.duration + math.max(0, tonumber(pulse.gap) or 0),
      }
    end
  end
  if #pulses == 0 then
    return false
  end

  self._nextRunId = self._nextRunId + 1
  local first = pulses[1]
  local run = setmetatable({
    name = name,
    target = target,
    _id = self._nextRunId,
    _engine = self,
    _system = opts.system,
    _pulses = pulses,
    _index = 2,
    _remaining = first.delay,
    _playing = true,
    _paused = false,
    _completeCallbacks = {},
    _stopCallbacks = {},
  }, Run)
  self.runs[run._id] = run
  self:trigger(first.payload)
  return run
end

---@param dt? number
---@return boolean
function Engine:update(dt)
  dt = math.max(0, tonumber(dt) or 0)
  local active = {}
  for _, run in pairs(self.runs) do
    active[#active + 1] = run
  end
  for _, run in ipairs(active) do
    if run._playing and not run._paused then
      run._remaining = run._remaining - dt
      while run._playing and run._remaining <= 0 do
        local pulse = run._pulses[run._index]
        if not pulse then
          completeRun(run)
        else
          run._index = run._index + 1
          self:trigger(pulse.payload)
          run._remaining = run._remaining + pulse.delay
        end
      end
    end
  end
  return next(self.runs) ~= nil
end

---@param name string
---@param target? string
---@param opts? FeelHapticStopOptions
---@return boolean
function Engine:stop(name, target, opts)
  local cancelled = cancelRuns(self, function(run)
    return run.name == name and (target == nil or run.target == target)
  end)
  if not cancelled then
    return false
  end
  opts = shallowCopy(opts)
  opts.pattern = name
  opts.target = target
  opts.name = target
  if type(self.driver.stop) == "function" then
    self.driver.stop(opts)
  end
  return true
end

---@param target? string
---@param opts? FeelHapticStopOptions
---@return boolean
function Engine:stopTarget(target, opts)
  local cancelled = cancelRuns(self, function(run)
    return target == nil or run.target == target
  end)
  opts = shallowCopy(opts)
  opts.target = target
  opts.name = target
  local stopped = type(self.driver.stop) == "function" and self.driver.stop(opts) == true
  return cancelled or stopped
end

---@param opts? FeelHapticStopOptions
---@return boolean
function Engine:stopAll(opts)
  return self:stopTarget(nil, opts)
end

---@param enabled? boolean
---@return boolean
function Engine:setEnabled(enabled)
  self._enabled = enabled ~= false
  if not self._enabled then
    self:stopAll()
  end
  return self._enabled
end

---@return boolean
function Engine:isEnabled()
  return self._enabled
end

---@param scale number
---@return number
function Engine:setScale(scale)
  self._scale = clamp01(scale, 1)
  if self._scale == 0 then
    self:stopAll()
  end
  return self._scale
end

---@return number
function Engine:scale()
  return self._scale
end

---@param driver? FeelHapticsDriver
---@param opts? FeelHapticsOptions
---@return FeelHaptics
function Haptics.new(driver, opts)
  driver = driver or {}
  opts = opts or {}
  local engine = setmetatable({
    driver = driver,
    patterns = {},
    runs = {},
    defaultDuration = math.max(0, tonumber(opts.duration) or 0.12),
    _enabled = opts.enabled ~= false,
    _scale = clamp01(opts.scale, 1),
    _nextRunId = 0,
  }, Engine)
  if opts.presets ~= false then
    engine:defineAll(BUILTIN_PRESETS)
  end
  return engine
end

Haptics.presets = {}
for name, pattern in pairs(BUILTIN_PRESETS) do
  Haptics.presets[name] = copyPattern(pattern)
end

return Haptics
