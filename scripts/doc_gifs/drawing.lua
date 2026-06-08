local Draw = {}

Draw.palette = {
  bg = { 0.025, 0.028, 0.04, 1 },
  bg2 = { 0.04, 0.045, 0.062, 1 },
  panel = { 0.07, 0.08, 0.108, 0.96 },
  panel2 = { 0.04, 0.046, 0.064, 0.94 },
  line = { 1, 1, 1, 0.13 },
  text = { 0.94, 0.97, 1, 1 },
  muted = { 0.58, 0.66, 0.76, 1 },
  cyan = { 0.1, 0.82, 1, 1 },
  pink = { 1, 0.18, 0.46, 1 },
  gold = { 1, 0.72, 0.18, 1 },
  green = { 0.32, 1, 0.52, 1 },
  violet = { 0.62, 0.38, 1, 1 },
}

function Draw.setColor(color, alpha)
  love.graphics.setColor(color[1], color[2], color[3], (color[4] or 1) * (alpha or 1))
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

function Draw.clamp(value, minValue, maxValue)
  return math.max(minValue, math.min(maxValue, value))
end

function Draw.smooth(value)
  value = Draw.clamp(value, 0, 1)
  return value * value * (3 - 2 * value)
end

function Draw.clear(width, height)
  Draw.setColor(Draw.palette.bg)
  love.graphics.rectangle("fill", 0, 0, width, height)
  Draw.setColor(Draw.palette.bg2, 0.54)
  for y = 0, height, 36 do
    love.graphics.rectangle("fill", 0, y, width, 1)
  end
  for x = 0, width, 36 do
    love.graphics.rectangle("fill", x, 0, 1, height)
  end
end

function Draw.header(ctx, target)
  love.graphics.setFont(ctx.fonts.title)
  Draw.setColor(Draw.palette.text)
  love.graphics.print(target.title, 56, 42)
  love.graphics.setFont(ctx.fonts.body)
  Draw.setColor(Draw.palette.muted)
  love.graphics.print(target.subtitle or "", 58, 84)
end

function Draw.panel(x, y, w, h, alpha)
  Draw.setColor(Draw.palette.panel, alpha or 1)
  love.graphics.rectangle("fill", x, y, w, h, 8, 8)
  Draw.setColor(Draw.palette.line)
  love.graphics.rectangle("line", x + 0.5, y + 0.5, w - 1, h - 1, 8, 8)
end

function Draw.label(text, x, y, color, font)
  love.graphics.setFont(font)
  Draw.setColor(color or Draw.palette.text)
  love.graphics.print(text, x, y)
end

function Draw.centerLabel(text, x, y, w, color, font)
  love.graphics.setFont(font)
  Draw.setColor(color or Draw.palette.text)
  love.graphics.printf(text, x, y, w, "center")
end

function Draw.button(x, y, w, h, scale, glow, color, label, font)
  love.graphics.push()
  love.graphics.translate(x + w / 2, y + h / 2)
  love.graphics.scale(scale or 1)

  Draw.setColor(color, 0.18 + (glow or 0) * 0.26)
  love.graphics.rectangle("fill", -w / 2 - 18, -h / 2 - 18, w + 36, h + 36, 12, 12)
  Draw.setColor(Draw.palette.panel2)
  love.graphics.rectangle("fill", -w / 2, -h / 2, w, h, 8, 8)
  Draw.setColor(color)
  love.graphics.setLineWidth(3)
  love.graphics.rectangle("line", -w / 2, -h / 2, w, h, 8, 8)
  love.graphics.setLineWidth(1)
  Draw.centerLabel(label, -w / 2, -10, w, Draw.palette.text, font)

  love.graphics.pop()
end

function Draw.progressBar(x, y, w, h, progress, color, label, font)
  Draw.setColor(Draw.palette.panel2)
  love.graphics.rectangle("fill", x, y, w, h, 6, 6)
  Draw.setColor(color)
  love.graphics.rectangle("fill", x, y, w * Draw.clamp(progress, 0, 1), h, 6, 6)
  Draw.setColor(Draw.palette.line)
  love.graphics.rectangle("line", x, y, w, h, 6, 6)
  if label then
    Draw.centerLabel(label, x, y + h + 10, w, Draw.palette.muted, font)
  end
end

function Draw.timelineStep(x, y, w, h, label, active, done, color, font)
  local alpha = done and 1 or (active and 0.88 or 0.34)
  Draw.setColor(done and color or Draw.palette.panel2, alpha)
  love.graphics.rectangle("fill", x, y, w, h, 8, 8)
  Draw.setColor(active and color or Draw.palette.line, active and 1 or 0.9)
  love.graphics.setLineWidth(active and 3 or 1)
  love.graphics.rectangle("line", x, y, w, h, 8, 8)
  love.graphics.setLineWidth(1)
  Draw.centerLabel(label, x, y + h / 2 - 8, w, Draw.palette.text, font)
end

function Draw.spark(x, y, radius, color, alpha)
  Draw.setColor(color, alpha or 1)
  love.graphics.circle("fill", x, y, radius)
  Draw.setColor(color, (alpha or 1) * 0.22)
  love.graphics.circle("fill", x, y, radius * 3)
end

function Draw.wave(x, y, w, h, amount, color)
  Draw.setColor(color)
  love.graphics.setLineWidth(3)
  local points = {}
  local amp = h * (0.18 + 0.32 * Draw.clamp(amount, 0, 1))
  for i = 0, 42 do
    local p = i / 42
    points[#points + 1] = x + p * w
    points[#points + 1] = y + h / 2 + math.sin(p * math.pi * 6) * amp * (0.35 + amount * 0.65)
  end
  love.graphics.line(points)
  love.graphics.setLineWidth(1)
end

function Draw.isoBox(x, y, w, h, depth, color, scale, rotation)
  scale = scale or 1
  rotation = rotation or 0
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation)
  love.graphics.scale(scale)

  local top = Draw.mixColor(color, { 1, 1, 1, 1 }, 0.22)
  local side = Draw.mixColor(color, { 0, 0, 0, 1 }, 0.28)
  local side2 = Draw.mixColor(color, { 0, 0, 0, 1 }, 0.42)

  Draw.setColor(side2)
  love.graphics.polygon("fill", -w / 2, -h / 2, 0, -h / 2 + depth, 0, h / 2 + depth, -w / 2, h / 2)
  Draw.setColor(side)
  love.graphics.polygon("fill", w / 2, -h / 2, 0, -h / 2 + depth, 0, h / 2 + depth, w / 2, h / 2)
  Draw.setColor(top)
  love.graphics.polygon("fill", -w / 2, -h / 2, 0, -h / 2 + depth, w / 2, -h / 2, 0, -h / 2 - depth)
  Draw.setColor(color)
  love.graphics.rectangle("line", -w / 2, -h / 2, w, h, 4, 4)

  love.graphics.pop()
end

return Draw
