---@meta feel.feedbacks
---@diagnostic disable: duplicate-doc-field

---@class FeelFeedbacksModule
local feelFeedbacks = {}

---@class FeelFeedbacksOptions
---@field love? FeelLoveAdapter
---@field g3d? FeelG3dAdapter
---@field menori? FeelMenoriAdapter
---@field emit? fun(event: FeelEvent, ctx: FeelContext)
---@field audio? fun(event: FeelAudioEvent, ctx: FeelContext)
---@field log? fun(message: string, ctx: FeelContext)
---@field markDirty? fun(ctx: FeelContext)

---@class FeelFeedbacks

---@class FeelFeedbackPlayOptions: FeelPlayOptions
---@field target? FeelTarget

---@alias FeelFeedbackContext table<string, any>

---@alias FeelFeedbackManifest FeelFeedbackStep[]

---@alias FeelFeedbackStep FeelStep|FeelFeedbackShorthandStep|FeelFeedbackTimeStep

---@class FeelFeedbackShorthandStep
---@field kind string
---@field payload? table
---@field [string] any

---@class FeelFeedbackTimeStep
---@field kind "time.freeze"|"time.slow"|"time.restore"
---@field scale? number
---@field duration? number
---@field returnDuration? number
---@field inDuration? number
---@field attack? number
---@field ease? string
---@field returnEase? string

---@alias FeelFeedbackEventName
---| '"screen.flash"'
---| '"screen.fade"'
---| '"screen.clear"'
---| '"sound.play"'
---| '"sound.stop"'
---| '"particle.emit"'
---| '"post.set"'
---| '"post.tween"'
---| '"post.clear"'
---| '"g3d.camera.shake"'
---| '"g3d.camera.fov"'
---| '"g3d.camera.height"'
---| '"g3d.camera.yaw"'
---| '"g3d.camera.targetOffset"'
---| '"g3d.camera.reset"'
---| '"g3d.model.scalePunch"'
---| '"g3d.model.squash"'
---| '"g3d.model.positionShake"'
---| '"g3d.model.rotationShake"'
---| '"g3d.model.reset"'
---| '"menori.camera.shake"'
---| '"menori.camera.fov"'
---| '"menori.camera.height"'
---| '"menori.camera.yaw"'
---| '"menori.camera.distance"'
---| '"menori.camera.targetOffset"'
---| '"menori.camera.reset"'
---| '"menori.node.scalePunch"'
---| '"menori.node.squash"'
---| '"menori.node.positionShake"'
---| '"menori.node.rotationShake"'
---| '"menori.node.reset"'
---| '"menori.animation.action"'
---| '"menori.animation.play"'
---| '"menori.animation.pause"'
---| '"menori.animation.stop"'
---| '"menori.animation.seek"'
---| '"menori.animation.speed"'
---| '"menori.uniform.set"'
---| '"menori.uniform.pulse"'
---| '"menori.uniform.reset"'

---@param opts? FeelFeedbacksOptions
---@return FeelFeedbacks
function feelFeedbacks.new(opts) end

---@param name string
---@param steps FeelFeedbackManifest
---@return FeelFeedbackManifest
function FeelFeedbacks.define(name, steps) end

---@param name string
---@return FeelFeedbackManifest?
function FeelFeedbacks.get(name) end

---@overload fun(name: string, context?: FeelFeedbackContext, opts?: FeelFeedbackPlayOptions): FeelContext?
---@overload fun(steps: FeelFeedbackManifest, context?: FeelFeedbackContext, opts?: FeelFeedbackPlayOptions): FeelContext?
---@param nameOrSteps string|FeelFeedbackManifest
---@param context? FeelFeedbackContext
---@param opts? FeelFeedbackPlayOptions
---@return FeelContext?
function FeelFeedbacks.play(nameOrSteps, context, opts) end

---@param name? string
function FeelFeedbacks.clear(name) end

---@return number
function FeelFeedbacks.timeScale() end

---@return FeelTarget
function FeelFeedbacks.timeTarget() end

return feelFeedbacks
