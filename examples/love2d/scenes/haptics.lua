local Scene = {
	title = "Haptics",
	summary = "Cross-platform haptic events drive controller rumble and mobile vibration from one recipe.",
}

local feel
local feelLove
local shared
local fx
local actions
local logs
local selected
local target
local joysticks

local function addLog(text)
	shared.log(logs, text, 8)
end

local function pulse(color)
	target.color = color
	target.values.scale = 0.7
	target.values.opacity = 1
	feel.play({
		{ kind = "animate", duration = 0.08, to = { scale = 1.22, opacity = 0.9 }, ease = "quadout" },
		{ kind = "animate", duration = 0.2, to = { scale = 1, opacity = 1 }, ease = "backout" },
	}, target)
end

local function defineSequences()
	feel.define("haptic.light", {
		{ kind = "emit", event = "haptic.play", payload = { value = 0.35, duration = 0.12 } },
		{ kind = "audio", cue = "tap" },
		{ kind = "emit", event = "screen.flash", payload = { amount = 0.14, duration = 0.1, color = { 0.1, 0.82, 1, 1 } } },
		{
			kind = "callback",
			callback = function()
				pulse(shared.palette.cyan)
			end,
		},
	})

	feel.define("haptic.split", {
		{ kind = "emit", event = "haptic.play", payload = { left = 0.15, right = 0.9, duration = 0.22 } },
		{ kind = "audio", cue = "split" },
		{ kind = "emit", event = "camera.shake", payload = { amount = 4, duration = 0.16 } },
		{
			kind = "callback",
			callback = function()
				pulse(shared.palette.violet)
			end,
		},
	})

	feel.define("haptic.player", {
		{ kind = "emit", event = "haptic.play", payload = { name = "p1", value = 0.7, duration = 0.18, system = false } },
		{ kind = "audio", cue = "player" },
		{ kind = "emit", event = "screen.flash", payload = { amount = 0.18, duration = 0.12, color = { 1, 0.72, 0.18, 1 } } },
		{
			kind = "callback",
			callback = function()
				pulse(shared.palette.gold)
			end,
		},
	})

	feel.define("haptic.stop", {
		{ kind = "emit", event = "haptic.stop", payload = {} },
		{ kind = "emit", event = "screen.clear", payload = {} },
	})

	feel.define("haptic.system", {
		{ kind = "emit", event = "haptic.vibrate", payload = { duration = 0.2 } },
		{ kind = "audio", cue = "system" },
		{
			kind = "callback",
			callback = function()
				pulse(shared.palette.green)
			end,
		},
	})
end

local function playAction(index)
	local action = actions[index]
	if not action then
		return
	end

	feel.play(action.sequence, nil, fx:handlers({
		emit = function(event)
			addLog("emit:" .. event.kind)
			if event.kind == "haptic.play" and event.payload and event.payload.name and not fx.hapticEntries[event.payload.name] then
				addLog("missing target:" .. event.payload.name)
			elseif event.kind == "haptic.play" and #joysticks == 0 then
				addLog("no registered joystick")
			end
		end,
		audio = function(event)
			addLog("audio:" .. event.cue)
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

local function loadJoysticks()
	joysticks = {}
	if not love.joystick or not love.joystick.getJoysticks then
		return
	end

	for index, joystick in ipairs(love.joystick.getJoysticks()) do
		local name = "p" .. index
		fx:haptic(name, joystick)
		joysticks[#joysticks + 1] = name
	end
end

function Scene.load(ctx)
	feel = ctx.feel
	feelLove = ctx.feelLove
	shared = ctx.shared
	fx = feelLove.new()
	logs = {}
	selected = 1
	target = feel.target({ values = { scale = 1, opacity = 1 } })
	target.color = shared.palette.cyan

	loadJoysticks()
	fx:sounds({
		tap = shared.makeTone(420, 0.06, 0.1),
		split = shared.makeTone(640, 0.08, 0.12),
		player = shared.makeTone(780, 0.08, 0.12),
		system = shared.makeTone(920, 0.08, 0.1),
	})

	local p = shared.palette
	actions = {
		{ label = "VALUE", sequence = "haptic.light", color = p.cyan, x = 108, y = 486, w = 154, h = 64 },
		{ label = "L/R", sequence = "haptic.split", color = p.violet, x = 284, y = 486, w = 154, h = 64 },
		{ label = "P1", sequence = "haptic.player", color = p.gold, x = 460, y = 486, w = 154, h = 64 },
		{ label = "STOP", sequence = "haptic.stop", color = p.pink, x = 636, y = 486, w = 154, h = 64 },
		{ label = "SYSTEM", sequence = "haptic.system", color = p.green, x = 812, y = 486, w = 154, h = 64 },
	}

	defineSequences()
	addLog(#joysticks > 0 and ("registered " .. #joysticks .. " haptic target(s)") or "no joystick found")
end

function Scene.update(ctx, dt)
	fx:update(dt)
end

local function drawTarget()
	local p = shared.palette
	local v = target.values

	shared.panel(108, 174, 824, 248, 0.82)
	love.graphics.push()
	love.graphics.translate(520, 298)
	love.graphics.scale(v.scale or 1)
	shared.color(target.color or p.cyan, v.opacity or 1)
	love.graphics.setLineWidth(6)
	love.graphics.circle("line", 0, 0, 74)
	love.graphics.circle("line", 0, 0, 32)
	shared.color(target.color or p.cyan, 0.18)
	love.graphics.circle("fill", 0, 0, 84)
	love.graphics.pop()

	shared.color(p.text)
	love.graphics.printf("haptic.play: value, left/right, or named player", 108, 212, 824, "center")
	shared.color(p.muted)
	love.graphics.printf("Default haptic.play also calls love.system.vibrate(duration) for mobile devices.", 108, 386, 824, "center")
end

local function drawTargets()
	local p = shared.palette
	shared.color(p.muted)
	love.graphics.print("registered targets", 126, 438)
	for i = 1, 4 do
		local name = joysticks[i]
		local x = 290 + (i - 1) * 74
		shared.color(name and p.green or p.panel)
		love.graphics.rectangle("fill", x, 432, 52, 24, 6, 6)
		shared.color(name and p.bg or p.muted)
		love.graphics.printf(name or "-", x, 438, 52, "center")
	end
end

function Scene.draw(ctx)
	local p = shared.palette

	shared.color(p.text)
	love.graphics.print("haptics as adapter events", 86, 120)
	shared.color(p.muted)
	love.graphics.print("One recipe can rumble registered joysticks and vibrate mobile devices.", 86, 144)

	fx:push()
	drawTarget()
	fx:pop()
	drawTargets()
	fx:drawOverlay()

	for i, action in ipairs(actions) do
		local hot = selected == i
		shared.color(hot and shared.mixColor(p.panel, action.color, 0.2) or p.panel)
		love.graphics.rectangle("fill", action.x, action.y, action.w, action.h, 10, 10)
		shared.color(action.color, hot and 1 or 0.55)
		love.graphics.setLineWidth(hot and 4 or 2)
		love.graphics.rectangle("line", action.x, action.y, action.w, action.h, 10, 10)
		shared.color(p.text)
		love.graphics.printf(action.label, action.x, action.y + action.h / 2 - 8, action.w, "center")
	end

	shared.drawLogs(logs, 108, 584, 824, 76)
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
