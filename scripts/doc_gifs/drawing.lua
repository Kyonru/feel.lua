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

function Draw.feedbackChip(text, x, y, color, font, alpha)
  font = font or love.graphics.getFont()
  alpha = alpha or 1
  love.graphics.setFont(font)
  local w = font:getWidth(text) + 34
  local h = 30
  Draw.setColor(Draw.palette.panel2, 0.96 * alpha)
  love.graphics.rectangle("fill", x, y, w, h, 2, 2)
  Draw.setColor(color, 0.78 * alpha)
  love.graphics.rectangle("fill", x, y, 5, h)
  Draw.setColor(color, 0.56 * alpha)
  love.graphics.rectangle("line", x + 0.5, y + 0.5, w - 1, h - 1, 2, 2)
  Draw.setColor(Draw.palette.ink, 0.94 * alpha)
  love.graphics.print(text, x + 17, y + 7)
  return w, h
end

function Draw.feedbackRow(items, x, y, font)
  local cursor = x
  for _, item in ipairs(items or {}) do
    local w = Draw.feedbackChip(item.text, cursor, y, item.color or Draw.palette.cyan, font, item.alpha or 1)
    cursor = cursor + w + 7
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

function Draw.ring(x, y, radius, progress, color, alpha, lineWidth)
  progress = Draw.clamp(progress, 0, 1)
  Draw.setColor(color, alpha or 0.85)
  love.graphics.setLineWidth(lineWidth or 4)
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

function Draw.heart(x, y, size, color, alpha, scale, mode, lineWidth)
  local points = {}
  scale = scale or 1
  for i = 0, 64 do
    local angle = i / 64 * math.pi * 2
    local px = 16 * math.sin(angle) ^ 3
    local py = 13 * math.cos(angle) - 5 * math.cos(angle * 2) - 2 * math.cos(angle * 3) - math.cos(angle * 4)
    points[#points + 1] = x + px / 17 * size * scale
    points[#points + 1] = y - py / 17 * size * scale
  end
  Draw.setColor(color, alpha or 1)
  love.graphics.setLineWidth(lineWidth or 1)
  love.graphics.polygon(mode or "fill", points)
  love.graphics.setLineWidth(1)
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

function Draw.controller(image, x, y, left, right, leftColor, rightColor)
  local scale = 2.5
  local leftX = x - 90
  local rightX = x + 90
  local motorY = y + 46

  Draw.shadow(x - 132, y + 78, 264, 24, 12, 0.28)
  Draw.setColor(leftColor, 0.08 + left * 0.18)
  love.graphics.circle("fill", leftX, motorY, 31 + left * 18)
  Draw.setColor(rightColor, 0.08 + right * 0.18)
  love.graphics.circle("fill", rightX, motorY, 31 + right * 18)

  Draw.setColor({ 1, 1, 1, 1 })
  love.graphics.draw(image, x, y, 0, scale, scale, image:getWidth() / 2, image:getHeight() / 2)

  Draw.setColor(Draw.palette.panel2, 0.9)
  love.graphics.circle("fill", leftX, motorY, 12)
  love.graphics.circle("fill", rightX, motorY, 12)
  Draw.setColor(leftColor, 0.34 + left * 0.66)
  love.graphics.circle("fill", leftX, motorY, 6 + left * 5)
  Draw.setColor(rightColor, 0.34 + right * 0.66)
  love.graphics.circle("fill", rightX, motorY, 6 + right * 5)

  Draw.ring(leftX, motorY, 28 + left * 22, 1, leftColor, left * 0.82)
  Draw.ring(rightX, motorY, 28 + right * 22, 1, rightColor, right * 0.82)
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

function Draw.cube3d(x, y, size, yaw, pitch, roll, color, fov, scale)
  yaw = yaw or 0
  pitch = pitch or 0
  roll = roll or 0
  fov = fov or 60
  scale = scale or 1

  local cy, sy = math.cos(yaw), math.sin(yaw)
  local cp, sp = math.cos(pitch), math.sin(pitch)
  local cr, sr = math.cos(roll), math.sin(roll)
  local distance = 4.5
  local focalScale = 60 / math.max(30, fov)
  local source = {
    { -1, -1, -1 }, { 1, -1, -1 },
    { 1, 1, -1 }, { -1, 1, -1 },
    { -1, -1, 1 }, { 1, -1, 1 },
    { 1, 1, 1 }, { -1, 1, 1 },
  }
  local points = {}
  local transformed = {}

  for i, vertex in ipairs(source) do
    local vx, vy, vz = vertex[1], vertex[2], vertex[3]
    local yawX = vx * cy + vz * sy
    local yawZ = -vx * sy + vz * cy
    local pitchY = vy * cp - yawZ * sp
    local pitchZ = vy * sp + yawZ * cp
    local rollX = yawX * cr - pitchY * sr
    local rollY = yawX * sr + pitchY * cr
    local perspective = size * scale * focalScale * distance / (distance + pitchZ)
    points[i] = { x + rollX * perspective, y - rollY * perspective }
    transformed[i] = { rollX, rollY, pitchZ }
  end

  local faces = {
    { indices = { 1, 2, 3, 4 }, shade = 0.02 },
    { indices = { 5, 8, 7, 6 }, shade = -0.32 },
    { indices = { 1, 4, 8, 5 }, shade = -0.22 },
    { indices = { 2, 6, 7, 3 }, shade = -0.1 },
    { indices = { 4, 3, 7, 8 }, shade = 0.22 },
    { indices = { 1, 5, 6, 2 }, shade = -0.38 },
  }

  for _, face in ipairs(faces) do
    face.depth = 0
    for _, index in ipairs(face.indices) do
      face.depth = face.depth + transformed[index][3]
    end
    face.depth = face.depth / #face.indices
  end
  table.sort(faces, function(a, b) return a.depth > b.depth end)

  for _, face in ipairs(faces) do
    local polygon = {}
    for _, index in ipairs(face.indices) do
      polygon[#polygon + 1] = points[index][1]
      polygon[#polygon + 1] = points[index][2]
    end
    local faceColor
    if face.shade >= 0 then
      faceColor = Draw.mixColor(color, { 1, 1, 1, 1 }, face.shade)
    else
      faceColor = Draw.mixColor(color, { 0, 0, 0, 1 }, -face.shade)
    end
    Draw.setColor(faceColor)
    love.graphics.polygon("fill", polygon)
    Draw.setColor(Draw.palette.ink, 0.34)
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", polygon)
  end
  love.graphics.setLineWidth(1)
end

local function nearestImage(path)
  local image = love.graphics.newImage(path)
  image:setFilter("nearest", "nearest")
  return image
end

local function imagePair(root, first, second)
  return { nearestImage(root .. first), nearestImage(root .. second) }
end

-- Kenney New Platformer Pack 1.1 (CC0): https://kenney.nl/assets/new-platformer-pack
-- Only the selected frames used by these captures are vendored with the app.
function Draw.loadKenneyPlatformer()
  local root = "assets/kenney-new-platformer/"
  local actorRoot = root .. "actors/"
  local backgroundRoot = root .. "backgrounds/"
  local terrainRoot = root .. "terrain/"
  return {
    actors = {
      mouse = imagePair(actorRoot, "mouse_walk_a.png", "mouse_walk_b.png"),
      snail = imagePair(actorRoot, "snail_walk_a.png", "snail_walk_b.png"),
      ladybug = imagePair(actorRoot, "ladybug_walk_a.png", "ladybug_walk_b.png"),
      worm = imagePair(actorRoot, "worm_normal_move_a.png", "worm_normal_move_b.png"),
      slime = imagePair(actorRoot, "slime_normal_walk_a.png", "slime_normal_walk_b.png"),
      fireSlime = imagePair(actorRoot, "slime_fire_walk_a.png", "slime_fire_walk_b.png"),
      spikeSlime = imagePair(actorRoot, "slime_spike_walk_a.png", "slime_spike_walk_b.png"),
      bee = imagePair(actorRoot, "bee_a.png", "bee_b.png"),
      fly = imagePair(actorRoot, "fly_a.png", "fly_b.png"),
      fish = imagePair(actorRoot, "fish_blue_swim_a.png", "fish_blue_swim_b.png"),
    },
    themes = {
      hills = {
        background = nearestImage(backgroundRoot .. "background_color_hills.png"),
        ground = {
          nearestImage(terrainRoot .. "terrain_grass_horizontal_left.png"),
          nearestImage(terrainRoot .. "terrain_grass_horizontal_middle.png"),
          nearestImage(terrainRoot .. "terrain_grass_horizontal_right.png"),
        },
      },
      desert = {
        background = nearestImage(backgroundRoot .. "background_color_desert.png"),
        ground = {
          nearestImage(terrainRoot .. "terrain_sand_horizontal_left.png"),
          nearestImage(terrainRoot .. "terrain_sand_horizontal_middle.png"),
          nearestImage(terrainRoot .. "terrain_sand_horizontal_right.png"),
        },
      },
      mushrooms = {
        background = nearestImage(backgroundRoot .. "background_color_mushrooms.png"),
        ground = {
          nearestImage(terrainRoot .. "terrain_purple_horizontal_left.png"),
          nearestImage(terrainRoot .. "terrain_purple_horizontal_middle.png"),
          nearestImage(terrainRoot .. "terrain_purple_horizontal_right.png"),
        },
      },
    },
    hit = nearestImage(root .. "effects/hit.png"),
  }
end

function Draw.loadInputPromptsController()
  return nearestImage("assets/kenney-input-prompts/controller_generic.png")
end

function Draw.kenneyActor(assets, name, x, feetY, clock, impact, facing, lift)
  impact = Draw.clamp(impact or 0)
  local frames = assets.actors[name or "snail"] or assets.actors.snail
  local frame = frames[math.floor((clock or 0) * 4) % #frames + 1]
  local width, height = frame:getDimensions()
  facing = facing or 1
  local scale = 1.42
  Draw.setColor({ 1, 1, 1, 1 })
  love.graphics.push()
  love.graphics.translate(x, feetY - (lift or 0))
  love.graphics.rotate(impact * 0.08)
  love.graphics.scale(facing * scale * (1 + impact * 0.08), scale * (1 - impact * 0.1))
  love.graphics.draw(frame, 0, 0, 0, 1, 1, width / 2, height)
  love.graphics.pop()
end

function Draw.kenneyArena(assets, x, y, w, h, state)
  state = state or {}
  local impact = Draw.clamp(state.impact or 0)
  local attack = Draw.clamp(state.attack or impact)
  local clock = state.time or 0
  local theme = assets.themes[state.background or "hills"] or assets.themes.hills
  local playerFacing = state.playerFacing or -1
  local enemyFacing = state.enemyFacing or 1
  local playerLift = state.playerLift or 0
  local enemyLift = state.enemyLift or 0

  love.graphics.push()
  love.graphics.setScissor(x, y, w, h)
  Draw.setColor({ 1, 1, 1, 1 })
  local backgroundWidth, backgroundHeight = theme.background:getDimensions()
  local backgroundScale = h / backgroundHeight
  for backgroundX = x, x + w, backgroundWidth * backgroundScale do
    love.graphics.draw(theme.background, backgroundX, y, 0, backgroundScale, backgroundScale)
  end

  local tileWidth, tileHeight = theme.ground[2]:getDimensions()
  local groundY = y + h - tileHeight
  love.graphics.draw(theme.ground[1], x, groundY)
  for tileX = x + tileWidth, x + w - tileWidth, tileWidth do
    love.graphics.draw(theme.ground[2], tileX, groundY)
  end
  love.graphics.draw(theme.ground[3], x + w - tileWidth, groundY)

  local playerX = state.playerX or (x + w * 0.39 + attack * 76)
  local enemyX = x + w * 0.61 + impact * 12
  local feetY = groundY + 10
  if not state.hidePlayer then
    Draw.kenneyActor(assets, state.player or "mouse", playerX, feetY, clock, attack * 0.12, playerFacing, playerLift)
  end

  if not state.hideEnemy then
    Draw.kenneyActor(assets, state.enemy or "snail", enemyX, feetY, clock, impact, enemyFacing, enemyLift)
  end

  if impact > 0.04 then
    local contactX = enemyX - 48
    local contactY = feetY - 42 - enemyLift
    local hitWidth, hitHeight = assets.hit:getDimensions()
    Draw.setColor({ 1, 1, 1, 1 }, impact)
    local hitScale = 0.6 + impact * 0.52
    love.graphics.draw(assets.hit, contactX, contactY, impact * 0.5, hitScale, hitScale, hitWidth / 2, hitHeight / 2)
    Draw.setColor({ 1, 1, 1, 1 }, impact * 0.84)
    love.graphics.draw(assets.hit, contactX - 34, contactY + 25, -impact * 0.35, hitScale * 0.42, hitScale * 0.42, hitWidth / 2, hitHeight / 2)
  end
  love.graphics.setScissor()
  love.graphics.pop()
  return enemyX, feetY
end

return Draw
