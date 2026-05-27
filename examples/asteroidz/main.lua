package.path = "?.lua;?/init.lua;../../?.lua;../../?/init.lua;" .. package.path

require("extension")
local feel = require("feel")
local feelLove = require("feel.love")
local constants = require("constants")
local state = require("state")
local palette = require("colors").palette
local color = require("colors").color
local emitParticles = require("effects").emitParticles
local makeTone = require("effects").makeTone
local sequences = require("sequences")
local ship = require("ship")
local asteroidsUtil = require("asteroids")
local background = require("background")

local function resetGame()
	sequences.create()
	state.reset()
	constants.fx:reset()
	ship:reset()
	ship.lives = ship.max_lives
end

function love.load()
	love.window.setMode(constants.W, constants.H, { resizable = true, minwidth = 720, minheight = 480 })
	love.window.setTitle("feel.lua - Asteroidz")
	math.randomseed(os.time())
	background:load()

	constants.fx:sounds({
		shoot = makeTone(880, 0.06, 0.12),
		hit = makeTone(180, 0.12, 0.18),
		boom = makeTone(90, 0.28, 0.24),
	})
	resetGame()
end

function love.update(dt)
	feel.update(dt)
	constants.fx:update(dt)
	background:update(dt)

	ship.fireCooldown = math.max(0, ship.fireCooldown - dt)
	ship.invulnerable = math.max(0, ship.invulnerable - dt)
	local gameOver = state.get("gameOver")

	if love.keyboard.isDown("left", "a") then
		ship.angle = ship.angle - 4.5 * dt
	end
	if love.keyboard.isDown("right", "d") then
		ship.angle = ship.angle + 4.5 * dt
	end
	if love.keyboard.isDown("up", "w") and not gameOver then
		local thrust = 260
		ship.vx = ship.vx + math.cos(ship.angle) * thrust * dt
		ship.vy = ship.vy + math.sin(ship.angle) * thrust * dt
		sequences.play("ship.thrust", ship.target, { restart = true, key = "ship.thrust" })
	end
	if love.keyboard.isDown("space") then
		ship:shoot()
	end

	if not gameOver then
		local newX = ship.x + ship.vx * dt
		local newY = ship.y + ship.vy * dt

		local wrapX = math.wrap(newX, 0, constants.W)
		local wrapY = math.wrap(newY, 0, constants.H)

		if newX ~= wrapX or wrapY ~= newY then
			sequences.play("ship.teleport", ship.target, { restart = true, key = "ship.teleport" })
		end

		ship.x = wrapX
		ship.y = wrapY
		ship.vx = ship.vx * (1 - math.min(0.55 * dt, 0.12))
		ship.vy = ship.vy * (1 - math.min(0.55 * dt, 0.12))
	end

	local bullets = state.get("bullets")

	for i = #bullets, 1, -1 do
		local bullet = bullets[i]
		bullet.life = bullet.life - dt
		bullet.x = math.wrap(bullet.x + bullet.vx * dt, 0, constants.W)
		bullet.y = math.wrap(bullet.y + bullet.vy * dt, 0, constants.H)
		if bullet.life <= 0 then
			table.remove(bullets, i)
		end
	end

	local asteroids = state.get("asteroids")

	for i = #asteroids, 1, -1 do
		local asteroid = asteroids[i]
		asteroid.x = math.wrap(asteroid.x + asteroid.vx * dt, 0, constants.W)
		asteroid.y = math.wrap(asteroid.y + asteroid.vy * dt, 0, constants.H)
		asteroid.angle = asteroid.angle + asteroid.spin * dt

		for j = #bullets, 1, -1 do
			local bullet = bullets[j]
			local radius = asteroid.r + 4
			if math.distanceSquared(asteroid, bullet) < radius * radius then
				table.remove(bullets, j)
				asteroidsUtil.destroy(asteroids, i, bullet, function()
					state.set("score", state.get("score") + math.floor(100 - asteroid.r))

					emitParticles(asteroid.x, asteroid.y, palette.gold, math.floor(asteroid.r * 0.8), 170)
					sequences.play(
						"asteroid.hit",
						asteroid.target,
						{ x = asteroid.x, y = asteroid.y, color = palette.gold }
					)
				end)
				break
			end
		end
	end

	for _, asteroid in ipairs(asteroids) do
		local radius = asteroid.r + 12
		if math.distanceSquared(asteroid, ship) < radius * radius then
			ship:hit()
			break
		end
	end

	local particles = state.get("particles")
	for i = #particles, 1, -1 do
		local p = particles[i]
		p.life = p.life - dt
		p.x = p.x + p.vx * dt
		p.y = p.y + p.vy * dt
		if p.life <= 0 then
			table.remove(particles, i)
		end
	end

	if #asteroids == 0 and not gameOver then
		state.set("wave", state.get("wave") + 1)
		state.spawn_wave()

		constants.fx:emit({ kind = "screen.flash", payload = { color = palette.green, amount = 0.22, duration = 0.18 } })
	end
end

function love.draw()
	love.graphics.clear(palette.bg)

	constants.fx:drawPost(function()
		constants.fx:push()

		background:draw()

		local bullets = state.get("bullets")

		for _, bullet in ipairs(bullets) do
			color(palette.green, math.min(1, bullet.life * 2))
			love.graphics.circle("fill", bullet.x, bullet.y, 2.5)
		end
		local asteroids = state.get("asteroids")

		for _, asteroid in ipairs(asteroids) do
			asteroidsUtil.draw(asteroid)
		end

		local particles = state.get("particles")

		for _, particle in ipairs(particles) do
			local alpha = math.max(0, particle.life / particle.maxLife)
			color(particle.color, alpha)
			love.graphics.circle("fill", particle.x, particle.y, particle.size * alpha)
		end

		ship:draw()
		constants.fx:pop()
	end)
	constants.fx:drawOverlay()

	local score = state.get("score")
	local lives = ship.lives
	local wave = state.get("wave")
	local gameOver = state.get("gameOver")

	color(palette.line)
	love.graphics.print("ASTEROIDZ", 28, 24)
	color(palette.muted)
	love.graphics.print("arrows/WASD thrust + turn  |  space shoot  |  r restart", 28, 48)
	color(palette.gold)
	love.graphics.print("score " .. score, 28, 74)
	love.graphics.print("lives " .. lives, 160, 74)
	love.graphics.print("wave " .. wave, 270, 74)

	if gameOver then
		color(palette.pink)
		love.graphics.printf("GAME OVER", 0, constants.H / 2 - 24, constants.W, "center")
		color(palette.muted)
		love.graphics.printf("press R to restart", 0, constants.H / 2 + 8, constants.W, "center")
	end
end

function love.keypressed(key)
	if key == "space" then
		ship:shoot()
	elseif key == "r" then
		resetGame()
	end
end
