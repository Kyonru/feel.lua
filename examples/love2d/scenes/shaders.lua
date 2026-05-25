local Scene = {
	title = "Shaders",
	summary = "Registered LOVE Shaders with immediate uniform sends, tweens, apply/clear, and mixed feel events.",
}

local feel
local feelLove
local shared
local fx
local actions
local logs
local selected
local marker
local time
local shaderEnabled

local function addLog(text)
	shared.log(logs, text, 8)
end

local function shaderCode()
	return [[
extern number amount;
extern number tint;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
  vec4 pixel = Texel(tex, texture_coords) * color;
  number wave = sin((screen_coords.y + screen_coords.x * 0.35) * 0.055) * amount;
  pixel.r = min(1.0, pixel.r + wave + tint * 0.45);
  pixel.g = min(1.0, pixel.g + tint * 0.18);
  pixel.b = max(0.0, pixel.b - tint * 0.25);
  return pixel;
}
]]
end

local function pulseMarker(color)
	marker.color = color
	marker.target.values.scale = 0.4
	marker.target.values.opacity = 1
	feel.play({
		{ kind = "animate", duration = 0.18, to = { scale = 1.8, opacity = 0.38 }, ease = "quadout" },
		{ kind = "animate", duration = 0.22, to = { scale = 2.4, opacity = 0 }, ease = "quadout" },
	}, marker.target)
end

local function defineSequences()
	feel.define("shader.apply", {
		{ kind = "emit", event = "shader.apply", payload = { name = "glow" } },
		{ kind = "emit", event = "shader.send", payload = { name = "glow", uniform = "amount", value = 0.12 } },
		{ kind = "emit", event = "shader.send", payload = { name = "glow", uniform = "tint", value = 0.15 } },
		{ kind = "audio", cue = "apply" },
		{
			kind = "callback",
			callback = function()
				shaderEnabled = true
			end,
		},
	})

	feel.define("shader.pulse", {
		{ kind = "emit", event = "shader.apply", payload = { name = "glow" } },
		{
			kind = "callback",
			callback = function()
				shaderEnabled = true
			end,
		},
		{ kind = "emit", event = "shader.tween", payload = { name = "glow", uniform = "amount", value = 0.95, duration = 0.16, ease = "quadout" } },
		{ kind = "emit", event = "shader.tween", payload = { name = "glow", uniform = "tint", value = 0.85, duration = 0.16, ease = "quadout" } },
		{ kind = "audio", cue = "pulse" },
		{ kind = "emit", event = "camera.shake", payload = { amount = 5, duration = 0.16 } },
		{ kind = "emit", event = "screen.flash", payload = { amount = 0.18, duration = 0.12, color = { 0.62, 0.38, 1, 1 } } },
		{
			kind = "callback",
			callback = function()
				pulseMarker(shared.palette.violet)
			end,
		},
		{ kind = "wait", duration = 0.22 },
		{ kind = "emit", event = "shader.tween", payload = { name = "glow", uniform = "amount", value = 0.18, duration = 0.32, ease = "quadout" } },
		{ kind = "emit", event = "shader.tween", payload = { name = "glow", uniform = "tint", value = 0.2, duration = 0.32, ease = "quadout" } },
	})

	feel.define("shader.clear", {
		{ kind = "emit", event = "shader.clear", payload = {} },
		{ kind = "emit", event = "screen.clear", payload = {} },
		{
			kind = "callback",
			callback = function()
				shaderEnabled = false
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
		end,
		audio = function(event)
			addLog("audio:" .. event.cue)
		end,
	}))
	if love.graphics.setShader then
		love.graphics.setShader()
	end
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
	time = 0
	shaderEnabled = false
	marker = {
		color = shared.palette.violet,
		target = feel.target({ values = { scale = 0, opacity = 0 } }),
	}

	local p = shared.palette
	local shader
	if love.graphics.newShader then
		shader = love.graphics.newShader(shaderCode())
	end
	fx:shader("glow", shader, { uniforms = { amount = 0, tint = 0 } })
	fx:sounds({
		apply = shared.makeTone(520, 0.08, 0.12),
		pulse = shared.makeTone(880, 0.12, 0.14),
	})

	actions = {
		{ label = "APPLY", sequence = "shader.apply", color = p.cyan, x = 164, y = 492, w = 190, h = 64 },
		{ label = "PULSE", sequence = "shader.pulse", color = p.violet, x = 424, y = 492, w = 190, h = 64 },
		{ label = "CLEAR", sequence = "shader.clear", color = p.gold, x = 684, y = 492, w = 190, h = 64 },
	}

	defineSequences()
	addLog("fx:shader registered glow")
end

function Scene.update(ctx, dt)
	time = time + dt
	fx:update(dt)
end

local function drawWorld()
	local p = shared.palette
	shared.panel(108, 172, 824, 284, 0.8)

	for i = 0, 9 do
		local x = 160 + i * 76
		local height = 74 + math.sin(time * 2 + i * 0.7) * 34
		shared.color(i % 2 == 0 and p.cyan or p.pink, 0.55)
		love.graphics.rectangle("fill", x, 342 - height, 42, height, 8, 8)
	end

	shared.color(p.text)
	love.graphics.printf("shader target area", 108, 218, 824, "center")
	shared.color(p.muted)
	love.graphics.printf(shaderEnabled and "fx:pushShader('glow') wraps only this panel" or "press APPLY or PULSE to enable the registered shader", 108, 242, 824, "center")
end

local function drawMarker()
	local v = marker.target.values
	if not v.opacity or v.opacity <= 0 then
		return
	end
	shared.color(marker.color, v.opacity)
	love.graphics.setLineWidth(4)
	love.graphics.circle("line", 520, 315, 42 * (v.scale or 1))
	love.graphics.setLineWidth(1)
end

function Scene.draw(ctx)
	local p = shared.palette

	shared.color(p.text)
	love.graphics.print("shader uniforms as feel events", 86, 120)
	shared.color(p.muted)
	love.graphics.print("Recipes apply shaders, send uniforms, tween strength, and mix in audio/camera/screen feedback.", 86, 144)

	fx:push()
	if shaderEnabled then
		fx:pushShader("glow")
	end
	drawWorld()
	drawMarker()
	if shaderEnabled then
		fx:popShader()
	end
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

	shared.drawLogs(logs, 108, 590, 824, 76)
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
