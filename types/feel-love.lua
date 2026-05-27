---@meta feel.love
---@diagnostic disable: duplicate-doc-alias, duplicate-doc-field

---@class FeelLoveModule
local feelLove = {}

---@class FeelLoveAdapter
---@field opts FeelLoveOptions
---@field defaults FeelLoveDefaults
---@field cameraTarget table
---@field camera table<string, number>
---@field shake table<string, number>
---@field flash table
---@field fade table
---@field soundEntries table<string, FeelLoveSoundEntry>
---@field hapticEntries table<string, FeelLoveHapticEntry>
---@field particleEntries table<string, FeelLoveParticleEntry>
---@field particleOrder string[]
---@field shaderEntries table<string, FeelLoveShaderEntry>
---@field shaderStack table[]
---@field activeShader? any
---@field post FeelLovePostState

---@class FeelLoveOptions
---@field width? number
---@field height? number
---@field x? number
---@field y? number
---@field scale? number
---@field rotation? number
---@field duration? number
---@field shakeAmount? number
---@field shakeDuration? number
---@field shakeFrequency? number
---@field flashAmount? number
---@field flashDuration? number
---@field fadeAmount? number
---@field fadeDuration? number
---@field hapticDuration? number

---@class FeelLoveDefaults
---@field x number
---@field y number
---@field scale number
---@field rotation number
---@field shakeAmount number
---@field shakeDuration number
---@field shakeFrequency number
---@field flashAmount number
---@field flashDuration number
---@field fadeAmount number
---@field fadeDuration number
---@field tweenDuration number
---@field hapticDuration number

---@class FeelLoveSourceLike
---@field play? fun(self: FeelLoveSourceLike)
---@field stop? fun(self: FeelLoveSourceLike)
---@field pause? fun(self: FeelLoveSourceLike)
---@field setVolume? fun(self: FeelLoveSourceLike, value: number)
---@field setPitch? fun(self: FeelLoveSourceLike, value: number)
---@field setPosition? fun(self: FeelLoveSourceLike, x: number, y: number, z: number)

---@class FeelLoveSoundOptions
---@field restart? boolean
---@field volume? number
---@field pitch? number
---@field pan? number

---@class FeelLoveSoundEntry
---@field name string
---@field sources FeelLoveSourceLike[]
---@field restart boolean
---@field target table

---@class FeelLoveJoystickLike
---@field isVibrationSupported? fun(self: FeelLoveJoystickLike): boolean
---@field setVibration? fun(self: FeelLoveJoystickLike, left?: number, right?: number, duration?: number)

---@class FeelLoveHapticOptions
---@field duration? number

---@class FeelLoveHapticEntry
---@field name string
---@field joysticks FeelLoveJoystickLike[]
---@field duration? number

---@class FeelLoveParticleSystemLike
---@field emit? fun(self: FeelLoveParticleSystemLike, count: number)
---@field start? fun(self: FeelLoveParticleSystemLike)
---@field stop? fun(self: FeelLoveParticleSystemLike)
---@field reset? fun(self: FeelLoveParticleSystemLike)
---@field update? fun(self: FeelLoveParticleSystemLike, dt: number)
---@field setPosition? fun(self: FeelLoveParticleSystemLike, x: number, y: number)

---@class FeelLoveParticleOptions
---@field x? number
---@field y? number

---@class FeelLoveParticleEntry
---@field name string
---@field system FeelLoveParticleSystemLike

---@class FeelLoveParticleBulkEntry
---@field name? string
---@field system? FeelLoveParticleSystemLike
---@field opts? FeelLoveParticleOptions
---@field options? FeelLoveParticleOptions
---@field [integer] any

---@class FeelLoveShaderLike
---@field send? fun(self: FeelLoveShaderLike, uniform: string, value: any)

---@class FeelLoveShaderOptions
---@field uniforms? table<string, any>
---@field values? table<string, any>

---@class FeelLoveShaderEntry
---@field name string
---@field shader FeelLoveShaderLike
---@field target table
---@field values table<string, any>

---@alias FeelLovePostEffectName '"bloom"'|'"chromatic"'|'"grade"'|'"lens"'|'"vignette"'|'"volume"'
---@alias FeelLoveSoundEventName '"sound.play"'|'"sound.stop"'|'"sound.pause"'|'"sound.resume"'|'"sound.volume"'|'"sound.pitch"'|'"sound.pan"'
---@alias FeelLoveHapticEventName '"haptic.play"'|'"haptic.stop"'|'"haptic.vibrate"'
---@alias FeelLoveParticleEventName '"particle.emit"'|'"particle.start"'|'"particle.stop"'|'"particle.reset"'|'"particle.move"'
---@alias FeelLoveShaderEventName '"shader.send"'|'"shader.tween"'|'"shader.apply"'|'"shader.clear"'
---@alias FeelLovePostEventName '"post.set"'|'"post.tween"'|'"post.enable"'|'"post.disable"'|'"post.weight"'|'"post.clear"'
---@alias FeelLoveCameraEventName '"camera.shake"'|'"camera.zoom"'|'"camera.move"'|'"camera.reset"'
---@alias FeelLoveScreenEventName '"screen.flash"'|'"screen.fade"'|'"screen.clear"'
---@alias FeelLoveEventName FeelLoveSoundEventName|FeelLoveHapticEventName|FeelLoveParticleEventName|FeelLoveShaderEventName|FeelLovePostEventName|FeelLoveCameraEventName|FeelLoveScreenEventName|string

---@class FeelLoveBloomValues
---@field intensity? number
---@field threshold? number
---@field softness? number
---@field passes? number

---@class FeelLoveChromaticValues
---@field force? number
---@field x? number
---@field y? number

---@class FeelLoveGradeValues
---@field exposure? number
---@field saturation? number
---@field hueShift? number
---@field contrast? number

---@class FeelLoveLensValues
---@field distortion? number

---@class FeelLoveVignetteValues
---@field intensity? number
---@field radius? number
---@field softness? number

---@class FeelLoveVolumeValues
---@field weight? number

---@alias FeelLovePostValues FeelLoveBloomValues|FeelLoveChromaticValues|FeelLoveGradeValues|FeelLoveLensValues|FeelLoveVignetteValues|FeelLoveVolumeValues|table<string, number>

---@class FeelLoveTimedPayload
---@field duration? number
---@field ease? string
---@field restart? boolean

---@class FeelLoveSoundPayload: FeelLoveTimedPayload
---@field cue? string
---@field volume? number
---@field pitch? number
---@field pan? number

---@class FeelLoveHapticPayload
---@field name? string
---@field value? number
---@field left? number
---@field right? number
---@field duration? number
---@field system? boolean

---@class FeelLoveParticlePayload
---@field name? string
---@field count? integer
---@field x? number
---@field y? number

---@class FeelLoveShaderPayload: FeelLoveTimedPayload
---@field name? string
---@field uniform? string
---@field value? any

---@class FeelLovePostPayload: FeelLoveTimedPayload
---@field effect? FeelLovePostEffectName
---@field values? FeelLovePostValues
---@field value? number

---@class FeelLoveCameraPayload: FeelLoveTimedPayload
---@field amount? number
---@field frequency? number
---@field scale? number
---@field x? number
---@field y? number

---@class FeelLoveScreenPayload
---@field color? number[]
---@field amount? number
---@field alpha? number
---@field duration? number

---@alias FeelLovePayload FeelLoveSoundPayload|FeelLoveHapticPayload|FeelLoveParticlePayload|FeelLoveShaderPayload|FeelLovePostPayload|FeelLoveCameraPayload|FeelLoveScreenPayload|table

---@class FeelLoveEvent
---@field kind? FeelLoveEventName
---@field event? FeelLoveEventName
---@field name? FeelLoveEventName|string
---@field cue? string
---@field payload? FeelLovePayload

---@class FeelLoveHandlers
---@field emit? fun(event: FeelLoveEvent, ctx?: any)
---@field audio? fun(event: FeelLoveEvent, ctx?: any)

---@class FeelLovePostEffect
---@field name FeelLovePostEffectName
---@field defaults table<string, number>
---@field enabled boolean
---@field target table

---@class FeelLovePostState
---@field effects table<FeelLovePostEffectName, FeelLovePostEffect>
---@field canvases table<string, any>
---@field shaders table<string, FeelLoveShaderLike>
---@field width? number
---@field height? number

---@class FeelLovePostTweenOptions
---@field duration? number
---@field ease? string
---@field restart? boolean

---@alias FeelLoveDrawCallback fun()

---@param opts? FeelLoveOptions
---@return FeelLoveAdapter
function feelLove.new(opts) end

---@param name string
---@param sourceOrSources? FeelLoveSourceLike|FeelLoveSourceLike[]
---@param opts? FeelLoveSoundOptions
---@return FeelLoveAdapter
function FeelLoveAdapter:sound(name, sourceOrSources, opts) end

---@param map? table<string, FeelLoveSourceLike|FeelLoveSourceLike[]>
---@return FeelLoveAdapter
function FeelLoveAdapter:sounds(map) end

---@param name string
---@return boolean
function FeelLoveAdapter:stopSound(name) end

---@return boolean
function FeelLoveAdapter:stopSounds() end

---@param name string
---@param joystickOrJoysticks? FeelLoveJoystickLike|FeelLoveJoystickLike[]
---@param opts? FeelLoveHapticOptions
---@return FeelLoveAdapter
function FeelLoveAdapter:haptic(name, joystickOrJoysticks, opts) end

---@param map? table<string, FeelLoveJoystickLike|FeelLoveJoystickLike[]>
---@return FeelLoveAdapter
function FeelLoveAdapter:haptics(map) end

---@param name string
---@return boolean
function FeelLoveAdapter:stopHaptic(name) end

---@return boolean
function FeelLoveAdapter:stopHaptics() end

---@param duration? number
---@return boolean
function FeelLoveAdapter:vibrate(duration) end

---@param name string
---@param system? FeelLoveParticleSystemLike
---@param opts? FeelLoveParticleOptions
---@return FeelLoveAdapter
function FeelLoveAdapter:particle(name, system, opts) end

---@param map? table<string, FeelLoveParticleSystemLike>|FeelLoveParticleBulkEntry[]
---@return FeelLoveAdapter
function FeelLoveAdapter:particles(map) end

---@param name string
---@param shader? FeelLoveShaderLike
---@param opts? FeelLoveShaderOptions
---@return FeelLoveAdapter
function FeelLoveAdapter:shader(name, shader, opts) end

---@param map? table<string, FeelLoveShaderLike>
---@return FeelLoveAdapter
function FeelLoveAdapter:shaders(map) end

---@param name string
---@return boolean
function FeelLoveAdapter:pushShader(name) end

---@return boolean
function FeelLoveAdapter:popShader() end

---@param effect FeelLovePostEffectName
---@param values FeelLovePostValues
---@return boolean
function FeelLoveAdapter:setPost(effect, values) end

---@param effect FeelLovePostEffectName
---@param values FeelLovePostValues
---@param opts? FeelLovePostTweenOptions
---@return boolean
function FeelLoveAdapter:tweenPost(effect, values, opts) end

---@param effect FeelLovePostEffectName
---@return boolean
function FeelLoveAdapter:enablePost(effect) end

---@param effect FeelLovePostEffectName
---@return boolean
function FeelLoveAdapter:disablePost(effect) end

---@return boolean
function FeelLoveAdapter:clearPost() end

---@param dt? number
function FeelLoveAdapter:update(dt) end

---@overload fun(self: FeelLoveAdapter, event: { kind: FeelLovePostEventName, payload: FeelLovePostPayload }, ctx?: any): boolean, any
---@overload fun(self: FeelLoveAdapter, event: { kind: FeelLoveSoundEventName, payload: FeelLoveSoundPayload }, ctx?: any): boolean, any
---@overload fun(self: FeelLoveAdapter, event: { kind: FeelLoveHapticEventName, payload: FeelLoveHapticPayload }, ctx?: any): boolean, any
---@overload fun(self: FeelLoveAdapter, event: { kind: FeelLoveParticleEventName, payload: FeelLoveParticlePayload }, ctx?: any): boolean, any
---@overload fun(self: FeelLoveAdapter, event: { kind: FeelLoveShaderEventName, payload: FeelLoveShaderPayload }, ctx?: any): boolean, any
---@overload fun(self: FeelLoveAdapter, event: { kind: FeelLoveCameraEventName, payload: FeelLoveCameraPayload }, ctx?: any): boolean, any
---@overload fun(self: FeelLoveAdapter, event: { kind: FeelLoveScreenEventName, payload: FeelLoveScreenPayload }, ctx?: any): boolean, any
---@param event? FeelLoveEvent
---@param ctx? any
---@return boolean
---@return any ctx
function FeelLoveAdapter:emit(event, ctx) end

---@param event? FeelLoveEvent
---@return boolean
function FeelLoveAdapter:audio(event) end

---@param extra? FeelLoveHandlers
---@return FeelLoveHandlers
function FeelLoveAdapter:handlers(extra) end

function FeelLoveAdapter:push() end
function FeelLoveAdapter:pop() end
function FeelLoveAdapter:drawOverlay() end
function FeelLoveAdapter:drawParticles() end

---@param drawScene FeelLoveDrawCallback
---@return boolean
function FeelLoveAdapter:drawPost(drawScene) end

return feelLove
