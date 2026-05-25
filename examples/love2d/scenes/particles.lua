local Scene = {
	title = "Particles",
	summary = "ParticleSystem events combined with sound, shake, flash, waits, and marker animation.",
}

local feel
local feelLove
local shared
local fx
local actions
local logs
local selected
local marker
local moveSide
local streamX
local streamY

local function addLog(text)
	shared.log(logs, text, 3)
end

local function pulseMarker(x, y, color, size)
	marker.x = x
	marker.y = y
	marker.color = color
	marker.target.values.scale = 0.35
	marker.target.values.opacity = 1
	feel.play({
		{ kind = "animate", duration = 0.22, to = { scale = size or 1.8, opacity = 0.35 }, ease = "quadout" },
		{ kind = "animate", duration = 0.22, to = { scale = 2.2, opacity = 0 }, ease = "quadout" },
	}, marker.target)
end

local function defineSequences()
	feel.define("particles.burst", {
		{ kind = "audio", cue = "burst" },
		{ kind = "emit", event = "camera.shake", payload = { amount = 5, duration = 0.14 } },
		{ kind = "emit", event = "screen.flash", payload = { amount = 0.22, duration = 0.12, color = { 0.1, 0.82, 1, 1 } } },
		{ kind = "emit", event = "particle.start", payload = { name = "spark", x = 280, y = 322 } },
		{ kind = "emit", event = "particle.emit", payload = { name = "spark", count = 72, x = 280, y = 322 } },
		{ kind = "emit", event = "particle.stop", payload = { name = "spark" } },
		{
			kind = "callback",
			callback = function()
				pulseMarker(280, 322, shared.palette.cyan, 2.3)
			end,
		},
	})

	feel.define("particles.comet", {
		{ kind = "audio", cue = "comet" },
		{ kind = "emit", event = "particle.start", payload = { name = "spark", x = 180, y = 250 } },
		{ kind = "emit", event = "particle.emit", payload = { name = "spark", count = 20, x = 180, y = 250 } },
		{ kind = "wait", duration = 0.08 },
		{ kind = "emit", event = "particle.move", payload = { name = "spark", x = 360, y = 315 } },
		{ kind = "emit", event = "particle.emit", payload = { name = "spark", count = 26, x = 360, y = 315 } },
		{ kind = "wait", duration = 0.08 },
		{ kind = "emit", event = "particle.move", payload = { name = "spark", x = 540, y = 250 } },
		{ kind = "emit", event = "particle.emit", payload = { name = "spark", count = 34, x = 540, y = 250 } },
		{ kind = "emit", event = "particle.stop", payload = { name = "spark" } },
		{
			kind = "callback",
			callback = function()
				pulseMarker(540, 250, shared.palette.gold, 1.8)
			end,
		},
	})

	feel.define("particles.stream.start", {
		{ kind = "audio", cue = "stream" },
		{ kind = "emit", event = "particle.start", payload = { name = "stream", x = 520, y = 322 } },
		{ kind = "emit", event = "sound.volume", payload = { cue = "stream", volume = 0.42, duration = 0.25 } },
	})

	feel.define("particles.stream.stop", {
		{ kind = "emit", event = "particle.stop", payload = { name = "stream" } },
		{ kind = "emit", event = "sound.volume", payload = { cue = "stream", volume = 0, duration = 0.28 } },
		{ kind = "wait", duration = 0.28 },
		{ kind = "emit", event = "sound.stop", payload = { cue = "stream" } },
	})

	feel.define("particles.reset", {
		{ kind = "emit", event = "particle.reset", payload = { name = "spark" } },
		{ kind = "emit", event = "particle.reset", payload = { name = "stream" } },
		{ kind = "emit", event = "screen.clear" },
		{ kind = "emit", event = "sound.stop", payload = { cue = "stream" } },
	})
end

local function playAction(index)
	local action = actions[index]
	if not action then
		return
	end

	if action.event == "move" then
		moveSide = moveSide == "left" and "right" or "left"
		streamX = moveSide == "left" and 420 or 620
		fx:emit({ kind = "particle.move", payload = { name = "stream", x = streamX, y = streamY } })
		pulseMarker(streamX, streamY, shared.palette.pink, 1.5)
		addLog("emit:particle.move x=" .. streamX)
		return
	end

	feel.play(action.sequence, nil, fx:handlers({
		emit = function(event)
			addLog("emit:" .. event.kind)
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

function Scene.load(ctx)
	feel = ctx.feel
	feelLove = ctx.feelLove
	shared = ctx.shared
	fx = feelLove.new()
	logs = {}
	selected = 1
	moveSide = "right"
	streamX = 520
	streamY = 322
	marker = {
		x = 280,
		y = 322,
		color = shared.palette.cyan,
		target = feel.target({ values = { scale = 0, opacity = 0 } }),
	}

	local p = shared.palette
	local streamCue = shared.makeTone(180, 0.8, 0.06)
	if streamCue and streamCue.setLooping then
		streamCue:setLooping(true)
	end

	fx:sounds({
		burst = shared.makeTone(900, 0.09, 0.15),
		comet = shared.makeTone(520, 0.16, 0.11),
	})
	fx:sound("stream", streamCue, { restart = false, volume = 0 })
	fx:particles({
		{ name = "spark", system = shared.makeParticleSystem(p.cyan, { buffer = 512, imageSize = 12, speedMin = 180, speedMax = 520, gravity = 190, lifeMin = 0.45, lifeMax = 1.1, sizeStart = 2.6 }) },
		{ name = "stream", system = shared.makeParticleSystem(p.pink, { buffer = 512, imageSize = 10, rate = 180, speedMin = 70, speedMax = 190, gravity = -20, lifeMin = 0.5, lifeMax = 1.2, sizeStart = 1.6 }) },
	})

	actions = {
		{ label = "BURST", sequence = "particles.burst", color = p.cyan, x = 78, y = 468, w = 156, h = 60 },
		{ label = "COMET", sequence = "particles.comet", color = p.gold, x = 258, y = 468, w = 156, h = 60 },
		{ label = "STREAM", sequence = "particles.stream.start", color = p.green, x = 438, y = 468, w = 156, h = 60 },
		{ label = "MOVE", event = "move", color = p.pink, x = 618, y = 468, w = 156, h = 60 },
		{ label = "STOP", sequence = "particles.stream.stop", color = p.violet, x = 798, y = 468, w = 156, h = 60 },
		{ label = "RESET", sequence = "particles.reset", color = p.muted, x = 410, y = 542, w = 220, h = 50 },
	}

	defineSequences()
	addLog("fx:particles registered spark + stream")
end

function Scene.update(ctx, dt)
	fx:update(dt)
end

local function drawStage()
	local p = shared.palette
	shared.panel(98, 170, 844, 278, 0.78)

	shared.color(p.muted, 0.34)
	love.graphics.line(180, 250, 540, 250)
	love.graphics.line(180, 250, 360, 315)
	love.graphics.line(360, 315, 540, 250)
	love.graphics.line(420, 210, 420, 408)
	love.graphics.line(520, 210, 520, 408)
	love.graphics.line(620, 210, 620, 408)

	shared.color(p.cyan, 0.9)
	love.graphics.circle("line", 280, 322, 40)
	shared.color(p.gold, 0.9)
	love.graphics.circle("line", 540, 250, 26)
	shared.color(p.pink, 0.9)
	love.graphics.circle("line", streamX, streamY, 28)
	shared.color(p.muted)
	love.graphics.print("burst", 260, 374)
	love.graphics.print("comet path", 266, 236)
	love.graphics.print("stream", streamX - 28, streamY + 52)
end

local function drawMarker()
	local v = marker.target.values
	if not v.opacity or v.opacity <= 0 then
		return
	end

	shared.color(marker.color, v.opacity)
	love.graphics.setLineWidth(4)
	love.graphics.circle("line", marker.x, marker.y, 26 * (v.scale or 1))
	love.graphics.setLineWidth(1)
end

function Scene.draw(ctx)
	local p = shared.palette

	shared.color(p.text)
	love.graphics.print("particles as feel events", 86, 120)
	shared.color(p.muted)
	love.graphics.print("Particle events are mixed with audio, waits, camera shake, screen flash, and callback-driven marker pulses.", 86, 144)

	fx:push()
	drawStage()
	fx:drawParticles()
	drawMarker()
	fx:pop()
	fx:drawOverlay()

	for i, action in ipairs(actions) do
		local hot = selected == i
		shared.color(hot and shared.mixColor(p.panel, action.color, 0.2) or p.panel)
		love.graphics.rectangle("fill", action.x, action.y, action.w, action.h, 12, 12)
		shared.color(action.color, hot and 1 or 0.55)
		love.graphics.setLineWidth(hot and 4 or 2)
		love.graphics.rectangle("line", action.x, action.y, action.w, action.h, 12, 12)
		shared.color(p.text)
		love.graphics.printf(action.label, action.x, action.y + action.h / 2 - 8, action.w, "center")
	end

	shared.drawLogs(logs, 98, 596, 844, 76)
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
