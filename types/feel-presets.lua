---@meta feel.presets

---@class FeelPresetOptions
---@field name? string
---@field color? number[]
---@field duration? number
---@field returnDuration? number
---@field shakeDuration? number
---@field shake? number
---@field scale? number
---@field rotation? number
---@field fov? number
---@field fovDuration? number
---@field freeze? number

---@class FeelPresetsModule
local presets = {}

---@param opts? FeelPresetOptions
---@return FeelFeedbackManifest
function presets.hitLight(opts) end

---@param opts? FeelPresetOptions
---@return FeelFeedbackManifest
function presets.hitHeavy(opts) end

---@param opts? FeelPresetOptions
---@return FeelFeedbackManifest
function presets.cameraPunch(opts) end

---@param opts? FeelPresetOptions
---@return FeelFeedbackManifest
function presets.modelImpact(opts) end

return presets
