package.path = "?.lua;?/init.lua;../../?.lua;../../?/init.lua;" .. package.path

local feel = require("feel")
local feelLove = require("feel.love")

local W, H = 1040, 680
local buttons = {}
local particles = {}
local beams = {}
local logs = {}
local sources = {}
local pointer = { x = 0, y = 0 }
local screen = {
	heat = 0,
	combo = 0,
}
local fx = feelLove.new()
local selected = 1

local palette = {
	bg = { 0.025, 0.028, 0.04, 1 },
	panel = { 0.065, 0.07, 0.1, 0.92 },
	text = { 0.94, 0.97, 1, 1 },
	muted = { 0.58, 0.66, 0.76, 1 },
	cyan = { 0.1, 0.82, 1, 1 },
	pink = { 1, 0.18, 0.46, 1 },
	gold = { 1, 0.72, 0.18, 1 },
	green = { 0.32, 1, 0.52, 1 },
	violet = { 0.62, 0.38, 1, 1 },
}

local function addLog(text)
	logs[#logs + 1] = text
	while #logs > 8 do
		table.remove(logs, 1)
	end
end

local function color(c, alpha)
	love.graphics.setColor(c[1], c[2], c[3], (c[4] or 1) * (alpha or 1))
end

local function mix(a, b, t)
	return a + (b - a) * t
end

local function mixColor(a, b, t)
	return {
		mix(a[1], b[1], t),
		mix(a[2], b[2], t),
		mix(a[3], b[3], t),
		mix(a[4] or 1, b[4] or 1, t),
	}
end

local function makeTone(frequency, duration, volume)
	if not love.sound or not love.audio then
		return nil
	end

	local sampleRate = 44100
	local count = math.floor(sampleRate * duration)
	local data = love.sound.newSoundData(count, sampleRate, 16, 1)
	for i = 0, count - 1 do
		local t = i / sampleRate
		local fade = math.max(0, 1 - t / duration)
		local wave = math.sin(t * frequency * math.pi * 2)
		data:setSample(i, wave * (volume or 0.22) * fade)
	end
	return love.audio.newSource(data, "static")
end

local function emitParticles(x, y, base, count, power)
	for _ = 1, count do
		local angle = math.random() * math.pi * 2
		local speed = power * (0.35 + math.random() * 0.9)
		particles[#particles + 1] = {
			x = x,
			y = y,
			vx = math.cos(angle) * speed,
			vy = math.sin(angle) * speed,
			life = 0.4 + math.random() * 0.35,
			maxLife = 0.75,
			size = 3 + math.random() * 7,
			color = mixColor(base, { 1, 1, 1, 1 }, math.random() * 0.35),
		}
	end
end

local function emitBeam(button)
	beams[#beams + 1] = {
		x = button.x + button.w / 2,
		y = button.y + button.h / 2,
		life = 0.28,
		maxLife = 0.28,
		color = button.color,
	}
end

local function playCue(cue)
	local source = sources[cue]
	if source then
		source:stop()
		source:play()
	end
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

local function playSequence(button, name, trigger)
	feel.play(name, button.target, fx:handlers({
		trigger = trigger,
		emit = function(event)
			if event.kind == "burst" then
				emitParticles(button.x + button.w / 2, button.y + button.h / 2, button.color, event.payload.count, event.payload.power)
			elseif event.kind == "beam" then
				emitBeam(button)
			elseif event.kind == "heat" then
				screen.heat = math.max(screen.heat, event.payload.amount)
			end
			addLog("emit:" .. event.kind .. " trigger=" .. tostring(event.trigger))
		end,
		audio = function(event)
			playCue(event.cue)
			addLog("audio:" .. event.cue)
		end,
		markDirty = function() end,
	}))
end

local function defineSequences()
	feel.clear()

	feel.define("button.hover", {
		{ kind = "animate", duration = 0.1, to = { scale = 1.035, y = -4 }, ease = "quadout" },
	})

	feel.define("button.idle", {
		{ kind = "animate", duration = 0.16, to = { scale = 1, x = 0, y = 0, rotation = 0, opacity = 1 }, ease = "quadout" },
	})

	feel.define("button.press", {
		{ kind = "audio", cue = "press" },
		{ kind = "animate", duration = 0.04, to = { scaleX = 1.07, scaleY = 0.9, y = 3 }, ease = "quadout" },
	})

	feel.define("launch.perfect", {
		{ kind = "audio", cue = "perfect" },
		{ kind = "emit", event = "burst", payload = { count = 42, power = 260 } },
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
		{ kind = "emit", event = "burst", payload = { count = 20, power = 190 } },
		{ kind = "animate", duration = 0.18, to = { x = 0, scale = 1 }, ease = "backout" },
	})

	feel.define("launch.warning", {
		{ kind = "audio", cue = "warn" },
		{ kind = "emit", event = "camera.shake", payload = { amount = 6, duration = 0.18 } },
		{ kind = "animate", duration = 0.055, to = { scaleX = 0.96, scaleY = 1.08, y = -7 }, ease = "quadout" },
		{ kind = "emit", event = "burst", payload = { count = 14, power = 130 } },
		{ kind = "animate", duration = 0.16, to = { scaleX = 1, scaleY = 1, y = 0 }, ease = "backout" },
	})
end

local function resetButtons()
	buttons = {}
	targetButton("PERFECT", "burst + beam + callback", 126, 232, palette.cyan, "launch.perfect")
	targetButton("OVERLOAD", "shake + heat + multi-step jitter", 397, 232, palette.pink, "launch.overload")
	targetButton("PHASE", "fade dash + particle return", 668, 232, palette.violet, "launch.phase")
	targetButton("WARNING", "squash + warning burst", 397, 352, palette.gold, "launch.warning")
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

function love.load()
	love.window.setMode(W, H, { resizable = true, minwidth = 760, minheight = 520 })
	love.window.setTitle("feel.lua - complex feedback lab")
	math.randomseed(os.time())

	sources = {
		press = makeTone(420, 0.045, 0.12),
		perfect = makeTone(960, 0.12, 0.2),
		overload = makeTone(150, 0.22, 0.24),
		phase = makeTone(680, 0.14, 0.18),
		warn = makeTone(260, 0.16, 0.18),
	}

	defineSequences()
	resetButtons()
	addLog("feel.define: 6 sequences")
end

function love.update(dt)
	feel.update(dt)
	fx:update(dt)
	screen.heat = math.max(0, screen.heat - dt * 0.9)

	for i = #particles, 1, -1 do
		local p = particles[i]
		p.life = p.life - dt
		p.x = p.x + p.vx * dt
		p.y = p.y + p.vy * dt
		p.vy = p.vy + 320 * dt
		if p.life <= 0 then
			table.remove(particles, i)
		end
	end

	for i = #beams, 1, -1 do
		local beam = beams[i]
		beam.life = beam.life - dt
		if beam.life <= 0 then
			table.remove(beams, i)
		end
	end
end

local function drawBackground()
	color(palette.bg)
	love.graphics.rectangle("fill", 0, 0, W, H)

	for i = 0, 22 do
		local alpha = 0.035 + screen.heat * 0.055
		color(i % 2 == 0 and palette.pink or palette.cyan, alpha)
		local x = i * 54 + math.sin(love.timer.getTime() * 0.9 + i) * 16
		love.graphics.line(x, 0, x - 160, H)
	end

	if screen.heat > 0 then
		color(palette.pink, screen.heat * 0.18)
		love.graphics.rectangle("fill", 0, 0, W, H)
	end
end

local function drawButton(button, index)
	local v = button.target.values
	local cx = button.x + button.w / 2
	local cy = button.y + button.h / 2
	local hot = button.hovered or selected == index
	local fill = hot and mixColor(palette.panel, button.color, 0.18) or palette.panel

	love.graphics.push()
	love.graphics.translate(cx + (v.x or 0), cy + (v.y or 0))
	love.graphics.rotate(v.rotation or 0)
	love.graphics.scale((v.scale or 1) * (v.scaleX or 1), (v.scale or 1) * (v.scaleY or 1))
	love.graphics.translate(-button.w / 2, -button.h / 2)

	color(fill, v.opacity or 1)
	love.graphics.rectangle("fill", 0, 0, button.w, button.h, 14, 14)
	color(button.color, hot and 0.95 or 0.55)
	love.graphics.setLineWidth(hot and 4 or 2)
	love.graphics.rectangle("line", 0, 0, button.w, button.h, 14, 14)

	color(button.color, 0.25 + math.sin(love.timer.getTime() * 4 + index) * 0.08)
	love.graphics.rectangle("fill", 16, 14, 56, 5, 3, 3)
	love.graphics.rectangle("fill", button.w - 76, button.h - 18, 52, 4, 3, 3)

	color(palette.text, v.opacity or 1)
	love.graphics.print(button.label, 20, 28)
	color(palette.muted, 0.88 * (v.opacity or 1))
	love.graphics.print(button.subtitle, 20, 54)
	love.graphics.pop()
end

local function drawEffects()
	for _, beam in ipairs(beams) do
		local t = beam.life / beam.maxLife
		color(beam.color, t * 0.42)
		love.graphics.setLineWidth(8 * t)
		love.graphics.line(beam.x, beam.y, W - 90, 82)
		color(beam.color, t * 0.22)
		love.graphics.circle("fill", beam.x, beam.y, 80 * (1 - t) + 18)
	end

	for _, p in ipairs(particles) do
		local t = math.max(0, p.life / p.maxLife)
		color(p.color, t)
		love.graphics.circle("fill", p.x, p.y, p.size * t)
	end
end

local function drawLogPanel()
	color({ 0.02, 0.025, 0.038, 0.86 })
	love.graphics.rectangle("fill", 82, 494, 876, 126, 12, 12)
	color({ 1, 1, 1, 0.13 })
	love.graphics.rectangle("line", 82, 494, 876, 126, 12, 12)
	color(palette.text)
	love.graphics.print("event stream", 106, 512)

	for i, line in ipairs(logs) do
		color(palette.muted, 0.94)
		love.graphics.print(line, 106, 530 + i * 10)
	end
end

function love.draw()
	fx:push()
	drawBackground()

	color(palette.text)
	love.graphics.print("feel.lua", 86, 78)
	color(palette.muted)
	love.graphics.print("Standalone flux-backed feedback stack: animation, emit, audio, callback, shake, particles, flash, and beam effects.", 86, 104)

	color({ 0.02, 0.025, 0.038, 0.74 })
	love.graphics.rectangle("fill", 82, 178, 876, 282, 18, 18)
	color({ 1, 1, 1, 0.12 })
	love.graphics.rectangle("line", 82, 178, 876, 282, 18, 18)

	drawEffects()
	for i, button in ipairs(buttons) do
		drawButton(button, i)
	end
	drawLogPanel()
	fx:pop()

	fx:drawOverlay()
end

function love.mousemoved(x, y)
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

function love.mousepressed(x, y, button)
	if button ~= 1 then
		return
	end
	local hit, index = hitButton(x, y)
	if hit then
		selected = index
		hit.pressed = true
		playSequence(hit, "button.press", "press")
	end
end

function love.mousereleased(x, y, button)
	if button ~= 1 then
		return
	end
	local hit = hitButton(x, y)
	for _, candidate in ipairs(buttons) do
		if candidate.pressed then
			candidate.pressed = false
			feel.play("button.idle", candidate.target)
			if candidate == hit then
				playSequence(candidate, candidate.sequence, "activate")
			end
		end
	end
end

function love.keypressed(key)
	if key == "right" or key == "down" then
		selected = selected % #buttons + 1
		feel.play("button.hover", buttons[selected].target)
	elseif key == "left" or key == "up" then
		selected = ((selected - 2) % #buttons) + 1
		feel.play("button.hover", buttons[selected].target)
	elseif key == "return" or key == "space" then
		local button = buttons[selected]
		playSequence(button, "button.press", "press")
		playSequence(button, button.sequence, "activate")
	elseif key == "r" then
		screen.combo = 0
		screen.heat = 0
		fx:reset()
		particles = {}
		beams = {}
		logs = {}
		feel.clear()
		defineSequences()
		resetButtons()
		addLog("reset")
	end
end
