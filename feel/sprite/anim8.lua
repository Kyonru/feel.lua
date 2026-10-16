local moduleName = ...
local prefix = "feel"
if moduleName and moduleName ~= "" then
  prefix = moduleName:gsub("%.sprite%.anim8$", "")
end

local Sprite = require(prefix .. ".sprite")

---@module "feel.sprite.anim8"

local Anim8 = {}

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
function Anim8.draw(animation, image, target, opts)
  if type(animation) ~= "table" or type(animation.draw) ~= "function" then
    return false
  end
  opts = opts or {}
  local pose = Sprite.pose(target, opts, opts.pose)
  local graphics = love and love.graphics
  if graphics and graphics.push then
    graphics.push("all")
  end
  if graphics and graphics.setColor then
    graphics.setColor(pose.tintR, pose.tintG, pose.tintB, pose.opacity)
  end
  animation:draw(
    image,
    pose.x,
    pose.y,
    pose.rotation,
    pose.scaleX,
    pose.scaleY,
    opts.originX or 0,
    opts.originY or 0,
    opts.shearX or 0,
    opts.shearY or 0
  )
  if graphics and graphics.pop then
    graphics.pop()
  end
  return true
end

return Anim8
