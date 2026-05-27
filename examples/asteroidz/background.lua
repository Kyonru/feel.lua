local constants = require("constants")
local color = require("colors").color
local palette = require("colors").palette

local background = {
	stars = {},
}

local function createStars()
	local stars = background.stars
	for i = 1, 120 do
		stars[i] = { x = math.random() * constants.W, y = math.random() * constants.H, a = 0.18 + math.random() * 0.72 }
	end
end

function background:load()
	createStars()
end

function background:update(dt) end

function background:draw()
	local stars = background.stars
	for _, star in ipairs(stars) do
		color(palette.line, star.a)
		love.graphics.points(star.x, star.y)
	end
end

return background
