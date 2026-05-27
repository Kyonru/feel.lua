local moduleName = ...
local prefix = moduleName or "feel"

---@return FeelModule
return require(prefix .. ".init")
