--- Clamp value in range
---@param x number
---@param min number
---@param max number
math.clamp = function(x, min, max)
	return math.max(min, math.min(max, x))
end

--- Wrap value around a min and max number
--- @param value number
--- @param max number
--- @param min number
math.wrap = function(value, min, max)
	local min_value = min or 0
	if value < min_value then
		return value + max
	elseif value >= max then
		return value - max
	else
		return value
	end
end

--- Get distance squared
---@param a table
---@param b table
math.distanceSquared = function(a, b)
	local dx = a.x - b.x
	local dy = a.y - b.y
	return dx * dx + dy * dy
end
