local moduleName = ...
local prefix = "feel"
if moduleName and moduleName ~= "" then
  prefix = moduleName:gsub("%.sprite$", "")
end

---@type FeelModule
local feel = require(prefix)

---@module "feel.sprite"

---@class FeelSpriteModule
local Sprite = {}

---@class FeelSpriteValues
---@field offsetX number
---@field offsetY number
---@field rotation number
---@field scaleX number
---@field scaleY number
---@field opacity number
---@field tintR number
---@field tintG number
---@field tintB number
---@field flash number
---@field glow number
---@field outline number

---@class FeelSpritePose
---@field x number
---@field y number
---@field rotation number
---@field scaleX number
---@field scaleY number
---@field opacity number
---@field tintR number
---@field tintG number
---@field tintB number
---@field flash number
---@field glow number
---@field outline number

---@class FeelSpriteBasePose
---@field x? number
---@field y? number
---@field rotation? number
---@field scaleX? number
---@field scaleY? number
---@field opacity? number
---@field tintR? number
---@field tintG? number
---@field tintB? number
---@field flash? number
---@field glow? number
---@field outline? number

---@class FeelSpriteEffectOptions
---@field duration? number
---@field ease? string
---@field x? number
---@field y? number
---@field rotation? number
---@field squash? number
---@field stretch? number
---@field flash? number
---@field glow? number
---@field outline? number
---@field count? integer
---@field interval? number
---@field restart? boolean
---@field key? string
---@field play? FeelPlayOptions

local DEFAULTS = {
  offsetX = 0,
  offsetY = 0,
  rotation = 0,
  scaleX = 1,
  scaleY = 1,
  opacity = 1,
  tintR = 1,
  tintG = 1,
  tintB = 1,
  flash = 0,
  glow = 0,
  outline = 0,
}

local function copy(value)
  local result = {}
  for key, item in pairs(value or {}) do
    result[key] = item
  end
  return result
end

local function withDefaults(values)
  local result = copy(DEFAULTS)
  for key, value in pairs(values or {}) do
    result[key] = value
  end
  return result
end

local function restoreStep(values, duration, ease)
  return {
    kind = "animate",
    duration = duration,
    ease = ease or "backout",
    to = values,
  }
end

local EFFECTS = {
  hitLight = function(opts)
    local duration = opts.duration or 0.14
    return {
      {
        kind = "animate",
        duration = duration,
        ease = opts.ease or "quadout",
        from = {
          offsetX = opts.x or -4,
          offsetY = opts.y or 0,
          rotation = opts.rotation or -0.025,
          scaleX = 1 + (opts.stretch or 0.08),
          scaleY = 1 - (opts.squash or 0.08),
          flash = opts.flash or 0.8,
        },
        to = { offsetX = 0, offsetY = 0, rotation = 0, scaleX = 1, scaleY = 1, flash = 0 },
      },
    }
  end,
  hitHeavy = function(opts)
    local duration = opts.duration or 0.24
    return {
      {
        kind = "animate",
        duration = duration * 0.35,
        ease = "quadout",
        from = {
          offsetX = opts.x or -10,
          offsetY = opts.y or -2,
          rotation = opts.rotation or -0.07,
          scaleX = 1 + (opts.stretch or 0.18),
          scaleY = 1 - (opts.squash or 0.2),
          flash = opts.flash or 1,
          outline = opts.outline or 1,
        },
        to = { offsetX = 2, offsetY = 1, rotation = 0.025, scaleX = 0.96, scaleY = 1.04, flash = 0.15, outline = 0 },
      },
      restoreStep(
        { offsetX = 0, offsetY = 0, rotation = 0, scaleX = 1, scaleY = 1, flash = 0, outline = 0 },
        duration * 0.65,
        opts.ease
      ),
    }
  end,
  land = function(opts)
    local duration = opts.duration or 0.22
    return {
      {
        kind = "animate",
        duration = duration * 0.35,
        ease = "quadout",
        from = {
          offsetY = opts.y or 3,
          scaleX = 1 + (opts.squash or 0.18),
          scaleY = 1 - (opts.stretch or 0.25),
        },
        to = { offsetY = 0, scaleX = 0.96, scaleY = 1.06 },
      },
      restoreStep({ offsetY = 0, scaleX = 1, scaleY = 1 }, duration * 0.65, opts.ease),
    }
  end,
  recoil = function(opts)
    return {
      {
        kind = "animate",
        duration = opts.duration or 0.16,
        ease = opts.ease or "quadout",
        from = { offsetX = opts.x or -8, offsetY = opts.y or 0, rotation = opts.rotation or -0.04 },
        to = { offsetX = 0, offsetY = 0, rotation = 0 },
      },
    }
  end,
  wobble = function(opts)
    local rotation = opts.rotation or 0.09
    local duration = (opts.duration or 0.24) / 4
    return {
      { kind = "animate", duration = duration, ease = "quadout", to = { rotation = rotation } },
      { kind = "animate", duration = duration, ease = "sineinout", to = { rotation = -rotation * 0.7 } },
      { kind = "animate", duration = duration, ease = "sineinout", to = { rotation = rotation * 0.35 } },
      { kind = "animate", duration = duration, ease = "quadout", to = { rotation = 0 } },
    }
  end,
  blink = function(opts)
    local interval = opts.interval or 0.06
    return {
      {
        kind = "repeat",
        count = math.max(1, math.floor(opts.count or 3)),
        sequence = {
          { kind = "animate", duration = 0, to = { opacity = 0 } },
          { kind = "wait", duration = interval },
          { kind = "animate", duration = 0, to = { opacity = 1 } },
          { kind = "wait", duration = interval },
        },
      },
    }
  end,
  spawn = function(opts)
    return {
      {
        kind = "animate",
        duration = opts.duration or 0.24,
        ease = opts.ease or "backout",
        from = { scaleX = 0.45, scaleY = 0.45, opacity = 0, glow = opts.glow or 1 },
        to = { scaleX = 1, scaleY = 1, opacity = 1, glow = 0 },
      },
    }
  end,
  despawn = function(opts)
    return {
      {
        kind = "animate",
        duration = opts.duration or 0.18,
        ease = opts.ease or "quadin",
        to = { scaleX = 0.55, scaleY = 0.55, opacity = 0, glow = opts.glow or 0.5 },
      },
    }
  end,
  chargePulse = function(opts)
    local duration = opts.duration or 0.36
    return {
      {
        kind = "animate",
        duration = duration * 0.45,
        ease = "sineinout",
        to = { scaleX = 1.08, scaleY = 1.08, glow = opts.glow or 1, outline = opts.outline or 0.7 },
      },
      {
        kind = "animate",
        duration = duration * 0.55,
        ease = "sineinout",
        to = { scaleX = 1, scaleY = 1, glow = 0, outline = 0 },
      },
    }
  end,
}

---@param meta? table
---@return FeelTarget
function Sprite.target(meta)
  meta = copy(meta)
  meta.values = withDefaults(meta.values)
  return feel.target(meta)
end

---@param target FeelTarget
---@return FeelTarget
function Sprite.reset(target)
  feel.clear(target)
  target.values = target.values or {}
  for key, value in pairs(DEFAULTS) do
    target.values[key] = value
  end
  return target
end

---@param target FeelTarget
---@param base? FeelSpriteBasePose
---@param out? FeelSpritePose
---@return FeelSpritePose
function Sprite.pose(target, base, out)
  base = base or {}
  out = out or {}
  local values = target and target.values or DEFAULTS
  out.x = (base.x or 0) + (values.offsetX or 0)
  out.y = (base.y or 0) + (values.offsetY or 0)
  out.rotation = (base.rotation or 0) + (values.rotation or 0)
  out.scaleX = (base.scaleX or 1) * (values.scaleX or 1)
  out.scaleY = (base.scaleY or 1) * (values.scaleY or 1)
  out.opacity = (base.opacity or 1) * (values.opacity or 1)
  out.tintR = (base.tintR or 1) * (values.tintR or 1)
  out.tintG = (base.tintG or 1) * (values.tintG or 1)
  out.tintB = (base.tintB or 1) * (values.tintB or 1)
  out.flash = math.max(base.flash or 0, values.flash or 0)
  out.glow = math.max(base.glow or 0, values.glow or 0)
  out.outline = math.max(base.outline or 0, values.outline or 0)
  return out
end

---@param target FeelTarget
---@param base FeelSpriteBasePose|fun(pose: FeelSpritePose, target: FeelTarget): any
---@param callback? fun(pose: FeelSpritePose, target: FeelTarget): any
---@param out? FeelSpritePose
---@return any
function Sprite.draw(target, base, callback, out)
  if type(base) == "function" then
    callback = base
    base = nil
  end
  assert(type(callback) == "function", "sprite draw callback must be a function")
  return callback(Sprite.pose(target, base, out), target)
end

---@param name string
---@param opts? FeelSpriteEffectOptions
---@return FeelStep[]?
function Sprite.sequence(name, opts)
  local factory = EFFECTS[name]
  return factory and factory(opts or {}) or nil
end

---@return string[]
function Sprite.list()
  local names = {}
  for name in pairs(EFFECTS) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

---@param target FeelTarget
---@param name string
---@param opts? FeelSpriteEffectOptions
---@return FeelContext|false
function Sprite.play(target, name, opts)
  opts = opts or {}
  local sequence = Sprite.sequence(name, opts)
  if not sequence then
    return false
  end
  local playOpts = copy(opts.play)
  playOpts.restart = opts.restart ~= false
  playOpts.key = opts.key or ("sprite." .. name)
  return feel.play(sequence, target, playOpts) or false
end

Sprite.effects = copy(EFFECTS)
Sprite.defaults = copy(DEFAULTS)

return Sprite
