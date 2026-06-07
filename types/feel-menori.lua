---@meta feel.menori
---@diagnostic disable: duplicate-doc-field

---@class FeelMenoriModule
local feelMenori = {}

---@class FeelMenoriModuleLike
---@field ml? FeelMenoriMlLike

---@class FeelMenoriMlLike
---@field vec2? fun(x?: number, y?: number): FeelMenoriVec2Like
---@field vec3? fun(x?: number, y?: number, z?: number): FeelMenoriVec3Like
---@field vec4? fun(x?: number, y?: number, z?: number, w?: number): FeelMenoriVec4Like
---@field quat? FeelMenoriQuatFactoryLike

---@class FeelMenoriQuatFactoryLike
---@field from_euler_angles? fun(yaw: number, pitch: number, roll: number): FeelMenoriQuatLike
---@field from_direction? fun(forward: FeelMenoriVec3Like, up?: FeelMenoriVec3Like): FeelMenoriQuatLike

---@class FeelMenoriAdapter
---@field menori FeelMenoriModuleLike
---@field defaultCamera? FeelMenoriCameraLike
---@field defaultEnvironment? FeelMenoriEnvironmentLike
---@field nodeEntries table<string, FeelMenoriNodeEntry>
---@field nodeOrder string[]
---@field animationEntries table<string, FeelMenoriAnimationEntry>
---@field animationOrder string[]
---@field uniformEntries table<string, FeelMenoriUniformEntry>
---@field uniformOrder string[]
---@field cameraEntry? FeelMenoriCameraEntry

---@class FeelMenoriNewOptions
---@field camera? FeelMenoriCameraLike
---@field environment? FeelMenoriEnvironmentLike

---@class FeelMenoriVec2Like
---@field x number
---@field y number
---@field set? fun(self: FeelMenoriVec2Like, x?: number, y?: number): FeelMenoriVec2Like

---@class FeelMenoriVec3Like
---@field x number
---@field y number
---@field z number
---@field set? fun(self: FeelMenoriVec3Like, x?: number|table, y?: number, z?: number): FeelMenoriVec3Like

---@class FeelMenoriVec4Like
---@field x number
---@field y number
---@field z number
---@field w number
---@field set? fun(self: FeelMenoriVec4Like, x?: number|table, y?: number, z?: number, w?: number): FeelMenoriVec4Like

---@class FeelMenoriQuatLike
---@field x? number
---@field y? number
---@field z? number
---@field w? number

---@class FeelMenoriMat4Like
---@field perspective_RH_NO? fun(self: FeelMenoriMat4Like, fov: number, aspect: number, near: number, far: number): FeelMenoriMat4Like
---@field clone? fun(self: FeelMenoriMat4Like): FeelMenoriMat4Like
---@field inverse? fun(self: FeelMenoriMat4Like): FeelMenoriMat4Like

---@class FeelMenoriNodeLike
---@field position? FeelMenoriVec3Like
---@field render_flag? boolean
---@field update_flag? boolean
---@field set_position? fun(self: FeelMenoriNodeLike, x: number, y: number, z: number)
---@field set_rotation? fun(self: FeelMenoriNodeLike, q: FeelMenoriQuatLike)
---@field set_scale? fun(self: FeelMenoriNodeLike, sx: number, sy?: number, sz?: number)

---@class FeelMenoriCameraLike
---@field eye? FeelMenoriVec3Like
---@field center? FeelMenoriVec3Like
---@field up? FeelMenoriVec3Like
---@field m_projection? FeelMenoriMat4Like
---@field m_inv_projection? FeelMenoriMat4Like
---@field fov? number
---@field aspect? number
---@field near? number
---@field far? number
---@field update_view_matrix? fun(self: FeelMenoriCameraLike)

---@class FeelMenoriEnvironmentLike
---@field camera? FeelMenoriCameraLike
---@field set_vector? fun(self: FeelMenoriEnvironmentLike, name: string, value: FeelMenoriVec2Like|FeelMenoriVec3Like|FeelMenoriVec4Like)

---@class FeelMenoriAnimationsLike
---@field accumulator? number
---@field set_action? fun(self: FeelMenoriAnimationsLike, index: number)
---@field set_action_by_name? fun(self: FeelMenoriAnimationsLike, name: string)
---@field update? fun(self: FeelMenoriAnimationsLike, dt: number)

---@class FeelMenoriUniformListLike
---@field set? fun(self: FeelMenoriUniformListLike, name: string, ...)
---@field set_color? fun(self: FeelMenoriUniformListLike, name: string, ...)
---@field set_vector? fun(self: FeelMenoriUniformListLike, name: string, value: FeelMenoriVec2Like|FeelMenoriVec3Like|FeelMenoriVec4Like)
---@field set_matrix? fun(self: FeelMenoriUniformListLike, name: string, value: FeelMenoriMat4Like)

---@class FeelMenoriNodeOptions
---@field values? FeelMenoriNodeValues
---@field [string] any

---@class FeelMenoriNodeValues
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

---@class FeelMenoriCameraOptions
---@field mode? "lookAt"|"orbit"|"direction"
---@field camera? FeelMenoriCameraLike
---@field environment? FeelMenoriEnvironmentLike
---@field fov? number
---@field baseFov? number
---@field aspect? number
---@field near? number
---@field far? number
---@field nclip? number
---@field fclip? number
---@field forceProjection? boolean
---@field viewPositionUniform? string|false
---@field values? FeelMenoriCameraValues
---@field [string] any

---@class FeelMenoriCameraValues
---@field x? number
---@field y? number
---@field z? number
---@field tx? number
---@field ty? number
---@field tz? number
---@field upX? number
---@field upY? number
---@field upZ? number
---@field yaw? number
---@field pitch? number
---@field roll? number
---@field direction? number
---@field distance? number
---@field fov? number
---@field aspect? number
---@field near? number
---@field far? number
---@field shakeX? number
---@field shakeY? number
---@field shakeZ? number
---@field heightKick? number
---@field yawKick? number
---@field targetOffsetX? number
---@field targetOffsetY? number
---@field targetOffsetZ? number
---@field fovKick? number
---@field distanceKick? number
---@field [string] number

---@class FeelMenoriAnimationOptions
---@field action? string
---@field actionIndex? number
---@field driveTime? boolean
---@field resetAction? boolean
---@field values? FeelMenoriAnimationValues
---@field [string] any

---@class FeelMenoriAnimationValues
---@field speed? number
---@field playing? number
---@field time? number
---@field actionIndex? number
---@field [string] number

---@class FeelMenoriUniformOptions
---@field type? "color"|"vector"|"matrix"
---@field method? "set"|"set_color"|"set_vector"|"set_matrix"
---@field keys? string[]
---@field matrix? FeelMenoriMat4Like
---@field values? FeelMenoriUniformValues
---@field [string] any

---@class FeelMenoriUniformValues
---@field value? number
---@field x? number
---@field y? number
---@field z? number
---@field w? number
---@field r? number
---@field g? number
---@field b? number
---@field a? number
---@field [string] number

---@class FeelMenoriNodeEntry
---@field name string
---@field node FeelMenoriNodeLike
---@field target FeelTarget

---@class FeelMenoriCameraEntry
---@field mode "lookAt"|"orbit"|"direction"
---@field camera FeelMenoriCameraLike
---@field environment? FeelMenoriEnvironmentLike
---@field target FeelTarget
---@field baseFov number
---@field aspect number
---@field near number
---@field far number
---@field viewPositionUniform? string|false

---@class FeelMenoriAnimationEntry
---@field name string
---@field animations FeelMenoriAnimationsLike
---@field target FeelTarget
---@field driveTime boolean

---@class FeelMenoriUniformEntry
---@field name string
---@field object FeelMenoriUniformListLike
---@field uniform string
---@field method string
---@field keys string[]
---@field target FeelTarget
---@field resetValues table<string, number>

---@alias FeelMenoriEventName
---| '"menori.node.lookAt"'
---| '"menori.node.visible"'
---| '"menori.node.scalePunch"'
---| '"menori.node.squash"'
---| '"menori.node.positionShake"'
---| '"menori.node.rotationShake"'
---| '"menori.node.reset"'
---| '"menori.camera.lookAt"'
---| '"menori.camera.orbit"'
---| '"menori.camera.projection"'
---| '"menori.camera.shake"'
---| '"menori.camera.fov"'
---| '"menori.camera.height"'
---| '"menori.camera.yaw"'
---| '"menori.camera.distance"'
---| '"menori.camera.targetOffset"'
---| '"menori.camera.reset"'
---| '"menori.animation.action"'
---| '"menori.animation.play"'
---| '"menori.animation.pause"'
---| '"menori.animation.stop"'
---| '"menori.animation.seek"'
---| '"menori.animation.speed"'
---| '"menori.uniform.set"'
---| '"menori.uniform.pulse"'
---| '"menori.uniform.reset"'

---@class FeelMenoriNamedPayload
---@field name? string
---@field duration? number
---@field returnDuration? number
---@field ease? string
---@field returnEase? string
---@field restart? boolean
---@field key? string
---@field [string] any

---@alias FeelMenoriPayload FeelMenoriNamedPayload|table

---@class FeelMenoriEvent
---@field kind? FeelMenoriEventName|string
---@field event? FeelMenoriEventName|string
---@field name? FeelMenoriEventName|string
---@field payload? FeelMenoriPayload

---@class FeelMenoriHandlers
---@field emit? fun(event: FeelMenoriEvent, ctx?: any)
---@field audio? fun(event: any, ctx?: any)
---@field log? fun(message: string, ctx?: any)
---@field markDirty? fun(ctx?: any)

---@param menori FeelMenoriModuleLike
---@param opts? FeelMenoriNewOptions
---@return FeelMenoriAdapter
function feelMenori.new(menori, opts) end

---@param name string
---@param node FeelMenoriNodeLike
---@param opts? FeelMenoriNodeOptions
---@return FeelTarget
function FeelMenoriAdapter.node(name, node, opts) end

---@param name string
---@param node FeelMenoriNodeLike
---@param opts? FeelMenoriNodeOptions
---@return FeelTarget
function FeelMenoriAdapter.model(name, node, opts) end

---@overload fun(self: FeelMenoriAdapter, opts?: FeelMenoriCameraOptions): FeelTarget
---@overload fun(self: FeelMenoriAdapter, camera: FeelMenoriCameraLike, opts?: FeelMenoriCameraOptions): FeelTarget
---@overload fun(self: FeelMenoriAdapter, environment: FeelMenoriEnvironmentLike, opts?: FeelMenoriCameraOptions): FeelTarget
---@param cameraOrEnvironment? FeelMenoriCameraLike|FeelMenoriEnvironmentLike|FeelMenoriCameraOptions
---@param opts? FeelMenoriCameraOptions
---@return FeelTarget
function FeelMenoriAdapter.camera(cameraOrEnvironment, opts) end

---@param name string
---@param animations FeelMenoriAnimationsLike
---@param opts? FeelMenoriAnimationOptions
---@return FeelTarget
function FeelMenoriAdapter.animation(name, animations, opts) end

---@param name string
---@param object FeelMenoriUniformListLike
---@param uniform string
---@param opts? FeelMenoriUniformOptions
---@return FeelTarget
function FeelMenoriAdapter.uniform(name, object, uniform, opts) end

---@param name string
---@return FeelMenoriNodeEntry|FeelMenoriAnimationEntry|FeelMenoriUniformEntry?
function FeelMenoriAdapter.get(name) end

---@param name? string
---@return boolean
function FeelMenoriAdapter.clear(name) end

---@param dt? number
---@return FeelMenoriAdapter
function FeelMenoriAdapter.update(dt) end

---@param event? FeelMenoriEvent
---@param ctx? any
---@return boolean
---@return any ctx
function FeelMenoriAdapter.emit(event, ctx) end

---@param extra? FeelMenoriHandlers
---@return FeelMenoriHandlers
function FeelMenoriAdapter.handlers(extra) end

return feelMenori
