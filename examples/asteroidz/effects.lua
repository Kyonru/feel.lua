local state = require("state")

local function emitParticles(x, y, base, count, speed)
	local particles = state.get("particles")
	for _ = 1, count do
		local angle = math.random() * math.pi * 2
		local velocity = speed * (0.35 + math.random() * 0.9)
		particles[#particles + 1] = {
			x = x,
			y = y,
			vx = math.cos(angle) * velocity,
			vy = math.sin(angle) * velocity,
			life = 0.35 + math.random() * 0.45,
			maxLife = 0.8,
			size = 2 + math.random() * 4,
			color = base,
		}
	end
end

local function makeTone(frequency, duration, volume)
	local sampleRate = 44100
	local count = math.floor(sampleRate * duration)
	local data = love.sound.newSoundData(count, sampleRate, 16, 1)
	for i = 0, count - 1 do
		local t = i / sampleRate
		local fade = math.max(0, 1 - t / duration)
		local wave = math.sin(t * frequency * math.pi * 2)
		data:setSample(i, wave * (volume or 0.18) * fade)
	end
	return love.audio.newSource(data, "static")
end

return {
	emitParticles = emitParticles,
	makeTone = makeTone,
}
