local feel = require("feel")
local constants = require("constants")
local palette = require("colors").palette
local effects = require("effects")
local ship = require("ship")
local pubSub = require("pubsub")

local function play_sequence(name, target, extra)
	extra = extra or {}
	local opts = constants.fx:handlers({
		trigger = extra.trigger or "game",
		restart = extra.restart,
		key = extra.key,
		emit = function(event)
			if event.kind == "ship.trail" then
				local back = ship.angle + math.pi
				effects.emitParticles(ship.x + math.cos(back) * 14, ship.y + math.sin(back) * 14, palette.cyan, 2, 95)
			elseif event.kind == "spark" then
				effects.emitParticles(
					extra.x or ship.x,
					extra.y or ship.y,
					extra.color or palette.gold,
					event.payload.count or 14,
					event.payload.speed or 180
				)
			end
		end,
	})
	feel.play(name, target, opts)
end

local function create_sequences()
	feel.clear()

	feel.define("ship.thrust", {
		{ kind = "emit", event = "ship.trail" },
		{ kind = "animate", duration = 0.05, to = { scale = 1.08 }, ease = "quadout" },
		{ kind = "animate", duration = 0.1, to = { scale = 1 }, ease = "quadout" },
	})

	feel.define("ship.shoot", {
		{ kind = "audio", cue = "shoot" },
		{ kind = "emit", event = "screen.flash", payload = { color = palette.cyan, amount = 0.08, duration = 0.06 } },
		{ kind = "animate", duration = 0.04, to = { scaleX = 0.88, scaleY = 1.18 }, ease = "quadout" },
		{ kind = "animate", duration = 0.1, to = { scaleX = 1, scaleY = 1 }, ease = "backout" },
	})

	feel.define("asteroid.hit", {
		{ kind = "audio", cue = "hit" },
		{
			kind = "parallel",
			steps = {
				{ kind = "emit", event = "camera.shake", payload = { amount = 5, duration = 0.14, frequency = 36 } },
				{
					kind = "emit",
					event = "screen.flash",
					payload = { color = palette.gold, amount = 0.16, duration = 0.1 },
				},
				{ kind = "animate", duration = 0.08, to = { scale = 1.25, opacity = 0.35 }, ease = "quadout" },
			},
		},
	})

	feel.define("ship.teleport", {
		{
			kind = "emit",
			event = "post.set",
			payload = { effect = "bloom", values = { intensity = 10, threshold = 0.52, softness = 0.18, passes = 3 } },
		},
		{
			kind = "parallel",
			steps = {
				{
					kind = "emit",
					event = "post.tween",
					payload = { effect = "lens", values = { distortion = 1.5 }, duration = 0.1, ease = "quadout" },
				},
				{
					kind = "emit",
					event = "post.tween",
					payload = { effect = "bloom", values = { intensity = 10 }, duration = 0.1, ease = "quadout" },
				},
				{ kind = "animate", duration = 0.06, to = { teleportGlow = 1 }, ease = "quadout" },
			},
		},
		{ kind = "wait", duration = 0.12 },
		{
			kind = "parallel",
			steps = {
				{
					kind = "emit",
					event = "post.tween",
					payload = { effect = "lens", values = { distortion = 0 }, duration = 0.1, ease = "quadout" },
				},
				{
					kind = "emit",
					event = "post.tween",
					payload = { effect = "bloom", values = { intensity = 0 }, duration = 0.1, ease = "quadout" },
				},
				{ kind = "animate", duration = 0.24, to = { teleportGlow = 0 }, ease = "quadout" },
			},
		},
	})

	feel.define("ship.explode", {
		{ kind = "audio", cue = "boom" },
		{
			kind = "parallel",
			steps = {
				{ kind = "emit", event = "camera.shake", payload = { amount = 18, duration = 0.42, frequency = 30 } },
				{
					kind = "emit",
					event = "screen.flash",
					payload = { color = palette.pink, amount = 0.42, duration = 0.22 },
				},
				{
					kind = "animate",
					duration = 0.12,
					to = { opacity = 0.15, scale = 1.45, rotation = 0.8 },
					ease = "quadout",
				},
				{ kind = "emit", event = "post.set", payload = { effect = "chromatic", values = { force = 0 } } },
				{
					kind = "emit",
					event = "post.tween",
					payload = {
						effect = "chromatic",
						values = { force = 1, x = -0.0001, y = 0.0001 },
						duration = 0.08,
						ease = "quadout",
					},
				},
			},
		},
		{ kind = "wait", duration = 0.25 },
		{
			kind = "parallel",
			steps = {
				{ kind = "animate", duration = 0.2, to = { opacity = 1, scale = 1, rotation = 0 }, ease = "backout" },
				{
					kind = "emit",
					event = "post.tween",
					payload = {
						effect = "chromatic",
						values = { force = 0, x = 0, y = 0 },
						duration = 0.1,
						ease = "quadout",
					},
				},
			},
		},
	})

	pubSub:on("play_sequence", function(props)
		play_sequence(props.name, props.target, props.extra)
	end)
end

return {
	create = create_sequences,
	play = play_sequence,
}
