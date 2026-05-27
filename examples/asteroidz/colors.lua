local palette = {
	bg = { 0.025, 0.027, 0.035, 1 },
	line = { 0.82, 0.92, 1, 1 },
	muted = { 0.48, 0.58, 0.68, 1 },
	cyan = { 0.08, 0.86, 1, 1 },
	pink = { 1, 0.2, 0.48, 1 },
	gold = { 1, 0.72, 0.2, 1 },
	green = { 0.34, 1, 0.58, 1 },
}

local function color(c, alpha)
	love.graphics.setColor(c[1], c[2], c[3], (c[4] or 1) * (alpha or 1))
end

return {
	palette = palette,
	color = color,
}
