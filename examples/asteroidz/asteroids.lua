local feel = require("feel")
local color = require("colors").color
local palette = require("colors").palette

--- Create a asteroid
---@param x number
---@param y number
---@param radius number
local function makeAsteroid(x, y, radius)
	local asteroid = {
		x = x,
		y = y,
		vx = (math.random() - 0.5) * 120,
		vy = (math.random() - 0.5) * 120,
		r = radius,
		spin = (math.random() - 0.5) * 1.8,
		angle = math.random() * math.pi * 2,
		shape = {},
		target = feel.target({ values = { scale = 1, opacity = 1 } }),
	}

	local points = 9 + math.random(0, 4)
	for i = 1, points do
		asteroid.shape[i] = 0.72 + math.random() * 0.42
	end

	return asteroid
end

--- Destroy an asteroid
---@param asteroids table
---@param index number
---@param bullet table
---@param callback function
local function breakAsteroid(asteroids, index, bullet, callback)
	local asteroid = asteroids[index]

	callback(asteroid)
	-- score = score + math.floor(100 - asteroid.r)
	-- emitParticles(asteroid.x, asteroid.y, palette.gold, math.floor(asteroid.r * 0.8), 170)
	-- sequences.play("asteroid.hit", asteroid.target, { x = asteroid.x, y = asteroid.y, color = palette.gold })

	table.remove(asteroids, index)
	if asteroid.r > 25 then
		for _ = 1, 2 do
			local child = makeAsteroid(asteroid.x, asteroid.y, asteroid.r * 0.58)
			child.vx = child.vx + (bullet and bullet.vx or 0) * 0.08
			child.vy = child.vy + (bullet and bullet.vy or 0) * 0.08
			asteroids[#asteroids + 1] = child
		end
	end
end

--- Draw an asteroid
---@param asteroid table
local function drawAsteroid(asteroid)
	local v = asteroid.target.values
	color(palette.line, v.opacity or 1)
	love.graphics.push()
	love.graphics.setLineWidth(3)
	love.graphics.translate(asteroid.x, asteroid.y)
	love.graphics.rotate(asteroid.angle)
	love.graphics.scale(v.scale or 1)
	local points = {}
	for i, factor in ipairs(asteroid.shape) do
		local angle = (i / #asteroid.shape) * math.pi * 2
		points[#points + 1] = math.cos(angle) * asteroid.r * factor
		points[#points + 1] = math.sin(angle) * asteroid.r * factor
	end
	love.graphics.polygon("line", points)
	love.graphics.pop()
end

return {
	draw = drawAsteroid,
	destroy = breakAsteroid,
	create = makeAsteroid,
}
