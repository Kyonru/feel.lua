---@meta feel
---@diagnostic disable: duplicate-doc-alias, duplicate-doc-field

---@class FeelModule
---@field flux table
---@field fields string[]
local feel = {}

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
---@field children FeelRunner[]
---@field tweens table[]
---@field cancelled? boolean

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

---@class FeelWaitStep
---@field kind "wait"|"pause"
---@field duration? number
---@field time? number

---@class FeelEmitStep
---@field kind "emit"
---@field event? string
---@field name? string
---@field payload? any

---@class FeelAudioStep
---@field kind "audio"
---@field cue string
---@field audioKind? string

---@class FeelCallbackStep
---@field kind "callback"
---@field callback? fun(ctx: FeelContext)
---@field fn? fun(ctx: FeelContext)

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

---@class FeelParallelStep
---@field kind "parallel"
---@field steps? FeelSequenceInput[]
---@field sequences? FeelSequenceInput[]
---@field target? FeelTarget
---@field trigger? string
---@field opts? FeelPlayOptions

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

---@class FeelRandomOption
---@field weight? number
---@field chance? number
---@field step? FeelSequenceInput
---@field sequence? FeelSequenceInput
---@field steps? FeelSequenceInput

---@class FeelRandomStep
---@field kind "random"
---@field options? FeelRandomOption[]
---@field target? FeelTarget
---@field trigger? string
---@field opts? FeelPlayOptions

---@class FeelLogStep
---@field kind "log"
---@field message? string
---@field text? string

---@alias FeelStepKind '"animate"'|'"wait"'|'"pause"'|'"emit"'|'"audio"'|'"callback"'|'"play"'|'"parallel"'|'"repeat"'|'"random"'|'"log"'
---@alias FeelStep FeelAnimateStep|FeelWaitStep|FeelEmitStep|FeelAudioStep|FeelCallbackStep|FeelPlayStep|FeelParallelStep|FeelRepeatStep|FeelRandomStep|FeelLogStep|table
---@alias FeelStepInput FeelStep|fun(ctx: FeelContext)|string|number|boolean|nil
---@alias FeelSequenceInput string|FeelStepInput|FeelStepInput[]|nil|false

---@param meta? FeelTargetMeta
---@return FeelTarget
function feel.target(meta) end

---@param name string
---@param sequence FeelSequenceInput
---@return FeelStep[]?
function feel.define(name, sequence) end

---@param name string
---@return FeelStep[]?
function feel.get(name) end

---@overload fun(name: string, target?: FeelTarget, opts?: FeelPlayOptions): FeelContext?
---@overload fun(sequence: FeelSequenceInput, target?: FeelTarget, opts?: FeelPlayOptions): FeelContext?
---@param nameOrSequence FeelSequenceInput
---@param target? FeelTarget
---@param opts? FeelPlayOptions
---@return FeelContext?
function feel.play(nameOrSequence, target, opts) end

---@param dt? number
---@return boolean
function feel.update(dt) end

---@param target? FeelTarget
function feel.clear(target) end

---@param step FeelStepInput
---@return FeelStep?
function feel.normalizeStep(step) end

---@param value FeelSequenceInput
---@return FeelStep[]?
function feel.normalizeSequence(value) end

return feel
