---@meta feel.sprite

---@class FeelSpriteModule
---@field effects table<string, fun(opts: FeelSpriteEffectOptions): FeelStep[]>
---@field defaults FeelSpriteValues
local feelSprite = {}

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

---@param meta? table
---@return FeelTarget
function feelSprite.target(meta) end

---@param target FeelTarget
---@return FeelTarget
function feelSprite.reset(target) end

---@param target FeelTarget
---@param base? FeelSpriteBasePose
---@param out? FeelSpritePose
---@return FeelSpritePose
function feelSprite.pose(target, base, out) end

---@overload fun(target: FeelTarget, callback: fun(pose: FeelSpritePose, target: FeelTarget): any): any
---@param target FeelTarget
---@param base FeelSpriteBasePose
---@param callback fun(pose: FeelSpritePose, target: FeelTarget): any
---@param out? FeelSpritePose
---@return any
function feelSprite.draw(target, base, callback, out) end

---@param name string
---@param opts? FeelSpriteEffectOptions
---@return FeelStep[]?
function feelSprite.sequence(name, opts) end

---@return string[]
function feelSprite.list() end

---@param target FeelTarget
---@param name string
---@param opts? FeelSpriteEffectOptions
---@return FeelContext|false
function feelSprite.play(target, name, opts) end

return feelSprite
