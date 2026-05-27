---@meta feel
---@diagnostic disable: duplicate-doc-alias, duplicate-doc-field

---@class FeelModule
---@field flux table
---@field fields string[]
---@field active fun(): FeelActiveRun[]
---@field isPlaying fun(target?: FeelTarget, key?: string|number|table): boolean
---@field validate fun(sequence: FeelSequenceInput): boolean, string?
---@field channel fun(): FeelChannel
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
---@field elapsed number
---@field cancelled? boolean

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

---@class FeelFeedbackEvent
---@field target? FeelTarget
---@field opts? FeelPlayOptions
---@field payload? any
---@field [string] any

---@alias FeelFeedbackHandler fun(event: FeelFeedbackEvent)

---@class FeelChannel

---@alias FeelStepKind
---| '"animate"'
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
---@alias FeelStep FeelAnimateStep|FeelWaitStep|FeelSideEffectStep|FeelControlStep|table
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

---@param sequence FeelSequenceInput
---@return boolean ok
---@return string? err
function feel.validate(sequence) end

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

---@return FeelActiveRun[]
function feel.active() end

---@param target? FeelTarget
---@param key? string|number|table
---@return boolean
function feel.isPlaying(target, key) end

---@param target? FeelTarget
function feel.clear(target) end

---@return FeelChannel
function feel.channel() end

---@param intent string
---@param handler FeelFeedbackHandler
---@return fun()
function FeelChannel:on(intent, handler) end

---@param intent string
---@param handler FeelFeedbackHandler
---@return boolean
function FeelChannel:off(intent, handler) end

---@param intent string
---@param event? FeelFeedbackEvent
---@return integer
function FeelChannel:emit(intent, event) end

---@param intent string
---@param sequence FeelSequenceInput
---@param defaults? FeelFeedbackEvent
---@return fun()
function FeelChannel:map(intent, sequence, defaults) end

---@param intent? string
function FeelChannel:clear(intent) end

---@param step FeelStepInput
---@return FeelStep?
function feel.normalizeStep(step) end

---@param value FeelSequenceInput
---@return FeelStep[]?
function feel.normalizeSequence(value) end

return feel
