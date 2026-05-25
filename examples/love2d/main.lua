package.path = "?.lua;?/init.lua;../../?.lua;../../?/init.lua;" .. package.path

local feel = require("feel")
local feelLove = require("feel.love")
local shared = require("shared")

local scenes = {
	require("scenes.feedback_stack"),
	require("scenes.sound_controls"),
	require("scenes.particles"),
	require("scenes.shaders"),
	require("scenes.haptics"),
	require("scenes.camera_screen"),
}

local current = 1
local scene
local W, H = 1040, 680

local ctx = {
	feel = feel,
	feelLove = feelLove,
	shared = shared,
	width = W,
	height = H,
}

local function loadScene(index)
	if scene and scene.unload then
		scene.unload(ctx)
	end

	feel.clear()
	current = ((index - 1) % #scenes) + 1
	scene = scenes[current]
	if scene.load then
		scene.load(ctx)
	end
end

local function drawChrome()
	local p = shared.palette
	shared.color(p.text)
	love.graphics.print("feel.lua", 64, 38)
	shared.color(p.muted)
	love.graphics.print(string.format("%d / %d", current, #scenes), 64, 62)

	shared.color(p.text)
	love.graphics.print("<", W - 144, 42)
	love.graphics.print(">", W - 74, 42)

	shared.color(p.text)
	love.graphics.printf(scene.title or "Example", 0, 40, W, "center")
	shared.color(p.muted)
	love.graphics.printf(scene.summary or "", 0, 64, W, "center")
end

function love.load()
	love.window.setMode(W, H, { resizable = true, minwidth = 760, minheight = 520 })
	love.window.setTitle("feel.lua - showcase")
	math.randomseed(os.time())
	loadScene(1)
end

function love.update(dt)
	feel.update(dt)
	if scene and scene.update then
		scene.update(ctx, dt)
	end
end

function love.draw()
	shared.clear()
	if scene and scene.draw then
		scene.draw(ctx)
	end
	drawChrome()
end

function love.mousemoved(x, y)
	if scene and scene.mousemoved then
		scene.mousemoved(ctx, x, y)
	end
end

function love.mousepressed(x, y, button)
	if scene and scene.mousepressed then
		scene.mousepressed(ctx, x, y, button)
	end
end

function love.mousereleased(x, y, button)
	if scene and scene.mousereleased then
		scene.mousereleased(ctx, x, y, button)
	end
end

function love.keypressed(key)
	if key == "right" then
		loadScene(current + 1)
	elseif key == "left" then
		loadScene(current - 1)
	elseif key == "r" then
		loadScene(current)
	elseif scene and scene.keypressed then
		scene.keypressed(ctx, key)
	end
end
