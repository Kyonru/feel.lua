package.path = "?.lua;?/init.lua;../../?.lua;../../?/init.lua;vendor/?.lua;vendor/?/init.lua;" .. package.path

local feel = require("feel")
local feelLove = require("feel.love")
local feelMenori = require("feel.menori")
local createFeedbacks = require("feedbacks")
local menori = require("vendor.menori")

local unpack = table.unpack or unpack

local fx
local menorifx
local Feedbacks
local scene
local rootNode
local camera
local environment
local whiteImage
local sceneCanvas
local sceneDepthCanvas
local sceneCanvasWidth
local sceneCanvasHeight
local coreNode
local floorNode
local leftNode
local rightNode
local satelliteRigNode
local satelliteNode
local core
local leftObelisk
local rightObelisk
local satellite
local satelliteOrbit
local cameraTarget
local satelliteAnimation
local time = 0
local timeMode = "normal"
local orbitAction = "orbit"
local logs = {}

local colors = {
	bg = { 0.035, 0.04, 0.052 },
	panel = { 0.07, 0.08, 0.105, 0.86 },
	text = { 0.93, 0.97, 1 },
	muted = { 0.57, 0.65, 0.76 },
	cyan = { 0.12, 0.82, 1 },
	pink = { 1, 0.28, 0.58 },
	gold = { 1, 0.72, 0.2 },
	green = { 0.32, 1, 0.56 },
}

local timeButtons = {
	{ mode = "slow", label = "SLOW", color = colors.gold, x = 0, y = 0, w = 96, h = 30 },
	{ mode = "pause", label = "PAUSE", color = colors.pink, x = 0, y = 0, w = 112, h = 30 },
}

local function log(message)
	logs[#logs + 1] = message
	while #logs > 6 do
		table.remove(logs, 1)
	end
end

local function setColor(color, alpha)
	love.graphics.setColor(color[1], color[2], color[3], alpha or color[4] or 1)
end

local function whiteTexture()
	local imageData = love.image.newImageData(1, 1)
	imageData:setPixel(0, 0, 1, 1, 1, 1)
	local image = love.graphics.newImage(imageData)
	image:setFilter("nearest", "nearest")
	return image
end

local function material(name, color)
	local mat = menori.Material({ name = name })
	mat.main_texture = whiteImage
	mat:set("baseColor", color)
	mat:set("emissiveTexture", whiteImage)
	mat:set("emissiveFactor", { 0, 0, 0 })
	mat:set("alphaCutoff", 0)
	mat:set("opaque", true)
	return mat
end

local function modelNode(name, mesh, color, parent)
	local node = menori.ModelNode(mesh, material(name .. ".material", color))
	node.name = name
	local attachParent = parent or rootNode
	attachParent:attach(node)
	return node
end

local function newDepthCanvas(width, height)
	local formats = { "depth24", "depth16", "depth32f" }
	for _, format in ipairs(formats) do
		local ok, canvas = pcall(love.graphics.newCanvas, width, height, {
			format = format,
			readable = false,
		})
		if ok and canvas then
			return canvas
		end
	end
	return nil
end

local function ensureSceneCanvas()
	local width, height = love.graphics.getDimensions()
	if sceneCanvas and sceneCanvasWidth == width and sceneCanvasHeight == height then
		return true
	end

	sceneCanvasWidth = width
	sceneCanvasHeight = height
	sceneCanvas = love.graphics.newCanvas(width, height)
	sceneDepthCanvas = newDepthCanvas(width, height)
	return sceneCanvas ~= nil
end

local function clearSceneCanvas()
	local ok = pcall(love.graphics.clear, colors.bg[1], colors.bg[2], colors.bg[3], 1, true, true)
	if not ok then
		love.graphics.clear(colors.bg)
	end
end

local function layoutTimeButtons(width)
	local gap = 10
	local x = width - 44
	for index = #timeButtons, 1, -1 do
		local button = timeButtons[index]
		x = x - button.w
		button.x = x
		button.y = 104
		x = x - gap
	end
end

local function buttonContains(button, x, y)
	return x >= button.x and x <= button.x + button.w and y >= button.y and y <= button.y + button.h
end

local function timeButtonLabel(button)
	if button.mode == "slow" and timeMode == "slow" then
		return "NORMAL"
	end
	if button.mode == "pause" and timeMode == "pause" then
		return "RESUME"
	end
	return button.label
end

local function setTimeMode(mode)
	if not Feedbacks then
		return
	end

	timeMode = mode
	Feedbacks.play("time." .. mode, nil, {
		target = Feedbacks.timeTarget(),
		restart = true,
		key = "demo.time",
	})

	if mode == "slow" then
		log("time: slow motion")
	elseif mode == "pause" then
		log("time: paused")
	else
		log("time: normal")
	end
end

local function toggleTimeMode(mode)
	if mode == "slow" then
		setTimeMode(timeMode == "slow" and "normal" or "slow")
	elseif mode == "pause" then
		setTimeMode(timeMode == "pause" and "normal" or "pause")
	end
end

local function clickTimeButton(x, y)
	layoutTimeButtons(love.graphics.getWidth())
	for _, button in ipairs(timeButtons) do
		if buttonContains(button, x, y) then
			toggleTimeMode(button.mode)
			return true
		end
	end
	return false
end

local function createSatelliteAnimation(node)
	local animation = {
		accumulator = 0,
		action = "orbit",
		actions = {
			orbit = { radius = 1.7, height = 0.58, speed = 1.35 },
			wide = { radius = 2.35, height = 0.34, speed = 0.82 },
		},
	}

	function animation:set_action_by_name(name)
		if self.actions[name] then
			self.action = name
		end
	end

	function animation:set_action(index)
		self.action = index == 2 and "wide" or "orbit"
	end

	function animation:update(dt)
		self.accumulator = self.accumulator + dt
		local action = self.actions[self.action] or self.actions.orbit
		local phase = self.accumulator * action.speed
		local x = math.cos(phase) * action.radius
		local z = math.sin(phase) * action.radius
		local y = action.height + math.sin(phase * 2.4) * 0.16

		node:set_position(x, y, z)
		node:set_rotation(menori.ml.quat.from_euler_angles(phase, phase * 0.45, phase * 0.2))
	end

	return animation
end

local function createSceneObjects()
	scene = menori.Scene()
	rootNode = menori.Node("root")

	local width, height = love.graphics.getDimensions()
	camera = menori.PerspectiveCamera(62, width / height, 0.2, 256)
	environment = menori.Environment(camera)

	fx = feelLove.new()
	menorifx = feelMenori.new(menori, { environment = environment })

	floorNode = modelNode("floor", menori.Box(7.4, 0.08, 7.4), { 0.08, 0.1, 0.12, 1 })
	coreNode = modelNode("core", menori.Box(0.92, 0.92, 0.92), { 0.12, 0.82, 1, 1 })
	leftNode = modelNode("left-obelisk", menori.Box(0.46, 1.35, 0.46), { 1, 0.28, 0.58, 1 })
	rightNode = modelNode("right-obelisk", menori.Box(0.5, 1.15, 0.5), { 1, 0.72, 0.2, 1 })
	satelliteRigNode = menori.Node("satellite-rig")
	rootNode:attach(satelliteRigNode)
	satelliteNode = modelNode("satellite", menori.Box(0.34, 0.34, 0.34), { 0.32, 1, 0.56, 1 }, satelliteRigNode)
	floorNode.layer = 0
	coreNode.layer = 1
	leftNode.layer = 1
	rightNode.layer = 1
	satelliteNode.layer = 2

	menorifx:node("floor", floorNode, {
		values = { x = 0, y = -0.72, z = 0, scale = 1 },
	})
	core = menorifx:node("core", coreNode, {
		values = { x = 0, y = 0.02, z = 0, rx = 0.08, ry = 0, rz = 0, scale = 1 },
	})
	leftObelisk = menorifx:node("left-obelisk", leftNode, {
		values = { x = -2.05, y = -0.05, z = -0.75, rx = 0.12, ry = -0.28, rz = 0.08, scale = 1 },
	})
	rightObelisk = menorifx:node("right-obelisk", rightNode, {
		values = { x = 2.05, y = -0.1, z = 0.85, rx = -0.1, ry = 0.34, rz = -0.12, scale = 1 },
	})
	satellite = menorifx:node("satellite", satelliteRigNode, {
		values = { scale = 1 },
	})
	cameraTarget = menorifx:camera(environment, {
		mode = "orbit",
		fov = 62,
		aspect = width / height,
		near = 0.2,
		far = 256,
		values = {
			tx = 0,
			ty = 0.22,
			tz = 0,
			distance = 5.6,
			yaw = -0.42,
			pitch = math.rad(14),
		},
	})

	menorifx:uniform("core.tint", coreNode.material, "baseColor", {
		keys = { "r", "g", "b", "a" },
		values = { r = 0.12, g = 0.82, b = 1, a = 1 },
	})
	menorifx:uniform("left.tint", leftNode.material, "baseColor", {
		keys = { "r", "g", "b", "a" },
		values = { r = 1, g = 0.28, b = 0.58, a = 1 },
	})
	menorifx:uniform("right.tint", rightNode.material, "baseColor", {
		keys = { "r", "g", "b", "a" },
		values = { r = 1, g = 0.72, b = 0.2, a = 1 },
	})
	menorifx:uniform("satellite.tint", satelliteNode.material, "baseColor", {
		keys = { "r", "g", "b", "a" },
		values = { r = 0.32, g = 1, b = 0.56, a = 1 },
	})

	satelliteAnimation = createSatelliteAnimation(satelliteNode)
	satelliteAnimation:update(0)
	satelliteOrbit = menorifx:animation("satellite-orbit", satelliteAnimation, {
		action = "orbit",
		values = { speed = 1, playing = 1 },
	})

	Feedbacks = createFeedbacks({
		fx = fx,
		menorifx = menorifx,
		colors = colors,
		log = log,
	})
end

local function resetDemo()
	feel.clear(core)
	feel.clear(leftObelisk)
	feel.clear(rightObelisk)
	feel.clear(satellite)
	feel.clear(satelliteOrbit)
	feel.clear(cameraTarget)

	core.values.x = 0
	core.values.y = 0.02
	core.values.z = 0
	core.values.rx = 0.08
	core.values.ry = 0
	core.values.rz = 0
	core.values.scale = 1

	leftObelisk.values.x = -2.05
	leftObelisk.values.y = -0.05
	leftObelisk.values.z = -0.75
	leftObelisk.values.scale = 1
	rightObelisk.values.x = 2.05
	rightObelisk.values.y = -0.1
	rightObelisk.values.z = 0.85
	rightObelisk.values.scale = 1
	satellite.values.scale = 1
	satelliteOrbit.values.speed = 1
	satelliteOrbit.values.playing = 1

	cameraTarget.values.tx = 0
	cameraTarget.values.ty = 0.22
	cameraTarget.values.tz = 0
	cameraTarget.values.distance = 5.6
	cameraTarget.values.yaw = -0.42
	cameraTarget.values.pitch = math.rad(14)

	orbitAction = "orbit"
	satelliteAnimation.accumulator = 0
	satelliteAnimation:set_action_by_name("orbit")
	satelliteAnimation:update(0)

	menorifx:update(0)
	setTimeMode("normal")
	Feedbacks.play("demo.reset", nil, { restart = true, key = "demo.reset" })
	log("reset targets")
end

local function playImpact()
	Feedbacks.play("hit.heavy", nil, { restart = true, key = "hit.heavy" })
	log("Feedbacks.play: hit.heavy")
end

local function boostOrbit()
	Feedbacks.play("orbit.boost", nil, { restart = true, key = "orbit.boost" })
	log("animation: speed boost")
end

local function toggleOrbitPause()
	if satelliteOrbit.values.playing == 0 then
		Feedbacks.play("orbit.resume", nil, { restart = true, key = "orbit.pause" })
		log("animation: resume")
	else
		Feedbacks.play("orbit.pause", nil, { restart = true, key = "orbit.pause" })
		log("animation: pause")
	end
end

local function seekOrbit()
	local targetTime = math.random() * 8
	Feedbacks.play("orbit.seek", { time = targetTime }, { restart = true, key = "orbit.seek" })
	log("animation: seek " .. string.format("%.2f", targetTime))
end

local function switchOrbitAction()
	orbitAction = orbitAction == "orbit" and "wide" or "orbit"
	Feedbacks.play("orbit.action", { action = orbitAction }, { restart = true, key = "orbit.action" })
	log("animation action: " .. orbitAction)
end

local function playPalettePulse()
	Feedbacks.play("palette.hot", nil, { restart = true, key = "palette.hot" })
	log("uniforms: warm pulse")
end

function love.load()
	love.window.setTitle("feel.lua + Menori")
	love.graphics.setBackgroundColor(colors.bg)
	math.randomseed(os.time())
	whiteImage = whiteTexture()
	createSceneObjects()
	log("space/click: Menori feedback")
	log("O action, F speed, S seek, A pause")
	log("U uniforms, P post, 1 slow, 2 pause")
end

function love.update(dt)
	local gameDt = dt * (Feedbacks and Feedbacks.timeScale() or 1)
	time = time + gameDt

	core.values.ry = math.sin(time * 0.75) * 0.42
	core.values.rz = math.cos(time * 0.5) * 0.16
	leftObelisk.values.ry = leftObelisk.values.ry + gameDt * 0.36
	rightObelisk.values.ry = rightObelisk.values.ry - gameDt * 0.32
	cameraTarget.values.yaw = cameraTarget.values.yaw + gameDt * 0.12

	feel.update(dt)
	menorifx:update(gameDt)
	scene:update_nodes(rootNode, environment)
	fx:update(dt)
end

local function drawScene()
	scene:render_nodes(rootNode, environment, {
		node_sort_comp = menori.Scene.layer_comp,
	})
end

local function drawSceneToCanvas()
	if not ensureSceneCanvas() then
		return nil
	end

	love.graphics.push("all")
	if sceneDepthCanvas then
		love.graphics.setCanvas({
			sceneCanvas,
			depthstencil = sceneDepthCanvas,
		})
	else
		love.graphics.setCanvas(sceneCanvas)
	end
	clearSceneCanvas()
	drawScene()
	love.graphics.setCanvas()
	love.graphics.pop()

	return sceneCanvas
end

local function drawOverlay()
	local active = feel.active()
	local width = love.graphics.getWidth()
	local height = love.graphics.getHeight()
	layoutTimeButtons(width)

	setColor(colors.panel)
	love.graphics.rectangle("fill", 24, 24, width - 48, 162, 8, 8)
	setColor(colors.text)
	love.graphics.print("feel.lua + rozenmad/Menori", 44, 42)
	setColor(colors.muted)
	love.graphics.print(
		"SPACE/click hits. O action. F speed. S seek. A pause. U uniforms. P focus. 1 slow. 2 pause.",
		44,
		68
	)
	love.graphics.print("Active runners: " .. tostring(#active), 44, 96)
	love.graphics.print("Time scale: " .. string.format("%.2f", Feedbacks and Feedbacks.timeScale() or 1), 220, 96)
	love.graphics.print("Animation: " .. orbitAction .. " / speed " .. string.format("%.2f", satelliteOrbit.values.speed or 1), 404, 96)

	for _, button in ipairs(timeButtons) do
		local buttonActive = timeMode == button.mode
		setColor(buttonActive and button.color or colors.panel, buttonActive and 0.86 or 0.72)
		love.graphics.rectangle("fill", button.x, button.y, button.w, button.h, 6, 6)
		setColor(buttonActive and colors.text or button.color)
		love.graphics.rectangle("line", button.x, button.y, button.w, button.h, 6, 6)
		love.graphics.printf(timeButtonLabel(button), button.x, button.y + 8, button.w, "center")
	end

	setColor(colors.panel)
	love.graphics.rectangle("fill", 24, height - 146, width - 48, 118, 8, 8)
	for index, message in ipairs(logs) do
		setColor(index == #logs and colors.text or colors.muted)
		love.graphics.print(message, 44, height - 132 + (index - 1) * 17)
	end
end

function love.draw()
	local renderedScene = drawSceneToCanvas()
	fx:drawPost(function()
		love.graphics.clear(colors.bg)
		if renderedScene then
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.draw(renderedScene, 0, 0)
		else
			drawScene()
		end
	end)
	fx:drawOverlay()
	drawOverlay()
end

function love.mousepressed(x, y, button)
	if button == 1 then
		if clickTimeButton(x, y) then
			return
		end
		playImpact()
	end
end

function love.keypressed(key)
	if key == "space" or key == "return" then
		playImpact()
	elseif key == "o" then
		switchOrbitAction()
	elseif key == "f" then
		boostOrbit()
	elseif key == "s" then
		seekOrbit()
	elseif key == "a" then
		toggleOrbitPause()
	elseif key == "u" then
		playPalettePulse()
	elseif key == "p" then
		Feedbacks.play("post.focus", nil, { restart = true, key = "post.focus" })
		log("post: focus grade + vignette")
	elseif key == "c" then
		Feedbacks.play("post.clear", nil, { restart = true, key = "post.clear" })
		log("post: clear")
	elseif key == "1" then
		toggleTimeMode("slow")
	elseif key == "2" then
		toggleTimeMode("pause")
	elseif key == "r" then
		resetDemo()
	elseif key == "escape" then
		love.event.quit()
	end
end

function love.resize(width, height)
	sceneCanvas = nil
	sceneDepthCanvas = nil
	if cameraTarget then
		cameraTarget.values.aspect = width / height
		menorifx:update(0)
	end
end
