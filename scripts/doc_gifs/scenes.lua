package.path = "./?.lua;./?/init.lua;" .. package.path

local feel = require("feel")
local feelLove = require("feel.love")
local Draw = require("scripts.doc_gifs.drawing")

local Scenes = {}

local STAGE = { x = 74, y = 132, w = 812, h = 376 }

local function action(at, fn)
  return { at = at, run = fn }
end

local function copyColor(color)
  return Draw.copyColor(color)
end

local function pushChip(ctx, text, color)
  ctx.chips[#ctx.chips + 1] = { text = text, color = color or ctx.primary, alpha = 1 }
  while #ctx.chips > 5 do
    table.remove(ctx.chips, 1)
  end
end

local function resetCommon(ctx, target)
  feel.clear()
  ctx.fx = feelLove.new({
    width = ctx.width,
    height = ctx.height,
    shakeAmount = 12,
    shakeDuration = 0.28,
    shakeFrequency = 38,
    flashAmount = 0.54,
    flashDuration = 0.16,
  })
  ctx.primary = copyColor(target.primary or Draw.palette.cyan)
  ctx.secondary = copyColor(target.secondary or Draw.palette.gold)
  ctx.chips = {}
  ctx.particles = {}
  ctx.rings = {}
  ctx.beams = {}
  ctx.toast = nil
  ctx.sound = { level = 0, volume = 0.65, pitch = 1, pan = 0 }
  ctx.haptic = { left = 0, right = 0, remaining = 0 }
  ctx.values = feel.target({
    values = {
      x = 0,
      y = 0,
      cardX = -250,
      cardY = 0,
      scale = 1,
      glow = 0,
      pulse = 0,
      progress = 0,
      ring = 0,
      heat = 0,
      tilt = 0,
      count = 0,
      choice = 0,
      orbit = 0,
    },
  })
  ctx.actions = {}
end

local function handlers(ctx, extra)
  extra = extra or {}
  return ctx.fx:handlers({
    emit = function(event, runCtx)
      if type(extra.emit) == "function" then
        extra.emit(event, runCtx)
      end
    end,
    audio = function(event, runCtx)
      if type(extra.audio) == "function" then
        extra.audio(event, runCtx)
      end
    end,
    log = function(message, runCtx)
      pushChip(ctx, message, Draw.palette.violet)
      if type(extra.log) == "function" then
        extra.log(message, runCtx)
      end
    end,
  })
end

local function play(ctx, sequence, target, key, extra)
  local opts = handlers(ctx, extra)
  opts.restart = true
  opts.key = key or "doc-gif"
  return feel.play(sequence, target, opts)
end

local function spawnBurst(ctx, x, y, color, count, spread)
  count = count or 18
  spread = spread or 210
  for _ = 1, count do
    local angle = math.random() * math.pi * 2
    local speed = spread * (0.35 + math.random() * 0.7)
    ctx.particles[#ctx.particles + 1] = {
      x = x,
      y = y,
      vx = math.cos(angle) * speed,
      vy = math.sin(angle) * speed - 26,
      life = 0.42 + math.random() * 0.2,
      maxLife = 0.64,
      size = 3 + math.random() * 4,
      color = copyColor(color),
    }
  end
end

local function spawnDirectionalBurst(ctx, x, y, color, count, direction, arc, spread)
  count = count or 18
  direction = direction or 0
  arc = arc or math.pi * 0.5
  spread = spread or 220
  for _ = 1, count do
    local angle = direction + (math.random() - 0.5) * arc
    local speed = spread * (0.42 + math.random() * 0.68)
    ctx.particles[#ctx.particles + 1] = {
      x = x,
      y = y,
      vx = math.cos(angle) * speed,
      vy = math.sin(angle) * speed - 18,
      life = 0.6 + math.random() * 0.32,
      maxLife = 0.92,
      size = 3 + math.random() * 4,
      color = copyColor(color),
    }
  end
end

local function addRing(ctx, x, y, color, duration, radius)
  ctx.rings[#ctx.rings + 1] = {
    x = x,
    y = y,
    color = copyColor(color),
    duration = duration or 0.48,
    life = duration or 0.48,
    radius = radius or 46,
  }
end

local function addBeam(ctx, x1, y1, x2, y2, color, duration)
  ctx.beams[#ctx.beams + 1] = {
    x1 = x1,
    y1 = y1,
    x2 = x2,
    y2 = y2,
    color = copyColor(color),
    duration = duration or 0.18,
    life = duration or 0.18,
  }
end

local function updateCommon(ctx, dt)
  feel.update(dt)
  if ctx.g3dfx then
    ctx.g3dfx:update()
  end
  ctx.fx:update(dt)

  for i = #ctx.particles, 1, -1 do
    local p = ctx.particles[i]
    p.life = p.life - dt
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.vy = p.vy + 240 * dt
    if p.life <= 0 then
      table.remove(ctx.particles, i)
    end
  end

  for i = #ctx.rings, 1, -1 do
    local ring = ctx.rings[i]
    ring.life = ring.life - dt
    if ring.life <= 0 then
      table.remove(ctx.rings, i)
    end
  end

  for i = #ctx.beams, 1, -1 do
    local beam = ctx.beams[i]
    beam.life = beam.life - dt
    if beam.life <= 0 then
      table.remove(ctx.beams, i)
    end
  end

  if ctx.toast then
    ctx.toast.life = ctx.toast.life - dt
    if ctx.toast.life <= 0 then
      ctx.toast = nil
    end
  end

  ctx.sound.level = math.max(0, ctx.sound.level - dt * 1.55)
  ctx.haptic.remaining = math.max(0, ctx.haptic.remaining - dt)
  if ctx.haptic.remaining <= 0 then
    ctx.haptic.left = 0
    ctx.haptic.right = 0
  end
end

local function drawParticles(ctx)
  for _, p in ipairs(ctx.particles) do
    local alpha = Draw.clamp(p.life / p.maxLife, 0, 1)
    Draw.spark(p.x, p.y, p.size * alpha, p.color, alpha)
  end
end

local function drawRings(ctx)
  for _, ring in ipairs(ctx.rings) do
    local p = 1 - ring.life / ring.duration
    Draw.ring(ring.x, ring.y, ring.radius + p * 44, 1, ring.color, (1 - p) * 0.75)
  end
end

local function drawBeams(ctx)
  for _, beam in ipairs(ctx.beams) do
    Draw.beam(beam.x1, beam.y1, beam.x2, beam.y2, beam.color, Draw.clamp(beam.life / beam.duration, 0, 1))
  end
end

local function drawChrome(ctx, target)
  Draw.clear(ctx.width, ctx.height)
  Draw.header(ctx, target)
  Draw.stage(STAGE.x, STAGE.y, STAGE.w, STAGE.h)
  Draw.chipRow(ctx.chips, STAGE.x + 24, STAGE.y + STAGE.h - 44, ctx.fonts.small)
end

local function toast(ctx, text, color)
  ctx.toast = { text = text, color = color or ctx.primary, life = 0.92 }
end

local function drawToast(ctx)
  if not ctx.toast then
    return
  end
  local alpha = Draw.clamp(ctx.toast.life / 0.92, 0, 1)
  Draw.chip(ctx.toast.text, STAGE.x + STAGE.w - 190, STAGE.y + 24, ctx.toast.color, ctx.fonts.small, alpha)
end

local function triggerTwice(ctx, fn)
  ctx.actions = {
    action(0.28, fn),
    action(1.55, fn),
  }
end

local function setupGettingStarted(ctx)
  local function trigger()
    play(ctx, {
      {
        kind = "parallel",
        steps = {
          { kind = "emit", event = "spark.burst", payload = { count = 24 } },
          { kind = "animate", duration = 0.08, ease = "quadout", to = { scale = 0.9, glow = 1, y = 8 } },
        },
      },
      { kind = "wait", duration = 0.04 },
      { kind = "animate", duration = 0.3, ease = "backout", to = { scale = 1, glow = 0, y = 0 } },
      { kind = "log", message = "played" },
    }, ctx.values, "getting-started", {
      emit = function(event)
        spawnBurst(ctx, 480, 278, ctx.secondary, event.payload.count, 230)
        pushChip(ctx, "emit spark", ctx.secondary)
      end,
      log = function()
        toast(ctx, "feedback played", Draw.palette.green)
      end,
    })
  end
  triggerTwice(ctx, trigger)
end

local function drawGettingStarted(ctx, target)
  local v = ctx.values.values
  drawChrome(ctx, target)
  Draw.label("target.values", 182, 190, Draw.palette.muted, ctx.fonts.small)
  Draw.button(360, 236 + v.y, 240, 76, v.scale, v.glow, ctx.primary, "DEPLOY", ctx.fonts.body)
  Draw.meter(210, 378, 560, 10, Draw.clamp((ctx.time % 1.27) / 1.27, 0, 1), ctx.primary)
  drawRings(ctx)
  drawParticles(ctx)
  drawToast(ctx)
end

local function setupAnimate(ctx)
  ctx.values.values.progress = 0
  ctx.values.values.scale = 0.94
  local function trigger()
    play(ctx, {
      { kind = "animate", duration = 0.52, ease = "cubicout", from = { progress = 0, scale = 0.94, glow = 0, tilt = -0.08, y = 0 }, to = { progress = 1, scale = 1.1, glow = 1, tilt = 0.04, y = -18 } },
      { kind = "animate", duration = 0.24, ease = "backout", to = { scale = 1, glow = 0.22, tilt = 0, y = 0 } },
      { kind = "wait", duration = 0.42 },
    }, ctx.values, "animate.card")
    pushChip(ctx, "animate to", ctx.primary)
  end
  triggerTwice(ctx, trigger)
end

local function drawAnimate(ctx, target)
  local v = ctx.values.values
  drawChrome(ctx, target)
  Draw.setColor({ 1, 1, 1, 0.08 })
  love.graphics.rectangle("fill", 278, 288, 406, 3, 2, 2)
  for i = 0, 5 do
    Draw.spark(278 + i * 78, 289, 3, Draw.palette.faint, 0.65)
  end
  Draw.card(212, 230, 132, 104, Draw.palette.faint, "queue", ctx.fonts.small, false, 0)
  Draw.card(244, 214, 132, 104, Draw.palette.faint, "next", ctx.fonts.small, false, 0)
  Draw.card(620, 218, 150, 122, ctx.secondary, "dock", ctx.fonts.body, false, 0)
  local x = Draw.mix(306, 695, v.progress)
  local y = 280 + v.y - math.sin(v.progress * math.pi) * 22
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(v.tilt)
  Draw.card(-84, -58, 168, 116, ctx.primary, "selected", ctx.fonts.body, true, v.glow)
  love.graphics.pop()
  Draw.meter(326, 394, 328, 10, v.progress, ctx.primary, "x + scale + glow", ctx.fonts.small)
end

local function setupEasing(ctx)
  ctx.ease = {
    { name = "linear", target = feel.target({ values = { x = 0, glow = 0 } }), color = Draw.palette.cyan },
    { name = "quadout", target = feel.target({ values = { x = 0, glow = 0 } }), color = Draw.palette.green },
    { name = "sineinout", target = feel.target({ values = { x = 0, glow = 0 } }), color = Draw.palette.pink },
    { name = "backout", target = feel.target({ values = { x = 0, glow = 0 } }), color = Draw.palette.gold },
    { name = "elasticout", target = feel.target({ values = { x = 0, glow = 0 } }), color = Draw.palette.cyan },
    { name = "bounceout", target = feel.target({ values = { x = 0, glow = 0 } }), color = Draw.palette.violet },
  }
  local function trigger()
    for _, item in ipairs(ctx.ease) do
      play(ctx, {
        { kind = "animate", duration = 0.78, ease = item.name, from = { x = 0, glow = 0 }, to = { x = 1, glow = 1 } },
        { kind = "wait", duration = 0.18 },
        { kind = "animate", duration = 0.24, ease = "quadout", to = { x = 0, glow = 0 } },
      }, item.target, "ease." .. item.name)
    end
  end
  triggerTwice(ctx, trigger)
end

local function drawEasing(ctx, target)
  drawChrome(ctx, target)
  for index, item in ipairs(ctx.ease) do
    local y = 160 + (index - 1) * 58
    local x = 190 + item.target.values.x * 320
    Draw.setColor({ 1, 1, 1, 0.09 })
    love.graphics.rectangle("fill", 190, y + 24, 360, 2)
    Draw.setColor(Draw.palette.faint, 0.55)
    love.graphics.circle("fill", 190, y + 25, 7)
    love.graphics.circle("fill", 510, y + 25, 7)
    Draw.setColor(item.color, 0.18)
    love.graphics.circle("fill", x, y + 25, 28 + item.target.values.glow * 10)
    Draw.spark(x, y + 25, 16, item.color, 1)
    Draw.chip(item.name, 642, y + 10, item.color, ctx.fonts.small)
  end
end

local function setupSequence(ctx)
  local function trigger()
    ctx.values.values.progress = 0
    play(ctx, {
      { kind = "callback", callback = function() pushChip(ctx, "lift", ctx.primary) end },
      { kind = "animate", duration = 0.22, ease = "quadout", to = { y = -34, glow = 1, progress = 0.32 } },
      { kind = "wait", duration = 0.18 },
      { kind = "callback", callback = function() pushChip(ctx, "wait", ctx.secondary) end },
      { kind = "emit", event = "spark.burst", payload = { count = 18 } },
      { kind = "animate", duration = 0.3, ease = "backout", to = { y = 0, glow = 0, progress = 1 } },
    }, ctx.values, "sequence.chest", {
      emit = function(event)
        spawnBurst(ctx, 480, 250, ctx.secondary, event.payload.count, 170)
        pushChip(ctx, "emit", Draw.palette.green)
      end,
    })
  end
  triggerTwice(ctx, trigger)
end

local function drawChest(ctx, x, y, glow)
  Draw.shadow(x - 58, y + 38, 116, 22, 12, 0.25)
  Draw.setColor(Draw.palette.gold, 0.2 + glow * 0.26)
  love.graphics.circle("fill", x, y + 8, 72)
  Draw.setColor(Draw.palette.panel2)
  love.graphics.rectangle("fill", x - 64, y - 16, 128, 72, 8, 8)
  Draw.setColor(Draw.palette.gold)
  love.graphics.rectangle("line", x - 64, y - 16, 128, 72, 8, 8)
  Draw.setColor(Draw.palette.gold, 0.72)
  love.graphics.rectangle("fill", x - 54, y - 28, 108, 28, 8, 8)
  Draw.setColor(Draw.palette.ink)
  love.graphics.rectangle("fill", x - 8, y + 6, 16, 18, 4, 4)
end

local function drawSequence(ctx, target)
  local v = ctx.values.values
  drawChrome(ctx, target)
  Draw.chipRow({
    { text = "animate", color = ctx.primary },
    { text = "wait", color = ctx.secondary },
    { text = "emit", color = Draw.palette.green },
  }, 300, 176, ctx.fonts.small)
  drawChest(ctx, 480, 292 + v.y, v.glow)
  Draw.meter(326, 404, 328, 10, v.progress, ctx.primary)
  drawParticles(ctx)
end

local function setupParallel(ctx)
  local function trigger()
    ctx.values.values.ring = 0
    play(ctx, {
      {
        kind = "parallel",
        steps = {
          { kind = "animate", duration = 0.38, ease = "backout", to = { scale = 1.22, glow = 1 } },
          { kind = "animate", duration = 0.55, ease = "quadout", to = { ring = 1 } },
          { kind = "emit", event = "spark.burst", payload = { count = 22 } },
        },
      },
      { kind = "animate", duration = 0.28, ease = "quadout", to = { scale = 1, glow = 0, ring = 0 } },
    }, ctx.values, "parallel.power", {
      emit = function(event)
        spawnBurst(ctx, 480, 280, ctx.secondary, event.payload.count, 190)
        pushChip(ctx, "3 branches", ctx.primary)
      end,
    })
  end
  triggerTwice(ctx, trigger)
end

local function drawParallel(ctx, target)
  local v = ctx.values.values
  drawChrome(ctx, target)
  Draw.ring(480, 280, 92, v.ring, ctx.secondary, 0.92)
  Draw.setColor(ctx.primary, 0.16 + v.glow * 0.3)
  love.graphics.circle("fill", 480, 280, 74 * v.scale)
  Draw.spark(480, 280, 34 * v.scale, ctx.primary, 1)
  Draw.chipRow({
    { text = "scale", color = ctx.primary },
    { text = "ring", color = ctx.secondary },
    { text = "burst", color = Draw.palette.green },
  }, 314, 398, ctx.fonts.small)
  drawParticles(ctx)
end

local function setupRepeat(ctx)
  local function trigger()
    ctx.values.values.count = 0
    play(ctx, {
      {
        kind = "repeat",
        count = 3,
        step = {
          { kind = "callback", callback = function() ctx.values.values.count = ctx.values.values.count + 1; pushChip(ctx, "tick " .. ctx.values.values.count, ctx.primary) end },
          { kind = "animate", duration = 0.08, ease = "quadout", to = { pulse = 1, scale = 1.18 } },
          { kind = "animate", duration = 0.18, ease = "quadout", to = { pulse = 0, scale = 1 } },
          { kind = "wait", duration = 0.06 },
        },
      },
    }, ctx.values, "repeat.combo")
  end
  triggerTwice(ctx, trigger)
end

local function drawRepeat(ctx, target)
  local v = ctx.values.values
  drawChrome(ctx, target)
  Draw.setColor(ctx.secondary, 0.12 + v.pulse * 0.28)
  love.graphics.circle("fill", 480, 276, 86 + v.pulse * 32)
  Draw.centerLabel("COMBO", 360, 218, 240, Draw.palette.muted, ctx.fonts.body)
  love.graphics.setFont(ctx.fonts.title)
  Draw.setColor(Draw.palette.ink)
  love.graphics.printf("x" .. tostring(math.max(0, math.floor(v.count))), 360, 260, 240, "center")
  for i = 1, 3 do
    Draw.spark(430 + i * 36, 346, 8, i <= v.count and ctx.primary or Draw.palette.faint, i <= v.count and 1 or 0.45)
  end
end

local function setupRandom(ctx)
  local function trigger()
    ctx.values.values.choice = 0
    play(ctx, {
      {
        kind = "random",
        options = {
          { weight = 3, step = { kind = "callback", callback = function() ctx.values.values.choice = 1; pushChip(ctx, "common", ctx.primary) end } },
          { weight = 1, step = { kind = "callback", callback = function() ctx.values.values.choice = 2; pushChip(ctx, "rare", ctx.secondary) end } },
        },
      },
      { kind = "animate", duration = 0.18, ease = "backout", to = { pulse = 1, glow = 1 } },
      { kind = "animate", duration = 0.34, ease = "quadout", to = { pulse = 0, glow = 0 } },
    }, ctx.values, "random.reward")
  end
  triggerTwice(ctx, trigger)
end

local function drawRandom(ctx, target)
  local v = ctx.values.values
  drawChrome(ctx, target)
  local cards = {
    { label = "coin", color = ctx.primary },
    { label = "gem", color = ctx.secondary },
    { label = "spark", color = Draw.palette.violet },
  }
  for i, card in ipairs(cards) do
    local selected = v.choice == i or (i == 1 and v.choice == 0)
    local y = selected and 230 - v.pulse * 14 or 244
    Draw.card(262 + (i - 1) * 156, y, 112, 128, card.color, selected and card.label or "?", ctx.fonts.body, selected, selected and v.glow or 0)
  end
  Draw.chip("weighted pick", 394, 392, ctx.primary, ctx.fonts.small)
end

local function setupCallbacks(ctx)
  local function trigger()
    ctx.values.values.progress = 0
    play(ctx, {
      { kind = "emit", event = "spark.burst", payload = { count = 8 } },
      { kind = "audio", cue = "ui-pop" },
      { kind = "callback", callback = function() pushChip(ctx, "callback", Draw.palette.green) end },
      { kind = "log", message = "log" },
    }, ctx.values, "callbacks.bus", {
      emit = function(event)
        pushChip(ctx, "emit", ctx.primary)
        spawnBurst(ctx, 690, 284, ctx.secondary, event.payload.count, 150)
      end,
      audio = function()
        pushChip(ctx, "audio", ctx.secondary)
      end,
    })
  end
  triggerTwice(ctx, trigger)
end

local function drawCallbacks(ctx, target)
  drawChrome(ctx, target)
  local items = {
    { "emit", ctx.primary },
    { "audio", ctx.secondary },
    { "callback", Draw.palette.green },
    { "log", Draw.palette.violet },
  }
  for i, item in ipairs(items) do
    Draw.card(144 + (i - 1) * 170, 232, 130, 96, item[2], item[1], ctx.fonts.body, true, 0.2)
    if i < #items then
      Draw.beam(274 + (i - 1) * 170, 280, 310 + (i - 1) * 170, 280, Draw.palette.faint, 0.55)
    end
  end
  drawParticles(ctx)
end

local function setupPulse(ctx)
  local function trigger()
    play(ctx, {
      { kind = "emit", event = "pulse.start" },
      { kind = "animate", duration = 0.09, ease = "quadout", to = { scale = 1.2, glow = 1, pulse = 1 } },
      { kind = "animate", duration = 0.38, ease = "backout", to = { scale = 1, glow = 0, pulse = 0 } },
      { kind = "log", message = "settled" },
    }, ctx.values, "pulse.badge", {
      emit = function()
        pushChip(ctx, "pulse.start", ctx.primary)
      end,
    })
  end
  triggerTwice(ctx, trigger)
end

local function drawPulse(ctx, target)
  local v = ctx.values.values
  drawChrome(ctx, target)
  Draw.setColor(ctx.primary, 0.12 + v.pulse * 0.25)
  love.graphics.circle("fill", 480, 278, 86 + v.pulse * 52)
  Draw.button(366, 238, 228, 72, v.scale, v.glow, ctx.primary, "LEVEL UP", ctx.fonts.body)
end

local function setupSoundObjects(ctx)
  ctx.fx:sound("ui-pop", {
    play = function()
      ctx.sound.level = 1
      pushChip(ctx, "audio", ctx.secondary)
    end,
    stop = function() end,
    setVolume = function(_, value) ctx.sound.volume = value end,
    setPitch = function(_, value) ctx.sound.pitch = value end,
    setPosition = function(_, x) ctx.sound.pan = x end,
  }, { volume = 0.65 })
  ctx.fx:haptic("pad", {
    isVibrationSupported = function() return true end,
    setVibration = function(_, left, right, duration)
      ctx.haptic.left = left or 0
      ctx.haptic.right = right or left or 0
      ctx.haptic.remaining = duration or 0.18
      pushChip(ctx, "rumble", ctx.primary)
    end,
  })
  local system = { x = 480, y = 280 }
  function system:setPosition(x, y)
    self.x = x or self.x
    self.y = y or self.y
  end
  function system:emit(count)
    spawnBurst(ctx, self.x, self.y, ctx.primary, count or 16, 240)
    pushChip(ctx, "particle.emit", ctx.primary)
  end
  function system:update() end
  function system:start() end
  function system:stop() end
  function system:reset() end
  ctx.fx:particle("sparks", system)
end

local function setupAdapter(ctx, id)
  setupSoundObjects(ctx)
  if id == "shader" then
    local ok, shader = pcall(love.graphics.newShader, [[
extern number amount;
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen)
{
  vec4 pixel = Texel(tex, uv) * color;
  number scan = sin(screen.y * 0.26) * 0.5 + 0.5;
  number split = sin(screen.x * 0.038 + screen.y * 0.014) * 0.5 + 0.5;
  vec3 tint = mix(vec3(0.0, 0.9, 1.0), vec3(1.0, 0.12, 0.7), split);
  pixel.rgb = mix(pixel.rgb, pixel.rgb * 0.18 + tint * (0.7 + step(0.55, scan) * 0.35), amount);
  return pixel;
}
]])
    if ok and shader then
      ctx.shader = shader
      ctx.fx:shader("glow", shader, { uniforms = { amount = 0 } })
    end
  elseif id == "feedbacks" then
    local feedbacks = require("feel.feedbacks")
    ctx.Feedbacks = feedbacks.new({
      love = ctx.fx,
      emit = function(event)
        if event.kind == "screen.flash" then
          pushChip(ctx, "flash", ctx.secondary)
        elseif event.kind and event.kind:match("^post%.") then
          pushChip(ctx, "post", Draw.palette.violet)
        end
      end,
    })
    ctx.Feedbacks.define("impact.stack", {
      { kind = "time.freeze", duration = 0.035 },
      {
        kind = "parallel",
        steps = {
          { kind = "screen.flash", amount = 0.28, duration = 0.12, color = ctx.secondary },
          { kind = "camera.shake", amount = 11, duration = 0.18, frequency = 34 },
          { kind = "post.tween", effect = "bloom", values = { intensity = 1.2 }, duration = 0.1, restart = true },
          { kind = "emit", event = "particle.emit", payload = { name = "sparks", count = 18, x = 480, y = 280 } },
          { kind = "animate", duration = 0.08, ease = "quadout", to = { scale = 1.18, glow = 1 } },
        },
      },
      { kind = "wait", duration = 0.14 },
      {
        kind = "parallel",
        steps = {
          { kind = "post.tween", effect = "bloom", values = { intensity = 0 }, duration = 0.34, restart = true },
          { kind = "animate", duration = 0.3, ease = "backout", to = { scale = 1, glow = 0 } },
        },
      },
    })
  end
end

local function setupAdapterAction(ctx, id)
  local function trigger()
    if id == "shake" then
      play(ctx, {
        { kind = "emit", event = "camera.shake", payload = { amount = 14, duration = 0.28, frequency = 36 } },
        { kind = "animate", duration = 0.08, ease = "quadout", to = { scale = 1.12, glow = 1 } },
        { kind = "animate", duration = 0.28, ease = "backout", to = { scale = 1, glow = 0 } },
      }, ctx.values, "shake")
      pushChip(ctx, "camera.shake", ctx.primary)
    elseif id == "flash" then
      play(ctx, {
        { kind = "emit", event = "screen.flash", payload = { amount = 0.58, duration = 0.18, color = ctx.secondary } },
        { kind = "animate", duration = 0.12, ease = "quadout", to = { glow = 1 } },
        { kind = "animate", duration = 0.3, ease = "quadout", to = { glow = 0 } },
      }, ctx.values, "flash")
      pushChip(ctx, "screen.flash", ctx.secondary)
    elseif id == "sound" then
      play(ctx, {
        { kind = "emit", event = "sound.pan", payload = { cue = "ui-pop", pan = -0.8 } },
        { kind = "emit", event = "sound.volume", payload = { cue = "ui-pop", volume = 1, duration = 0.08, restart = true } },
        { kind = "emit", event = "sound.pitch", payload = { cue = "ui-pop", pitch = 1.4, duration = 0.12, restart = true } },
        { kind = "audio", cue = "ui-pop" },
        { kind = "emit", event = "sound.pan", payload = { cue = "ui-pop", pan = 0.8, duration = 0.32, ease = "quadout", restart = true } },
        { kind = "wait", duration = 0.18 },
        { kind = "emit", event = "sound.pitch", payload = { cue = "ui-pop", pitch = 1, duration = 0.3, ease = "quadout", restart = true } },
        { kind = "emit", event = "sound.volume", payload = { cue = "ui-pop", volume = 0.65, duration = 0.3, ease = "quadout", restart = true } },
        { kind = "emit", event = "sound.pan", payload = { cue = "ui-pop", pan = 0, duration = 0.22, ease = "quadout", restart = true } },
      }, nil, "sound", {
        emit = function(event)
          if event.kind and event.kind:match("^sound%.") then
            pushChip(ctx, event.kind:gsub("sound%.", ""), ctx.primary)
          end
        end,
      })
    elseif id == "haptics" then
      play(ctx, {
        { kind = "emit", event = "haptic.play", payload = { name = "pad", left = 0.25, right = 0.92, duration = 0.24, system = false } },
      }, nil, "haptics")
    elseif id == "particles" then
      ctx.values.values.progress = 0
      play(ctx, {
        {
          kind = "parallel",
          steps = {
            { kind = "animate", duration = 0.18, ease = "quadout", from = { progress = 0, glow = 0, scale = 1, tilt = 0 }, to = { progress = 1, glow = 1, scale = 1.12, tilt = 0.1 } },
            { kind = "emit", event = "particle.emit", payload = { name = "sparks", count = 42, x = 538, y = 276 } },
            { kind = "emit", event = "screen.flash", payload = { amount = 0.12, duration = 0.08, color = ctx.secondary } },
          },
        },
        { kind = "wait", duration = 0.32 },
        { kind = "animate", duration = 0.34, ease = "backout", to = { progress = 0.18, glow = 0, scale = 1, tilt = 0 } },
      }, ctx.values, "particles", {
        emit = function(event)
          if event.kind == "particle.emit" then
            local payload = event.payload or {}
            addBeam(ctx, 414, 294, payload.x or 538, payload.y or 276, ctx.secondary, 0.22)
            addRing(ctx, payload.x or 538, payload.y or 276, ctx.secondary, 0.5, 24)
            spawnDirectionalBurst(ctx, payload.x or 538, payload.y or 276, ctx.secondary, 18, math.pi, math.pi * 0.7, 260)
            spawnDirectionalBurst(ctx, 404, 294, ctx.primary, 10, math.pi, math.pi * 0.45, 180)
          end
        end,
      })
    elseif id == "shader" then
      play(ctx, {
        { kind = "emit", event = "shader.tween", payload = { name = "glow", uniform = "amount", value = 1, duration = 0.16, restart = true } },
        { kind = "wait", duration = 0.14 },
        { kind = "emit", event = "shader.tween", payload = { name = "glow", uniform = "amount", value = 0, duration = 0.34, restart = true } },
      }, nil, "shader")
      pushChip(ctx, "uniform tween", ctx.secondary)
    elseif id == "post-processing" then
      play(ctx, {
        { kind = "emit", event = "post.set", payload = { effect = "bloom", values = { threshold = 0.4, softness = 0.2, passes = 2 } } },
        { kind = "emit", event = "post.tween", payload = { effect = "bloom", values = { intensity = 1.35 }, duration = 0.12, restart = true } },
        { kind = "emit", event = "post.tween", payload = { effect = "chromatic", values = { force = 1, x = 0.014, y = -0.006 }, duration = 0.1, restart = true } },
        { kind = "wait", duration = 0.2 },
        { kind = "emit", event = "post.tween", payload = { effect = "bloom", values = { intensity = 0.12 }, duration = 0.36, restart = true } },
        { kind = "emit", event = "post.tween", payload = { effect = "chromatic", values = { force = 0, x = 0, y = 0 }, duration = 0.28, restart = true } },
      }, nil, "post")
      pushChip(ctx, "post stack", Draw.palette.violet)
    elseif id == "feedbacks" then
      ctx.Feedbacks.play("impact.stack", nil, { target = ctx.values, restart = true, key = "impact.stack" })
      pushChip(ctx, "impact.stack", ctx.primary)
    elseif id == "love2d" then
      play(ctx, {
        {
          kind = "parallel",
          steps = {
            { kind = "emit", event = "particle.emit", payload = { name = "sparks", count = 18, x = 508, y = 286 } },
            { kind = "emit", event = "screen.flash", payload = { amount = 0.22, duration = 0.14, color = ctx.primary } },
            { kind = "emit", event = "camera.shake", payload = { amount = 7, duration = 0.18 } },
            { kind = "animate", duration = 0.1, ease = "quadout", to = { scale = 1.18, glow = 1 } },
          },
        },
        { kind = "animate", duration = 0.32, ease = "backout", to = { scale = 1, glow = 0 } },
      }, ctx.values, "love2d")
      pushChip(ctx, "feel.update", ctx.primary)
    end
  end
  triggerTwice(ctx, trigger)
end

local function drawArena(ctx, id)
  local v = ctx.values.values
  if id == "shake" or id == "feedbacks" or id == "love2d" then
    ctx.fx:push()
  end
  Draw.setColor({ 1, 1, 1, 0.08 })
  love.graphics.rectangle("line", 188, 192, 480, 228, 12, 12)
  Draw.ship(358, 306, -0.05, ctx.primary, 1)
  Draw.setColor(ctx.secondary, 0.16 + v.glow * 0.28)
  love.graphics.circle("fill", 536, 286, 46 + v.glow * 24)
  Draw.spark(536, 286, 20 * v.scale, ctx.secondary, 1)
  if id == "feedbacks" or id == "love2d" then
    drawParticles(ctx)
  end
  if id == "shake" or id == "feedbacks" or id == "love2d" then
    ctx.fx:pop()
    Draw.chip("HP 92", 198, 154, Draw.palette.green, ctx.fonts.small)
    Draw.chip("score 1,240", 684, 154, ctx.primary, ctx.fonts.small)
  end
end

local function drawAdapter(ctx, target, id)
  drawChrome(ctx, target)
  if id == "shake" or id == "feedbacks" or id == "love2d" then
    drawArena(ctx, id)
  elseif id == "flash" then
    drawArena(ctx, id)
  elseif id == "sound" then
    Draw.wave(178, 220, 500, 92, ctx.sound.level, ctx.primary)
    Draw.meter(210, 362, 180, 16, ctx.sound.volume, ctx.primary, "volume", ctx.fonts.small)
    Draw.meter(430, 362, 180, 16, (ctx.sound.pitch - 0.7) / 0.8, ctx.secondary, "pitch", ctx.fonts.small)
    Draw.setColor({ 1, 1, 1, 0.08 })
    love.graphics.rectangle("fill", 258, 310, 410, 8, 4, 4)
    Draw.spark(463 + ctx.sound.pan * 190, 314, 11, ctx.secondary, 1)
    Draw.centerLabel("pan", 382, 328, 180, Draw.palette.muted, ctx.fonts.small)
  elseif id == "haptics" then
    Draw.controller(360, 220, ctx.haptic.left, ctx.haptic.right, ctx.primary)
    Draw.ring(422, 274, 44 + ctx.haptic.left * 24, 1, ctx.primary, ctx.haptic.left * 0.8)
    Draw.ring(522, 274, 44 + ctx.haptic.right * 24, 1, ctx.primary, ctx.haptic.right * 0.8)
    Draw.chipRow({
      { text = "left motor", color = ctx.primary },
      { text = "right motor", color = ctx.secondary },
    }, 356, 386, ctx.fonts.small)
  elseif id == "particles" then
    local v = ctx.values.values
    Draw.setColor({ 1, 1, 1, 0.08 })
    love.graphics.rectangle("line", 188, 192, 480, 228, 12, 12)
    Draw.setColor(ctx.secondary, 0.16 + v.glow * 0.24)
    love.graphics.circle("fill", 538, 276, 70 + v.glow * 18)
    Draw.setColor(Draw.palette.panel2)
    love.graphics.circle("fill", 538, 276, 46)
    Draw.setColor(ctx.secondary, 0.82)
    love.graphics.circle("line", 538, 276, 46)
    Draw.setColor(ctx.secondary, 0.55 + v.glow * 0.35)
    love.graphics.line(512, 262, 528, 276, 516, 298)
    love.graphics.line(542, 236, 538, 276, 566, 292)
    Draw.ship(384 + v.progress * 18, 294, v.tilt, ctx.primary, v.scale)
    Draw.beam(414, 294, 414 + (124 * math.max(v.progress, 0.18)), 276, ctx.secondary, 0.28 + v.glow * 0.72)
    for i = 1, 5 do
      local p = i / 6
      local alpha = (0.18 + v.glow * 0.72) * (1 - p * 0.35)
      Draw.spark(414 + p * 118, 294 - p * 18 + math.sin(ctx.time * 7 + i) * 3, 3 + i * 0.7, ctx.secondary, alpha)
    end
    Draw.spark(538, 276, 18 + v.glow * 10, ctx.secondary, 1)
    drawParticles(ctx)
  elseif id == "shader" then
    local amount = ctx.fx.shaderEntries.glow and (ctx.fx.shaderEntries.glow.values.amount or 0) or 0
    Draw.setColor(ctx.secondary, 0.1 + amount * 0.28)
    love.graphics.circle("fill", 480, 264, 70 + amount * 42)
    if ctx.shader then
      ctx.fx:pushShader("glow")
    end
    Draw.card(330, 214, 300, 144, ctx.primary, "preview", ctx.fonts.body, true, amount)
    Draw.spark(424, 286, 28, ctx.secondary, 1)
    Draw.spark(548, 286, 32, Draw.palette.violet, 1)
    if ctx.shader then
      ctx.fx:popShader()
    end
    Draw.meter(330, 394, 300, 14, amount, ctx.secondary, "uniform amount", ctx.fonts.small)
  elseif id == "post-processing" then
    local bloom = ctx.fx.post.effects.bloom.target.values.intensity or 0
    local chromatic = ctx.fx.post.effects.chromatic.target.values.force or 0
    Draw.setColor(Draw.palette.pink, chromatic * 0.38)
    love.graphics.rectangle("fill", 272 - chromatic * 10, 204, 412, 230, 12, 12)
    Draw.setColor(Draw.palette.cyan, chromatic * 0.38)
    love.graphics.rectangle("fill", 272 + chromatic * 10, 204, 412, 230, 12, 12)
    Draw.setColor(ctx.secondary, 0.1 + bloom * 0.24)
    love.graphics.circle("fill", 480, 288, 84 + bloom * 50)
    Draw.ship(390, 306, -0.08, ctx.primary, 1)
    Draw.spark(548, 278, 26, ctx.secondary, 1)
    Draw.chip("bloom + chromatic", 390, 394, Draw.palette.violet, ctx.fonts.small)
  end
  drawRings(ctx)
  drawBeams(ctx)
  ctx.fx:drawOverlay()
end

local function makeG3dModel()
  return {
    translation = { 0, 0, 0 },
    rotation = { 0, 0, 0 },
    scale = { 1, 1, 1 },
    setTranslation = function(self, x, y, z) self.translation = { x, y, z } end,
    setRotation = function(self, x, y, z) self.rotation = { x, y, z } end,
    setScale = function(self, x, y, z) self.scale = { x, y, z } end,
  }
end

local function setupThree(ctx, id)
  ctx.three = {
    model = makeG3dModel(),
    camera = { fov = 60 },
  }
  if id == "g3d" then
    ctx.three.camera.lookAt = function(x, y, z, tx, ty, tz)
      ctx.three.camera.eye = { x, y, z }
      ctx.three.camera.center = { tx, ty, tz }
    end
    local feelG3d = require("feel.g3d")
    ctx.g3dfx = feelG3d.new({ camera = ctx.three.camera })
    ctx.g3dfx:model("drone", ctx.three.model, {
      values = { x = 0, y = 0, z = 0, scale = 1, rz = 0 },
    })
    ctx.g3dfx:camera({
      mode = "lookAt",
      fov = 60,
      values = { x = 0, y = -7, z = 4, tx = 0, ty = 0, tz = 0 },
    })
  end

  local function trigger()
    if id == "g3d" then
      local opts = ctx.g3dfx:handlers({
        emit = function(event)
          if event.kind and event.kind:match("^g3d%.") then
            pushChip(ctx, event.kind:gsub("g3d%.", ""), ctx.primary)
          end
        end,
      })
      opts.restart = true
      opts.key = "three.g3d"
      feel.play({
        {
          kind = "parallel",
          steps = {
            { kind = "emit", event = "g3d.camera.shake", payload = { amount = 0.12, duration = 0.18, frequency = 34 } },
            { kind = "emit", event = "g3d.camera.fov", payload = { amount = 4, duration = 0.07, returnDuration = 0.22 } },
            { kind = "emit", event = "g3d.model.scalePunch", payload = { name = "drone", amount = 0.24, duration = 0.07, returnDuration = 0.24 } },
            { kind = "emit", event = "g3d.model.rotationShake", payload = { name = "drone", amount = 0.14, duration = 0.18 } },
          },
        },
      }, nil, opts)
    else
      play(ctx, {
        {
          kind = "parallel",
          steps = {
            { kind = "animate", duration = 0.24, ease = "quadout", to = { orbit = 1 } },
            { kind = "animate", duration = 0.08, ease = "quadout", to = { scale = 1.18, glow = 1, heat = 1 } },
            { kind = "animate", duration = 0.18, ease = "quadout", to = { progress = 1 } },
          },
        },
        { kind = "animate", duration = 0.38, ease = "backout", to = { scale = 1, glow = 0, heat = 0, orbit = 0, progress = 0 } },
      }, ctx.values, "three.menori")
      pushChip(ctx, "node", ctx.primary)
      pushChip(ctx, "uniform", ctx.secondary)
      pushChip(ctx, "animation", Draw.palette.green)
    end
  end
  triggerTwice(ctx, trigger)
end

local function drawThree(ctx, target, id)
  local v = ctx.values.values
  drawChrome(ctx, target)
  local scale = v.scale
  local rot = v.orbit * 0.5
  local glow = v.glow
  if id == "g3d" then
    scale = ctx.three.model.scale[1] or 1
    rot = ctx.three.model.rotation[3] or 0
    glow = math.max(0, (scale - 1) * 3)
  end
  Draw.setColor(id == "g3d" and ctx.primary or ctx.secondary, 0.12 + glow * 0.22)
  love.graphics.circle("fill", 480, 280, 118 + glow * 42)
  Draw.isoBox(480, 282, 152, 112, 38, id == "g3d" and ctx.primary or ctx.secondary, scale, rot)
  if id == "g3d" then
    Draw.isoBox(326, 330, 72, 62, 20, ctx.secondary, 0.82, -0.08)
    Draw.isoBox(646, 334, 76, 66, 20, Draw.palette.green, 0.82, 0.08)
    Draw.chip("camera + model", 394, 408, ctx.primary, ctx.fonts.small)
  else
    local ox = math.sin(v.orbit * math.pi * 2) * 110
    Draw.isoBox(480 + ox, 210, 54, 48, 14, Draw.palette.green, 0.82, 0.08)
    Draw.ring(480, 282, 126, v.progress, ctx.primary, 0.86)
    Draw.chip("node + uniform + anim", 356, 408, ctx.primary, ctx.fonts.small)
  end
end

local SETUP = {
  ["getting-started"] = setupGettingStarted,
  animate = setupAnimate,
  easing = setupEasing,
  sequence = setupSequence,
  parallel = setupParallel,
  ["repeat"] = setupRepeat,
  random = setupRandom,
  callbacks = setupCallbacks,
  pulse = setupPulse,
}

local DRAW = {
  ["getting-started"] = drawGettingStarted,
  animate = drawAnimate,
  easing = drawEasing,
  sequence = drawSequence,
  parallel = drawParallel,
  ["repeat"] = drawRepeat,
  random = drawRandom,
  callbacks = drawCallbacks,
  pulse = drawPulse,
}

function Scenes.create(target, ctx)
  resetCommon(ctx, target)

  if SETUP[target.id] then
    SETUP[target.id](ctx)
  elseif target.scene == "three" then
    setupThree(ctx, target.id)
  else
    setupAdapter(ctx, target.id)
    setupAdapterAction(ctx, target.id)
  end

  return {
    update = function(_, updateCtx, _, dt)
      updateCommon(updateCtx, dt)
    end,
    draw = function(_, drawCtx, drawTarget)
      if DRAW[drawTarget.id] then
        DRAW[drawTarget.id](drawCtx, drawTarget)
      elseif drawTarget.scene == "three" then
        drawThree(drawCtx, drawTarget, drawTarget.id)
      else
        drawAdapter(drawCtx, drawTarget, drawTarget.id)
      end
    end,
  }
end

return Scenes
