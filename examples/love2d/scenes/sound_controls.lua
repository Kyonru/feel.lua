local Scene = {
	title = "Sound Controls",
	summary = "Registered LOVE Source cues plus audio steps and sound emit events for volume, pitch, and pan.",
}

local feel
local feelLove
local shared
local fx
local pads
local logs
local selected

local function addLog(text)
	shared.log(logs, text, 8)
end

local function defineSequences()
	feel.define("sound.pop", {
		{ kind = "audio", cue = "pop" },
	})

	feel.define("sound.slow", {
		{ kind = "emit", event = "sound.pitch", payload = { cue = "pop", pitch = 0.65, duration = 0.08 } },
		{ kind = "emit", event = "sound.volume", payload = { cue = "pop", volume = 0.55, duration = 0.08 } },
		{ kind = "audio", cue = "pop" },
		{ kind = "emit", event = "sound.pitch", payload = { cue = "pop", pitch = 1, duration = 0.2 } },
		{ kind = "emit", event = "sound.volume", payload = { cue = "pop", volume = 1, duration = 0.2 } },
	})

	feel.define("sound.pan", {
		{ kind = "emit", event = "sound.pan", payload = { cue = "pop", pan = -1, duration = 0.06 } },
		{ kind = "audio", cue = "pop" },
		{ kind = "wait", duration = 0.1 },
		{ kind = "emit", event = "sound.pan", payload = { cue = "pop", pan = 1, duration = 0.08 } },
		{ kind = "audio", cue = "pop" },
		{ kind = "emit", event = "sound.pan", payload = { cue = "pop", pan = 0, duration = 0.22 } },
	})
end

local function playPad(index)
	local pad = pads[index]
	if not pad then
		return
	end

	feel.play(pad.sequence, pad.target, fx:handlers({
		audio = function(event)
			addLog("audio:" .. event.cue)
		end,
		emit = function(event)
			addLog("emit:" .. event.kind)
		end,
	}))
	feel.play({
		{ kind = "animate", duration = 0.05, to = { scale = 0.94 }, ease = "quadout" },
		{ kind = "animate", duration = 0.18, to = { scale = 1 }, ease = "backout" },
	}, pad.target)
end

local function hitPad(x, y)
	for i = #pads, 1, -1 do
		local pad = pads[i]
		if x >= pad.x and x <= pad.x + pad.w and y >= pad.y and y <= pad.y + pad.h then
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

	fx:sound("pop", {
		shared.makeTone(440, 0.08, 0.18),
		shared.makeTone(660, 0.08, 0.16),
		shared.makeTone(880, 0.08, 0.14),
	})

	local p = shared.palette
	pads = {
		{ label = "POP", sequence = "sound.pop", color = p.cyan, x = 126, y = 250, w = 245, h = 132, target = feel.target({ values = { scale = 1 } }) },
		{ label = "SLOW", sequence = "sound.slow", color = p.gold, x = 397, y = 250, w = 245, h = 132, target = feel.target({ values = { scale = 1 } }) },
		{ label = "PAN", sequence = "sound.pan", color = p.pink, x = 668, y = 250, w = 245, h = 132, target = feel.target({ values = { scale = 1 } }) },
	}

	defineSequences()
	addLog("fx:sound pop has 3 alternates")
end

function Scene.update(ctx, dt)
	fx:update(dt)
end

local function drawMeter(label, value, min, max, x, y, color)
	local t = (value - min) / (max - min)
	t = math.max(0, math.min(1, t))
	shared.color(shared.palette.muted)
	love.graphics.print(label, x, y)
	shared.color({ 1, 1, 1, 0.12 })
	love.graphics.rectangle("fill", x + 72, y + 4, 220, 8, 4, 4)
	shared.color(color)
	love.graphics.rectangle("fill", x + 72, y + 4, 220 * t, 8, 4, 4)
end

function Scene.draw(ctx)
	local p = shared.palette
	local values = fx.soundEntries.pop.target.values

	shared.color(p.text)
	love.graphics.print("adapter-owned sound state", 86, 120)
	shared.color(p.muted)
	love.graphics.print("Audio steps play cues; emit events shape the next playback.", 86, 144)

	for i, pad in ipairs(pads) do
		local v = pad.target.values
		local hot = selected == i
		love.graphics.push()
		love.graphics.translate(pad.x + pad.w / 2, pad.y + pad.h / 2)
		love.graphics.scale(v.scale or 1)
		love.graphics.translate(-pad.w / 2, -pad.h / 2)
		shared.color(hot and shared.mixColor(p.panel, pad.color, 0.2) or p.panel)
		love.graphics.rectangle("fill", 0, 0, pad.w, pad.h, 14, 14)
		shared.color(pad.color, hot and 1 or 0.55)
		love.graphics.setLineWidth(hot and 4 or 2)
		love.graphics.rectangle("line", 0, 0, pad.w, pad.h, 14, 14)
		shared.color(p.text)
		love.graphics.printf(pad.label, 0, 48, pad.w, "center")
		love.graphics.pop()
	end

	shared.panel(126, 420, 787, 80)
	drawMeter("volume", values.volume or 1, 0, 1, 150, 438, p.cyan)
	drawMeter("pitch", values.pitch or 1, 0.5, 1.5, 150, 460, p.gold)
	drawMeter("pan", values.pan or 0, -1, 1, 520, 438, p.pink)
	shared.drawLogs(logs, 126, 526, 787, 96)
end

function Scene.mousepressed(ctx, x, y, button)
	if button ~= 1 then
		return
	end
	local index = hitPad(x, y)
	if index then
		selected = index
		playPad(index)
	end
end

function Scene.keypressed(ctx, key)
	if key == "down" then
		selected = selected % #pads + 1
	elseif key == "up" then
		selected = ((selected - 2) % #pads) + 1
	elseif key == "return" or key == "space" then
		playPad(selected)
	end
end

return Scene
