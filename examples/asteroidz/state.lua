local feelLove = require("feel.love")
local constants = require("constants")
local createAsteroid = require("asteroids").create

--- @class GlobalState
---@field asteroids table[]
---@field bullets table[]
---@field particles table[]
---@field score number
---@field wave number
---@field gameOver boolean

--- @type GlobalState
local state = {
	asteroids = {},
	bullets = {},
	particles = {},
	score = 0,
	wave = 1,
	gameOver = false,
}

--- @alias StateProperty   "asteroids" | "bullets" | "particles"  | "score" | "wave" | "gameOver"

--- Get state or a property
---@param name? StateProperty
---@return GlobalState|any
local get = function(name)
	if not name then
		return state
	end

	return state[name]
end

--- Set a state property
--- @param name StateProperty
--- @param value any
local set = function(name, value)
	state[name] = value
end

local function spawn_wave()
	state.asteroids = {}
	local asteroids = state.asteroids
	local wave = state.wave
	for i = 1, 4 + wave do
		local side = math.random(4)
		local x = side <= 2 and math.random() * constants.W or (side == 3 and -40 or constants.W + 40)
		local y = side > 2 and math.random() * constants.H or (side == 1 and -40 or constants.H + 40)
		asteroids[#asteroids + 1] = createAsteroid(x, y, 34 + math.random() * 18)
	end
end

local reset = function()
	state = {
		asteroids = {},
		bullets = {},
		particles = {},
		score = 0,
		wave = 1,
		gameOver = false,
	}
	spawn_wave()
end

return {
	get = get,
	set = set,
	reset = reset,
	spawn_wave = spawn_wave,
}
