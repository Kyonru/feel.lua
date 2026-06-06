---@module "feel.presets"

---@class FeelPresetsModule
---@field hitLight fun(opts?: table): FeelFeedbackManifest
---@field hitHeavy fun(opts?: table): FeelFeedbackManifest
---@field cameraPunch fun(opts?: table): FeelFeedbackManifest
---@field modelImpact fun(opts?: table): FeelFeedbackManifest
---@type FeelPresetsModule
local Presets = {}

local function value(opts, key, fallback)
  opts = opts or {}
  if opts[key] ~= nil then
    return opts[key]
  end
  return fallback
end

---@param opts? table
---@return FeelFeedbackManifest
function Presets.cameraPunch(opts)
  opts = opts or {}
  return {
    {
      kind = "parallel",
      steps = {
        {
          kind = "g3d.camera.shake",
          amount = value(opts, "shake", 0.08),
          duration = value(opts, "duration", 0.12),
        },
        {
          kind = "g3d.camera.fov",
          amount = value(opts, "fov", 4),
          duration = value(opts, "fovDuration", 0.05),
          returnDuration = value(opts, "returnDuration", 0.16),
        },
      },
    },
  }
end

---@param opts? table
---@return FeelFeedbackManifest
function Presets.modelImpact(opts)
  opts = opts or {}
  local name = value(opts, "name", "$name")
  return {
    {
      kind = "parallel",
      steps = {
        {
          kind = "g3d.model.scalePunch",
          name = name,
          amount = value(opts, "scale", 0.18),
          duration = value(opts, "duration", 0.06),
          returnDuration = value(opts, "returnDuration", 0.2),
        },
        {
          kind = "g3d.model.rotationShake",
          name = name,
          amount = value(opts, "rotation", 0.08),
          duration = value(opts, "shakeDuration", 0.14),
        },
      },
    },
  }
end

---@param opts? table
---@return FeelFeedbackManifest
function Presets.hitLight(opts)
  opts = opts or {}
  return {
    {
      kind = "parallel",
      steps = {
        {
          kind = "screen.flash",
          color = value(opts, "color", { 1, 0.85, 0.35, 1 }),
          amount = 0.16,
          duration = 0.08,
        },
        { kind = "g3d.camera.shake", amount = value(opts, "shake", 0.05), duration = 0.1 },
        {
          kind = "g3d.model.scalePunch",
          name = value(opts, "name", "$name"),
          amount = 0.12,
          duration = 0.05,
          returnDuration = 0.14,
        },
      },
    },
  }
end

---@param opts? table
---@return FeelFeedbackManifest
function Presets.hitHeavy(opts)
  opts = opts or {}
  return {
    { kind = "time.freeze", duration = value(opts, "freeze", 0.035) },
    {
      kind = "parallel",
      steps = {
        {
          kind = "screen.flash",
          color = value(opts, "color", { 1, 0.76, 0.28, 1 }),
          amount = 0.32,
          duration = 0.08,
        },
        { kind = "g3d.camera.shake", amount = value(opts, "shake", 0.13), duration = 0.16 },
        { kind = "g3d.camera.fov", amount = value(opts, "fov", 5), duration = 0.05, returnDuration = 0.18 },
        {
          kind = "g3d.model.scalePunch",
          name = value(opts, "name", "$name"),
          amount = 0.24,
          duration = 0.06,
          returnDuration = 0.22,
        },
      },
    },
  }
end

return Presets
