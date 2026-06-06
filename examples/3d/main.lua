package.path = "?.lua;?/init.lua;../../?.lua;../../?/init.lua;vendor/?.lua;vendor/?/init.lua;" .. package.path

local feel = require("feel")
local feelG3d = require("feel.g3d")
local g3d = require("vendor.g3d")

local g3dfx
local shipModel
local floorModel
local leftRockModel
local rightRockModel
local rearRockModel
local ship
local camera
local leftRock
local rightRock
local rearRock
local lookTargets
local lookIndex = 0
local currentLookTarget
local time = 0
local logs = {}

local colors = {
	bg = { 0.04, 0.045, 0.06 },
	panel = { 0.08, 0.09, 0.12, 0.84 },
	text = { 0.92, 0.96, 1 },
	muted = { 0.56, 0.62, 0.72 },
	cyan = { 0.16, 0.78, 1 },
	pink = { 1, 0.27, 0.68 },
	gold = { 1, 0.74, 0.22 },
	green = { 0.24, 1, 0.58 },
}

local function log(message)
	logs[#logs + 1] = message
	while #logs > 5 do
		table.remove(logs, 1)
	end
end

local function cubeVertices(size)
	local s = (size or 1) / 2
	local vertices = {}

	local function vertex(x, y, z, u, v, nx, ny, nz)
		vertices[#vertices + 1] = { x * s, y * s, z * s, u, v, nx, ny, nz }
	end

	local function face(a, b, c, d, nx, ny, nz)
		vertex(a[1], a[2], a[3], 0, 0, nx, ny, nz)
		vertex(b[1], b[2], b[3], 1, 0, nx, ny, nz)
		vertex(c[1], c[2], c[3], 1, 1, nx, ny, nz)
		vertex(a[1], a[2], a[3], 0, 0, nx, ny, nz)
		vertex(c[1], c[2], c[3], 1, 1, nx, ny, nz)
		vertex(d[1], d[2], d[3], 0, 1, nx, ny, nz)
	end

	face({ 1, -1, -1 }, { 1, 1, -1 }, { 1, 1, 1 }, { 1, -1, 1 }, 1, 0, 0)
	face({ -1, 1, -1 }, { -1, -1, -1 }, { -1, -1, 1 }, { -1, 1, 1 }, -1, 0, 0)
	face({ -1, 1, -1 }, { 1, 1, -1 }, { 1, 1, 1 }, { -1, 1, 1 }, 0, 1, 0)
	face({ 1, -1, -1 }, { -1, -1, -1 }, { -1, -1, 1 }, { 1, -1, 1 }, 0, -1, 0)
	face({ -1, -1, 1 }, { 1, -1, 1 }, { 1, 1, 1 }, { -1, 1, 1 }, 0, 0, 1)
	face({ -1, 1, -1 }, { 1, 1, -1 }, { 1, -1, -1 }, { -1, -1, -1 }, 0, 0, -1)

	return vertices
end

local function whiteTexture()
	local imageData = love.image.newImageData(1, 1)
	imageData:setPixel(0, 0, 1, 1, 1, 1)
	local image = love.graphics.newImage(imageData)
	image:setFilter("nearest", "nearest")
	return image
end

local function setColor(color, alpha)
	love.graphics.setColor(color[1], color[2], color[3], alpha or color[4] or 1)
end

local function defineSequences()
	feel.define("ship.hit", {
		{ kind = "animate", duration = 0.06, to = { scale = 1.34, rz = 0.22 }, ease = "quadout" },
		{ kind = "animate", duration = 0.22, to = { scale = 1, rz = 0 }, ease = "backout" },
	})

	feel.define("camera.punch", {
		{ kind = "animate", duration = 0.08, to = { y = -5.15, z = 2.75 }, ease = "quadout" },
		{ kind = "animate", duration = 0.34, to = { y = -6.4, z = 3.2 }, ease = "backout" },
	})

	feel.define("rock.bounce", {
		{ kind = "animate", duration = 0.09, to = { z = 0.2, scale = 1.22 }, ease = "quadout" },
		{ kind = "animate", duration = 0.26, to = { z = -0.15, scale = 1 }, ease = "bounceout" },
	})
end

local function playImpact()
	feel.play("ship.hit", ship, { restart = true, key = "ship.hit" })
	feel.play("camera.punch", camera, { restart = true, key = "camera.punch" })
	feel.play("rock.bounce", leftRock, { restart = true, key = "left.bounce" })
	feel.play("rock.bounce", rightRock, { restart = true, key = "right.bounce" })
	feel.play("rock.bounce", rearRock, { restart = true, key = "rear.bounce" })
	log("feel.play: model wobble + camera punch")
end

local function applyLookTarget()
	if not currentLookTarget then
		return
	end

	shipModel:lookAt({
		currentLookTarget.x,
		currentLookTarget.y,
		currentLookTarget.z,
	})
end

local function faceNextTarget()
	lookIndex = (lookIndex % #lookTargets) + 1
	local target = lookTargets[lookIndex]
	currentLookTarget = target

	if target.reset then
		currentLookTarget = nil
		feel.clear(ship)
		ship.values.rx = 0.18
		ship.values.ry = 0
		ship.values.rz = 0
		ship.values.scale = 1
		g3dfx:update()
		log("look: main pose")
		return
	end

	feel.play({
		{ kind = "emit", event = "g3d.model.lookAt", payload = { name = "ship", x = target.x, y = target.y, z = target.z } },
	}, nil, g3dfx:handlers({
		emit = function(event)
			log("look: " .. target.label .. " (" .. event.kind .. ")")
		end,
	}))
end

local function resetDemo()
	feel.clear(ship)
	feel.clear(camera)
	feel.clear(leftRock)
	feel.clear(rightRock)
	feel.clear(rearRock)

	ship.values.x = 0
	ship.values.y = 0
	ship.values.z = 0.1
	ship.values.rx = 0.18
	ship.values.ry = 0
	ship.values.rz = 0
	ship.values.scale = 1

	camera.values.x = 0
	camera.values.y = -6.4
	camera.values.z = 3.2
	camera.values.tx = 0
	camera.values.ty = 0
	camera.values.tz = 0

	leftRock.values.z = -0.15
	leftRock.values.scale = 1
	rightRock.values.z = -0.1
	rightRock.values.scale = 1
	rearRock.values.z = -0.2
	rearRock.values.scale = 1

	lookIndex = 0
	currentLookTarget = nil

	g3dfx:update()
	log("reset targets")
end

function love.load()
	love.window.setTitle("feel.lua + g3d")
	love.graphics.setBackgroundColor(colors.bg)

	g3dfx = feelG3d.new(g3d)
	local texture = whiteTexture()
	local cube = cubeVertices(1)

	shipModel = g3d.newModel(cube, texture)
	floorModel = g3d.newModel(cube, texture)
	leftRockModel = g3d.newModel(cube, texture)
	rightRockModel = g3d.newModel(cube, texture)
	rearRockModel = g3d.newModel(cube, texture)

	ship = g3dfx:model("ship", shipModel, {
		values = { x = 0, y = 0, z = 0.1, rx = 0.18, ry = 0, rz = 0, scale = 1 },
	})
	g3dfx:model("floor", floorModel, {
		values = { x = 0, y = 0, z = -0.75, sx = 7.4, sy = 7.4, sz = 0.08 },
	})
	leftRock = g3dfx:model("left-rock", leftRockModel, {
		values = { x = -2.25, y = 0.7, z = -0.15, rx = 0.4, ry = 0.2, rz = 0.2, scale = 0.72 },
	})
	rightRock = g3dfx:model("right-rock", rightRockModel, {
		values = { x = 2.15, y = -0.6, z = -0.1, rx = -0.2, ry = 0.35, rz = -0.28, scale = 0.64 },
	})
	rearRock = g3dfx:model("rear-rock", rearRockModel, {
		values = { x = 0.15, y = 2.1, z = -0.2, rx = 0.1, ry = -0.25, rz = 0.45, scale = 0.58 },
	})
	camera = g3dfx:camera({
		mode = "lookAt",
		values = { x = 0, y = -6.4, z = 3.2, tx = 0, ty = 0, tz = 0 },
	})
	lookTargets = {
		{ label = "right rock", x = rightRock.values.x, y = rightRock.values.y, z = rightRock.values.z },
		{ label = "rear rock", x = rearRock.values.x, y = rearRock.values.y, z = rearRock.values.z },
		{ label = "left rock", x = leftRock.values.x, y = leftRock.values.y, z = leftRock.values.z },
		{ label = "main pose", reset = true },
	}

	defineSequences()
	log("space/click: feedback pulse")
	log("L: cycle look objectives")
end

function love.update(dt)
	time = time + dt
	ship.values.ry = math.sin(time * 0.7) * 0.24
	leftRock.values.rz = leftRock.values.rz + dt * 0.35
	rightRock.values.rz = rightRock.values.rz - dt * 0.28
	rearRock.values.rz = rearRock.values.rz + dt * 0.22

	feel.update(dt)
	g3dfx:update()
	applyLookTarget()
end

local function drawScene()
	if love.graphics.setDepthMode then
		love.graphics.setDepthMode("lequal", true)
	end

	setColor(colors.green)
	floorModel:draw()
	setColor(colors.cyan)
	shipModel:draw()
	setColor(colors.pink)
	leftRockModel:draw()
	setColor(colors.gold)
	rightRockModel:draw()
	setColor(colors.green)
	rearRockModel:draw()

	if love.graphics.setDepthMode then
		love.graphics.setDepthMode()
	end
	love.graphics.setColor(1, 1, 1, 1)
end

local function drawOverlay()
	local active = feel.active()
	local width = love.graphics.getWidth()
	local height = love.graphics.getHeight()

	setColor(colors.panel)
	love.graphics.rectangle("fill", 24, 24, width - 48, 118, 8, 8)
	setColor(colors.text)
	love.graphics.print("feel.lua + groverburger/g3d", 44, 42)
	setColor(colors.muted)
	love.graphics.print(
		"SPACE/click plays target animations. L cycles g3d.model.lookAt objectives. g3dfx:update() applies values.",
		44,
		68
	)
	love.graphics.print("Active runners: " .. tostring(#active), 44, 94)

	setColor(colors.panel)
	love.graphics.rectangle("fill", 24, height - 132, width - 48, 104, 8, 8)
	for index, message in ipairs(logs) do
		setColor(index == #logs and colors.text or colors.muted)
		love.graphics.print(message, 44, height - 116 + (index - 1) * 18)
	end
end

function love.draw()
	love.graphics.clear(colors.bg)
	drawScene()
	drawOverlay()
end

function love.mousepressed(_, _, button)
	if button == 1 then
		playImpact()
	end
end

function love.keypressed(key)
	if key == "space" or key == "return" then
		playImpact()
	elseif key == "l" then
		faceNextTarget()
	elseif key == "r" then
		resetDemo()
	elseif key == "escape" then
		love.event.quit()
	end
end

function love.resize(width, height)
	g3dfx:emit({ kind = "g3d.camera.resize", payload = { width = width, height = height } })
end
