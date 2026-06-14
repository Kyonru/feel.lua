local Scene = {
	title = "Spring",
	summary = "Use spring steps for punchy impact motion and springy anchors.",
}

local feel
local shared
local target
local logs
local actions
local selected

local function addLog(text)
	shared.log(logs, text, 10)
end

local function runSequence(sequence, label)
	feel.play(sequence, target, {
		restart = true,
		key = "spring.scene",
		emit = function(event)
			addLog(event.kind .. ":" .. tostring(event.payload and (event.payload.kind or event.kind) or label))
		end,
		onComplete = function()
			addLog("complete " .. label)
		end,
	})
	addLog("play " .. label)
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

local function springImpact()
	runSequence({
		{ kind = "spring", pull = { y = 28, scale = -0.2 }, stiffness = 260, damping = 11 },
	}, "impact")
end

local function springSettle()
	runSequence({
		{ kind = "spring", from = { x = -138, rotation = -0.24 }, to = { x = 0, rotation = 0, y = 0, scale = 1 }, stiffness = 185, damping = 14 },
	}, "settle")
end

local function springHeavy()
	runSequence({
		{ kind = "spring", pull = { scale = -0.28 }, stiffness = 130, damping = 8 },
	}, "heavy")
end

local function drawPod()
	local v = target.values
	local p = shared.palette
	local restY = 356
	local restX = 520

	shared.panel(232, 178, 616, 280)
	shared.color(p.text)
	love.graphics.print("spring target", 276, 212)
	shared.color(p.muted)
	love.graphics.print("Use spring pull and spring to for natural motion: overshoot and settle are built in.", 276, 236)
	shared.color(p.muted)
	love.graphics.print("Press actions repeatedly to feel restart + settle behavior.", 276, 254)

	love.graphics.push()
	love.graphics.translate(restX, restY)
	love.graphics.translate(v.x or 0, v.y or 0)
	love.graphics.rotate(v.rotation or 0)
	shared.color(p.panel, 0.9)
	love.graphics.rectangle("fill", -98, -74, 196, 112, 14, 14)
	shared.color(p.pink)
	love.graphics.rectangle("line", -98, -74, 196, 112, 14, 14)

	local scale = v.scale or 1
	shared.color(p.green)
	love.graphics.circle("line", 0, 0, 26 * scale)
	shared.color(p.cyan, 0.95)
	love.graphics.setLineWidth(4)
	love.graphics.rectangle("line", -36 * scale, -28 * scale, 72 * scale, 56 * scale, 10, 10)
	love.graphics.setLineWidth(1)
	love.graphics.pop()

	shared.color(p.muted)
	love.graphics.printf("scale", 276, 480, 220, "left")
	love.graphics.printf("x", 498, 480, 220, "left")
	shared.color(p.text)
	love.graphics.print(string.format("%.2f", v.scale or 1), 276, 498)
	love.graphics.print(string.format("%.2f", v.x or 0), 498, 498)
end

function Scene.load(ctx)
	feel = ctx.feel
	shared = ctx.shared
	logs = {}
	selected = 1
	target = feel.target({ values = { x = 0, y = 0, scale = 1, rotation = 0 } })

	local p = shared.palette
	actions = {
		{ label = "IMPACT", run = springImpact, color = p.pink, x = 236, y = 552, w = 186, h = 64 },
		{ label = "SETTLE", run = springSettle, color = p.gold, x = 440, y = 552, w = 186, h = 64 },
		{ label = "HEAVY", run = springHeavy, color = p.cyan, x = 644, y = 552, w = 186, h = 64 },
	}

	addLog("click action buttons to trigger spring motion")
end

function Scene.draw(ctx)
	local p = shared.palette
	shared.color(p.text)
	love.graphics.print("Spring step demo", 86, 120)
	shared.color(p.muted)
	love.graphics.print("Try impact for an impulse, settle for to/from motion, and heavy for lower damping.", 86, 144)

	drawPod()

	for i, action in ipairs(actions) do
		local hot = selected == i
		shared.color(hot and shared.mixColor(p.panel, action.color, 0.2) or p.panel)
		love.graphics.rectangle("fill", action.x, action.y, action.w, action.h, 12, 12)
		shared.color(action.color, hot and 1 or 0.55)
		love.graphics.setLineWidth(hot and 4 or 2)
		love.graphics.rectangle("line", action.x, action.y, action.w, action.h, 12, 12)
		shared.color(p.text)
		love.graphics.printf(action.label, action.x, action.y + 22, action.w, "center")
		shared.color(hot and p.text or p.muted, 0.8)
		love.graphics.printf("click", action.x, action.y + 44, action.w, "center")
	end

	shared.drawLogs(logs, 246, 636, 588, 66)
end

function Scene.mousepressed(_, x, y, button)
	if button ~= 1 then
		return
	end
	local index = hitAction(x, y)
	if index then
		selected = index
		actions[index].run()
	end
end

function Scene.keypressed(_, key)
	if key == "up" then
		selected = ((selected - 2) % #actions) + 1
	elseif key == "down" then
		selected = selected % #actions + 1
	elseif key == "space" or key == "return" then
		actions[selected].run()
	end
end

return Scene
