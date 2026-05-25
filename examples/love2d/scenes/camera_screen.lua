local Scene = {
	title = "Camera + Screen",
	summary = "LOVE adapter emit events become camera motion, shake, flash, fade, and reset state.",
}

local feel
local feelLove
local shared
local fx
local target
local actions
local logs
local selected

local function addLog(text)
	shared.log(logs, text, 8)
end

local function defineSequences()
	feel.define("adapter.shake", {
		{ kind = "emit", event = "camera.shake", payload = { amount = 14, duration = 0.35, frequency = 34 } },
		{ kind = "emit", event = "screen.flash", payload = { amount = 0.46, duration = 0.2, color = { 1, 0.92, 0.65, 1 } } },
		{ kind = "animate", duration = 0.08, to = { scale = 1.16, rotation = -0.04 }, ease = "quadout" },
		{ kind = "animate", duration = 0.22, to = { scale = 1, rotation = 0 }, ease = "backout" },
	})

	feel.define("adapter.zoom", {
		{ kind = "emit", event = "camera.move", payload = { x = -52, y = -28, duration = 0.2, ease = "quadout" } },
		{ kind = "emit", event = "camera.zoom", payload = { scale = 1.16, duration = 0.2, ease = "quadout" } },
		{ kind = "wait", duration = 0.16 },
		{ kind = "emit", event = "camera.reset", payload = { duration = 0.35, ease = "backout" } },
	})

	feel.define("adapter.fade", {
		{ kind = "emit", event = "screen.fade", payload = { alpha = 0.5, duration = 0.45, color = { 0.06, 0.08, 0.12, 1 } } },
		{ kind = "wait", duration = 0.18 },
		{ kind = "emit", event = "screen.clear" },
	})
end

local function playAction(index)
	local action = actions[index]
	if not action then
		return
	end
	feel.play(action.sequence, target, fx:handlers({
		emit = function(event)
			addLog("emit:" .. event.kind)
		end,
	}))
end

local function hitAction(x, y)
	for i = #actions, 1, -1 do
		local action = actions[i]
		if x >= action.x and x <= action.x + action.w and y >= action.y and y <= action.y + action.h then
			return i
		end
	end
	return nil
end

function Scene.load(ctx)
	feel = ctx.feel
	feelLove = ctx.feelLove
	shared = ctx.shared
	fx = feelLove.new()
	target = feel.target({ values = { scale = 1, rotation = 0 } })
	logs = {}
	selected = 1

	local p = shared.palette
	actions = {
		{ label = "SHAKE", sequence = "adapter.shake", color = p.gold, x = 150, y = 475, w = 210, h = 70 },
		{ label = "ZOOM", sequence = "adapter.zoom", color = p.cyan, x = 414, y = 475, w = 210, h = 70 },
		{ label = "FADE", sequence = "adapter.fade", color = p.violet, x = 678, y = 475, w = 210, h = 70 },
	}

	defineSequences()
	addLog("fx:handlers handles camera/screen")
end

function Scene.update(ctx, dt)
	fx:update(dt)
end

local function drawWorld()
	local p = shared.palette
	local v = target.values

	for i = 0, 12 do
		shared.color(i % 2 == 0 and p.cyan or p.pink, 0.07)
		love.graphics.line(80 + i * 74, 150, 18 + i * 74, 430)
	end

	love.graphics.push()
	love.graphics.translate(520, 292)
	love.graphics.rotate(v.rotation or 0)
	love.graphics.scale(v.scale or 1)
	shared.color(p.panel)
	love.graphics.rectangle("fill", -110, -82, 220, 164, 16, 16)
	shared.color(p.green, 0.9)
	love.graphics.setLineWidth(5)
	love.graphics.rectangle("line", -110, -82, 220, 164, 16, 16)
	shared.color(p.text)
	love.graphics.printf("WORLD", -110, -8, 220, "center")
	love.graphics.pop()
end

function Scene.draw(ctx)
	local p = shared.palette

	shared.color(p.text)
	love.graphics.print("adapter events as draw-time state", 86, 120)
	shared.color(p.muted)
	love.graphics.print("The core only emits events; the LOVE adapter turns them into camera and overlay behavior.", 86, 144)

	fx:push()
	drawWorld()
	fx:pop()

	for i, action in ipairs(actions) do
		local hot = selected == i
		shared.color(hot and shared.mixColor(p.panel, action.color, 0.2) or p.panel)
		love.graphics.rectangle("fill", action.x, action.y, action.w, action.h, 12, 12)
		shared.color(action.color, hot and 1 or 0.55)
		love.graphics.setLineWidth(hot and 4 or 2)
		love.graphics.rectangle("line", action.x, action.y, action.w, action.h, 12, 12)
		shared.color(p.text)
		love.graphics.printf(action.label, action.x, action.y + 25, action.w, "center")
	end

	shared.drawLogs(logs, 150, 570, 738, 72)
	fx:drawOverlay()
end

function Scene.mousepressed(ctx, x, y, button)
	if button ~= 1 then
		return
	end
	local index = hitAction(x, y)
	if index then
		selected = index
		playAction(index)
	end
end

function Scene.keypressed(ctx, key)
	if key == "down" then
		selected = selected % #actions + 1
	elseif key == "up" then
		selected = ((selected - 2) % #actions) + 1
	elseif key == "return" or key == "space" then
		playAction(selected)
	end
end

return Scene
