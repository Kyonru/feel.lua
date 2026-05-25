local Shared = {}
Shared.particleImages = {}

Shared.palette = {
	bg = { 0.025, 0.028, 0.04, 1 },
	panel = { 0.065, 0.07, 0.1, 0.92 },
	panel2 = { 0.035, 0.04, 0.058, 0.9 },
	text = { 0.94, 0.97, 1, 1 },
	muted = { 0.58, 0.66, 0.76, 1 },
	cyan = { 0.1, 0.82, 1, 1 },
	pink = { 1, 0.18, 0.46, 1 },
	gold = { 1, 0.72, 0.18, 1 },
	green = { 0.32, 1, 0.52, 1 },
	violet = { 0.62, 0.38, 1, 1 },
}

function Shared.color(c, alpha)
	love.graphics.setColor(c[1], c[2], c[3], (c[4] or 1) * (alpha or 1))
end

function Shared.clear()
	Shared.color(Shared.palette.bg)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
end

function Shared.mix(a, b, t)
	return a + (b - a) * t
end

function Shared.mixColor(a, b, t)
	return {
		Shared.mix(a[1], b[1], t),
		Shared.mix(a[2], b[2], t),
		Shared.mix(a[3], b[3], t),
		Shared.mix(a[4] or 1, b[4] or 1, t),
	}
end

function Shared.panel(x, y, w, h, alpha)
	Shared.color(Shared.palette.panel2, alpha or 1)
	love.graphics.rectangle("fill", x, y, w, h, 14, 14)
	Shared.color({ 1, 1, 1, 0.12 })
	love.graphics.rectangle("line", x, y, w, h, 14, 14)
end

function Shared.log(logs, text, limit)
	logs[#logs + 1] = text
	while #logs > (limit or 8) do
		table.remove(logs, 1)
	end
end

function Shared.makeTone(frequency, duration, volume)
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

function Shared.makeParticleSystem(base, opts)
	if not love.image or not love.graphics or not love.graphics.newImage or not love.graphics.newParticleSystem then
		return nil
	end

	opts = opts or {}
	local size = opts.imageSize or 8
	local data = love.image.newImageData(size, size)
	for y = 0, size - 1 do
		for x = 0, size - 1 do
			local dx = (x + 0.5) / size * 2 - 1
			local dy = (y + 0.5) / size * 2 - 1
			local alpha = math.max(0, 1 - math.sqrt(dx * dx + dy * dy))
			data:setPixel(x, y, 1, 1, 1, alpha)
		end
	end

	local image = love.graphics.newImage(data)
	Shared.particleImages[#Shared.particleImages + 1] = image

	local system = love.graphics.newParticleSystem(image, opts.buffer or 256)
	local gravity = opts.gravity or 260
	system:setParticleLifetime(opts.lifeMin or 0.32, opts.lifeMax or 0.72)
	system:setSpeed(opts.speedMin or 70, opts.speedMax or 260)
	system:setLinearAcceleration(0, gravity, 0, gravity)
	system:setSpread(opts.spread or math.pi * 2)
	system:setSizes(opts.sizeStart or 1.3, opts.sizeEnd or 0)
	if opts.spinMin or opts.spinMax then
		system:setSpin(opts.spinMin or 0, opts.spinMax or 0)
	end
	system:setColors(base[1], base[2], base[3], base[4] or 1, base[1], base[2], base[3], 0)
	system:setEmissionRate(opts.rate or 80)
	system:stop()
	return system
end

function Shared.drawLogs(logs, x, y, w, h)
	Shared.panel(x, y, w, h)
	Shared.color(Shared.palette.text)
	love.graphics.print("event stream", x + 18, y + 16)
	for i, line in ipairs(logs) do
		Shared.color(Shared.palette.muted, 0.94)
		love.graphics.print(line, x + 18, y + 34 + i * 12)
	end
end

return Shared
