---@module "feel.haptics"

---@class FeelHapticsModule
---@field presets table<string, FeelHapticPulse[]|FeelHapticSegment[]>
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
---@field minPulse? number Minimum generated pulse duration. Defaults to 0.02 seconds.
---@field maxPulse? number Maximum generated pulse duration. Defaults to 0.2 seconds.
---@field minGap? number Minimum generated pulse gap. Defaults to 0.02 seconds.
---@field maxGap? number Maximum generated pulse gap. Defaults to 0.2 seconds.
---@field maxGeneratedPulses? integer Safety limit for one compiled pattern. Defaults to 2048.

---@class FeelHapticPulse
---@field value? number
---@field intensity? number Alias for value.
---@field left? number
---@field right? number
---@field duration? number
---@field gap? number
---@field delay? number Delay before this pulse.
---@field system? boolean
---@field [string] any

---@class FeelHapticSegment
---@field type "continuous"|"pulse"|"line"|"curve"
---@field at? number Start time in seconds.
---@field timestamp? number Alias for at.
---@field duration number
---@field intensity? number|FeelHapticValuePoint[]
---@field frequency? number|FeelHapticValuePoint[]
---@field value? number
---@field left? number
---@field right? number
---@field system? boolean
---@field [string] any

---@class FeelHapticValuePoint
---@field time number
---@field value number

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
---@field patterns table<string, FeelHapticPulse[]|FeelHapticSegment[]>
---@field compiledPatterns table<string, FeelHapticPulse[]>
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

local function continuous(at, duration, intensity)
  return { type = "continuous", at = at, duration = duration, intensity = intensity }
end

local function pulseSegment(at, duration, intensity, frequency)
  return { type = "pulse", at = at, duration = duration, intensity = intensity, frequency = frequency }
end

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
  softTap = { continuous(0, 0.02, 0.25) },
  doubleTap = { continuous(0, 0.035, 0.55), continuous(0.09, 0.035, 0.65) },
  tripleTap = { continuous(0, 0.03, 0.5), continuous(0.08, 0.03, 0.6), continuous(0.16, 0.03, 0.75) },
  longPress = { continuous(0, 0.2, 0.55) },
  rumble = { pulseSegment(0, 1, 0.85, 0.2) },
  drone = { pulseSegment(0, 0.8, 0.45, 0.55) },
  flutter = {
    continuous(0, 0.025, 0.35),
    continuous(0.08, 0.025, 0.45),
    continuous(0.15, 0.025, 0.55),
    continuous(0.4, 0.025, 0.5),
    continuous(0.48, 0.025, 0.6),
    continuous(0.56, 0.025, 0.7),
  },
  trill = { pulseSegment(0, 0.4, 0.75, 0.95), pulseSegment(0.7, 0.4, 0.9, 0.95) },
  alert = {
    pulseSegment(0, 0.25, 0.9, 1),
    pulseSegment(0.38, 0.25, 0.9, 1),
    pulseSegment(0.76, 0.25, 1, 1),
  },
  reject = { continuous(0, 0.09, 0.8), continuous(0.16, 0.09, 0.8) },
  alarm = {
    continuous(0, 0.18, 0.85),
    continuous(0.24, 0.09, 0.7),
    continuous(0.38, 0.09, 0.9),
  },
  waltz = {
    continuous(0, 0.07, 0.9),
    continuous(0.22, 0.03, 0.45),
    continuous(0.42, 0.03, 0.45),
    continuous(0.66, 0.07, 0.9),
    continuous(0.88, 0.03, 0.45),
    continuous(1.08, 0.03, 0.45),
  },
  warDrum = {
    continuous(0, 0.12, 1),
    continuous(0.22, 0.04, 0.55),
    continuous(0.31, 0.04, 0.65),
    continuous(0.5, 0.12, 1),
  },
  thunder = { pulseSegment(0, 0.9, 0.65, 0.3), pulseSegment(0.7, 1.1, 0.8, 0.35) },
  finale = {
    continuous(0, 0.06, 0.35),
    continuous(0.18, 0.08, 0.5),
    continuous(0.38, 0.1, 0.65),
    continuous(0.56, 0.06, 0.75),
    continuous(0.7, 0.06, 0.85),
    continuous(0.9, 0.22, 1),
  },
  drumroll = { pulseSegment(0, 0.7, 0.25, 0.98), continuous(0.9, 0.2, 1) },
  crescendo = {
    {
      type = "line",
      at = 0,
      duration = 1,
      intensity = { { time = 0, value = 0.15 }, { time = 1, value = 1 } },
      frequency = { { time = 0, value = 0.35 }, { time = 1, value = 0.95 } },
    },
  },
  morse = { continuous(0, 0.035, 0.65), continuous(0.11, 0.14, 0.8), continuous(0.31, 0.035, 0.65) },
  siren = {
    pulseSegment(0, 0.4, 0.8, 0.4),
    pulseSegment(0.42, 0.4, 0.3, 0.95),
    pulseSegment(0.84, 0.4, 0.8, 0.4),
    pulseSegment(1.26, 0.4, 0.3, 0.95),
  },
  shudder = {
    pulseSegment(0, 0.25, 0.9, 0.6),
    pulseSegment(0.26, 0.25, 0.2, 0.6),
    pulseSegment(0.52, 0.25, 0.9, 0.6),
    pulseSegment(0.78, 0.25, 0.2, 0.6),
    pulseSegment(1.04, 0.25, 0.9, 0.6),
  },
  windup = {
    continuous(0, 0.035, 0.25),
    continuous(0.38, 0.035, 0.35),
    continuous(0.62, 0.035, 0.5),
    continuous(0.78, 0.035, 0.65),
    continuous(0.86, 0.035, 0.8),
    continuous(0.91, 0.05, 1),
  },
  unwind = {
    continuous(0, 0.035, 1),
    continuous(0.05, 0.035, 0.8),
    continuous(0.13, 0.035, 0.65),
    continuous(0.29, 0.035, 0.5),
    continuous(0.53, 0.035, 0.35),
    continuous(0.91, 0.035, 0.25),
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

local function deepCopy(value)
  if type(value) ~= "table" then
    return value
  end
  local result = {}
  for key, item in pairs(value) do
    result[key] = deepCopy(item)
  end
  return result
end

local function copyPattern(pattern)
  local result = {}
  for index, pulse in ipairs(pattern or {}) do
    result[index] = deepCopy(pulse)
  end
  return result
end

local function lerp(a, b, amount)
  return a + (b - a) * amount
end

local function normalizeCurve(points, duration, fallback)
  local normalized = {}
  for _, point in ipairs(type(points) == "table" and points or {}) do
    if type(point) == "table" then
      normalized[#normalized + 1] = {
        time = math.max(0, math.min(duration, tonumber(point.time) or 0)),
        value = clamp01(point.value, fallback),
      }
    end
  end
  table.sort(normalized, function(a, b)
    return a.time < b.time
  end)
  if #normalized == 0 then
    return { { time = 0, value = fallback }, { time = duration, value = fallback } }
  end
  if normalized[1].time > 0 then
    table.insert(normalized, 1, { time = 0, value = normalized[1].value })
  end
  if normalized[#normalized].time < duration then
    normalized[#normalized + 1] = { time = duration, value = normalized[#normalized].value }
  end
  return normalized
end

local function sampleCurve(points, time)
  if time <= points[1].time then
    return points[1].value
  end
  for index = 1, #points - 1 do
    local current = points[index]
    local following = points[index + 1]
    if time <= following.time then
      local span = following.time - current.time
      if span <= 0 then
        return following.value
      end
      return lerp(current.value, following.value, (time - current.time) / span)
    end
  end
  return points[#points].value
end

local function isTimelinePattern(pattern)
  for _, entry in ipairs(pattern or {}) do
    if type(entry) == "table" and (entry.type ~= nil or entry.at ~= nil or entry.timestamp ~= nil) then
      return true
    end
  end
  return false
end

local function segmentPayload(segment, intensity)
  local payload = shallowCopy(segment)
  payload.type = nil
  payload.at = nil
  payload.timestamp = nil
  payload.frequency = nil
  payload.gap = nil
  payload.delay = nil
  payload.value = segment.value ~= nil and segment.value or intensity
  payload.intensity = payload.value
  return payload
end

local function addInterval(engine, intervals, startTime, endTime, payload, source)
  if endTime <= startTime then
    return
  end
  assert(#intervals < engine.maxGeneratedPulses, "haptic pattern exceeds maxGeneratedPulses")
  intervals[#intervals + 1] = {
    start = startTime,
    finish = endTime,
    payload = payload,
    source = source,
  }
end

local function resolveShotLength(engine, remaining, intensity)
  local maximum = math.max(engine.minPulse, math.min(remaining, engine.maxPulse))
  return math.min(remaining, lerp(engine.minPulse, maximum, clamp01(intensity, 0.5)))
end

local function resolveGapLength(engine, remaining, frequency)
  local maximum = math.max(engine.minGap, math.min(remaining, engine.maxGap))
  return lerp(maximum, engine.minGap, clamp01(frequency, 0.5))
end

local function segmentIntervals(engine, segment, source, intervals)
  local kind = segment.type or "continuous"
  assert(kind == "continuous" or kind == "pulse" or kind == "line" or kind == "curve", "unknown haptic segment type: " .. tostring(kind))
  local startTime = math.max(0, tonumber(segment.at) or tonumber(segment.timestamp) or 0)
  local duration = math.max(0, tonumber(segment.duration) or 0)
  if duration <= 0 then
    return
  end
  if kind == "continuous" then
    local intensity = clamp01(segment.intensity, segment.value or 1)
    addInterval(engine, intervals, startTime, startTime + duration, segmentPayload(segment, intensity), source)
    return
  end

  local intensityCurve
  local frequencyCurve
  if kind == "line" or kind == "curve" then
    local intensityFallback = clamp01(type(segment.intensity) == "number" and segment.intensity or segment.value, 0.5)
    local frequencyFallback = clamp01(type(segment.frequency) == "number" and segment.frequency or nil, 0.5)
    intensityCurve = normalizeCurve(segment.intensity, duration, intensityFallback)
    frequencyCurve = normalizeCurve(segment.frequency, duration, frequencyFallback)
  end
  local cursor = 0
  while cursor < duration do
    local intensity = intensityCurve and sampleCurve(intensityCurve, cursor) or clamp01(segment.intensity, 0.5)
    local frequency = frequencyCurve and sampleCurve(frequencyCurve, cursor) or clamp01(segment.frequency, 0.5)
    local remaining = duration - cursor
    local shot = resolveShotLength(engine, remaining, intensity)
    addInterval(engine, intervals, startTime + cursor, startTime + cursor + shot, segmentPayload(segment, intensity), source)
    cursor = cursor + shot + resolveGapLength(engine, remaining, frequency)
  end
end

local function compileTimeline(engine, pattern)
  local intervals = {}
  for source, segment in ipairs(pattern) do
    assert(type(segment) == "table", "timeline haptic patterns must contain segment tables")
    assert(
      segment.type ~= nil or segment.at ~= nil or segment.timestamp ~= nil,
      "cannot mix sequential pulses with timeline segments"
    )
    segmentIntervals(engine, segment, source, intervals)
  end
  if #intervals == 0 then
    return {}
  end

  local boundaries = {}
  for _, interval in ipairs(intervals) do
    boundaries[#boundaries + 1] = interval.start
    boundaries[#boundaries + 1] = interval.finish
  end
  table.sort(boundaries)
  local unique = {}
  for _, boundary in ipairs(boundaries) do
    if unique[#unique] ~= boundary then
      unique[#unique + 1] = boundary
    end
  end

  local spans = {}
  for index = 1, #unique - 1 do
    local spanStart = unique[index]
    local spanEnd = unique[index + 1]
    local left, right = 0, 0
    local strongest
    local strongestValue = -1
    local system = false
    local systemDefault = false
    for _, interval in ipairs(intervals) do
      if interval.start < spanEnd and interval.finish > spanStart then
        local payload = interval.payload
        local value = clamp01(payload.value, payload.intensity or 1)
        local intervalLeft = clamp01(payload.left, value)
        local intervalRight = clamp01(payload.right, value)
        left = math.max(left, intervalLeft)
        right = math.max(right, intervalRight)
        if math.max(intervalLeft, intervalRight) > strongestValue then
          strongest = interval
          strongestValue = math.max(intervalLeft, intervalRight)
        end
        if payload.system == true then
          system = true
        elseif payload.system == nil then
          systemDefault = true
        end
      end
    end
    if strongest then
      local output = shallowCopy(strongest.payload)
      output.left = left
      output.right = right
      output.value = math.max(left, right)
      output.intensity = output.value
      if system then
        output.system = true
      elseif not systemDefault then
        output.system = false
      else
        output.system = nil
      end
      spans[#spans + 1] = {
        start = spanStart,
        finish = spanEnd,
        source = strongest.source,
        payload = output,
      }
    end
  end

  local compiled = {}
  local cursor = 0
  for _, span in ipairs(spans) do
    local previous = compiled[#compiled]
    if previous
      and previous._source == span.source
      and previous.left == span.payload.left
      and previous.right == span.payload.right
      and previous.system == span.payload.system
      and previous._finish == span.start
    then
      previous.duration = span.finish - previous._start
      previous._finish = span.finish
    else
      local output = shallowCopy(span.payload)
      output.delay = math.max(0, span.start - cursor)
      output.duration = span.finish - span.start
      output._source = span.source
      output._start = span.start
      output._finish = span.finish
      compiled[#compiled + 1] = output
    end
    cursor = span.finish
  end
  for _, output in ipairs(compiled) do
    output._source = nil
    output._start = nil
    output._finish = nil
  end
  assert(#compiled <= engine.maxGeneratedPulses, "haptic pattern exceeds maxGeneratedPulses")
  return compiled
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
---@param pattern FeelHapticPulse[]|FeelHapticSegment[]
---@return FeelHaptics
function Engine:define(name, pattern)
  assert(type(name) == "string", "haptic pattern name must be a string")
  assert(type(pattern) == "table", "haptic pattern must be a table")
  self.patterns[name] = copyPattern(pattern)
  self.compiledPatterns[name] = self:compile(pattern)
  return self
end

---@param pattern FeelHapticPulse[]|FeelHapticSegment[]
---@return FeelHapticPulse[]
function Engine:compile(pattern)
  assert(type(pattern) == "table", "haptic pattern must be a table")
  if isTimelinePattern(pattern) then
    return compileTimeline(self, pattern)
  end
  local compiled = {}
  for _, pulse in ipairs(pattern) do
    if type(pulse) == "number" then
      compiled[#compiled + 1] = { value = pulse }
    elseif type(pulse) == "table" then
      compiled[#compiled + 1] = deepCopy(pulse)
    end
  end
  return compiled
end

---@param patterns? table<string, FeelHapticPulse[]|FeelHapticSegment[]>
---@return FeelHaptics
function Engine:defineAll(patterns)
  for name, pattern in pairs(patterns or {}) do
    self:define(name, pattern)
  end
  return self
end

---@param name string
---@return FeelHapticPulse[]|FeelHapticSegment[]|nil
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
  self.compiledPatterns[name] = nil
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

local function pulseBefore(pulse)
  return math.max(0, tonumber(pulse.delay) or 0)
end

local function pulseAfter(engine, pulse)
  return math.max(0, tonumber(pulse.duration) or engine.defaultDuration) + math.max(0, tonumber(pulse.gap) or 0)
end

local function triggerRunPulse(engine, run, pulse)
  local payload = shallowCopy(run._opts)
  for key, value in pairs(pulse) do
    payload[key] = value
  end
  payload.target = run.target
  payload.name = run.target
  payload.duration = math.max(0, tonumber(pulse.duration) or engine.defaultDuration)
  payload.gap = nil
  payload.delay = nil
  payload.restart = nil
  engine:trigger(payload)
end

---@param nameOrPattern string|FeelHapticPulse[]|FeelHapticSegment[]
---@param opts? FeelHapticPlayOptions
---@return FeelHapticRun|false
function Engine:play(nameOrPattern, opts)
  if not self._enabled or self._scale <= 0 then
    return false
  end
  opts = opts or {}
  local name = type(nameOrPattern) == "string" and nameOrPattern or "<anonymous>"
  local pattern
  if type(nameOrPattern) == "string" then
    pattern = self.compiledPatterns[nameOrPattern]
  else
    pattern = self:compile(nameOrPattern)
  end
  if type(pattern) ~= "table" or #pattern == 0 then
    return false
  end

  local target = opts.target or opts.name
  if opts.restart ~= false then
    cancelRuns(self, function(run)
      return run.name == name and run.target == target
    end)
  end

  self._nextRunId = self._nextRunId + 1
  local first = pattern[1]
  local firstBefore = pulseBefore(first)
  local run = setmetatable({
    name = name,
    target = target,
    _id = self._nextRunId,
    _engine = self,
    _system = opts.system,
    _pulses = pattern,
    _opts = shallowCopy(opts),
    _index = 1,
    _remaining = firstBefore,
    _waiting = firstBefore > 0,
    _playing = true,
    _paused = false,
    _completeCallbacks = {},
    _stopCallbacks = {},
  }, Run)
  self.runs[run._id] = run
  if not run._waiting then
    triggerRunPulse(self, run, first)
    run._index = 2
    run._remaining = pulseAfter(self, first)
  end
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
        elseif run._waiting then
          triggerRunPulse(self, run, pulse)
          run._index = run._index + 1
          run._remaining = run._remaining + pulseAfter(self, pulse)
          run._waiting = false
        elseif pulseBefore(pulse) > 0 then
          run._remaining = run._remaining + pulseBefore(pulse)
          run._waiting = true
        else
          run._index = run._index + 1
          triggerRunPulse(self, run, pulse)
          run._remaining = run._remaining + pulseAfter(self, pulse)
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
    compiledPatterns = {},
    runs = {},
    defaultDuration = math.max(0, tonumber(opts.duration) or 0.12),
    _enabled = opts.enabled ~= false,
    _scale = clamp01(opts.scale, 1),
    _nextRunId = 0,
    minPulse = math.max(0.001, tonumber(opts.minPulse) or 0.02),
    maxPulse = math.max(0.001, tonumber(opts.maxPulse) or 0.2),
    minGap = math.max(0.001, tonumber(opts.minGap) or 0.02),
    maxGap = math.max(0.001, tonumber(opts.maxGap) or 0.2),
    maxGeneratedPulses = math.max(1, math.floor(tonumber(opts.maxGeneratedPulses) or 2048)),
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
