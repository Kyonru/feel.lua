package.path = "./?.lua;./?/init.lua;" .. package.path

local feel = require("feel")
local feelLove = require("feel.love")
local Draw = require("scripts.doc_gifs.drawing")

local Scenes = {}

local STAGE = { x = 74, y = 132, w = 812, h = 376 }

local KENNEY_STYLES = {
  ["getting-started"] = { player = "ladybug", enemy = "snail", background = "hills" },
  sequence = { player = "mouse", background = "mushrooms" },
  ["combo-recipe"] = { player = "mouse", enemy = "fireSlime", background = "mushrooms" },
  ["impact-feedback"] = { player = "bee", enemy = "snail", background = "hills", playerLift = 36 },
  sprite = { player = "ladybug", background = "desert" },
  shake = { player = "fish", enemy = "bee", background = "mushrooms", playerLift = 34, enemyLift = 36 },
  flash = { player = "bee", enemy = "ladybug", background = "desert", playerLift = 36 },
  particles = { player = "fly", enemy = "snail", background = "hills", playerLift = 38 },
  shader = { player = "ladybug", enemy = "fish", background = "desert", enemyLift = 32 },
  ["post-processing"] = { player = "fish", enemy = "fly", background = "mushrooms", playerLift = 34, enemyLift = 38 },
  feedbacks = { player = "bee", enemy = "snail", background = "hills", playerLift = 36 },
  love2d = { player = "ladybug", enemy = "fish", background = "desert", enemyLift = 32 },
}

local function kenneyState(id, state)
  state = state or {}
  for key, value in pairs(KENNEY_STYLES[id] or {}) do
    state[key] = value
  end
  return state
end

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

local function drawChrome(ctx, target)
  Draw.clear(ctx.width, ctx.height)
  Draw.header(ctx, target)
  Draw.feedbackRow(ctx.chips, STAGE.x + 24, STAGE.y + STAGE.h - 46, ctx.fonts.small)
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
        spawnDirectionalBurst(ctx, 594, 330, ctx.secondary, event.payload.count, math.pi, math.pi * 0.8, 230)
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
  Draw.kenneyArena(ctx.kenney, 98, 154, 764, 300, kenneyState(target.id, {
    attack = v.glow,
    impact = v.glow,
    time = ctx.time,
    effectColor = ctx.secondary,
  }))
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
    local progress = item.target.values.x
    local shownProgress = Draw.clamp(progress)
    local x = 170 + progress * 300
    Draw.setColor({ 1, 1, 1, 0.09 })
    love.graphics.rectangle("fill", 170, y + 24, 300, 2)
    love.graphics.rectangle("fill", 470, y + 24, 138, 1)
    Draw.setColor(Draw.palette.faint, 0.55)
    love.graphics.circle("fill", 170, y + 25, 4)
    love.graphics.circle("fill", 470, y + 25, 4)
    Draw.setColor(item.color, 0.24)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", x, y + 25, 13)
    love.graphics.setLineWidth(1)
    Draw.ring(x, y + 25, 13, shownProgress, item.color, 0.95, 2)
    Draw.setColor(item.color)
    love.graphics.circle("fill", x, y + 25, 6)
    Draw.feedbackChip(string.format("%s  %3d%%", item.name, math.floor(shownProgress * 100 + 0.5)), 620, y + 10, item.color, ctx.fonts.small)
  end
end

local function setupSequence(ctx)
  local function trigger()
    ctx.values.values.progress = 0
    ctx.values.values.choice = 0
    ctx.values.values.count = 0
    play(ctx, {
      {
        kind = "repeat",
        count = 3,
        step = {
          { kind = "callback", callback = function()
            ctx.values.values.count = ctx.values.values.count + 1
            pushChip(ctx, "hit " .. ctx.values.values.count, ctx.primary)
          end },
          {
            kind = "random",
            options = {
              { weight = 2, step = { kind = "callback", callback = function() ctx.values.values.choice = 1 end } },
              { weight = 1, step = { kind = "callback", callback = function() ctx.values.values.choice = 2 end } },
            },
          },
          {
            kind = "parallel",
            steps = {
              { kind = "animate", duration = 0.11, ease = "quadout", from = { progress = 0, glow = 0, scale = 1 }, to = { progress = 1, glow = 1, scale = 1.12 } },
              { kind = "emit", event = "spark.burst", payload = { count = 16 } },
            },
          },
          { kind = "animate", duration = 0.17, ease = "backout", to = { progress = 0, glow = 0, scale = 1 } },
          { kind = "wait", duration = 0.07 },
        },
      },
    }, ctx.values, "combo.recipe", {
      emit = function(event)
        local color = ctx.values.values.choice == 2 and ctx.secondary or ctx.primary
        spawnDirectionalBurst(ctx, 594, 330, color, event.payload.count, math.pi, math.pi * 0.8, 230)
      end,
    })
  end
  triggerTwice(ctx, trigger)
end

local function drawSequence(ctx, target)
  local v = ctx.values.values
  drawChrome(ctx, target)
  Draw.kenneyArena(ctx.kenney, 98, 154, 764, 300, kenneyState(target.id, {
    attack = v.progress,
    impact = v.glow,
    time = ctx.time,
    effectColor = v.choice == 2 and ctx.secondary or ctx.primary,
  }))
  Draw.feedbackRow({
    { text = "sequence", color = Draw.palette.green },
    { text = string.format("repeat  %d/3", math.floor(v.count)), color = ctx.primary },
    { text = v.choice == 2 and "random  heavy" or "random  jab", color = ctx.secondary },
    { text = "parallel  hit + burst", color = Draw.palette.violet },
  }, 158, 168, ctx.fonts.small)
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
          { kind = "animate", duration = 0.12, ease = "quadout", to = { pulse = 1, scale = 1.08 } },
          { kind = "animate", duration = 0.16, ease = "quadout", to = { pulse = 0, scale = 1 } },
          { kind = "wait", duration = 0.1 },
        },
      },
    }, ctx.values, "repeat.combo")
  end
  triggerTwice(ctx, trigger)
end

local function drawRepeat(ctx, target)
  local v = ctx.values.values
  drawChrome(ctx, target)

  local count = math.max(0, math.min(3, math.floor(v.count)))
  Draw.label("REPEAT x3", 288, 174, ctx.primary, ctx.fonts.small)
  Draw.label(string.format("PASS %d / 3", count), 570, 174, Draw.palette.muted, ctx.fonts.small)

  Draw.setColor(ctx.primary, 0.28 + v.pulse * 0.3)
  love.graphics.setLineWidth(2)
  love.graphics.line(324, 232, 294, 232, 294, 342, 666, 342, 666, 232, 636, 232)
  love.graphics.polygon("fill", 636, 232, 648, 225, 648, 239)
  love.graphics.setLineWidth(1)

  love.graphics.push()
  love.graphics.translate(480, 274)
  love.graphics.scale(v.scale)
  if v.pulse > 0 then
    Draw.setColor(ctx.primary, v.pulse * 0.12)
    love.graphics.rectangle("fill", -150, -64, 300, 128, 8, 8)
  end
  Draw.shadow(-126, -42, 260, 96, 6, 0.28)
  Draw.setColor(Draw.palette.panel2)
  love.graphics.rectangle("fill", -130, -48, 260, 96, 6, 6)
  Draw.setColor(ctx.primary, 0.5 + v.pulse * 0.5)
  love.graphics.setLineWidth(2 + v.pulse)
  love.graphics.rectangle("line", -129, -47, 258, 94, 6, 6)
  love.graphics.setLineWidth(1)
  Draw.centerLabel("CHILD STEP", -130, -25, 260, Draw.palette.muted, ctx.fonts.small)
  Draw.centerLabel("animate pulse", -130, 4, 260, Draw.palette.ink, ctx.fonts.body)
  love.graphics.pop()

  for i = 1, 3 do
    local x = 383 + (i - 1) * 68
    local complete = i <= count
    local active = i == count and v.pulse > 0
    Draw.setColor(complete and ctx.primary or Draw.palette.panel2, complete and (0.16 + (active and v.pulse * 0.18 or 0)) or 1)
    love.graphics.rectangle("fill", x, 370, 58, 42, 3, 3)
    Draw.setColor(complete and ctx.primary or Draw.palette.faint, complete and 0.9 or 0.55)
    love.graphics.setLineWidth(active and 3 or 1)
    love.graphics.rectangle("line", x + 0.5, 370.5, 57, 41, 3, 3)
    love.graphics.setLineWidth(1)
    Draw.centerLabel(tostring(i), x, 380, 58, complete and Draw.palette.ink or Draw.palette.muted, ctx.fonts.small)
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
  ctx.callbackStep = 0
  local function trigger()
    ctx.values.values.progress = 0
    ctx.callbackStep = 0
    play(ctx, {
      { kind = "emit", event = "spark.burst", payload = { count = 8 } },
      { kind = "wait", duration = 0.14 },
      { kind = "audio", cue = "ui-pop" },
      { kind = "wait", duration = 0.14 },
      { kind = "callback", callback = function()
        ctx.callbackStep = 3
        pushChip(ctx, "callback(fn)", Draw.palette.cyan)
      end },
      { kind = "wait", duration = 0.14 },
      { kind = "log", message = "ready" },
    }, ctx.values, "callbacks.bus", {
      emit = function(event)
        ctx.callbackStep = 1
        pushChip(ctx, "spark.burst", ctx.primary)
        spawnBurst(ctx, 552, 223, ctx.secondary, event.payload.count, 110)
      end,
      audio = function()
        ctx.callbackStep = 2
        pushChip(ctx, "ui-pop", ctx.secondary)
      end,
      log = function()
        ctx.callbackStep = 4
      end,
    })
  end
  triggerTwice(ctx, trigger)
end

local function drawCallbacks(ctx, target)
  drawChrome(ctx, target)
  local items = {
    { 'emit("spark.burst")', "particles.spawn(8)", ctx.primary },
    { 'audio("ui-pop")', "source:play()", ctx.secondary },
    { "callback(fn)", "fn(target)", Draw.palette.cyan },
    { 'log("ready")', 'print("ready")', Draw.palette.violet },
  }

  Draw.label("RECIPE STEP", 120, 174, Draw.palette.muted, ctx.fonts.small)
  Draw.label("HOST RESULT", 584, 174, Draw.palette.muted, ctx.fonts.small)
  for i, item in ipairs(items) do
    local y = 200 + (i - 1) * 60
    local active = i <= ctx.callbackStep
    local current = i == ctx.callbackStep
    local alpha = active and 0.82 or 0.24

    Draw.setColor(Draw.palette.panel2, 0.96)
    love.graphics.rectangle("fill", 120, y, 222, 42, 3, 3)
    love.graphics.rectangle("fill", 584, y, 252, 42, 3, 3)
    Draw.setColor(item[3], alpha)
    love.graphics.rectangle("fill", 120, y, 5, 42)
    love.graphics.rectangle("line", 120.5, y + 0.5, 221, 41, 3, 3)
    love.graphics.rectangle("fill", 584, y, 5, 42)
    love.graphics.rectangle("line", 584.5, y + 0.5, 251, 41, 3, 3)

    Draw.setColor(Draw.palette.faint, 0.48)
    love.graphics.rectangle("fill", 342, y + 20, 242, 2)
    Draw.setColor(item[3], alpha)
    love.graphics.circle("fill", 463, y + 21, active and 6 or 4)
    love.graphics.polygon("fill", 576, y + 16, 584, y + 21, 576, y + 26)
    if current then
      Draw.ring(463, y + 21, 13, 1, item[3], 0.72, 2)
    end

    Draw.label(item[1], 138, y + 11, active and Draw.palette.ink or Draw.palette.muted, ctx.fonts.small)
    Draw.label(item[2], 602, y + 11, active and Draw.palette.ink or Draw.palette.muted, ctx.fonts.small)
  end
  drawParticles(ctx)
end

local function setupPulse(ctx)
  local function trigger()
    play(ctx, {
      { kind = "emit", event = "pulse.start" },
      { kind = "animate", duration = 0.08, ease = "quadout", to = { scale = 1.2, glow = 1, pulse = 1 } },
      { kind = "animate", duration = 0.13, ease = "backout", to = { scale = 1, glow = 0.22, pulse = 0.25 } },
      { kind = "wait", duration = 0.07 },
      { kind = "animate", duration = 0.07, ease = "quadout", to = { scale = 1.11, glow = 0.62, pulse = 0.68 } },
      { kind = "animate", duration = 0.22, ease = "backout", to = { scale = 1, glow = 0, pulse = 0 } },
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
  Draw.feedbackRow({
    { text = "animate  scale", color = ctx.primary },
    { text = "ease  backout", color = ctx.secondary },
    { text = "recipe  pulse", color = Draw.palette.violet },
  }, 276, 168, ctx.fonts.small)
  Draw.shadow(384, 378, 192, 24, 12, 0.24)
  Draw.heart(480, 282, 104, ctx.primary, 0.12 * v.pulse, 1.18 + v.pulse * 0.3, "line", 3)
  Draw.heart(480, 282, 104, ctx.primary, 0.2 * v.pulse, 1.08 + v.pulse * 0.16, "line", 2)
  Draw.heart(480, 282, 104, ctx.primary, 1, v.scale)
  Draw.heart(458, 248, 22, Draw.palette.ink, 0.18 + v.glow * 0.2, v.scale * 0.9)
  for i = 1, 7 do
    local angle = i / 8 * math.pi * 2 - math.pi / 2
    local inner = 126 + v.pulse * 8
    local outer = inner + v.pulse * 12
    Draw.setColor(ctx.secondary, v.pulse * 0.7)
    love.graphics.setLineWidth(3)
    love.graphics.line(
      480 + math.cos(angle) * inner,
      282 + math.sin(angle) * inner,
      480 + math.cos(angle) * outer,
      282 + math.sin(angle) * outer
    )
  end
  love.graphics.setLineWidth(1)
  Draw.feedbackChip(string.format("target.scale  %.2f", v.scale), 402, 408, ctx.primary, ctx.fonts.small)
end

local function setupSprite(ctx)
  ctx.Sprite = require("feel.sprite")
  ctx.spriteFx = ctx.Sprite.target()
  local function trigger()
    ctx.Sprite.play(ctx.spriteFx, "hitHeavy", {
      x = -18,
      rotation = -0.1,
      squash = 0.24,
      stretch = 0.2,
      duration = 0.34,
    })
    pushChip(ctx, "hitHeavy", ctx.primary)
  end
  triggerTwice(ctx, trigger)
end

local function drawSprite(ctx, target)
  drawChrome(ctx, target)
  Draw.kenneyArena(ctx.kenney, 98, 154, 764, 300, kenneyState(target.id, {
    hidePlayer = true,
    hideEnemy = true,
    time = ctx.time,
  }))

  local frames = ctx.kenney.actors.ladybug
  local frame = frames[math.floor(ctx.time * 4) % #frames + 1]
  local width, height = frame:getDimensions()
  local pose = ctx.Sprite.pose(ctx.spriteFx, { x = 480, y = 402 })
  Draw.setColor(ctx.primary, 0.08 + pose.glow * 0.18)
  love.graphics.circle("fill", pose.x, pose.y - 42, 58 + pose.glow * 20)

  love.graphics.push()
  love.graphics.translate(pose.x, pose.y)
  love.graphics.rotate(pose.rotation)
  love.graphics.scale(pose.scaleX * 1.65, pose.scaleY * 1.65)
  if pose.outline > 0 then
    Draw.setColor(ctx.primary, pose.outline * 0.7)
    for _, offset in ipairs({ { -3, 0 }, { 3, 0 }, { 0, -3 }, { 0, 3 } }) do
      love.graphics.draw(frame, offset[1], offset[2], 0, 1, 1, width / 2, height)
    end
  end
  Draw.setColor({
    Draw.mix(pose.tintR, 1, pose.flash),
    Draw.mix(pose.tintG, 1, pose.flash),
    Draw.mix(pose.tintB, 1, pose.flash),
    pose.opacity,
  })
  love.graphics.draw(frame, 0, 0, 0, 1, 1, width / 2, height)
  love.graphics.pop()

  Draw.feedbackRow({
    { text = "pose values", color = ctx.primary },
    { text = "draw callback", color = ctx.secondary },
    { text = "Anim8 optional", color = Draw.palette.green },
  }, 294, 174, ctx.fonts.small)
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
  elseif id == "impact-feedback" then
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
          { kind = "emit", event = "particle.emit", payload = { name = "sparks", count = 18, x = 594, y = 330 } },
          { kind = "audio", cue = "ui-pop" },
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
            { kind = "emit", event = "particle.emit", payload = { name = "sparks", count = 42, x = 594, y = 330 } },
            { kind = "emit", event = "screen.flash", payload = { amount = 0.12, duration = 0.08, color = ctx.secondary } },
          },
        },
        { kind = "wait", duration = 0.32 },
        { kind = "animate", duration = 0.34, ease = "backout", to = { progress = 0.18, glow = 0, scale = 1, tilt = 0 } },
      }, ctx.values, "particles", {
        emit = function(event)
          if event.kind == "particle.emit" then
            local payload = event.payload or {}
            addRing(ctx, payload.x or 594, payload.y or 330, ctx.secondary, 0.5, 24)
            spawnDirectionalBurst(ctx, payload.x or 594, payload.y or 330, ctx.secondary, 24, math.pi, math.pi * 0.8, 260)
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
    elseif id == "impact-feedback" then
      ctx.Feedbacks.play("impact.stack", nil, { target = ctx.values, restart = true, key = "impact.stack" })
      pushChip(ctx, "impact.stack", ctx.primary)
    elseif id == "love2d" then
      play(ctx, {
        {
          kind = "parallel",
          steps = {
            { kind = "emit", event = "particle.emit", payload = { name = "sparks", count = 18, x = 594, y = 330 } },
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
  if id == "shake" or id == "impact-feedback" or id == "love2d" then
    ctx.fx:push()
  end
  Draw.kenneyArena(ctx.kenney, 98, 154, 764, 300, kenneyState(id, {
    attack = v.glow,
    impact = v.glow,
    time = ctx.time,
    effectColor = ctx.secondary,
  }))
  if id == "impact-feedback" then
    local bloom = ctx.fx.post.effects.bloom.target.values.intensity or 0
    Draw.setColor(ctx.secondary, 0.06 + bloom * 0.12)
    love.graphics.circle("fill", 594, 330, 42 + bloom * 24)
    Draw.ring(594, 330, 28 + ctx.sound.level * 24, 1, Draw.palette.green, ctx.sound.level * 0.72, 2)
  end
  if id == "impact-feedback" or id == "love2d" then
    drawParticles(ctx)
  end
  if id == "shake" or id == "impact-feedback" or id == "love2d" then
    ctx.fx:pop()
  end
end

local function drawSpeaker(x, y, color, energy, label, font)
  energy = Draw.clamp(energy)
  Draw.shadow(x + 5, y + 7, 70, 116, 8, 0.24)
  Draw.setColor(Draw.palette.panel2)
  love.graphics.rectangle("fill", x, y, 70, 116, 5, 5)
  Draw.setColor(color, 0.34 + energy * 0.58)
  love.graphics.rectangle("line", x + 0.5, y + 0.5, 69, 115, 5, 5)
  Draw.setColor(Draw.palette.faint)
  love.graphics.circle("fill", x + 35, y + 39, 14)
  love.graphics.circle("fill", x + 35, y + 82, 24)
  Draw.setColor(color, 0.34 + energy * 0.66)
  love.graphics.circle("fill", x + 35, y + 39, 5 + energy * 3)
  love.graphics.circle("fill", x + 35, y + 82, 12 + energy * 8)
  Draw.setColor(Draw.palette.panel2)
  love.graphics.circle("fill", x + 35, y + 82, 5)
  Draw.centerLabel(label, x, y + 124, 70, Draw.palette.muted, font)
end

local function drawSoundScene(ctx)
  local sound = ctx.sound
  local level = Draw.clamp(sound.level)
  local pan = math.max(-1, math.min(1, sound.pan))
  local leftEnergy = level * (1 - pan) * 0.5
  local rightEnergy = level * (1 + pan) * 0.5
  local sourceX = 480 + pan * 190
  local waveLeft, waveRight = 252, 708
  local waveY = 270
  local amplitude = 2 + sound.volume * 32 * level
  local cycles = 3.5 + sound.pitch * 3.2

  drawSpeaker(132, 216, ctx.primary, leftEnergy, "L", ctx.fonts.small)
  drawSpeaker(758, 216, ctx.secondary, rightEnergy, "R", ctx.fonts.small)

  Draw.setColor(Draw.palette.faint, 0.34)
  love.graphics.rectangle("fill", waveLeft, waveY, waveRight - waveLeft, 2)
  local points = {}
  for i = 0, 72 do
    local p = i / 72
    points[#points + 1] = waveLeft + p * (waveRight - waveLeft)
    points[#points + 1] = waveY + math.sin(p * math.pi * 2 * cycles) * amplitude * math.sin(p * math.pi)
  end
  Draw.setColor(ctx.primary, 0.16 + level * 0.84)
  love.graphics.setLineWidth(3)
  love.graphics.line(points)
  love.graphics.setLineWidth(1)

  Draw.setColor(ctx.secondary, 0.1 + level * 0.18)
  love.graphics.circle("fill", sourceX, waveY, 24 + level * 15)
  Draw.ring(sourceX, waveY, 20 + level * 13, 1, ctx.secondary, 0.4 + level * 0.5, 2)
  Draw.setColor(ctx.secondary)
  love.graphics.circle("fill", sourceX, waveY, 8)
  Draw.feedbackChip("ui-pop", sourceX - 42, 188, ctx.secondary, ctx.fonts.small)

  Draw.setColor(Draw.palette.faint, 0.52)
  love.graphics.rectangle("fill", 290, 344, 380, 2)
  love.graphics.rectangle("fill", 479, 338, 2, 14)
  Draw.setColor(ctx.secondary, 0.24)
  love.graphics.line(sourceX, waveY + 18, sourceX, 345)
  Draw.setColor(ctx.secondary)
  love.graphics.circle("fill", sourceX, 345, 7)
  Draw.label("L", 274, 337, Draw.palette.muted, ctx.fonts.small)
  Draw.label("R", 680, 337, Draw.palette.muted, ctx.fonts.small)

  Draw.feedbackRow({
    { text = string.format("volume  %.2f", sound.volume), color = ctx.primary },
    { text = string.format("pitch  %.2fx", sound.pitch), color = ctx.secondary },
    { text = string.format("pan  %+.2f", pan), color = Draw.palette.violet },
  }, 274, 388, ctx.fonts.small)
end

local function drawAdapter(ctx, target, id)
  drawChrome(ctx, target)
  if id == "shake" or id == "impact-feedback" or id == "love2d" then
    drawArena(ctx, id)
  elseif id == "flash" then
    drawArena(ctx, id)
  elseif id == "sound" then
    drawSoundScene(ctx)
  elseif id == "haptics" then
    Draw.controller(ctx.inputPromptsController, 480, 294, ctx.haptic.left, ctx.haptic.right, ctx.primary, ctx.secondary)
    Draw.feedbackRow({
      { text = string.format("L motor  %.2f", ctx.haptic.left), color = ctx.primary },
      { text = string.format("R motor  %.2f", ctx.haptic.right), color = ctx.secondary },
    }, 348, 390, ctx.fonts.small)
  elseif id == "particles" then
    local v = ctx.values.values
    Draw.kenneyArena(ctx.kenney, 98, 154, 764, 300, kenneyState(id, {
      attack = v.progress,
      impact = v.glow,
      time = ctx.time,
      effectColor = ctx.secondary,
    }))
    drawParticles(ctx)
  elseif id == "shader" then
    local amount = ctx.fx.shaderEntries.glow and (ctx.fx.shaderEntries.glow.values.amount or 0) or 0
    local style = KENNEY_STYLES[id]
    local enemyX, feetY = Draw.kenneyArena(ctx.kenney, 98, 154, 764, 300, kenneyState(id, {
      attack = amount,
      impact = 0,
      time = ctx.time,
      effectColor = ctx.secondary,
      hideEnemy = true,
    }))
    if ctx.shader then
      ctx.fx:pushShader("glow")
    end
    Draw.kenneyActor(ctx.kenney, style.enemy, enemyX, feetY, ctx.time, amount, 1, style.enemyLift)
    if ctx.shader then
      ctx.fx:popShader()
    end
  elseif id == "post-processing" then
    local bloom = ctx.fx.post.effects.bloom.target.values.intensity or 0
    local chromatic = ctx.fx.post.effects.chromatic.target.values.force or 0
    Draw.setColor(Draw.palette.pink, chromatic * 0.38)
    love.graphics.rectangle("fill", 272 - chromatic * 10, 204, 412, 230, 12, 12)
    Draw.setColor(Draw.palette.cyan, chromatic * 0.38)
    love.graphics.rectangle("fill", 272 + chromatic * 10, 204, 412, 230, 12, 12)
    Draw.kenneyArena(ctx.kenney, 98, 154, 764, 300, kenneyState(id, {
      attack = math.min(1, bloom),
      impact = math.min(1, bloom),
      time = ctx.time,
      effectColor = ctx.secondary,
    }))
    Draw.setColor(ctx.secondary, 0.08 + bloom * 0.16)
    love.graphics.circle("fill", 594, 330, 44 + bloom * 26)
  end
  drawRings(ctx)
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
    ctx.g3dfx:model("cube", ctx.three.model, {
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
            { kind = "emit", event = "g3d.camera.fov", payload = { value = 4, duration = 0.07, returnDuration = 0.22 } },
            { kind = "emit", event = "g3d.model.scalePunch", payload = { name = "cube", amount = 0.24, duration = 0.07, returnDuration = 0.24 } },
            { kind = "emit", event = "g3d.model.rotationShake", payload = { name = "cube", amount = 0.14, duration = 0.18 } },
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
          },
        },
        { kind = "animate", duration = 0.38, ease = "backout", to = { scale = 1, glow = 0, heat = 0, orbit = 0 } },
      }, ctx.values, "three.menori")
      pushChip(ctx, "node", ctx.primary)
      pushChip(ctx, "camera.orbit", ctx.primary)
      pushChip(ctx, "uniform", ctx.secondary)
    end
  end
  triggerTwice(ctx, trigger)
end

local function drawCubeStage(ctx, color, groundY)
  groundY = groundY or 390
  Draw.setColor(color, 0.06)
  love.graphics.ellipse("fill", 480, groundY, 142, 26)
  Draw.setColor({ 0, 0, 0, 1 }, 0.38)
  love.graphics.ellipse("fill", 480, groundY, 104, 18)
end

local function drawG3dScene(ctx, scale, rotation, glow)
  local camera = ctx.three.camera
  local eye = camera.eye or { 0, -7, 4 }
  local shakeX = math.max(-9, math.min(9, (eye[1] or 0) * 90))
  local shakeY = math.max(-7, math.min(7, ((eye[3] or 4) - 4) * 48))
  local fov = camera.fov or 60

  love.graphics.push()
  love.graphics.setScissor(98, 154, 764, 300)
  love.graphics.translate(shakeX, shakeY)
  Draw.setColor({ 0.025, 0.055, 0.082, 1 })
  love.graphics.rectangle("fill", 98 - shakeX, 154 - shakeY, 764, 300)
  drawCubeStage(ctx, ctx.primary)
  Draw.setColor(ctx.primary, 0.08 + glow * 0.12)
  love.graphics.circle("fill", 480, 300, 112 + glow * 18)
  local modelRotation = ctx.three.model.rotation
  Draw.cube3d(
    480, 302, 70,
    0.62 + (modelRotation[2] or 0),
    -0.42 + (modelRotation[1] or 0),
    rotation,
    ctx.primary, fov, scale
  )
  love.graphics.setScissor()
  love.graphics.pop()

  Draw.feedbackChip(string.format("camera.fov  %.1f", fov), 116, 168, ctx.secondary, ctx.fonts.small)
  Draw.feedbackChip(string.format("cube.scale  %.2f", scale), 665, 168, ctx.primary, ctx.fonts.small)
end

local function drawMenoriScene(ctx, values)
  Draw.setColor({ 0.045, 0.035, 0.075, 1 })
  love.graphics.rectangle("fill", 98, 154, 764, 300)
  local tint = Draw.mixColor(ctx.secondary, Draw.palette.pink, values.heat * 0.72)
  local angle = values.orbit * math.pi * 2
  drawCubeStage(ctx, ctx.primary, 380)
  Draw.setColor(tint, 0.08 + values.glow * 0.12)
  love.graphics.circle("fill", 480, 286, 98 + values.glow * 16)
  Draw.cube3d(480, 286, 60, 0.62 + angle, -0.42, 0, tint, 60, values.scale)

  Draw.feedbackRow({
    { text = string.format("camera.orbit  %d deg", math.floor(values.orbit * 360 + 0.5)), color = ctx.primary },
    { text = string.format("node.scale  %.2f", values.scale), color = ctx.primary },
    { text = "uniform.tint", color = tint },
  }, 244, 416, ctx.fonts.small)
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
  if id == "g3d" then
    drawG3dScene(ctx, scale, rot, glow)
  else
    drawMenoriScene(ctx, v)
  end
end

local SETUP = {
  ["motion-basics"] = setupPulse,
  ["combo-recipe"] = setupSequence,
  ["host-integration"] = setupCallbacks,
  sprite = setupSprite,
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
  ["motion-basics"] = drawPulse,
  ["combo-recipe"] = drawSequence,
  ["host-integration"] = drawCallbacks,
  sprite = drawSprite,
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

local KENNEY_SCENES = {
  ["combo-recipe"] = true,
  ["impact-feedback"] = true,
  sprite = true,
  ["getting-started"] = true,
  sequence = true,
  shake = true,
  flash = true,
  particles = true,
  shader = true,
  ["post-processing"] = true,
  feedbacks = true,
  love2d = true,
}

function Scenes.create(target, ctx)
  resetCommon(ctx, target)
  if KENNEY_SCENES[target.id] then
    ctx.kenney = Draw.loadKenneyPlatformer()
  end
  if target.id == "haptics" then
    ctx.inputPromptsController = Draw.loadInputPromptsController()
  end

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
