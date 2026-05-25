local Scene = {
	title = "Feedback Stack",
	summary = "Animation, audio, emit events, callbacks, particles, beams, shake, and flash in one recipe runner.",
}

local feel
local feelLove
local shared
local fx
local buttons
local beams
local logs
local pointer
local selected
local screen

local function addLog(text)
	shared.log(logs, text, 8)
end

local function buttonCenter(button)
	return button.x + button.w / 2, button.y + button.h / 2
end

local function effectOrigin(button, origin)
	if origin and origin.x and origin.y then
		return origin.x, origin.y
	end
	return buttonCenter(button)
end

local function emitBeam(button, origin)
	local x, y = effectOrigin(button, origin)
	beams[#beams + 1] = {
		x = x,
		y = y,
		life = 0.28,
		maxLife = 0.28,
		color = button.color,
	}
end

local function targetButton(label, subtitle, x, y, color, sequence)
	local target = feel.target({
		label = label,
		values = { opacity = 1, scale = 1, x = 0, y = 0, rotation = 0 },
	})
	local button = {
		label = label,
		subtitle = subtitle,
		x = x,
		y = y,
		w = 245,
		h = 92,
		color = color,
		target = target,
		sequence = sequence,
		hovered = false,
		pressed = false,
	}
	buttons[#buttons + 1] = button
	return button
end

local function playSequence(button, name, trigger, origin)
	local handlers = fx:handlers({
		trigger = trigger,
		emit = function(event)
			if event.kind == "beam" then
				emitBeam(button)
			elseif event.kind == "heat" then
				screen.heat = math.max(screen.heat, event.payload.amount)
			end
			addLog("emit:" .. event.kind .. " trigger=" .. tostring(event.trigger))
		end,
		audio = function(event)
			addLog("audio:" .. event.cue)
		end,
		markDirty = function() end,
	})

	handlers.emit = function(event, ctx)
		if event.kind and event.kind:match("^particle%.") and event.payload and event.payload.fromButton then
			event.payload.x, event.payload.y = effectOrigin(button, origin)
		end
		fx:emit(event, ctx)
		if event.kind == "beam" then
			emitBeam(button, origin)
		elseif event.kind == "heat" then
			screen.heat = math.max(screen.heat, event.payload.amount)
		end
		addLog("emit:" .. event.kind .. " trigger=" .. tostring(event.trigger))
	end

	feel.play(name, button.target, handlers)
end

local function defineSequences()
	feel.define("button.hover", {
		{ kind = "animate", duration = 0.1, to = { scale = 1.035, y = -4 }, ease = "quadout" },
	})

	feel.define("button.idle", {
		{ kind = "animate", duration = 0.16, to = { scale = 1, x = 0, y = 0, rotation = 0, opacity = 1 }, ease = "quadout" },
	})

	feel.define("button.press", {
		{ kind = "audio", cue = "press" },
		{ kind = "emit", event = "particle.start", payload = { name = "press", fromButton = true } },
		{ kind = "emit", event = "particle.emit", payload = { name = "press", count = 10, fromButton = true } },
		{ kind = "emit", event = "particle.stop", payload = { name = "press" } },
		{ kind = "animate", duration = 0.04, to = { scaleX = 1.07, scaleY = 0.9, y = 3 }, ease = "quadout" },
	})

	feel.define("launch.perfect", {
		{ kind = "audio", cue = "perfect" },
		{ kind = "emit", event = "particle.start", payload = { name = "perfect", fromButton = true } },
		{ kind = "emit", event = "particle.emit", payload = { name = "perfect", count = 52, fromButton = true } },
		{ kind = "emit", event = "particle.stop", payload = { name = "perfect" } },
		{ kind = "emit", event = "beam", payload = {} },
		{ kind = "emit", event = "screen.flash", payload = { amount = 0.58 } },
		{ kind = "animate", duration = 0.07, to = { scale = 1.18, rotation = -0.035, y = -10 }, ease = "quadout" },
		{ kind = "animate", duration = 0.2, to = { scale = 1, scaleX = 1, scaleY = 1, rotation = 0, y = 0 }, ease = "backout" },
		{
			kind = "callback",
			callback = function()
				screen.combo = screen.combo + 1
				addLog("callback:combo=" .. screen.combo)
			end,
		},
	})

	feel.define("launch.overload", {
		{ kind = "audio", cue = "overload" },
		{ kind = "emit", event = "camera.shake", payload = { amount = 12, duration = 0.3 } },
		{ kind = "emit", event = "particle.start", payload = { name = "overload", fromButton = true } },
		{ kind = "emit", event = "particle.emit", payload = { name = "overload", count = 36, fromButton = true } },
		{ kind = "emit", event = "particle.stop", payload = { name = "overload" } },
		{ kind = "emit", event = "heat", payload = { amount = 0.75 } },
		{ kind = "animate", duration = 0.04, to = { x = -9, opacity = 0.78 }, ease = "quadout" },
		{ kind = "animate", duration = 0.05, to = { x = 11, rotation = 0.04 }, ease = "quadout" },
		{ kind = "animate", duration = 0.07, to = { x = -5, rotation = -0.025 }, ease = "quadout" },
		{ kind = "animate", duration = 0.16, to = { x = 0, rotation = 0, opacity = 1, scaleX = 1, scaleY = 1 }, ease = "backout" },
	})

	feel.define("launch.phase", {
		{ kind = "audio", cue = "phase" },
		{ kind = "emit", event = "beam", payload = {} },
		{ kind = "animate", duration = 0.08, to = { opacity = 0.35, x = 34, scale = 0.94 }, ease = "quadout" },
		{ kind = "animate", duration = 0.1, to = { opacity = 1, x = -16, scale = 1.08 }, ease = "quadout" },
		{ kind = "emit", event = "particle.start", payload = { name = "phase", fromButton = true } },
		{ kind = "emit", event = "particle.emit", payload = { name = "phase", count = 28, fromButton = true } },
		{ kind = "emit", event = "particle.stop", payload = { name = "phase" } },
		{ kind = "animate", duration = 0.18, to = { x = 0, scale = 1 }, ease = "backout" },
	})

	feel.define("launch.warning", {
		{ kind = "audio", cue = "warn" },
		{ kind = "emit", event = "camera.shake", payload = { amount = 6, duration = 0.18 } },
		{ kind = "animate", duration = 0.055, to = { scaleX = 0.96, scaleY = 1.08, y = -7 }, ease = "quadout" },
		{ kind = "emit", event = "particle.start", payload = { name = "warning", fromButton = true } },
		{ kind = "emit", event = "particle.emit", payload = { name = "warning", count = 24, fromButton = true } },
		{ kind = "emit", event = "particle.stop", payload = { name = "warning" } },
		{ kind = "animate", duration = 0.16, to = { scaleX = 1, scaleY = 1, y = 0 }, ease = "backout" },
	})
end

local function resetButtons()
	local p = shared.palette
	buttons = {}
	targetButton("PERFECT", "burst + beam + callback", 126, 232, p.cyan, "launch.perfect")
	targetButton("OVERLOAD", "shake + heat + multi-step jitter", 397, 232, p.pink, "launch.overload")
	targetButton("PHASE", "fade dash + particle return", 668, 232, p.violet, "launch.phase")
	targetButton("WARNING", "squash + warning burst", 397, 352, p.gold, "launch.warning")
end

local function hitButton(x, y)
	for i = #buttons, 1, -1 do
		local b = buttons[i]
		if x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
			return b, i
		end
	end
	return nil, nil
end

function Scene.load(ctx)
	feel = ctx.feel
	feelLove = ctx.feelLove
	shared = ctx.shared
	fx = feelLove.new()
	beams = {}
	logs = {}
	pointer = { x = 0, y = 0 }
	selected = 1
	screen = { heat = 0, combo = 0 }

	fx:sounds({
		press = shared.makeTone(420, 0.045, 0.12),
		perfect = shared.makeTone(960, 0.12, 0.2),
		overload = shared.makeTone(150, 0.22, 0.24),
		phase = shared.makeTone(680, 0.14, 0.18),
		warn = shared.makeTone(260, 0.16, 0.18),
	})
	fx:particles({
		{ name = "press", system = shared.makeParticleSystem(shared.palette.green, { speedMin = 80, speedMax = 180, gravity = 180, lifeMin = 0.18, lifeMax = 0.42, sizeStart = 1.3 }) },
		{ name = "perfect", system = shared.makeParticleSystem(shared.palette.cyan, { speedMax = 310, gravity = 330 }) },
		{ name = "overload", system = shared.makeParticleSystem(shared.palette.pink, { buffer = 384, speedMin = 180, speedMax = 430, gravity = 360, lifeMin = 0.28, lifeMax = 0.8, sizeStart = 2 }) },
		{ name = "phase", system = shared.makeParticleSystem(shared.palette.violet, { speedMax = 240, gravity = 220 }) },
		{ name = "warning", system = shared.makeParticleSystem(shared.palette.gold, { speedMax = 190, gravity = 300 }) },
	})

	defineSequences()
	resetButtons()
	addLog("feel.define: particles + 7 sequences")
end

function Scene.update(ctx, dt)
	fx:update(dt)
	screen.heat = math.max(0, screen.heat - dt * 0.9)

	for i = #beams, 1, -1 do
		local beam = beams[i]
		beam.life = beam.life - dt
		if beam.life <= 0 then
			table.remove(beams, i)
		end
	end
end

local function drawBackground()
	local p = shared.palette
	shared.color(p.bg)
	love.graphics.rectangle("fill", 0, 0, 1040, 680)

	for i = 0, 22 do
		local alpha = 0.035 + screen.heat * 0.055
		shared.color(i % 2 == 0 and p.pink or p.cyan, alpha)
		local x = i * 54 + math.sin(love.timer.getTime() * 0.9 + i) * 16
		love.graphics.line(x, 0, x - 160, 680)
	end

	if screen.heat > 0 then
		shared.color(p.pink, screen.heat * 0.18)
		love.graphics.rectangle("fill", 0, 0, 1040, 680)
	end
end

local function drawButton(button, index)
	local p = shared.palette
	local v = button.target.values
	local cx = button.x + button.w / 2
	local cy = button.y + button.h / 2
	local hot = button.hovered or selected == index
	local fill = hot and shared.mixColor(p.panel, button.color, 0.18) or p.panel

	love.graphics.push()
	love.graphics.translate(cx + (v.x or 0), cy + (v.y or 0))
	love.graphics.rotate(v.rotation or 0)
	love.graphics.scale((v.scale or 1) * (v.scaleX or 1), (v.scale or 1) * (v.scaleY or 1))
	love.graphics.translate(-button.w / 2, -button.h / 2)

	shared.color(fill, v.opacity or 1)
	love.graphics.rectangle("fill", 0, 0, button.w, button.h, 14, 14)
	shared.color(button.color, hot and 0.95 or 0.55)
	love.graphics.setLineWidth(hot and 4 or 2)
	love.graphics.rectangle("line", 0, 0, button.w, button.h, 14, 14)

	shared.color(button.color, 0.25 + math.sin(love.timer.getTime() * 4 + index) * 0.08)
	love.graphics.rectangle("fill", 16, 14, 56, 5, 3, 3)
	love.graphics.rectangle("fill", button.w - 76, button.h - 18, 52, 4, 3, 3)

	shared.color(p.text, v.opacity or 1)
	love.graphics.print(button.label, 20, 28)
	shared.color(p.muted, 0.88 * (v.opacity or 1))
	love.graphics.print(button.subtitle, 20, 54)
	love.graphics.pop()
end

local function drawEffects()
	for _, beam in ipairs(beams) do
		local t = beam.life / beam.maxLife
		shared.color(beam.color, t * 0.42)
		love.graphics.setLineWidth(8 * t)
		love.graphics.line(beam.x, beam.y, 950, 82)
		shared.color(beam.color, t * 0.22)
		love.graphics.circle("fill", beam.x, beam.y, 80 * (1 - t) + 18)
	end
end

function Scene.draw(ctx)
	local p = shared.palette

	fx:push()
	drawBackground()

	shared.color(p.text)
	love.graphics.print("stacked feedback recipes", 86, 120)
	shared.color(p.muted)
	love.graphics.print("Press a pad to run a named sequence with mixed primitives.", 86, 144)

	shared.panel(82, 178, 876, 282, 0.82)
	drawEffects()
	for i, button in ipairs(buttons) do
		drawButton(button, i)
	end
	fx:drawParticles()
	shared.drawLogs(logs, 82, 494, 876, 126)
	fx:pop()

	fx:drawOverlay()
end

function Scene.mousemoved(ctx, x, y)
	pointer.x, pointer.y = x, y
	local hit = hitButton(x, y)
	for _, button in ipairs(buttons) do
		local nextHover = button == hit
		if nextHover and not button.hovered then
			feel.play("button.hover", button.target)
		elseif not nextHover and button.hovered then
			feel.play("button.idle", button.target)
		end
		button.hovered = nextHover
	end
end

function Scene.mousepressed(ctx, x, y, button)
	if button ~= 1 then
		return
	end
	local hit, index = hitButton(x, y)
	if hit then
		selected = index
		hit.pressed = true
		hit.pressOrigin = { x = x, y = y }
		playSequence(hit, "button.press", "press", hit.pressOrigin)
	end
end

function Scene.mousereleased(ctx, x, y, button)
	if button ~= 1 then
		return
	end
	local hit = hitButton(x, y)
	for _, candidate in ipairs(buttons) do
		if candidate.pressed then
			candidate.pressed = false
			feel.play("button.idle", candidate.target)
			if candidate == hit then
				playSequence(candidate, candidate.sequence, "activate", candidate.pressOrigin)
			end
			candidate.pressOrigin = nil
		end
	end
end

function Scene.keypressed(ctx, key)
	if key == "down" then
		selected = selected % #buttons + 1
		feel.play("button.hover", buttons[selected].target)
	elseif key == "up" then
		selected = ((selected - 2) % #buttons) + 1
		feel.play("button.hover", buttons[selected].target)
	elseif key == "return" or key == "space" then
		local button = buttons[selected]
		playSequence(button, "button.press", "press")
		playSequence(button, button.sequence, "activate")
	end
end

return Scene
