---@meta feel.sprite.anim8

local feelSpriteAnim8 = {}

---@class FeelSpriteAnim8DrawOptions: FeelSpriteBasePose
---@field originX? number
---@field originY? number
---@field shearX? number
---@field shearY? number
---@field pose? FeelSpritePose Reusable output table.

---@param animation table Anim8 animation or compatible object.
---@param image any
---@param target FeelTarget
---@param opts? FeelSpriteAnim8DrawOptions
---@return boolean
function feelSpriteAnim8.draw(animation, image, target, opts) end

return feelSpriteAnim8
