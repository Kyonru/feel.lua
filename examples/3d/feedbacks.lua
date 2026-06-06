local feelFeedbacks = require("feel.feedbacks")

local function create(opts)
	opts = opts or {}
	local colors = opts.colors or {}
	local log = opts.log

	local Feedbacks = feelFeedbacks.new({
		love = opts.fx,
		g3d = opts.g3dfx,
		emit = function(event)
			if type(log) ~= "function" then
				return
			end
			if event.kind and event.kind:match("^post%.") then
				log("post: " .. event.kind)
			elseif event.kind and event.kind:match("^g3d%.") then
				log("g3d: " .. event.kind)
			end
		end,
	})

	Feedbacks.define("hit.heavy", {
		{ kind = "time.freeze", duration = 0.035 },
		{
			kind = "parallel",
			steps = {
				{ kind = "screen.flash", amount = 0.16, duration = 0.12, color = colors.cyan or { 0.2, 0.8, 1, 1 } },
				{ kind = "g3d.camera.shake", amount = 0.15, duration = 0.16, frequency = 36 },
				{ kind = "g3d.camera.fov", amount = 5, duration = 0.05, returnDuration = 0.18 },
				{ kind = "g3d.camera.height", amount = 0.18, duration = 0.06, returnDuration = 0.18 },
				{ kind = "g3d.model.scalePunch", name = "ship", amount = 0.34, duration = 0.06, returnDuration = 0.22 },
				{ kind = "g3d.model.rotationShake", name = "ship", amount = 0.1, duration = 0.16, frequency = 30 },
				{ kind = "g3d.model.positionShake", name = "left-rock", amount = 0.12, duration = 0.18 },
				{ kind = "g3d.model.positionShake", name = "right-rock", amount = 0.1, duration = 0.18 },
				{ kind = "g3d.model.positionShake", name = "rear-rock", amount = 0.08, duration = 0.18 },
				{
					kind = "post.set",
					effect = "bloom",
					values = { intensity = 0.35, threshold = 0.28, softness = 0.34, passes = 3 },
				},
				{
					kind = "post.tween",
					effect = "bloom",
					values = { intensity = 1.85 },
					duration = 0.08,
					ease = "quadout",
					restart = true,
				},
				{
					kind = "post.tween",
					effect = "chromatic",
					values = { force = 1, x = 0.01, y = -0.006 },
					duration = 0.07,
					ease = "quadout",
					restart = true,
				},
				{
					kind = "post.tween",
					effect = "lens",
					values = { distortion = 0.42 },
					duration = 0.08,
					ease = "quadout",
					restart = true,
				},
			},
		},
		{ kind = "wait", duration = 0.14 },
		{
			kind = "parallel",
			steps = {
				{
					kind = "post.tween",
					effect = "bloom",
					values = { intensity = 0.22 },
					duration = 0.36,
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
				{
					kind = "post.tween",
					effect = "lens",
					values = { distortion = 0 },
					duration = 0.22,
					ease = "quadout",
					restart = true,
				},
			},
		},
	})

	Feedbacks.define("ship.lookAt", {
		{ kind = "g3d.model.lookAt", name = "$name", x = "$x", y = "$y", z = "$z" },
	})

	Feedbacks.define("post.focus", {
		{
			kind = "post.tween",
			effect = "vignette",
			values = { intensity = 0.72, radius = 0.68, softness = 0.22 },
			duration = 0.22,
			ease = "quadout",
			restart = true,
		},
		{
			kind = "post.tween",
			effect = "grade",
			values = { exposure = 1.06, saturation = 1.32, hueShift = 0.06, contrast = 0.58 },
			duration = 0.24,
			ease = "quadout",
			restart = true,
		},
		{ kind = "wait", duration = 1.2 },
		{
			kind = "post.tween",
			effect = "vignette",
			values = { intensity = 0.18, radius = 0.8, softness = 0.42 },
			duration = 0.45,
			ease = "quadout",
			restart = true,
		},
		{
			kind = "post.tween",
			effect = "grade",
			values = { exposure = 1, saturation = 1, hueShift = 0, contrast = 0.4 },
			duration = 0.45,
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
		{ kind = "animate", duration = 0.16, ease = "quadout", to = { scale = 0.28 } },
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
				{ kind = "g3d.camera.reset", duration = 0 },
				{ kind = "g3d.model.reset", name = "ship", duration = 0 },
				{ kind = "g3d.model.reset", name = "left-rock", duration = 0 },
				{ kind = "g3d.model.reset", name = "right-rock", duration = 0 },
				{ kind = "g3d.model.reset", name = "rear-rock", duration = 0 },
			},
		},
	})

	return Feedbacks
end

return create
