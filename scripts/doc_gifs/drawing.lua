local Draw = {}

Draw.palette = {
  bg = { 0.024, 0.027, 0.036, 1 },
  bg2 = { 0.034, 0.039, 0.054, 1 },
  ink = { 0.92, 0.96, 1, 1 },
  muted = { 0.56, 0.64, 0.75, 1 },
  faint = { 0.24, 0.29, 0.38, 1 },
  panel = { 0.055, 0.064, 0.086, 0.94 },
  panel2 = { 0.035, 0.041, 0.056, 0.96 },
  line = { 1, 1, 1, 0.13 },
  cyan = { 0.1, 0.82, 1, 1 },
  pink = { 1, 0.18, 0.46, 1 },
  gold = { 1, 0.72, 0.18, 1 },
  green = { 0.32, 1, 0.52, 1 },
  violet = { 0.62, 0.38, 1, 1 },
  red = { 1, 0.24, 0.28, 1 },
}

function Draw.setColor(color, alpha)
  love.graphics.setColor(color[1], color[2], color[3], (color[4] or 1) * (alpha or 1))
end

function Draw.clamp(value, minValue, maxValue)
  minValue = minValue or 0
  maxValue = maxValue or 1
  return math.max(minValue, math.min(maxValue, value or 0))
end

function Draw.smooth(value)
  value = Draw.clamp(value, 0, 1)
  return value * value * (3 - 2 * value)
end

function Draw.mix(a, b, t)
  return a + (b - a) * t
end

function Draw.mixColor(a, b, t)
  return {
    Draw.mix(a[1], b[1], t),
    Draw.mix(a[2], b[2], t),
    Draw.mix(a[3], b[3], t),
    Draw.mix(a[4] or 1, b[4] or 1, t),
  }
end

function Draw.copyColor(color)
  return { color[1], color[2], color[3], color[4] or 1 }
end

function Draw.clear(width, height)
  Draw.setColor(Draw.palette.bg)
  love.graphics.rectangle("fill", 0, 0, width, height)

  Draw.setColor(Draw.palette.bg2, 0.78)
  love.graphics.rectangle("fill", 0, 0, width, height)

  Draw.setColor({ 1, 1, 1, 0.035 })
  for y = 0, height, 48 do
    love.graphics.rectangle("fill", 0, y, width, 1)
  end
  for x = 0, width, 48 do
    love.graphics.rectangle("fill", x, 0, 1, height)
  end

  Draw.setColor({ 0, 0, 0, 0.18 })
  love.graphics.rectangle("fill", 0, height - 72, width, 72)
end

function Draw.header(ctx, target)
  local titleY = 28
  love.graphics.setFont(ctx.fonts.title)
  Draw.setColor(Draw.palette.ink)
  love.graphics.print(target.title, 46, titleY)
  love.graphics.setFont(ctx.fonts.body)
  Draw.setColor(Draw.palette.muted)
  love.graphics.print(target.subtitle or "", 48, titleY + ctx.fonts.title:getHeight() + 10)
end

function Draw.stage(x, y, w, h)
  Draw.setColor(Draw.palette.panel, 0.9)
  love.graphics.rectangle("fill", x, y, w, h, 8, 8)
  Draw.setColor({ 1, 1, 1, 0.09 })
  love.graphics.rectangle("line", x + 0.5, y + 0.5, w - 1, h - 1, 8, 8)
end

function Draw.shadow(x, y, w, h, radius, alpha)
  Draw.setColor({ 0, 0, 0, alpha or 0.28 })
  love.graphics.rectangle("fill", x, y, w, h, radius or 10, radius or 10)
end

function Draw.panel(x, y, w, h, alpha)
  Draw.setColor(Draw.palette.panel2, alpha or 1)
  love.graphics.rectangle("fill", x, y, w, h, 8, 8)
  Draw.setColor(Draw.palette.line)
  love.graphics.rectangle("line", x + 0.5, y + 0.5, w - 1, h - 1, 8, 8)
end

function Draw.label(text, x, y, color, font)
  love.graphics.setFont(font)
  Draw.setColor(color or Draw.palette.ink)
  love.graphics.print(text, x, y)
end

function Draw.centerLabel(text, x, y, w, color, font)
  love.graphics.setFont(font)
  Draw.setColor(color or Draw.palette.ink)
  love.graphics.printf(text, x, y, w, "center")
end

function Draw.chip(text, x, y, color, font, alpha)
  font = font or love.graphics.getFont()
  love.graphics.setFont(font)
  local w = font:getWidth(text) + 24
  local h = 28
  Draw.setColor(color, 0.14 * (alpha or 1))
  love.graphics.rectangle("fill", x, y, w, h, 14, 14)
  Draw.setColor(color, 0.68 * (alpha or 1))
  love.graphics.rectangle("line", x + 0.5, y + 0.5, w - 1, h - 1, 14, 14)
  Draw.setColor(Draw.palette.ink, 0.92 * (alpha or 1))
  love.graphics.print(text, x + 12, y + 6)
  return w, h
end

function Draw.chipRow(items, x, y, font)
  local cursor = x
  for _, item in ipairs(items or {}) do
    local w = Draw.chip(item.text, cursor, y, item.color or Draw.palette.cyan, font, item.alpha or 1)
    cursor = cursor + w + 8
  end
end

function Draw.card(x, y, w, h, color, label, font, selected, glow)
  Draw.shadow(x + 6, y + 10, w, h, 10, selected and 0.34 or 0.22)
  if glow and glow > 0 then
    Draw.setColor(color, glow * 0.16)
    love.graphics.rectangle("fill", x - 12, y - 12, w + 24, h + 24, 14, 14)
  end
  Draw.setColor(Draw.palette.panel2)
  love.graphics.rectangle("fill", x, y, w, h, 10, 10)
  Draw.setColor(color, selected and 0.86 or 0.42)
  love.graphics.setLineWidth(selected and 3 or 1)
  love.graphics.rectangle("line", x, y, w, h, 10, 10)
  love.graphics.setLineWidth(1)
  Draw.centerLabel(label, x, y + h / 2 - 9, w, Draw.palette.ink, font)
end

function Draw.button(x, y, w, h, scale, glow, color, label, font)
  love.graphics.push()
  love.graphics.translate(x + w / 2, y + h / 2)
  love.graphics.scale(scale or 1)
  Draw.shadow(-w / 2 + 4, -h / 2 + 10, w, h, 10, 0.24)
  if glow and glow > 0 then
    Draw.setColor(color, glow * 0.2)
    love.graphics.rectangle("fill", -w / 2 - 16, -h / 2 - 16, w + 32, h + 32, 16, 16)
  end
  Draw.setColor(Draw.palette.panel2)
  love.graphics.rectangle("fill", -w / 2, -h / 2, w, h, 10, 10)
  Draw.setColor(color)
  love.graphics.setLineWidth(3)
  love.graphics.rectangle("line", -w / 2, -h / 2, w, h, 10, 10)
  love.graphics.setLineWidth(1)
  Draw.centerLabel(label, -w / 2, -10, w, Draw.palette.ink, font)
  love.graphics.pop()
end

function Draw.meter(x, y, w, h, value, color, label, font)
  value = Draw.clamp(value, 0, 1)
  Draw.setColor({ 1, 1, 1, 0.08 })
  love.graphics.rectangle("fill", x, y, w, h, h / 2, h / 2)
  Draw.setColor(color)
  love.graphics.rectangle("fill", x, y, w * value, h, h / 2, h / 2)
  Draw.setColor({ 1, 1, 1, 0.12 })
  love.graphics.rectangle("line", x, y, w, h, h / 2, h / 2)
  if label then
    Draw.centerLabel(label, x, y + h + 9, w, Draw.palette.muted, font)
  end
end

function Draw.ring(x, y, radius, progress, color, alpha)
  progress = Draw.clamp(progress, 0, 1)
  Draw.setColor(color, alpha or 0.85)
  love.graphics.setLineWidth(4)
  local segments = math.max(6, math.floor(64 * progress))
  local points = {}
  for i = 0, segments do
    local a = -math.pi / 2 + progress * math.pi * 2 * (i / segments)
    points[#points + 1] = x + math.cos(a) * radius
    points[#points + 1] = y + math.sin(a) * radius
  end
  if #points >= 4 then
    love.graphics.line(points)
  end
  love.graphics.setLineWidth(1)
end

function Draw.spark(x, y, radius, color, alpha)
  alpha = alpha or 1
  Draw.setColor(color, alpha)
  love.graphics.circle("fill", x, y, radius)
  Draw.setColor(color, alpha * 0.2)
  love.graphics.circle("fill", x, y, radius * 3.4)
end

function Draw.star(x, y, radius, color, alpha)
  Draw.setColor(color, alpha or 1)
  love.graphics.polygon("fill",
    x, y - radius,
    x + radius * 0.26, y - radius * 0.26,
    x + radius, y,
    x + radius * 0.26, y + radius * 0.26,
    x, y + radius,
    x - radius * 0.26, y + radius * 0.26,
    x - radius, y,
    x - radius * 0.26, y - radius * 0.26
  )
end

function Draw.wave(x, y, w, h, amount, color)
  Draw.setColor(color)
  love.graphics.setLineWidth(3)
  local points = {}
  local amp = h * (0.12 + 0.36 * Draw.clamp(amount, 0, 1))
  for i = 0, 48 do
    local p = i / 48
    points[#points + 1] = x + p * w
    points[#points + 1] = y + h / 2 + math.sin(p * math.pi * 7) * amp
  end
  love.graphics.line(points)
  love.graphics.setLineWidth(1)
end

function Draw.beam(x1, y1, x2, y2, color, alpha)
  Draw.setColor(color, (alpha or 1) * 0.18)
  love.graphics.setLineWidth(13)
  love.graphics.line(x1, y1, x2, y2)
  Draw.setColor(color, alpha or 1)
  love.graphics.setLineWidth(3)
  love.graphics.line(x1, y1, x2, y2)
  love.graphics.setLineWidth(1)
end

function Draw.ship(x, y, rotation, color, scale)
  scale = scale or 1
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation or 0)
  love.graphics.scale(scale)
  Draw.shadow(-20, -10, 40, 26, 8, 0.2)
  Draw.setColor(color)
  love.graphics.polygon("fill", 28, 0, -18, -18, -8, 0, -18, 18)
  Draw.setColor({ 1, 1, 1, 0.18 })
  love.graphics.polygon("fill", 15, 0, -10, -10, -5, 0, -10, 10)
  Draw.setColor(Draw.palette.ink, 0.9)
  love.graphics.setLineWidth(2)
  love.graphics.polygon("line", 28, 0, -18, -18, -8, 0, -18, 18)
  love.graphics.setLineWidth(1)
  love.graphics.pop()
end

function Draw.controller(x, y, left, right, color)
  Draw.shadow(x + 8, y + 12, 224, 108, 22, 0.24)
  Draw.setColor(Draw.palette.panel2)
  love.graphics.rectangle("fill", x, y, 224, 108, 24, 24)
  Draw.setColor(color, 0.72)
  love.graphics.rectangle("line", x, y, 224, 108, 24, 24)
  Draw.setColor(Draw.palette.faint)
  love.graphics.circle("fill", x + 62, y + 54, 25)
  love.graphics.circle("fill", x + 162, y + 54, 25)
  Draw.setColor(color, 0.2 + left * 0.72)
  love.graphics.circle("fill", x + 62, y + 54, 18 + left * 12)
  Draw.setColor(color, 0.2 + right * 0.72)
  love.graphics.circle("fill", x + 162, y + 54, 18 + right * 12)
end

function Draw.isoBox(x, y, w, h, depth, color, scale, rotation)
  scale = scale or 1
  rotation = rotation or 0
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation)
  love.graphics.scale(scale)
  Draw.shadow(-w / 2 + 10, h / 2 + depth * 0.5, w, 28, 14, 0.22)
  local top = Draw.mixColor(color, { 1, 1, 1, 1 }, 0.22)
  local side = Draw.mixColor(color, { 0, 0, 0, 1 }, 0.26)
  local side2 = Draw.mixColor(color, { 0, 0, 0, 1 }, 0.42)
  Draw.setColor(side2)
  love.graphics.polygon("fill", -w / 2, -h / 2, 0, -h / 2 + depth, 0, h / 2 + depth, -w / 2, h / 2)
  Draw.setColor(side)
  love.graphics.polygon("fill", w / 2, -h / 2, 0, -h / 2 + depth, 0, h / 2 + depth, w / 2, h / 2)
  Draw.setColor(top)
  love.graphics.polygon("fill", -w / 2, -h / 2, 0, -h / 2 + depth, w / 2, -h / 2, 0, -h / 2 - depth)
  Draw.setColor(color)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", -w / 2, -h / 2, w, h, 4, 4)
  love.graphics.setLineWidth(1)
  love.graphics.pop()
end

return Draw
