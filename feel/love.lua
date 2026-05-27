local moduleName = ...
local prefix = "feel"
if moduleName and moduleName ~= "" then
  prefix = moduleName:gsub("%.love$", "")
end

---@type FeelModule
local feel = require(prefix)

---@module "feel.love"

---@class FeelLoveModule
---@field new fun(opts?: FeelLoveOptions): FeelLoveAdapter
---@type FeelLoveModule
local FeelLove = {}

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
local Adapter = {}
Adapter.__index = Adapter

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
---@alias FeelLoveSoundEventName
---| '"sound.play"'
---| '"sound.stop"'
---| '"sound.pause"'
---| '"sound.resume"'
---| '"sound.volume"'
---| '"sound.pitch"'
---| '"sound.pan"'
---@alias FeelLoveHapticEventName '"haptic.play"'|'"haptic.stop"'|'"haptic.vibrate"'
---@alias FeelLoveParticleEventName
---| '"particle.emit"'
---| '"particle.start"'
---| '"particle.stop"'
---| '"particle.reset"'
---| '"particle.move"'
---@alias FeelLoveShaderEventName '"shader.send"'|'"shader.tween"'|'"shader.apply"'|'"shader.clear"'
---@alias FeelLovePostEventName
---| '"post.set"'
---| '"post.tween"'
---| '"post.enable"'
---| '"post.disable"'
---| '"post.weight"'
---| '"post.clear"'
---@alias FeelLoveCameraEventName '"camera.shake"'|'"camera.zoom"'|'"camera.move"'|'"camera.reset"'
---@alias FeelLoveScreenEventName '"screen.flash"'|'"screen.fade"'|'"screen.clear"'
---@alias FeelLoveCoreEventName FeelLoveSoundEventName|FeelLoveHapticEventName|FeelLoveParticleEventName
---@alias FeelLoveVisualEventName FeelLoveShaderEventName|FeelLovePostEventName
---@alias FeelLoveViewEventName FeelLoveCameraEventName|FeelLoveScreenEventName
---@alias FeelLoveEventName FeelLoveCoreEventName|FeelLoveVisualEventName|FeelLoveViewEventName|string

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

---@alias FeelLovePostVisualValues FeelLoveBloomValues|FeelLoveChromaticValues|FeelLoveGradeValues
---@alias FeelLovePostShapeValues FeelLoveLensValues|FeelLoveVignetteValues|FeelLoveVolumeValues
---@alias FeelLovePostValues FeelLovePostVisualValues|FeelLovePostShapeValues|table<string, number>

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

---@alias FeelLoveCorePayload FeelLoveSoundPayload|FeelLoveHapticPayload|FeelLoveParticlePayload
---@alias FeelLoveVisualPayload FeelLoveShaderPayload|FeelLovePostPayload|FeelLoveCameraPayload|FeelLoveScreenPayload
---@alias FeelLovePayload FeelLoveCorePayload|FeelLoveVisualPayload|table

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

---@class FeelLoveEvent
---@field kind? FeelLoveEventName
---@field event? FeelLoveEventName
---@field name? FeelLoveEventName|string
---@field cue? string
---@field payload? FeelLovePayload

---@class FeelLoveHandlers
---@field emit? fun(event: FeelLoveEvent, ctx?: any)
---@field audio? fun(event: FeelLoveEvent, ctx?: any)

---@alias FeelLoveDrawCallback fun()

local DEFAULT_FLASH = { 1, 1, 1, 1 }
local DEFAULT_FADE = { 0, 0, 0, 1 }
local SOUND_SETTERS = {
  volume = "setVolume",
  pitch = "setPitch",
  pan = "setPosition",
}
local POST_DEFAULTS = {
  bloom = { intensity = 0, threshold = 0.75, softness = 0.15, passes = 1 },
  chromatic = { force = 0, x = 0, y = 0 },
  grade = { exposure = 0, saturation = 1, hueShift = 0, contrast = 1 },
  lens = { distortion = 0 },
  vignette = { intensity = 0, radius = 0.75, softness = 0.35 },
  volume = { weight = 1 },
}
local POST_ORDER = { "grade", "lens", "chromatic", "bloom", "vignette" }
local POST_GENERAL_SHADER = [[
extern number exposure;
extern number saturation;
extern number hueShift;
extern number contrast;
extern number lensDistortion;
extern number chromaticForce;
extern vec2 chromaticOffset;
extern number vignetteIntensity;
extern number vignetteRadius;
extern number vignetteSoftness;

vec3 shiftHue(vec3 color, number shift)
{
  number amount = abs(sin(shift * 3.1415926));
  return mix(color, color.gbr, amount);
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen)
{
  vec2 centered = uv - vec2(0.5);
  number r2 = dot(centered, centered);
  vec2 warped = uv + centered * r2 * lensDistortion;
  vec2 ca = centered * chromaticForce * 0.012 + chromaticOffset;

  vec4 sample = Texel(tex, warped);
  sample.r = Texel(tex, warped + ca).r;
  sample.b = Texel(tex, warped - ca).b;

  vec3 graded = sample.rgb * pow(2.0, exposure);
  number luma = dot(graded, vec3(0.299, 0.587, 0.114));
  graded = mix(vec3(luma), graded, saturation);
  graded = shiftHue(graded, hueShift);
  graded = (graded - vec3(0.5)) * contrast + vec3(0.5);

  number dist = distance(uv, vec2(0.5));
  number vignette = smoothstep(vignetteRadius, vignetteRadius - max(vignetteSoftness, 0.001), dist);
  graded *= mix(1.0, vignette, vignetteIntensity);

  return vec4(graded, sample.a) * color;
}
]]
local POST_EXTRACT_SHADER = [[
extern number threshold;
extern number softness;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen)
{
  vec4 pixel = Texel(tex, uv);
  number bright = max(max(pixel.r, pixel.g), pixel.b);
  number amount = smoothstep(threshold, threshold + max(softness, 0.001), bright);
  return vec4(pixel.rgb * amount, pixel.a) * color;
}
]]
local POST_BLUR_SHADER = [[
extern vec2 direction;
extern vec2 texel;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen)
{
  vec2 stepv = direction * texel;
  vec4 sum = Texel(tex, uv) * 0.227027;
  sum += Texel(tex, uv + stepv * 1.384615) * 0.316216;
  sum += Texel(tex, uv - stepv * 1.384615) * 0.316216;
  sum += Texel(tex, uv + stepv * 3.230769) * 0.070270;
  sum += Texel(tex, uv - stepv * 3.230769) * 0.070270;
  return sum * color;
}
]]
local POST_BLOOM_SHADER = [[
extern Image bloomTex;
extern number intensity;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen)
{
  vec4 base = Texel(tex, uv);
  vec4 bloom = Texel(bloomTex, uv) * intensity;
  return vec4(base.rgb + bloom.rgb, base.a) * color;
}
]]
local POST_WEIGHT_SHADER = [[
extern Image processedTex;
extern number weight;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen)
{
  vec4 original = Texel(tex, uv);
  vec4 processed = Texel(processedTex, uv);
  return mix(original, processed, weight) * color;
}
]]

local function copyColor(color, fallback)
  color = color or fallback
  return {
    color[1] or fallback[1],
    color[2] or fallback[2],
    color[3] or fallback[3],
    color[4] or fallback[4] or 1,
  }
end

local function viewportSize(opts)
  if opts and opts.width and opts.height then
    return opts.width, opts.height
  end
  if love and love.graphics and love.graphics.getDimensions then
    return love.graphics.getDimensions()
  end
  return 0, 0
end

local function drawOverlay(overlay)
  if not love or not love.graphics or not love.graphics.setColor or not love.graphics.rectangle then
    return
  end

  local alpha = overlay.alpha or 0
  if alpha <= 0 then
    return
  end

  local color = overlay.color
  love.graphics.setColor(color[1], color[2], color[3], alpha * (color[4] or 1))
  love.graphics.rectangle("fill", 0, 0, overlay.width, overlay.height)
end

local function isSourceList(value)
  return type(value) == "table" and type(value.play) ~= "function" and #value > 0
end

local function collectSources(sourceOrSources)
  if sourceOrSources == nil then
    return {}
  end
  if isSourceList(sourceOrSources) then
    local sources = {}
    for _, source in ipairs(sourceOrSources) do
      if source then
        sources[#sources + 1] = source
      end
    end
    return sources
  end
  return { sourceOrSources }
end

local function isJoystickList(value)
  return type(value) == "table" and type(value.setVibration) ~= "function" and #value > 0
end

local function collectJoysticks(joystickOrJoysticks)
  if joystickOrJoysticks == nil then
    return {}
  end
  if isJoystickList(joystickOrJoysticks) then
    local joysticks = {}
    for _, joystick in ipairs(joystickOrJoysticks) do
      if joystick then
        joysticks[#joysticks + 1] = joystick
      end
    end
    return joysticks
  end
  return { joystickOrJoysticks }
end

local function callSource(source, method, ...)
  local fn = source and source[method]
  if type(fn) == "function" then
    fn(source, ...)
  end
end

local function restartOptions(restart, key)
  if restart == true then
    return {
      restart = true,
      key = key,
    }
  end
  return nil
end

local function cancelRestartedTween(target, key)
  feel.play({
    kind = "callback",
  }, target, {
    restart = true,
    key = key,
  })
end

local function applySourceValue(source, name, value)
  if value == nil then
    return
  end

  if name == "pan" then
    callSource(source, SOUND_SETTERS.pan, value, 0, 0)
    return
  end

  callSource(source, SOUND_SETTERS[name], value)
end

local function applySoundValues(entry)
  if not entry then
    return
  end

  local values = entry.target.values
  for _, source in ipairs(entry.sources) do
    applySourceValue(source, "volume", values.volume)
    applySourceValue(source, "pitch", values.pitch)
    applySourceValue(source, "pan", values.pan)
  end
end

local function selectedSource(entry)
  if not entry or #entry.sources == 0 then
    return nil
  end
  if #entry.sources == 1 then
    return entry.sources[1]
  end
  return entry.sources[math.random(#entry.sources)]
end

local function setSoundValue(entry, name, value, duration, ease, restart)
  if not entry or value == nil then
    return false
  end

  local key = "sound." .. tostring(entry.name) .. "." .. name
  if not duration or duration <= 0 then
    if restart then
      cancelRestartedTween(entry.target, key)
    end
    entry.target.values[name] = value
    applySoundValues(entry)
    return true
  end

  feel.play({
    kind = "animate",
    duration = duration,
    ease = ease,
    to = { [name] = value },
    onUpdate = function()
      applySoundValues(entry)
    end,
    onComplete = function()
      applySoundValues(entry)
    end,
  }, entry.target, restartOptions(restart, key))
  return true
end

local function playSound(entry, payload)
  local source = selectedSource(entry)
  if not source then
    return false
  end

  payload = payload or {}
  setSoundValue(entry, "volume", payload.volume, nil, nil, payload.restart)
  setSoundValue(entry, "pitch", payload.pitch, nil, nil, payload.restart)
  setSoundValue(entry, "pan", payload.pan, nil, nil, payload.restart)

  if entry.restart then
    callSource(source, "stop")
  end
  applySoundValues(entry)
  callSource(source, "play")
  return true
end

local function stopSources(entry)
  if not entry then
    return false
  end
  for _, source in ipairs(entry.sources) do
    callSource(source, "stop")
  end
  return true
end

local function pauseSources(entry)
  if not entry then
    return false
  end
  for _, source in ipairs(entry.sources) do
    callSource(source, "pause")
  end
  return true
end

local function resumeSources(entry)
  if not entry then
    return false
  end
  for _, source in ipairs(entry.sources) do
    callSource(source, "play")
  end
  return true
end

local function clamp01(value, fallback)
  if value == nil then
    value = fallback or 0
  end
  if value < 0 then
    return 0
  end
  if value > 1 then
    return 1
  end
  return value
end

local function supportsVibration(joystick)
  local fn = joystick and joystick.isVibrationSupported
  if type(fn) ~= "function" then
    return true
  end
  return fn(joystick) == true
end

local function canSetVibration(joystick)
  return type(joystick and joystick.setVibration) == "function" and supportsVibration(joystick)
end

local function vibrateSystem(duration)
  if not love or not love.system or type(love.system.vibrate) ~= "function" then
    return false
  end
  love.system.vibrate(duration)
  return true
end

local function playHapticEntry(entry, payload, defaultDuration)
  if not entry then
    return false
  end

  payload = payload or {}
  local value = payload.value ~= nil and payload.value or 1
  local left = clamp01(payload.left, value)
  local right = clamp01(payload.right, value)
  local duration = payload.duration or entry.duration or defaultDuration
  local played = false

  for _, joystick in ipairs(entry.joysticks) do
    if canSetVibration(joystick) then
      callSource(joystick, "setVibration", left, right, duration)
      played = true
    end
  end
  return played
end

local function stopHapticEntry(entry)
  if not entry then
    return false
  end

  local stopped = false
  for _, joystick in ipairs(entry.joysticks) do
    if canSetVibration(joystick) then
      callSource(joystick, "setVibration")
      stopped = true
    end
  end
  return stopped
end

local function setParticlePosition(entry, payload)
  if not entry or not payload then
    return
  end
  if payload.x ~= nil and payload.y ~= nil then
    callSource(entry.system, "setPosition", payload.x, payload.y)
  end
end

local function particleEntry(adapter, payload)
  return adapter.particleEntries[payload and payload.name]
end

local function emitParticle(entry, payload)
  if not entry then
    return false
  end
  payload = payload or {}
  setParticlePosition(entry, payload)
  callSource(entry.system, "emit", payload.count or 1)
  return true
end

local function startParticle(entry, payload)
  if not entry then
    return false
  end
  setParticlePosition(entry, payload)
  callSource(entry.system, "start")
  return true
end

local function stopParticle(entry)
  if not entry then
    return false
  end
  callSource(entry.system, "stop")
  return true
end

local function resetParticle(entry)
  if not entry then
    return false
  end
  callSource(entry.system, "reset")
  return true
end

local function shaderEntry(adapter, payloadOrName)
  if type(payloadOrName) == "table" then
    return adapter.shaderEntries[payloadOrName.name]
  end
  return adapter.shaderEntries[payloadOrName]
end

local function sendShaderValue(entry, uniform, value)
  if not entry or not uniform or value == nil then
    return false
  end
  entry.values[uniform] = value
  callSource(entry.shader, "send", uniform, value)
  return true
end

local function tweenShaderValue(entry, uniform, value, duration, ease, restart)
  if not entry or not uniform or type(value) ~= "number" then
    return false
  end

  local key = "shader." .. tostring(entry.name) .. "." .. tostring(uniform)
  if entry.values[uniform] == nil then
    entry.values[uniform] = 0
  end
  entry.target.values[uniform] = entry.values[uniform]

  if not duration or duration <= 0 then
    if restart then
      cancelRestartedTween(entry.target, key)
    end
    return sendShaderValue(entry, uniform, value)
  end

  feel.play({
    kind = "animate",
    duration = duration,
    ease = ease,
    to = { [uniform] = value },
    onUpdate = function(values)
      sendShaderValue(entry, uniform, values[uniform])
    end,
    onComplete = function(values)
      sendShaderValue(entry, uniform, values[uniform])
    end,
  }, entry.target, restartOptions(restart, key))
  return true
end

local function applyShader(adapter, entry)
  if not entry or not love or not love.graphics or not love.graphics.setShader then
    return false
  end
  love.graphics.setShader(entry.shader)
  adapter.activeShader = entry.shader
  return true
end

local function copyValues(values)
  local result = {}
  for key, value in pairs(values or {}) do
    result[key] = value
  end
  return result
end

local function newPostEffect(name, defaults)
  local target = feel.target()
  for key, value in pairs(defaults) do
    target.values[key] = value
  end
  return {
    name = name,
    defaults = copyValues(defaults),
    enabled = false,
    target = target,
  }
end

local function newPostState()
  local effects = {}
  for name, defaults in pairs(POST_DEFAULTS) do
    effects[name] = newPostEffect(name, defaults)
  end
  effects.volume.enabled = true
  return {
    effects = effects,
    canvases = {},
    shaders = {},
    width = nil,
    height = nil,
  }
end

local function resetPostEffect(entry)
  if not entry then
    return
  end
  feel.clear(entry.target)
  for key, value in pairs(entry.defaults) do
    entry.target.values[key] = value
  end
  entry.enabled = entry.name == "volume"
end

local function postEffect(adapter, effect)
  return adapter.post and adapter.post.effects[effect]
end

local function postAvailable()
  return love
    and love.graphics
    and love.graphics.newCanvas
    and love.graphics.newShader
    and love.graphics.setCanvas
    and love.graphics.setShader
    and love.graphics.draw
end

local function sendShader(shader, uniform, value)
  callSource(shader, "send", uniform, value)
end

local function setCanvas(canvas)
  if love and love.graphics and love.graphics.setCanvas then
    love.graphics.setCanvas(canvas)
  end
end

local function clearCanvas()
  if love and love.graphics and love.graphics.clear then
    love.graphics.clear(0, 0, 0, 0)
  end
end

local function drawCanvas(canvas)
  if love and love.graphics and love.graphics.draw then
    love.graphics.draw(canvas, 0, 0)
  end
end

local function white()
  if love and love.graphics and love.graphics.setColor then
    love.graphics.setColor(1, 1, 1, 1)
  end
end

local function createPostShader(source)
  if love and love.graphics and love.graphics.newShader then
    return love.graphics.newShader(source)
  end
  return nil
end

local function ensurePostResources(adapter)
  if not postAvailable() then
    return false
  end

  local width, height = viewportSize(adapter.opts)
  if width <= 0 or height <= 0 then
    return false
  end

  local post = adapter.post
  if post.width ~= width or post.height ~= height then
    post.width = width
    post.height = height
    post.canvases = {
      source = love.graphics.newCanvas(width, height),
      workA = love.graphics.newCanvas(width, height),
      workB = love.graphics.newCanvas(width, height),
      bloomA = love.graphics.newCanvas(width, height),
      bloomB = love.graphics.newCanvas(width, height),
    }
  end

  if not post.shaders.general then
    post.shaders.general = createPostShader(POST_GENERAL_SHADER)
    post.shaders.extract = createPostShader(POST_EXTRACT_SHADER)
    post.shaders.blur = createPostShader(POST_BLUR_SHADER)
    post.shaders.bloom = createPostShader(POST_BLOOM_SHADER)
    post.shaders.weight = createPostShader(POST_WEIGHT_SHADER)
  end

  return post.shaders.general and post.shaders.extract and post.shaders.blur and post.shaders.bloom and post.shaders.weight
end

local function anyPostEffectEnabled(post)
  for _, name in ipairs(POST_ORDER) do
    if post.effects[name].enabled then
      return true
    end
  end
  return false
end

local function renderPass(shader, input, output, configure)
  setCanvas(output)
  clearCanvas()
  white()
  love.graphics.setShader(shader)
  if configure then
    configure(shader)
  end
  drawCanvas(input)
  love.graphics.setShader()
  setCanvas()
end

local function sendGeneralPostUniforms(adapter, shader)
  local effects = adapter.post.effects
  local grade = effects.grade.enabled and effects.grade.target.values or effects.grade.defaults
  local lens = effects.lens.enabled and effects.lens.target.values or effects.lens.defaults
  local chromatic = effects.chromatic.enabled and effects.chromatic.target.values or effects.chromatic.defaults
  local vignette = effects.vignette.enabled and effects.vignette.target.values or effects.vignette.defaults

  sendShader(shader, "exposure", grade.exposure or 0)
  sendShader(shader, "saturation", grade.saturation or 1)
  sendShader(shader, "hueShift", grade.hueShift or 0)
  sendShader(shader, "contrast", grade.contrast or 1)
  sendShader(shader, "lensDistortion", lens.distortion or 0)
  sendShader(shader, "chromaticForce", chromatic.force or 0)
  sendShader(shader, "chromaticOffset", { chromatic.x or 0, chromatic.y or 0 })
  sendShader(shader, "vignetteIntensity", vignette.intensity or 0)
  sendShader(shader, "vignetteRadius", vignette.radius or 0.75)
  sendShader(shader, "vignetteSoftness", vignette.softness or 0.35)
end

local function setPostValues(adapter, effect, values)
  local entry = postEffect(adapter, effect)
  if not entry or type(values) ~= "table" then
    return false
  end
  for key, value in pairs(values) do
    entry.target.values[key] = value
  end
  entry.enabled = true
  return true
end

local function postRestartKey(effect, key)
  return "post." .. tostring(effect) .. "." .. tostring(key)
end

local function tweenPostValues(adapter, effect, values, opts)
  local entry = postEffect(adapter, effect)
  if not entry or type(values) ~= "table" then
    return false
  end

  local to = {}
  for key, value in pairs(values) do
    if type(value) == "number" then
      to[key] = value
      if entry.target.values[key] == nil then
        entry.target.values[key] = entry.defaults[key] or 0
      end
    else
      entry.target.values[key] = value
    end
  end
  entry.enabled = true

  opts = opts or {}
  if not opts.duration or opts.duration <= 0 then
    if opts.restart then
      for key, value in pairs(values) do
        if type(value) == "number" then
          cancelRestartedTween(entry.target, postRestartKey(effect, key))
        end
      end
    end
    for key, value in pairs(values) do
      entry.target.values[key] = value
    end
    return true
  end

  if next(to) == nil then
    return true
  end

  if opts.restart then
    for key, value in pairs(to) do
      feel.play({
        kind = "animate",
        duration = opts.duration,
        ease = opts.ease,
        to = { [key] = value },
      }, entry.target, restartOptions(true, postRestartKey(effect, key)))
    end
    return true
  end

  feel.play({
    kind = "animate",
    duration = opts.duration,
    ease = opts.ease,
    to = to,
  }, entry.target)
  return true
end

---@return nil
function Adapter:reset()
  feel.clear(self.cameraTarget)
  for _, entry in pairs(self.soundEntries) do
    feel.clear(entry.target)
  end
  for _, entry in pairs(self.shaderEntries) do
    feel.clear(entry.target)
  end
  for _, entry in pairs(self.post.effects) do
    resetPostEffect(entry)
  end
  self.shaderStack = {}
  self.activeShader = nil

  self.camera.x = self.defaults.x
  self.camera.y = self.defaults.y
  self.camera.scale = self.defaults.scale
  self.camera.rotation = self.defaults.rotation

  self.shake.amount = 0
  self.shake.duration = 0
  self.shake.remaining = 0
  self.shake.frequency = self.defaults.shakeFrequency
  self.shake.time = 0
  self.shake.x = 0
  self.shake.y = 0

  self.flash.alpha = 0
  self.flash.amount = 0
  self.flash.duration = 0
  self.flash.remaining = 0
  self.flash.color = copyColor(nil, DEFAULT_FLASH)

  self.fade.alpha = 0
  self.fade.amount = 0
  self.fade.duration = 0
  self.fade.remaining = 0
  self.fade.color = copyColor(nil, DEFAULT_FADE)
end

---@param name string
---@param sourceOrSources? FeelLoveSourceLike|FeelLoveSourceLike[]
---@param opts? FeelLoveSoundOptions
---@return FeelLoveAdapter
function Adapter:sound(name, sourceOrSources, opts)
  if not name then
    return self
  end

  opts = opts or {}
  local target = feel.target()
  target.values.volume = opts.volume ~= nil and opts.volume or 1
  target.values.pitch = opts.pitch ~= nil and opts.pitch or 1
  target.values.pan = opts.pan ~= nil and opts.pan or 0

  self.soundEntries[name] = {
    name = name,
    sources = collectSources(sourceOrSources),
    restart = opts.restart ~= false,
    target = target,
  }
  applySoundValues(self.soundEntries[name])
  return self
end

---@param map? table<string, FeelLoveSourceLike|FeelLoveSourceLike[]>
---@return FeelLoveAdapter
function Adapter:sounds(map)
  for name, sourceOrSources in pairs(map or {}) do
    self:sound(name, sourceOrSources)
  end
  return self
end

---@param name string
---@return boolean
function Adapter:stopSound(name)
  return stopSources(self.soundEntries[name])
end

---@return boolean
function Adapter:stopSounds()
  for _, entry in pairs(self.soundEntries) do
    stopSources(entry)
  end
  return true
end

---@param name string
---@param joystickOrJoysticks? FeelLoveJoystickLike|FeelLoveJoystickLike[]
---@param opts? FeelLoveHapticOptions
---@return FeelLoveAdapter
function Adapter:haptic(name, joystickOrJoysticks, opts)
  if not name then
    return self
  end

  opts = opts or {}
  self.hapticEntries[name] = {
    name = name,
    joysticks = collectJoysticks(joystickOrJoysticks),
    duration = opts.duration,
  }
  return self
end

---@param map? table<string, FeelLoveJoystickLike|FeelLoveJoystickLike[]>
---@return FeelLoveAdapter
function Adapter:haptics(map)
  for name, joystickOrJoysticks in pairs(map or {}) do
    self:haptic(name, joystickOrJoysticks)
  end
  return self
end

---@param name string
---@return boolean
function Adapter:stopHaptic(name)
  return stopHapticEntry(self.hapticEntries[name])
end

---@return boolean
function Adapter:stopHaptics()
  for _, entry in pairs(self.hapticEntries) do
    stopHapticEntry(entry)
  end
  return true
end

---@param duration? number
---@return boolean
function Adapter:vibrate(duration)
  return vibrateSystem(duration)
end

---@param name string
---@param system? FeelLoveParticleSystemLike
---@param opts? FeelLoveParticleOptions
---@return FeelLoveAdapter
function Adapter:particle(name, system, opts)
  if not name then
    return self
  end

  if not self.particleEntries[name] then
    self.particleOrder[#self.particleOrder + 1] = name
  end

  opts = opts or {}
  self.particleEntries[name] = {
    name = name,
    system = system,
  }
  setParticlePosition(self.particleEntries[name], opts)
  return self
end

---@param map? table<string, FeelLoveParticleSystemLike>|FeelLoveParticleBulkEntry[]
---@return FeelLoveAdapter
function Adapter:particles(map)
  map = map or {}
  for _, entry in ipairs(map) do
    if type(entry) == "table" then
      self:particle(entry.name or entry[1], entry.system or entry[2], entry.opts or entry.options)
    end
  end
  for name, system in pairs(map) do
    if type(name) ~= "number" then
      self:particle(name, system)
    end
  end
  return self
end

---@param name string
---@param shader? FeelLoveShaderLike
---@param opts? FeelLoveShaderOptions
---@return FeelLoveAdapter
function Adapter:shader(name, shader, opts)
  if not name then
    return self
  end

  opts = opts or {}
  local target = feel.target()
  local entry = {
    name = name,
    shader = shader,
    target = target,
    values = {},
  }

  for uniform, value in pairs(opts.uniforms or opts.values or {}) do
    entry.values[uniform] = value
    if type(value) == "number" then
      target.values[uniform] = value
    end
    callSource(shader, "send", uniform, value)
  end

  self.shaderEntries[name] = entry
  return self
end

---@param map? table<string, FeelLoveShaderLike>
---@return FeelLoveAdapter
function Adapter:shaders(map)
  for name, shader in pairs(map or {}) do
    self:shader(name, shader)
  end
  return self
end

---@param name string
---@return boolean
function Adapter:pushShader(name)
  local entry = shaderEntry(self, name)
  if not entry or not love or not love.graphics or not love.graphics.setShader then
    return false
  end

  local previous
  if love.graphics.getShader then
    previous = love.graphics.getShader()
  end
  self.shaderStack[#self.shaderStack + 1] = { shader = previous }
  love.graphics.setShader(entry.shader)
  self.activeShader = entry.shader
  return true
end

---@return boolean
function Adapter:popShader()
  if not love or not love.graphics or not love.graphics.setShader then
    return false
  end

  local frame = self.shaderStack[#self.shaderStack]
  self.shaderStack[#self.shaderStack] = nil
  local previous = frame and frame.shader or nil
  love.graphics.setShader(previous)
  self.activeShader = previous
  return true
end

---@param effect FeelLovePostEffectName
---@param values FeelLovePostValues
---@return boolean
function Adapter:setPost(effect, values)
  return setPostValues(self, effect, values)
end

---@param effect FeelLovePostEffectName
---@param values FeelLovePostValues
---@param opts? FeelLovePostTweenOptions
---@return boolean
function Adapter:tweenPost(effect, values, opts)
  return tweenPostValues(self, effect, values, opts)
end

---@param effect FeelLovePostEffectName
---@return boolean
function Adapter:enablePost(effect)
  local entry = postEffect(self, effect)
  if not entry then
    return false
  end
  entry.enabled = true
  return true
end

---@param effect FeelLovePostEffectName
---@return boolean
function Adapter:disablePost(effect)
  local entry = postEffect(self, effect)
  if not entry then
    return false
  end
  entry.enabled = false
  return true
end

---@return boolean
function Adapter:clearPost()
  for _, entry in pairs(self.post.effects) do
    resetPostEffect(entry)
  end
  return true
end

---@param dt? number
---@return nil
function Adapter:update(dt)
  dt = dt or 0

  for _, name in ipairs(self.particleOrder) do
    local entry = self.particleEntries[name]
    callSource(entry and entry.system, "update", dt)
  end

  if self.shake.remaining > 0 then
    self.shake.remaining = math.max(0, self.shake.remaining - dt)
    self.shake.time = self.shake.time + dt

    local duration = self.shake.duration > 0 and self.shake.duration or 1
    local strength = self.shake.amount * (self.shake.remaining / duration)
    local phase = self.shake.time * self.shake.frequency * math.pi * 2
    self.shake.x = math.sin(phase) * strength
    self.shake.y = math.cos(phase * 0.87) * strength * 0.55
  else
    self.shake.x = 0
    self.shake.y = 0
  end

  if self.flash.remaining > 0 then
    self.flash.remaining = math.max(0, self.flash.remaining - dt)
    local duration = self.flash.duration > 0 and self.flash.duration or 1
    self.flash.alpha = self.flash.amount * (self.flash.remaining / duration)
  else
    self.flash.alpha = 0
  end

  if self.fade.remaining > 0 then
    self.fade.remaining = math.max(0, self.fade.remaining - dt)
    local duration = self.fade.duration > 0 and self.fade.duration or 1
    self.fade.alpha = self.fade.amount * (self.fade.remaining / duration)
  elseif self.fade.duration > 0 then
    self.fade.alpha = 0
  end
end

---@param event? FeelLoveEvent
---@param ctx? any
---@return boolean
---@return any ctx
function Adapter:emit(event, ctx)
  local kind = event and (event.kind or event.event or event.name)
  local payload = event and event.payload or {}

  if kind == "camera.shake" then
    self.shake.amount = math.max(self.shake.amount, payload.amount or self.defaults.shakeAmount)
    self.shake.duration = payload.duration or self.defaults.shakeDuration
    self.shake.remaining = self.shake.duration
    self.shake.frequency = payload.frequency or self.defaults.shakeFrequency
    self.shake.time = 0
    return true
  elseif kind == "camera.zoom" then
    feel.play({
      kind = "animate",
      duration = payload.duration or self.defaults.tweenDuration,
      ease = payload.ease,
      to = { scale = payload.scale or self.defaults.scale },
    }, self.cameraTarget, restartOptions(payload.restart, "camera.zoom"))
    return true
  elseif kind == "camera.move" then
    feel.play({
      kind = "animate",
      duration = payload.duration or self.defaults.tweenDuration,
      ease = payload.ease,
      to = {
        x = payload.x or self.defaults.x,
        y = payload.y or self.defaults.y,
      },
    }, self.cameraTarget, restartOptions(payload.restart, "camera.move"))
    return true
  elseif kind == "camera.reset" then
    if payload.restart then
      feel.clear(self.cameraTarget)
    end
    feel.play({
      kind = "animate",
      duration = payload.duration or self.defaults.tweenDuration,
      ease = payload.ease,
      to = {
        x = self.defaults.x,
        y = self.defaults.y,
        scale = self.defaults.scale,
        rotation = self.defaults.rotation,
      },
    }, self.cameraTarget, restartOptions(payload.restart, "camera.reset"))
    self.shake.remaining = 0
    self.shake.x = 0
    self.shake.y = 0
    return true
  elseif kind == "screen.flash" then
    self.flash.color = copyColor(payload.color, DEFAULT_FLASH)
    self.flash.amount = payload.amount or payload.alpha or self.defaults.flashAmount
    self.flash.duration = payload.duration or self.defaults.flashDuration
    self.flash.remaining = self.flash.duration
    self.flash.alpha = self.flash.amount
    return true
  elseif kind == "screen.fade" then
    self.fade.color = copyColor(payload.color, DEFAULT_FADE)
    self.fade.amount = payload.alpha or payload.amount or self.defaults.fadeAmount
    self.fade.duration = payload.duration or self.defaults.fadeDuration
    self.fade.remaining = self.fade.duration
    self.fade.alpha = self.fade.amount
    return true
  elseif kind == "screen.clear" then
    self.flash.alpha = 0
    self.flash.remaining = 0
    self.fade.alpha = 0
    self.fade.remaining = 0
    return true
  elseif kind == "sound.play" then
    return playSound(self.soundEntries[payload.cue], payload)
  elseif kind == "sound.stop" then
    if payload.cue then
      return self:stopSound(payload.cue)
    end
    return self:stopSounds()
  elseif kind == "sound.pause" then
    return pauseSources(self.soundEntries[payload.cue])
  elseif kind == "sound.resume" then
    return resumeSources(self.soundEntries[payload.cue])
  elseif kind == "sound.volume" then
    return setSoundValue(self.soundEntries[payload.cue], "volume", payload.volume, payload.duration, payload.ease, payload.restart)
  elseif kind == "sound.pitch" then
    return setSoundValue(self.soundEntries[payload.cue], "pitch", payload.pitch, payload.duration, payload.ease, payload.restart)
  elseif kind == "sound.pan" then
    return setSoundValue(self.soundEntries[payload.cue], "pan", payload.pan, payload.duration, payload.ease, payload.restart)
  elseif kind == "haptic.play" then
    local played = false
    local systemDuration = payload.duration or self.defaults.hapticDuration
    if payload.name then
      local entry = self.hapticEntries[payload.name]
      if entry then
        systemDuration = payload.duration or entry.duration or self.defaults.hapticDuration
      end
      played = playHapticEntry(entry, payload, self.defaults.hapticDuration)
    else
      for _, entry in pairs(self.hapticEntries) do
        played = playHapticEntry(entry, payload, self.defaults.hapticDuration) or played
      end
    end
    if payload.system ~= false then
      played = vibrateSystem(systemDuration) or played
    end
    return played
  elseif kind == "haptic.stop" then
    local stopped
    if payload.name then
      stopped = self:stopHaptic(payload.name)
    else
      stopped = self:stopHaptics()
    end
    if payload.system ~= false then
      stopped = vibrateSystem(0) or stopped
    end
    return stopped
  elseif kind == "haptic.vibrate" then
    return vibrateSystem(payload.duration)
  elseif kind == "particle.emit" then
    return emitParticle(particleEntry(self, payload), payload)
  elseif kind == "particle.start" then
    return startParticle(particleEntry(self, payload), payload)
  elseif kind == "particle.stop" then
    return stopParticle(particleEntry(self, payload))
  elseif kind == "particle.reset" then
    return resetParticle(particleEntry(self, payload))
  elseif kind == "particle.move" then
    local entry = particleEntry(self, payload)
    setParticlePosition(entry, payload)
    return entry ~= nil
  elseif kind == "shader.send" then
    return sendShaderValue(shaderEntry(self, payload), payload.uniform, payload.value)
  elseif kind == "shader.tween" then
    return tweenShaderValue(shaderEntry(self, payload), payload.uniform, payload.value, payload.duration, payload.ease, payload.restart)
  elseif kind == "shader.apply" then
    return applyShader(self, shaderEntry(self, payload))
  elseif kind == "shader.clear" then
    if love and love.graphics and love.graphics.setShader then
      love.graphics.setShader()
      self.activeShader = nil
      self.shaderStack = {}
      return true
    end
    return false
  elseif kind == "post.set" then
    return self:setPost(payload.effect, payload.values)
  elseif kind == "post.tween" then
    return self:tweenPost(payload.effect, payload.values, payload)
  elseif kind == "post.enable" then
    return self:enablePost(payload.effect)
  elseif kind == "post.disable" then
    return self:disablePost(payload.effect)
  elseif kind == "post.weight" then
    return self:tweenPost("volume", { weight = payload.value }, payload)
  elseif kind == "post.clear" then
    return self:clearPost()
  end

  return false, ctx
end

---@param event? FeelLoveEvent
---@return boolean
function Adapter:audio(event)
  return playSound(self.soundEntries[event and event.cue], event)
end

---@param extra? FeelLoveHandlers
---@return FeelLoveHandlers
function Adapter:handlers(extra)
  extra = extra or {}
  local opts = {}
  for key, value in pairs(extra) do
    opts[key] = value
  end

  opts.emit = function(event, ctx)
    self:emit(event, ctx)
    if type(extra.emit) == "function" then
      extra.emit(event, ctx)
    end
  end

  opts.audio = function(event, ctx)
    self:audio(event)
    if type(extra.audio) == "function" then
      extra.audio(event, ctx)
    end
  end

  return opts
end

---@return nil
function Adapter:push()
  if not love or not love.graphics then
    return
  end

  if love.graphics.push then
    love.graphics.push()
  end
  if love.graphics.translate then
    love.graphics.translate(self.camera.x + self.shake.x, self.camera.y + self.shake.y)
  end
  if love.graphics.rotate then
    love.graphics.rotate(self.camera.rotation)
  end
  if love.graphics.scale then
    love.graphics.scale(self.camera.scale)
  end
end

---@return nil
function Adapter:pop()
  if love and love.graphics and love.graphics.pop then
    love.graphics.pop()
  end
end

---@return nil
function Adapter:drawOverlay()
  local width, height = viewportSize(self.opts)
  self.flash.width = width
  self.flash.height = height
  self.fade.width = width
  self.fade.height = height

  drawOverlay(self.fade)
  drawOverlay(self.flash)
end

---@return nil
function Adapter:drawParticles()
  if not love or not love.graphics or not love.graphics.draw then
    return
  end
  if love.graphics.setColor then
    love.graphics.setColor(1, 1, 1, 1)
  end
  for _, name in ipairs(self.particleOrder) do
    local entry = self.particleEntries[name]
    if entry and entry.system then
      love.graphics.draw(entry.system)
    end
  end
end

---@param drawScene FeelLoveDrawCallback
---@return boolean
function Adapter:drawPost(drawScene)
  if type(drawScene) ~= "function" then
    return false
  end
  if not anyPostEffectEnabled(self.post) and (self.post.effects.volume.target.values.weight or 1) >= 1 then
    drawScene()
    return true
  end
  if not ensurePostResources(self) then
    drawScene()
    return false
  end

  local post = self.post
  local canvases = post.canvases
  local shaders = post.shaders
  local width = post.width
  local height = post.height

  setCanvas(canvases.source)
  clearCanvas()
  drawScene()
  setCanvas()

  local current = canvases.source
  local nextCanvas = canvases.workA

  renderPass(shaders.general, current, nextCanvas, function(shader)
    sendGeneralPostUniforms(self, shader)
  end)
  current, nextCanvas = nextCanvas, canvases.workB

  local bloom = post.effects.bloom
  if bloom.enabled and (bloom.target.values.intensity or 0) > 0 then
    local bloomPasses = math.max(1, math.floor(bloom.target.values.passes or bloom.defaults.passes or 1))
    renderPass(shaders.extract, current, canvases.bloomA, function(shader)
      sendShader(shader, "threshold", bloom.target.values.threshold or 0.75)
      sendShader(shader, "softness", bloom.target.values.softness or 0.15)
    end)
    for _ = 1, bloomPasses do
      renderPass(shaders.blur, canvases.bloomA, canvases.bloomB, function(shader)
        sendShader(shader, "direction", { 1, 0 })
        sendShader(shader, "texel", { 1 / width, 1 / height })
      end)
      renderPass(shaders.blur, canvases.bloomB, canvases.bloomA, function(shader)
        sendShader(shader, "direction", { 0, 1 })
        sendShader(shader, "texel", { 1 / width, 1 / height })
      end)
    end
    renderPass(shaders.bloom, current, nextCanvas, function(shader)
      sendShader(shader, "bloomTex", canvases.bloomA)
      sendShader(shader, "intensity", bloom.target.values.intensity or 0)
    end)
    current, nextCanvas = nextCanvas, current == canvases.workA and canvases.workB or canvases.workA
  end

  white()
  local weight = clamp01(self.post.effects.volume.target.values.weight, 1)
  if weight < 1 then
    love.graphics.setShader(shaders.weight)
    sendShader(shaders.weight, "processedTex", current)
    sendShader(shaders.weight, "weight", weight)
    drawCanvas(canvases.source)
    love.graphics.setShader()
  else
    drawCanvas(current)
  end
  return true
end

---@param opts? FeelLoveOptions
---@return FeelLoveAdapter
function FeelLove.new(opts)
  opts = opts or {}
  local cameraTarget = feel.target({
    values = {
      x = opts.x or 0,
      y = opts.y or 0,
      scale = opts.scale or 1,
      rotation = opts.rotation or 0,
    },
  })

  local adapter = setmetatable({
    opts = opts,
    cameraTarget = cameraTarget,
    camera = cameraTarget.values,
    defaults = {
      x = opts.x or 0,
      y = opts.y or 0,
      scale = opts.scale or 1,
      rotation = opts.rotation or 0,
      shakeAmount = opts.shakeAmount or 6,
      shakeDuration = opts.shakeDuration or 0.22,
      shakeFrequency = opts.shakeFrequency or 42,
      flashAmount = opts.flashAmount or 0.5,
      flashDuration = opts.flashDuration or 0.18,
      fadeAmount = opts.fadeAmount or 1,
      fadeDuration = opts.fadeDuration or 0.35,
      tweenDuration = opts.duration or 0.16,
      hapticDuration = opts.hapticDuration or 0.12,
    },
    shake = {},
    flash = {},
    fade = {},
    soundEntries = {},
    hapticEntries = {},
    particleEntries = {},
    particleOrder = {},
    shaderEntries = {},
    shaderStack = {},
    post = newPostState(),
  }, Adapter)

  adapter:reset()
  return adapter
end

return FeelLove
