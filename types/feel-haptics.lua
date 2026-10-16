---@meta feel.haptics

---@class FeelHapticsModule
---@field presets table<string, FeelHapticPulse[]>
local feelHaptics = {}

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

---@param driver? FeelHapticsDriver
---@param opts? FeelHapticsOptions
---@return FeelHaptics
function feelHaptics.new(driver, opts) end

---@param name string
---@param pattern FeelHapticPulse[]
---@return FeelHaptics
function FeelHaptics:define(name, pattern) end

---@param patterns? table<string, FeelHapticPulse[]>
---@return FeelHaptics
function FeelHaptics:defineAll(patterns) end

---@param name string
---@return FeelHapticPulse[]?
function FeelHaptics:get(name) end

---@return string[]
function FeelHaptics:list() end

---@param name string
---@return boolean
function FeelHaptics:remove(name) end

---@param payload? FeelHapticPayload
---@return boolean
function FeelHaptics:trigger(payload) end

---@param nameOrPattern string|FeelHapticPulse[]
---@param opts? FeelHapticPlayOptions
---@return FeelHapticRun|false
function FeelHaptics:play(nameOrPattern, opts) end

---@param dt? number
---@return boolean
function FeelHaptics:update(dt) end

---@param name string
---@param target? string
---@param opts? FeelHapticStopOptions
---@return boolean
function FeelHaptics:stop(name, target, opts) end

---@param target? string
---@param opts? FeelHapticStopOptions
---@return boolean
function FeelHaptics:stopTarget(target, opts) end

---@param opts? FeelHapticStopOptions
---@return boolean
function FeelHaptics:stopAll(opts) end

---@param enabled? boolean
---@return boolean
function FeelHaptics:setEnabled(enabled) end

---@return boolean
function FeelHaptics:isEnabled() end

---@param scale number
---@return number
function FeelHaptics:setScale(scale) end

---@return number
function FeelHaptics:scale() end

return feelHaptics
