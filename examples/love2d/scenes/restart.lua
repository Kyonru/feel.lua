local Scene = {
	title = "Restart",
	summary = "Compare stacked plays with keyed restart cancellation.",
}

local feel
local shared
local actions
local logs
local selected
local lanes

local function addLog(text)
	shared.log(logs, text, 2)
end

local function pulseSequence(lane)
	return {
		{ kind = "animate", duration = 0.08, to = { scale = 1.32, opacity = 1, x = 72 }, ease = "quadout" },
		{ kind = "wait", duration = 0.28 },
		{ kind = "animate", duration = 0.22, to = { scale = 1, opacity = 0, x = 0 }, ease = "quadout" },
		{
			kind = "callback",
			callback = function()
				lane.done = lane.done + 1
				addLog(lane.label .. " complete " .. tostring(lane.done))
			end,
		},
	}
end

local function playLane(lane)
	lane.started = lane.started + 1
	addLog(lane.label .. " start " .. tostring(lane.started))

	local opts
	if lane.restart then
		opts = {
			restart = true,
			key = "restart.example." .. lane.label,
		}
	end

	feel.play(pulseSequence(lane), lane.target, opts)
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
	shared = ctx.shared
	logs = {}
	selected = 1

	local p = shared.palette
	lanes = {
		stack = {
			label = "stack",
			title = "NO RESTART",
			subtitle = "Every trigger is allowed to finish.",
			color = p.gold,
			y = 190,
			started = 0,
			done = 0,
			target = feel.target({ values = { scale = 1, opacity = 0, x = 0 } }),
		},
		restart = {
			label = "restart",
			title = "RESTART",
			subtitle = "A new trigger cancels the previous run.",
			color = p.cyan,
			y = 360,
			started = 0,
			done = 0,
			restart = true,
			target = feel.target({ values = { scale = 1, opacity = 0, x = 0 } }),
		},
	}

	actions = {
		{ label = "STACK", lane = lanes.stack, color = p.gold, x = 184, y = 532, w = 280, h = 62 },
		{ label = "RESTART", lane = lanes.restart, color = p.cyan, x = 576, y = 532, w = 280, h = 62 },
	}

	addLog("trigger either lane rapidly")
end

local function drawLane(lane)
	local p = shared.palette
	local v = lane.target.values
	local x = 154
	local y = lane.y
	local w = 732
	local h = 118

	shared.panel(x, y, w, h)
	shared.color(lane.color, 0.15 + (v.opacity or 0) * 0.25)
	love.graphics.rectangle("fill", x + 16, y + 16, w - 32, h - 32, 12, 12)

	shared.color(p.text)
	love.graphics.print(lane.title, x + 26, y + 24)
	shared.color(p.muted)
	love.graphics.print(lane.subtitle, x + 26, y + 48)
	love.graphics.print("started " .. tostring(lane.started), x + 26, y + 76)
	love.graphics.print("completed " .. tostring(lane.done), x + 150, y + 76)

	love.graphics.push()
	love.graphics.translate(x + 545 + (v.x or 0), y + 60)
	love.graphics.scale(v.scale or 1)
	shared.color(lane.color, 0.95)
	love.graphics.circle("fill", 0, 0, 24)
	shared.color(p.text, 0.9)
	love.graphics.circle("line", 0, 0, 33)
	love.graphics.pop()
end

function Scene.draw(ctx)
	local p = shared.palette

	shared.color(p.text)
	love.graphics.print("core restart slots", 86, 120)
	shared.color(p.muted)
	love.graphics.print("Click a lane repeatedly before the pulse completes to see whether old runs finish.", 86, 144)

	drawLane(lanes.stack)
	drawLane(lanes.restart)

	for i, action in ipairs(actions) do
		local hot = selected == i
		shared.color(hot and shared.mixColor(p.panel, action.color, 0.22) or p.panel)
		love.graphics.rectangle("fill", action.x, action.y, action.w, action.h, 12, 12)
		shared.color(action.color, hot and 1 or 0.58)
		love.graphics.setLineWidth(hot and 4 or 2)
		love.graphics.rectangle("line", action.x, action.y, action.w, action.h, 12, 12)
		shared.color(p.text)
		love.graphics.printf(action.label, action.x, action.y + 22, action.w, "center")
	end

	shared.drawLogs(logs, 184, 608, 672, 60)
end

function Scene.mousepressed(ctx, x, y, button)
	if button ~= 1 then
		return
	end
	local index = hitAction(x, y)
	if index then
		selected = index
		playLane(actions[index].lane)
	end
end

function Scene.keypressed(ctx, key)
	if key == "down" then
		selected = selected % #actions + 1
	elseif key == "up" then
		selected = ((selected - 2) % #actions) + 1
	elseif key == "return" or key == "space" then
		playLane(actions[selected].lane)
	end
end

return Scene
