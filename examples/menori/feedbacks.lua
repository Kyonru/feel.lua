local feelFeedbacks = require("feel.feedbacks")

local function create(opts)
	opts = opts or {}
	local colors = opts.colors or {}
	local log = opts.log

	local Feedbacks = feelFeedbacks.new({
		love = opts.fx,
		menori = opts.menorifx,
		emit = function(event)
			if type(log) ~= "function" then
				return
			end
			if event.kind and event.kind:match("^menori%.") then
				log("menori: " .. event.kind)
			elseif event.kind and event.kind:match("^post%.") then
				log("post: " .. event.kind)
			end
		end,
	})

	Feedbacks.define("hit.heavy", {
		{ kind = "time.freeze", duration = 0.035 },
		{
			kind = "parallel",
			steps = {
				{ kind = "screen.flash", amount = 0.14, duration = 0.11, color = colors.cyan or { 0.2, 0.8, 1, 1 } },
				{ kind = "menori.camera.shake", amount = 0.09, duration = 0.14, frequency = 36 },
				{ kind = "menori.camera.fov", amount = 4, duration = 0.05, returnDuration = 0.18 },
				{ kind = "menori.camera.distance", amount = -0.42, duration = 0.06, returnDuration = 0.24 },
				{ kind = "menori.camera.yaw", amount = 3, duration = 0.06, returnDuration = 0.2 },
				{ kind = "menori.node.scalePunch", name = "core", amount = 0.32, duration = 0.06, returnDuration = 0.22 },
				{ kind = "menori.node.rotationShake", name = "core", amount = 0.12, duration = 0.16, frequency = 32 },
				{ kind = "menori.node.positionShake", name = "left-obelisk", amount = 0.08, duration = 0.18 },
				{ kind = "menori.node.positionShake", name = "right-obelisk", amount = 0.08, duration = 0.18 },
				{ kind = "menori.node.scalePunch", name = "satellite", amount = 0.24, duration = 0.06, returnDuration = 0.2 },
				{
					kind = "menori.uniform.pulse",
					name = "core.tint",
					values = { r = 1, g = 0.24, b = 0.58 },
					duration = 0.05,
					returnDuration = 0.38,
				},
				{
					kind = "menori.uniform.pulse",
					name = "satellite.tint",
					values = { r = 1, g = 0.88, b = 0.2 },
					duration = 0.05,
					returnDuration = 0.28,
				},
				{
					kind = "post.tween",
					effect = "bloom",
					values = { intensity = 1.65, threshold = 0.28, softness = 0.34, passes = 3 },
					duration = 0.08,
					ease = "quadout",
					restart = true,
				},
				{
					kind = "post.tween",
					effect = "chromatic",
					values = { force = 0.7, x = 0.006, y = -0.004 },
					duration = 0.08,
					ease = "quadout",
					restart = true,
				},
			},
		},
		{ kind = "wait", duration = 0.12 },
		{
			kind = "parallel",
			steps = {
				{
					kind = "post.tween",
					effect = "bloom",
					values = { intensity = 0.2 },
					duration = 0.34,
					ease = "quadout",
					restart = true,
				},
				{
					kind = "post.tween",
					effect = "chromatic",
					values = { force = 0, x = 0, y = 0 },
					duration = 0.22,
					ease = "quadout",
					restart = true,
				},
			},
		},
	})

	Feedbacks.define("orbit.boost", {
		{ kind = "menori.animation.speed", name = "satellite-orbit", speed = 2.8, duration = 0.1, ease = "quadout" },
		{ kind = "wait", duration = 0.7 },
		{ kind = "menori.animation.speed", name = "satellite-orbit", speed = 1, duration = 0.22, ease = "quadout" },
	})

	Feedbacks.define("orbit.pause", {
		{ kind = "menori.animation.pause", name = "satellite-orbit" },
		{ kind = "menori.uniform.set", name = "satellite.tint", values = { r = 0.48, g = 0.55, b = 0.7 }, duration = 0.12 },
	})

	Feedbacks.define("orbit.resume", {
		{ kind = "menori.animation.play", name = "satellite-orbit" },
		{ kind = "menori.uniform.reset", name = "satellite.tint", duration = 0.16 },
	})

	Feedbacks.define("orbit.seek", {
		{ kind = "menori.animation.seek", name = "satellite-orbit", time = "$time" },
		{ kind = "menori.node.scalePunch", name = "satellite", amount = 0.18, duration = 0.05, returnDuration = 0.16 },
	})

	Feedbacks.define("orbit.action", {
		{ kind = "menori.animation.action", name = "satellite-orbit", action = "$action", reset = false },
		{ kind = "menori.uniform.pulse", name = "satellite.tint", values = { r = 0.45, g = 1, b = 0.54 }, duration = 0.05 },
	})

	Feedbacks.define("palette.hot", {
		{ kind = "menori.uniform.pulse", name = "core.tint", values = { r = 1, g = 0.34, b = 0.12 }, duration = 0.06, returnDuration = 0.42 },
		{ kind = "menori.uniform.pulse", name = "left.tint", values = { r = 1, g = 0.6, b = 0.2 }, duration = 0.06, returnDuration = 0.42 },
		{ kind = "menori.uniform.pulse", name = "right.tint", values = { r = 1, g = 0.32, b = 0.42 }, duration = 0.06, returnDuration = 0.42 },
	})

	Feedbacks.define("post.focus", {
		{
			kind = "post.tween",
			effect = "vignette",
			values = { intensity = 0.68, radius = 0.68, softness = 0.24 },
			duration = 0.22,
			ease = "quadout",
			restart = true,
		},
		{
			kind = "post.tween",
			effect = "grade",
			values = { exposure = 1.08, saturation = 1.28, hueShift = 0.04, contrast = 0.58 },
			duration = 0.22,
			ease = "quadout",
			restart = true,
		},
		{ kind = "wait", duration = 1.1 },
		{
			kind = "post.tween",
			effect = "vignette",
			values = { intensity = 0.18, radius = 0.82, softness = 0.42 },
			duration = 0.4,
			ease = "quadout",
			restart = true,
		},
		{
			kind = "post.tween",
			effect = "grade",
			values = { exposure = 1, saturation = 1, hueShift = 0, contrast = 0.4 },
			duration = 0.4,
			ease = "quadout",
			restart = true,
		},
	})

	Feedbacks.define("post.clear", {
		{ kind = "post.clear" },
		{ kind = "screen.clear" },
	})

	Feedbacks.define("time.normal", {
		{ kind = "animate", duration = 0.16, ease = "quadout", to = { scale = 1 } },
	})

	Feedbacks.define("time.slow", {
		{ kind = "animate", duration = 0.16, ease = "quadout", to = { scale = 0.3 } },
	})

	Feedbacks.define("time.pause", {
		{ kind = "animate", duration = 0.08, ease = "quadout", to = { scale = 0 } },
	})

	Feedbacks.define("demo.reset", {
		{
			kind = "parallel",
			steps = {
				{ kind = "post.clear" },
				{ kind = "screen.clear" },
				{ kind = "menori.camera.reset", duration = 0 },
				{ kind = "menori.node.reset", name = "core", duration = 0 },
				{ kind = "menori.node.reset", name = "left-obelisk", duration = 0 },
				{ kind = "menori.node.reset", name = "right-obelisk", duration = 0 },
				{ kind = "menori.node.reset", name = "satellite", duration = 0 },
				{ kind = "menori.uniform.reset", name = "core.tint", duration = 0 },
				{ kind = "menori.uniform.reset", name = "left.tint", duration = 0 },
				{ kind = "menori.uniform.reset", name = "right.tint", duration = 0 },
				{ kind = "menori.uniform.reset", name = "satellite.tint", duration = 0 },
				{ kind = "menori.animation.play", name = "satellite-orbit", action = "orbit", reset = true },
				{ kind = "menori.animation.speed", name = "satellite-orbit", speed = 1, duration = 0 },
			},
		},
	})

	return Feedbacks
end

return create
