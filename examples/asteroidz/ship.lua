local feel = require("feel")
local constants = require("constants")
local state = require("state")
local pubSub = require("pubsub")
local palette = require("colors").palette
local color = require("colors").color
local emitParticles = require("effects").emitParticles

---@class Ship
---@field x number
---@field y number
---@field vx number
---@field vy number
---@field angle number
---@field target FeelTarget
---@field lives number
---@field fireCooldown number
---@field invulnerable number
local ship = {
	x = constants.W / 2,
	y = constants.H / 2,
	vx = 0,
	vy = 0,
	angle = 0,
	target = feel.target({ values = { scale = 1, scaleX = 1, scaleY = 1, opacity = 1, rotation = 0, teleportGlow = 0 } }),
	lives = 3,
	max_lives = 3,
	fireCooldown = 0,
	invulnerable = 0,
}

function ship:shoot()
	local gameOver = state.get("gameOver")
	local bullets = state.get("bullets")

	if self.fireCooldown > 0 or gameOver then
		return
	end

	self.fireCooldown = 0.16
	local noseX = self.x + math.cos(self.angle) * 20
	local noseY = self.y + math.sin(self.angle) * 20
	bullets[#bullets + 1] = {
		x = noseX,
		y = noseY,
		vx = self.vx + math.cos(self.angle) * 430,
		vy = self.vy + math.sin(self.angle) * 430,
		life = 0.95,
	}

	pubSub:emit("play_sequence", {
		name = "ship.shoot",
		target = self.target,
		extra = { restart = true, key = "ship.shoot" },
	})
end

function ship:hit()
	local gameOver = state.get("gameOver")
	if self.invulnerable > 0 or gameOver then
		return
	end

	self.lives = self.lives - 1
	emitParticles(self.x, self.y, palette.pink, 42, 230)
	pubSub:emit("play_sequence", {
		name = "ship.explode",
		target = self.target,
		extra = { restart = true, key = "ship.explode" },
	})

	if self.lives <= 0 then
		state.set("gameOver", true)
	else
		self.x = constants.W / 2
		self.y = constants.H / 2
		self.vx = 0
		self.vy = 0
		self.invulnerable = 1.8
	end
end

function ship:draw()
	local gameOver = state.get("gameOver")
	local invulnerable = self.invulnerable
	if gameOver or (invulnerable > 0 and math.floor(invulnerable * 12) % 2 == 0) then
		return
	end

	local v = ship.target.values

	love.graphics.push()
	love.graphics.translate(ship.x, ship.y)
	love.graphics.rotate(ship.angle + (v.rotation or 0))
	love.graphics.scale((v.scale or 1) * (v.scaleX or 1), (v.scale or 1) * (v.scaleY or 1))

	local glow = v.teleportGlow or 0
	if glow > 0 then
		love.graphics.setLineWidth(8)
		color(palette.pink, 0.18 * glow)
		love.graphics.circle("fill", 0, 0, 36 + glow * 18)
		color(palette.cyan, 0.28 * glow)
		love.graphics.circle("fill", 0, 0, 22 + glow * 10)
		color(palette.cyan, 0.65 * glow)
		love.graphics.polygon("line", 22, 0, -16, -14, -9, 0, -16, 14)
	end

	love.graphics.setLineWidth(2)
	color(palette.cyan, v.opacity)
	love.graphics.polygon("line", 20, 0, -14, -12, -8, 0, -14, 12)
	love.graphics.pop()
end

function ship:reset()
	self = {
		x = constants.W / 2,
		y = constants.H / 2,
		vx = 0,
		vy = 0,
		angle = -math.pi / 2,
		target = feel.target({ values = { scale = 1, scaleX = 1, scaleY = 1, opacity = 1, rotation = 0, teleportGlow = 0 } }),
	}
	self.invulnerable = 1.5
end

return ship
