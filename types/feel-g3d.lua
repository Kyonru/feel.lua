---@meta feel.g3d
---@diagnostic disable: duplicate-doc-field

---@class FeelG3dModule
local feelG3d = {}

---@class FeelG3dModuleLike
---@field camera? FeelG3dCameraLike

---@class FeelG3dAdapter
---@field g3d FeelG3dModuleLike
---@field modelEntries table<string, FeelG3dModelEntry>
---@field modelOrder string[]
---@field cameraEntry? FeelG3dCameraEntry

---@class FeelG3dModelLike
---@field setTranslation? fun(self: FeelG3dModelLike, x: number, y: number, z: number)
---@field setRotation? fun(self: FeelG3dModelLike, x: number, y: number, z: number)
---@field setScale? fun(self: FeelG3dModelLike, x: number, y?: number, z?: number)
---@field lookAt? fun(self: FeelG3dModelLike, target: number[], up?: number[])

---@class FeelG3dCameraLike
---@field fov? number
---@field lookAt? fun(x: number, y: number, z: number, tx: number, ty: number, tz: number)
---@field lookInDirection? fun(x?: number, y?: number, z?: number, direction?: number, pitch?: number)
---@field resize? fun(width?: number, height?: number)
---@field updateProjectionMatrix? fun()

---@class FeelG3dModelOptions
---@field values? FeelG3dModelValues
---@field [string] any

---@class FeelG3dModelValues
---@field x? number
---@field y? number
---@field z? number
---@field rx? number
---@field ry? number
---@field rz? number
---@field sx? number
---@field sy? number
---@field sz? number
---@field scale? number
---@field offsetX? number
---@field offsetY? number
---@field offsetZ? number
---@field shakeX? number
---@field shakeY? number
---@field shakeZ? number
---@field rotationOffsetX? number
---@field rotationOffsetY? number
---@field rotationOffsetZ? number
---@field fxScale? number
---@field fxScaleX? number
---@field fxScaleY? number
---@field fxScaleZ? number
---@field [string] number

---@class FeelG3dCameraOptions
---@field mode? "lookAt"|"direction"
---@field values? FeelG3dCameraValues
---@field [string] any

---@class FeelG3dCameraValues
---@field x? number
---@field y? number
---@field z? number
---@field tx? number
---@field ty? number
---@field tz? number
---@field direction? number
---@field pitch? number
---@field shakeX? number
---@field shakeY? number
---@field shakeZ? number
---@field heightKick? number
---@field yawKick? number
---@field targetOffsetX? number
---@field targetOffsetY? number
---@field targetOffsetZ? number
---@field fovKick? number
---@field [string] number

---@class FeelG3dModelEntry
---@field name string
---@field model FeelG3dModelLike
---@field target FeelTarget

---@class FeelG3dCameraEntry
---@field mode "lookAt"|"direction"
---@field target FeelTarget
---@field baseFov? number

---@alias FeelG3dEventName
---| '"g3d.model.lookAt"'
---| '"g3d.camera.lookAt"'
---| '"g3d.camera.direction"'
---| '"g3d.camera.resize"'
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

---@class FeelG3dModelLookAtPayload
---@field name? string
---@field x? number
---@field y? number
---@field z? number
---@field up? number[]

---@class FeelG3dCameraLookAtPayload
---@field x? number
---@field y? number
---@field z? number
---@field tx? number
---@field ty? number
---@field tz? number

---@class FeelG3dCameraDirectionPayload
---@field x? number
---@field y? number
---@field z? number
---@field direction? number
---@field pitch? number

---@class FeelG3dCameraResizePayload
---@field width? number
---@field height? number

---@class FeelG3dCameraShakePayload
---@field amount? number
---@field xAmount? number
---@field yAmount? number
---@field zAmount? number
---@field duration? number
---@field frequency? number
---@field returnDuration? number
---@field ease? string
---@field returnEase? string
---@field restart? boolean
---@field key? string

---@class FeelG3dCameraPulsePayload
---@field amount? number
---@field value? number
---@field height? number
---@field duration? number
---@field returnDuration? number
---@field ease? string
---@field returnEase? string
---@field radians? boolean
---@field restart? boolean
---@field key? string

---@class FeelG3dCameraTargetOffsetPayload
---@field x? number
---@field y? number
---@field z? number
---@field offsetX? number
---@field offsetY? number
---@field offsetZ? number
---@field duration? number
---@field returnDuration? number
---@field ease? string
---@field returnEase? string
---@field restart? boolean
---@field key? string

---@class FeelG3dModelPulsePayload
---@field name? string
---@field amount? number
---@field scale? number
---@field sx? number
---@field sy? number
---@field sz? number
---@field xScale? number
---@field yScale? number
---@field zScale? number
---@field duration? number
---@field returnDuration? number
---@field ease? string
---@field returnEase? string
---@field restart? boolean
---@field key? string

---@class FeelG3dModelShakePayload
---@field name? string
---@field amount? number
---@field xAmount? number
---@field yAmount? number
---@field zAmount? number
---@field duration? number
---@field frequency? number
---@field returnDuration? number
---@field ease? string
---@field returnEase? string
---@field restart? boolean
---@field key? string

---@alias FeelG3dPayload FeelG3dModelLookAtPayload|FeelG3dCameraLookAtPayload
---| FeelG3dCameraDirectionPayload|FeelG3dCameraResizePayload
---| FeelG3dCameraShakePayload|FeelG3dCameraPulsePayload|FeelG3dCameraTargetOffsetPayload
---| FeelG3dModelPulsePayload|FeelG3dModelShakePayload|table

---@class FeelG3dEvent
---@field kind? FeelG3dEventName|string
---@field event? FeelG3dEventName|string
---@field name? FeelG3dEventName|string
---@field payload? FeelG3dPayload

---@class FeelG3dHandlers
---@field emit? fun(event: FeelG3dEvent, ctx?: any)
---@field audio? fun(event: any, ctx?: any)
---@field log? fun(message: string, ctx?: any)
---@field markDirty? fun(ctx?: any)

---@param g3d FeelG3dModuleLike
---@return FeelG3dAdapter
function feelG3d.new(g3d) end

---@param name string
---@param model FeelG3dModelLike
---@param opts? FeelG3dModelOptions
---@return FeelTarget
function FeelG3dAdapter:model(name, model, opts) end

---@param opts? FeelG3dCameraOptions
---@return FeelTarget
function FeelG3dAdapter:camera(opts) end

---@return FeelG3dAdapter
function FeelG3dAdapter:update() end

---@param name string
---@return FeelG3dModelEntry?
function FeelG3dAdapter:get(name) end

---@param name? string
---@return boolean
function FeelG3dAdapter:clear(name) end

---@param event? FeelG3dEvent
---@param ctx? any
---@return boolean
---@return any ctx
function FeelG3dAdapter:emit(event, ctx) end

---@param extra? FeelG3dHandlers
---@return FeelG3dHandlers
function FeelG3dAdapter:handlers(extra) end

return feelG3d
