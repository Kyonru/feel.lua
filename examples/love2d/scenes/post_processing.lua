local Scene = {
	title = "Post Processing",
	summary = "Canvas-backed post effects driven by post.set, post.tween, post.weight, and post.clear events.",
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

local function addLog(text)
	shared.log(logs, text, 8)
end

local function pulse(color)
	marker.color = color
	marker.target.values.scale = 0.7
	marker.target.values.opacity = 1
	feel.play({
		{ kind = "animate", duration = 0.12, to = { scale = 1.5, opacity = 0.82 }, ease = "quadout" },
		{ kind = "animate", duration = 0.28, to = { scale = 1, opacity = 1 }, ease = "backout" },
	}, marker.target)
end

local function defineSequences()
	feel.define("post.bloom", {
		{ kind = "emit", event = "post.set", payload = { effect = "bloom", values = { intensity = 0.25, threshold = 0.52, softness = 0.18 } } },
		{ kind = "emit", event = "post.tween", payload = { effect = "bloom", values = { intensity = 1.15 }, duration = 0.12, ease = "quadout" } },
		{ kind = "audio", cue = "bloom" },
		{ kind = "wait", duration = 0.16 },
		{ kind = "emit", event = "post.tween", payload = { effect = "bloom", values = { intensity = 0.38 }, duration = 0.42, ease = "quadout" } },
		{
			kind = "callback",
			callback = function()
				pulse(shared.palette.cyan)
			end,
		},
	})

	feel.define("post.chromatic", {
		{ kind = "emit", event = "post.set", payload = { effect = "chromatic", values = { force = 0 } } },
		{ kind = "emit", event = "post.tween", payload = { effect = "chromatic", values = { force = 1 }, duration = 0.08, ease = "quadout" } },
		{ kind = "emit", event = "camera.shake", payload = { amount = 4, duration = 0.12 } },
		{ kind = "audio", cue = "hit" },
		{ kind = "wait", duration = 0.08 },
		{ kind = "emit", event = "post.tween", payload = { effect = "chromatic", values = { force = 0 }, duration = 0.24, ease = "quadout" } },
	})

	feel.define("post.grade", {
		{ kind = "emit", event = "post.tween", payload = { effect = "grade", values = { exposure = 0.18, saturation = 1.35, hueShift = 0.06, contrast = 1.16 }, duration = 0.28, ease = "quadout" } },
		{ kind = "audio", cue = "grade" },
		{
			kind = "callback",
			callback = function()
				pulse(shared.palette.gold)
			end,
		},
	})

	feel.define("post.lens", {
		{ kind = "emit", event = "post.tween", payload = { effect = "lens", values = { distortion = 0.36 }, duration = 0.18, ease = "quadout" } },
		{ kind = "audio", cue = "lens" },
		{ kind = "wait", duration = 0.12 },
		{ kind = "emit", event = "post.tween", payload = { effect = "lens", values = { distortion = 0.08 }, duration = 0.3, ease = "quadout" } },
	})

	feel.define("post.vignette", {
		{ kind = "emit", event = "post.tween", payload = { effect = "vignette", values = { intensity = 0.78, radius = 0.62, softness = 0.24 }, duration = 0.24, ease = "quadout" } },
		{ kind = "audio", cue = "focus" },
		{
			kind = "callback",
			callback = function()
				pulse(shared.palette.violet)
			end,
		},
	})

	feel.define("post.weight", {
		{ kind = "emit", event = "post.weight", payload = { value = 0.15, duration = 0.28, ease = "quadout" } },
		{ kind = "wait", duration = 0.18 },
		{ kind = "emit", event = "post.weight", payload = { value = 1, duration = 0.4, ease = "quadout" } },
	})

	feel.define("post.clear", {
		{ kind = "emit", event = "post.clear", payload = {} },
		{ kind = "emit", event = "screen.clear", payload = {} },
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
	marker = {
		color = shared.palette.cyan,
		target = feel.target({ values = { scale = 1, opacity = 1 } }),
	}

	fx:sounds({
		bloom = shared.makeTone(520, 0.08, 0.1),
		hit = shared.makeTone(260, 0.08, 0.12),
		grade = shared.makeTone(680, 0.08, 0.1),
		lens = shared.makeTone(430, 0.08, 0.1),
		focus = shared.makeTone(760, 0.08, 0.09),
	})

	local p = shared.palette
	actions = {
		{ label = "BLOOM", sequence = "post.bloom", color = p.cyan, x = 74, y = 500, w = 122, h = 58 },
		{ label = "CHROMA", sequence = "post.chromatic", color = p.pink, x = 210, y = 500, w = 122, h = 58 },
		{ label = "GRADE", sequence = "post.grade", color = p.gold, x = 346, y = 500, w = 122, h = 58 },
		{ label = "LENS", sequence = "post.lens", color = p.green, x = 482, y = 500, w = 122, h = 58 },
		{ label = "VIGNETTE", sequence = "post.vignette", color = p.violet, x = 618, y = 500, w = 122, h = 58 },
		{ label = "WEIGHT", sequence = "post.weight", color = p.cyan, x = 754, y = 500, w = 122, h = 58 },
		{ label = "CLEAR", sequence = "post.clear", color = p.pink, x = 890, y = 500, w = 82, h = 58 },
	}

	defineSequences()
	addLog("fx:drawPost captures the bright stage")
end

function Scene.update(ctx, dt)
	time = time + dt
	fx:update(dt)
end

local function drawBrightStage()
	local p = shared.palette
	shared.color({ 0.018, 0.02, 0.03, 1 })
	love.graphics.rectangle("fill", 0, 0, 1040, 680)

	for i = 0, 14 do
		local x = 66 + i * 70
		local y = 178 + math.sin(time * 1.4 + i * 0.42) * 34
		shared.color(i % 3 == 0 and p.cyan or (i % 3 == 1 and p.pink or p.gold), 0.22)
		love.graphics.circle("fill", x, y, 68)
	end

	shared.panel(112, 170, 816, 250, 0.72)
	for i = 0, 8 do
		local x = 164 + i * 86
		local h = 78 + math.sin(time * 2.1 + i) * 42
		shared.color(i % 2 == 0 and p.cyan or p.gold, 0.82)
		love.graphics.rectangle("fill", x, 350 - h, 40, h, 8, 8)
	end

	local v = marker.target.values
	love.graphics.push()
	love.graphics.translate(520, 292)
	love.graphics.scale(v.scale or 1)
	shared.color(marker.color, 0.3 * (v.opacity or 1))
	love.graphics.circle("fill", 0, 0, 96)
	shared.color(marker.color, v.opacity or 1)
	love.graphics.setLineWidth(5)
	love.graphics.circle("line", 0, 0, 74)
	love.graphics.circle("line", 0, 0, 32)
	love.graphics.pop()

	shared.color(p.text)
	love.graphics.printf("post-processing target", 112, 214, 816, "center")
	shared.color(p.muted)
	love.graphics.printf("Bloom, chromatic offset, grading, lens distortion, vignette, and global weight all run after this scene is captured.", 132, 386, 776, "center")
end

local function drawMeters()
	local p = shared.palette
	local post = fx.post.effects
	local rows = {
		{ "bloom", post.bloom.target.values.intensity or 0, p.cyan },
		{ "chroma", post.chromatic.target.values.force or 0, p.pink },
		{ "grade", (post.grade.target.values.saturation or 1) - 1, p.gold },
		{ "lens", post.lens.target.values.distortion or 0, p.green },
		{ "vignette", post.vignette.target.values.intensity or 0, p.violet },
		{ "weight", post.volume.target.values.weight or 1, p.text },
	}

	for i, row in ipairs(rows) do
		local x = 126 + (i - 1) * 145
		local value = math.max(0, math.min(1, row[2]))
		shared.color(p.muted)
		love.graphics.print(row[1], x, 440)
		shared.color({ 1, 1, 1, 0.12 })
		love.graphics.rectangle("fill", x, 462, 104, 8, 4, 4)
		shared.color(row[3], 0.9)
		love.graphics.rectangle("fill", x, 462, 104 * value, 8, 4, 4)
	end
end

function Scene.draw(ctx)
	local p = shared.palette

	fx:drawPost(function()
		drawBrightStage()
	end)

	shared.color(p.text)
	love.graphics.print("post-processing as adapter state", 86, 120)
	shared.color(p.muted)
	love.graphics.print("Recipes tween full-screen shader parameters while the app keeps drawing a normal scene.", 86, 144)

	drawMeters()

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

	shared.drawLogs(logs, 108, 586, 824, 76)
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
