package.path = "./?.lua;./?/init.lua;" .. package.path

local feel = require("feel")
local feelLove = require("feel.love")
local Draw = require("scripts.doc_gifs.drawing")

local Scenes = {}

local function action(at, fn)
  return { at = at, run = fn }
end

local function pushLog(ctx, text)
  ctx.logs[#ctx.logs + 1] = text
  while #ctx.logs > 5 do
    table.remove(ctx.logs, 1)
  end
end

local function copyColor(color)
  return { color[1], color[2], color[3], color[4] or 1 }
end

local function resetCommon(ctx, target)
  feel.clear()
  ctx.fx = feelLove.new({
    width = ctx.width,
    height = ctx.height,
    shakeAmount = 12,
    shakeDuration = 0.32,
    flashAmount = 0.58,
    flashDuration = 0.18,
  })
  ctx.logs = {}
  ctx.particles = {}
  ctx.targetValues = feel.target({
    values = {
      x = 0,
      y = 0,
      scale = 1,
      glow = 0,
      pulse = 0,
      progress = 0,
      rotation = 0,
      orbit = 0,
      heat = 0,
    },
  })
  ctx.primary = copyColor(target.primary or Draw.palette.cyan)
  ctx.secondary = copyColor(target.secondary or Draw.palette.gold)
  ctx.actions = {}
end

local function sceneHandlers(ctx, extra)
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
      pushLog(ctx, message)
      if type(extra.log) == "function" then
        extra.log(message, runCtx)
      end
    end,
  })
end

local function play(ctx, sequence, target, key, extra)
  local opts = sceneHandlers(ctx, extra)
  opts.restart = true
  opts.key = key or "doc-gif"
  return feel.play(sequence, target, opts)
end

local function spawnBurst(ctx, x, y, color, count, spread)
  count = count or 18
  spread = spread or 220
  for _ = 1, count do
    local angle = math.random() * math.pi * 2
    local speed = spread * (0.38 + math.random() * 0.62)
    ctx.particles[#ctx.particles + 1] = {
      x = x,
      y = y,
      vx = math.cos(angle) * speed,
      vy = math.sin(angle) * speed - 20,
      life = 0.42 + math.random() * 0.22,
      maxLife = 0.64,
      size = 3 + math.random() * 4,
      color = copyColor(color),
    }
  end
end

local function updateParticles(ctx, dt)
  for index = #ctx.particles, 1, -1 do
    local particle = ctx.particles[index]
    particle.life = particle.life - dt
    particle.x = particle.x + particle.vx * dt
    particle.y = particle.y + particle.vy * dt
    particle.vy = particle.vy + 260 * dt
    if particle.life <= 0 then
      table.remove(ctx.particles, index)
    end
  end
end

local function drawParticles(ctx)
  for _, particle in ipairs(ctx.particles) do
    local alpha = Draw.clamp(particle.life / particle.maxLife, 0, 1)
    Draw.spark(particle.x, particle.y, particle.size * alpha, particle.color, alpha)
  end
end

local function updateCommon(ctx, dt)
  feel.update(dt)
  if ctx.g3dfx then
    ctx.g3dfx:update()
  end
  if ctx.menorifx and type(ctx.menorifx.update) == "function" then
    ctx.menorifx:update(dt)
  end
  ctx.fx:update(dt)
  updateParticles(ctx, dt)

  if ctx.sound then
    ctx.sound.level = math.max(0, ctx.sound.level - dt * 1.6)
  end
  if ctx.haptic then
    ctx.haptic.remaining = math.max(0, ctx.haptic.remaining - dt)
    if ctx.haptic.remaining <= 0 then
      ctx.haptic.left = 0
      ctx.haptic.right = 0
    end
  end
end

local function drawLogs(ctx, x, y, w)
  Draw.panel(x, y, w, 162, 0.92)
  Draw.label("event stream", x + 18, y + 16, Draw.palette.text, ctx.fonts.small)
  for index, line in ipairs(ctx.logs) do
    Draw.label(line, x + 18, y + 36 + index * 20, Draw.palette.muted, ctx.fonts.small)
  end
end

local function setupButton(scene, ctx, target)
  resetCommon(ctx, target)
  local id = target.id
  local values = ctx.targetValues.values

  if id == "animate" then
    values.x = -220
    values.scale = 0.82
  end

  local sequence
  if id == "getting-started" then
    sequence = {
      {
        kind = "parallel",
        steps = {
          { kind = "emit", event = "spark.burst", payload = { count = 22 } },
          { kind = "animate", duration = 0.08, ease = "quadout", to = { scale = 0.88, y = 10, glow = 1 } },
        },
      },
      { kind = "wait", duration = 0.04 },
      { kind = "animate", duration = 0.32, ease = "backout", to = { scale = 1, y = 0, glow = 0 } },
    }
  elseif id == "animate" then
    sequence = {
      { kind = "animate", duration = 0.7, ease = "quadout", to = { x = 220, scale = 1.1, glow = 1, rotation = 0.05 } },
      { kind = "wait", duration = 0.22 },
      { kind = "animate", duration = 0.42, ease = "backout", to = { x = -220, scale = 0.82, glow = 0, rotation = 0 } },
    }
  elseif id == "pulse" then
    sequence = {
      { kind = "emit", event = "pulse.start" },
      { kind = "animate", duration = 0.09, ease = "quadout", to = { scale = 1.2, glow = 1, pulse = 1 } },
      { kind = "animate", duration = 0.38, ease = "backout", to = { scale = 1, glow = 0, pulse = 0 } },
      { kind = "log", message = "pulse settled" },
    }
  else
    sequence = {
      { kind = "animate", duration = 0.1, ease = "quadout", to = { scale = 1.14, glow = 1 } },
      { kind = "animate", duration = 0.26, ease = "backout", to = { scale = 1, glow = 0 } },
    }
  end

  local function trigger()
    play(ctx, sequence, ctx.targetValues, id .. ".button", {
      emit = function(event)
        if event.kind == "spark.burst" then
          spawnBurst(ctx, 480, 292, ctx.secondary, event.payload.count or 18)
        end
        pushLog(ctx, "emit: " .. event.kind)
      end,
    })
  end

  ctx.actions = {
    action(0.28, trigger),
    action(1.55, trigger),
  }
end

local function drawButtonScene(scene, ctx, target)
  local values = ctx.targetValues.values
  Draw.clear(ctx.width, ctx.height)
  Draw.header(ctx, target)

  Draw.panel(112, 152, 736, 296)
  Draw.progressBar(174, 392, 608, 12, (ctx.time % 1.27) / 1.27, ctx.primary, nil, ctx.fonts.small)

  if target.id == "animate" then
    love.graphics.push()
    love.graphics.translate(480 + values.x, 282 + values.y)
    love.graphics.rotate(values.rotation)
    Draw.button(-110, -36, 220, 72, values.scale, values.glow, ctx.primary, "TARGET", ctx.fonts.body)
    love.graphics.pop()
    Draw.label("values.x", 176, 206, Draw.palette.muted, ctx.fonts.small)
    Draw.label("values.scale", 664, 206, Draw.palette.muted, ctx.fonts.small)
  else
    Draw.button(350, 236 + values.y, 260, 82, values.scale, values.glow, ctx.primary, target.id == "pulse" and "PULSE" or "LAUNCH", ctx.fonts.body)
    if target.id == "pulse" then
      Draw.setColor(ctx.primary, values.pulse * 0.18)
      love.graphics.circle("fill", 480, 277, 98 + values.pulse * 46)
    end
  end

  drawParticles(ctx)
  drawLogs(ctx, 626, 168, 220)
end

local function setupEasing(scene, ctx, target)
  resetCommon(ctx, target)
  ctx.easeTargets = {
    { name = "linear", target = feel.target({ values = { y = 0, glow = 0 } }), color = Draw.palette.cyan },
    { name = "backout", target = feel.target({ values = { y = 0, glow = 0 } }), color = Draw.palette.gold },
    { name = "bounceout", target = feel.target({ values = { y = 0, glow = 0 } }), color = Draw.palette.violet },
  }

  local function trigger()
    for _, item in ipairs(ctx.easeTargets) do
      play(ctx, {
        { kind = "animate", duration = 0.55, ease = item.name, from = { y = 0, glow = 0 }, to = { y = -118, glow = 1 } },
        { kind = "wait", duration = 0.18 },
        { kind = "animate", duration = 0.36, ease = "quadout", to = { y = 0, glow = 0 } },
      }, item.target, "easing." .. item.name)
    end
  end

  ctx.actions = {
    action(0.25, trigger),
    action(1.58, trigger),
  }
end

local function drawEasingScene(scene, ctx, target)
  Draw.clear(ctx.width, ctx.height)
  Draw.header(ctx, target)
  Draw.panel(104, 142, 752, 326)
  for index, item in ipairs(ctx.easeTargets) do
    local x = 220 + (index - 1) * 260
    local y = 348 + item.target.values.y
    Draw.setColor(Draw.palette.line)
    love.graphics.line(x, 196, x, 376)
    Draw.setColor(item.color, 0.16 + item.target.values.glow * 0.2)
    love.graphics.circle("fill", x, y, 58)
    Draw.spark(x, y, 24, item.color, 0.95)
    Draw.centerLabel(item.name, x - 90, 410, 180, Draw.palette.text, ctx.fonts.body)
  end
end

local function setupFlow(scene, ctx, target)
  resetCommon(ctx, target)
  ctx.flow = {
    step = 0,
    branchA = feel.target({ values = { progress = 0, pulse = 0 } }),
    branchB = feel.target({ values = { progress = 0, pulse = 0 } }),
    randomChoice = 0,
    ticks = 0,
  }

  local function resetFlow()
    ctx.flow.step = 0
    ctx.flow.randomChoice = 0
    ctx.flow.ticks = 0
    ctx.flow.branchA.values.progress = 0
    ctx.flow.branchA.values.pulse = 0
    ctx.flow.branchB.values.progress = 0
    ctx.flow.branchB.values.pulse = 0
    ctx.targetValues.values.progress = 0
    ctx.targetValues.values.pulse = 0
    ctx.logs = {}
  end

  local function triggerSequence()
    resetFlow()
    play(ctx, {
      { kind = "callback", callback = function() ctx.flow.step = 1; pushLog(ctx, "step: animate") end },
      { kind = "animate", duration = 0.34, ease = "quadout", to = { progress = 1 } },
      { kind = "wait", duration = 0.14 },
      { kind = "callback", callback = function() ctx.flow.step = 2; pushLog(ctx, "step: emit") end },
      { kind = "emit", event = "spark.burst", payload = { count = 12 } },
      { kind = "wait", duration = 0.18 },
      { kind = "callback", callback = function() ctx.flow.step = 3; pushLog(ctx, "step: callback") end },
    }, ctx.targetValues, "flow.sequence", {
      emit = function(event)
        if event.kind == "spark.burst" then
          spawnBurst(ctx, 650, 298, ctx.secondary, event.payload.count or 12, 180)
        end
      end,
    })
  end

  local function triggerParallel()
    resetFlow()
    play(ctx, {
      {
        kind = "parallel",
        steps = {
          {
            { kind = "animate", duration = 0.62, ease = "quadout", to = { progress = 1, pulse = 1 } },
            { kind = "animate", duration = 0.24, ease = "quadout", to = { pulse = 0 } },
          },
          {
            { kind = "wait", duration = 0.1 },
            { kind = "animate", duration = 0.52, ease = "backout", to = { progress = 1, pulse = 1 } },
            { kind = "animate", duration = 0.24, ease = "quadout", to = { pulse = 0 } },
          },
        },
      },
      { kind = "callback", callback = function() ctx.flow.step = 3; pushLog(ctx, "branches joined") end },
    }, ctx.flow.branchA, "flow.parallel")
    play(ctx, { { kind = "animate", duration = 0.62, ease = "quadout", to = { progress = 1, pulse = 1 } } }, ctx.flow.branchB, "flow.parallel.b")
  end

  local function triggerRepeat()
    resetFlow()
    play(ctx, {
      {
        kind = "repeat",
        count = 3,
        step = {
          { kind = "callback", callback = function() ctx.flow.ticks = ctx.flow.ticks + 1; pushLog(ctx, "repeat tick " .. ctx.flow.ticks) end },
          { kind = "animate", duration = 0.08, ease = "quadout", to = { pulse = 1 } },
          { kind = "animate", duration = 0.18, ease = "quadout", to = { pulse = 0 } },
          { kind = "wait", duration = 0.06 },
        },
      },
      { kind = "callback", callback = function() ctx.flow.step = 3; pushLog(ctx, "repeat done") end },
    }, ctx.targetValues, "flow.repeat")
  end

  local function triggerRandom()
    resetFlow()
    play(ctx, {
      {
        kind = "random",
        options = {
          { weight = 3, step = { kind = "callback", callback = function() ctx.flow.randomChoice = 1; pushLog(ctx, "random: small") end } },
          { weight = 1, step = { kind = "callback", callback = function() ctx.flow.randomChoice = 2; pushLog(ctx, "random: big") end } },
        },
      },
      { kind = "animate", duration = 0.28, ease = "backout", to = { pulse = 1 } },
      { kind = "animate", duration = 0.3, ease = "quadout", to = { pulse = 0 } },
    }, ctx.targetValues, "flow.random")
  end

  local function triggerCallbacks()
    resetFlow()
    play(ctx, {
      { kind = "emit", event = "spark.burst", payload = { count = 8 } },
      { kind = "audio", cue = "ui-pop" },
      { kind = "callback", callback = function() pushLog(ctx, "callback: ctx.trigger") end },
      { kind = "log", message = "log: sequence complete" },
    }, ctx.targetValues, "flow.callbacks", {
      emit = function(event)
        pushLog(ctx, "emit: " .. event.kind)
      end,
      audio = function(event)
        pushLog(ctx, "audio: " .. event.cue)
      end,
    })
  end

  local trigger = triggerSequence
  if target.id == "parallel" then
    trigger = triggerParallel
  elseif target.id == "repeat" then
    trigger = triggerRepeat
  elseif target.id == "random" then
    trigger = triggerRandom
  elseif target.id == "callbacks" then
    trigger = triggerCallbacks
  end

  ctx.actions = {
    action(0.28, trigger),
    action(1.62, trigger),
  }
end

local function drawFlowScene(scene, ctx, target)
  Draw.clear(ctx.width, ctx.height)
  Draw.header(ctx, target)
  Draw.panel(86, 148, 616, 322)
  drawLogs(ctx, 720, 158, 212)

  local id = target.id
  if id == "parallel" then
    Draw.progressBar(150, 230, 460, 28, ctx.flow.branchA.values.progress, ctx.primary, "branch A", ctx.fonts.small)
    Draw.progressBar(150, 322, 460, 28, ctx.flow.branchB.values.progress, ctx.secondary, "branch B", ctx.fonts.small)
    Draw.timelineStep(254, 386, 220, 54, ctx.flow.step == 3 and "joined" or "parallel", true, ctx.flow.step == 3, Draw.palette.green, ctx.fonts.body)
  elseif id == "repeat" then
    for index = 1, 3 do
      local done = ctx.flow.ticks >= index
      Draw.timelineStep(154 + (index - 1) * 150, 244, 108, 96, "tick " .. index, done, done, ctx.primary, ctx.fonts.body)
    end
    Draw.setColor(ctx.secondary, ctx.targetValues.values.pulse * 0.35)
    love.graphics.circle("fill", 384, 384, 52 + ctx.targetValues.values.pulse * 36)
  elseif id == "random" then
    Draw.timelineStep(168, 238, 190, 104, "small", ctx.flow.randomChoice == 1, ctx.flow.randomChoice == 1, ctx.primary, ctx.fonts.body)
    Draw.timelineStep(448, 238, 190, 104, "big", ctx.flow.randomChoice == 2, ctx.flow.randomChoice == 2, ctx.secondary, ctx.fonts.body)
    Draw.centerLabel("weighted option", 252, 380, 300, Draw.palette.muted, ctx.fonts.body)
  elseif id == "callbacks" then
    Draw.timelineStep(126, 230, 126, 72, "emit", true, #ctx.logs >= 1, ctx.primary, ctx.fonts.body)
    Draw.timelineStep(274, 230, 126, 72, "audio", true, #ctx.logs >= 2, ctx.secondary, ctx.fonts.body)
    Draw.timelineStep(422, 230, 126, 72, "callback", true, #ctx.logs >= 3, Draw.palette.green, ctx.fonts.body)
    Draw.timelineStep(570, 230, 126, 72, "log", true, #ctx.logs >= 4, Draw.palette.violet, ctx.fonts.body)
  else
    local progress = ctx.targetValues.values.progress
    Draw.timelineStep(126, 250, 138, 80, "animate", ctx.flow.step == 1, progress >= 1, ctx.primary, ctx.fonts.body)
    Draw.timelineStep(306, 250, 138, 80, "wait", ctx.flow.step == 1 and progress >= 1, ctx.flow.step >= 2, ctx.secondary, ctx.fonts.body)
    Draw.timelineStep(486, 250, 138, 80, "emit", ctx.flow.step == 2, ctx.flow.step >= 3, Draw.palette.green, ctx.fonts.body)
    Draw.progressBar(148, 386, 476, 12, progress, ctx.primary)
    drawParticles(ctx)
  end
end

local function makeSoundSource(ctx)
  return {
    play = function()
      ctx.sound.level = 1
      pushLog(ctx, "audio: ui-pop")
    end,
    stop = function() end,
    setVolume = function(_, value)
      ctx.sound.volume = value
    end,
    setPitch = function(_, value)
      ctx.sound.pitch = value
    end,
    setPosition = function(_, x)
      ctx.sound.pan = x
    end,
  }
end

local function makeHaptic(ctx)
  return {
    isVibrationSupported = function()
      return true
    end,
    setVibration = function(_, left, right, duration)
      ctx.haptic.left = left or 0
      ctx.haptic.right = right or left or 0
      ctx.haptic.remaining = duration or 0.15
      pushLog(ctx, "haptic: rumble")
    end,
  }
end

local function makeParticleSystem(ctx)
  local system = { x = 480, y = 288 }
  function system:setPosition(x, y)
    self.x = x or self.x
    self.y = y or self.y
  end
  function system:emit(count)
    spawnBurst(ctx, self.x, self.y, ctx.primary, count or 16, 260)
    pushLog(ctx, "particle.emit")
  end
  function system:update() end
  function system:start() end
  function system:stop() end
  function system:reset() ctx.particles = {} end
  return system
end

local function setupShader(ctx)
  local ok, shader = pcall(love.graphics.newShader, [[
extern number amount;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen)
{
  vec4 pixel = Texel(tex, uv) * color;
  number scan = sin(screen.y * 0.26) * 0.5 + 0.5;
  number bars = step(0.55, scan);
  number split = sin(screen.x * 0.038 + screen.y * 0.014) * 0.5 + 0.5;
  vec3 cyan = vec3(0.0, 0.9, 1.0);
  vec3 pink = vec3(1.0, 0.12, 0.7);
  vec3 tint = mix(cyan, pink, split);
  pixel.rgb = mix(pixel.rgb, pixel.rgb * 0.18 + tint * (0.75 + bars * 0.35), amount);
  return pixel;
}
]])
  if ok and shader then
    ctx.shader = shader
    ctx.fx:shader("glow", shader, { uniforms = { amount = 0 } })
  end
end

local function setupFeedbacks(ctx)
  local feedbacks = require("feel.feedbacks")
  ctx.Feedbacks = feedbacks.new({
    love = ctx.fx,
    emit = function(event)
      if event.kind and event.kind:match("^post%.") then
        pushLog(ctx, "post: " .. event.kind)
      elseif event.kind == "screen.flash" then
        pushLog(ctx, "screen.flash")
      end
    end,
  })
  ctx.Feedbacks.define("impact.stack", {
    { kind = "time.freeze", duration = 0.035 },
    {
      kind = "parallel",
      steps = {
        { kind = "screen.flash", amount = 0.28, duration = 0.12, color = ctx.secondary },
        { kind = "camera.shake", amount = 12, duration = 0.2, frequency = 32 },
        { kind = "post.tween", effect = "bloom", values = { intensity = 1.2 }, duration = 0.1, restart = true },
        { kind = "animate", duration = 0.08, ease = "quadout", to = { scale = 1.2, glow = 1 } },
      },
    },
    { kind = "wait", duration = 0.14 },
    {
      kind = "parallel",
      steps = {
        { kind = "post.tween", effect = "bloom", values = { intensity = 0 }, duration = 0.34, restart = true },
        { kind = "animate", duration = 0.32, ease = "backout", to = { scale = 1, glow = 0 } },
      },
    },
  })
end

local function setupAdapter(scene, ctx, target)
  resetCommon(ctx, target)
  ctx.sound = { level = 0, volume = 0.65, pitch = 1, pan = 0 }
  ctx.haptic = { left = 0, right = 0, remaining = 0 }
  ctx.fx:sound("ui-pop", makeSoundSource(ctx), { volume = 0.65 })
  ctx.fx:haptic("pad", makeHaptic(ctx))
  ctx.fx:particle("sparks", makeParticleSystem(ctx))
  if target.id == "shader" then
    setupShader(ctx)
  elseif target.id == "feedbacks" then
    setupFeedbacks(ctx)
  end

  local function trigger()
    local id = target.id
    if id == "shake" then
      play(ctx, {
        { kind = "emit", event = "camera.shake", payload = { amount = 16, duration = 0.32, frequency = 34 } },
        { kind = "animate", duration = 0.08, ease = "quadout", to = { scale = 1.12, glow = 1 } },
        { kind = "animate", duration = 0.28, ease = "backout", to = { scale = 1, glow = 0 } },
      }, ctx.targetValues, "adapter.shake")
      pushLog(ctx, "camera.shake")
    elseif id == "flash" then
      play(ctx, {
        { kind = "emit", event = "screen.flash", payload = { amount = 0.58, duration = 0.18, color = ctx.primary } },
        { kind = "animate", duration = 0.1, ease = "quadout", to = { glow = 1 } },
        { kind = "animate", duration = 0.3, ease = "quadout", to = { glow = 0 } },
      }, ctx.targetValues, "adapter.flash")
      pushLog(ctx, "screen.flash")
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
      }, nil, "adapter.sound", {
        emit = function(event)
          if event.kind and event.kind:match("^sound%.") then
            pushLog(ctx, event.kind)
          end
        end,
      })
    elseif id == "haptics" then
      play(ctx, {
        { kind = "emit", event = "haptic.play", payload = { name = "pad", left = 0.25, right = 0.9, duration = 0.24, system = false } },
      }, nil, "adapter.haptics")
    elseif id == "particles" then
      play(ctx, {
        { kind = "emit", event = "particle.emit", payload = { name = "sparks", count = 32, x = 480, y = 282 } },
        { kind = "emit", event = "screen.flash", payload = { amount = 0.18, duration = 0.12, color = ctx.secondary } },
      }, nil, "adapter.particles")
    elseif id == "shader" then
      play(ctx, {
        { kind = "emit", event = "shader.tween", payload = { name = "glow", uniform = "amount", value = 1, duration = 0.16, restart = true } },
        { kind = "wait", duration = 0.14 },
        { kind = "emit", event = "shader.tween", payload = { name = "glow", uniform = "amount", value = 0, duration = 0.34, restart = true } },
      }, nil, "adapter.shader")
      pushLog(ctx, "shader.tween")
    elseif id == "post-processing" then
      play(ctx, {
        { kind = "emit", event = "post.set", payload = { effect = "bloom", values = { threshold = 0.4, softness = 0.2, passes = 2 } } },
        { kind = "emit", event = "post.tween", payload = { effect = "bloom", values = { intensity = 1.35 }, duration = 0.12, restart = true } },
        { kind = "emit", event = "post.tween", payload = { effect = "chromatic", values = { force = 1, x = 0.014, y = -0.006 }, duration = 0.1, restart = true } },
        { kind = "wait", duration = 0.2 },
        { kind = "emit", event = "post.tween", payload = { effect = "bloom", values = { intensity = 0.12 }, duration = 0.36, restart = true } },
        { kind = "emit", event = "post.tween", payload = { effect = "chromatic", values = { force = 0, x = 0, y = 0 }, duration = 0.28, restart = true } },
      }, nil, "adapter.post")
      pushLog(ctx, "post.tween")
    elseif id == "feedbacks" then
      ctx.Feedbacks.play("impact.stack", nil, { target = ctx.targetValues, restart = true, key = "feedbacks.stack" })
      pushLog(ctx, "Feedbacks.play")
    elseif id == "love2d" then
      play(ctx, {
        {
          kind = "parallel",
          steps = {
            { kind = "emit", event = "particle.emit", payload = { name = "sparks", count = 18, x = 480, y = 286 } },
            { kind = "emit", event = "screen.flash", payload = { amount = 0.22, duration = 0.14, color = ctx.primary } },
            { kind = "emit", event = "camera.shake", payload = { amount = 7, duration = 0.18 } },
            { kind = "animate", duration = 0.1, ease = "quadout", to = { scale = 1.18, glow = 1 } },
          },
        },
        { kind = "animate", duration = 0.32, ease = "backout", to = { scale = 1, glow = 0 } },
      }, ctx.targetValues, "adapter.love2d")
      pushLog(ctx, "love.update: feel.update")
    end
  end

  ctx.actions = {
    action(0.32, trigger),
    action(1.62, trigger),
  }
end

local function drawWorldActor(ctx, x, y, label)
  local values = ctx.targetValues.values
  Draw.setColor(ctx.primary, 0.16 + values.glow * 0.24)
  love.graphics.circle("fill", x, y, 62 + values.glow * 28)
  Draw.button(x - 78, y - 32, 156, 64, values.scale, values.glow, ctx.primary, label or "ACTOR", ctx.fonts.small)
end

local function drawShaderPlate(ctx, x, y, amount)
  Draw.setColor(Draw.palette.panel2)
  love.graphics.rectangle("fill", x - 148, y - 82, 296, 164, 8, 8)
  Draw.setColor(ctx.primary, 0.2 + amount * 0.18)
  love.graphics.rectangle("fill", x - 118, y - 52, 236, 104, 6, 6)
  Draw.setColor(ctx.secondary, 0.75)
  love.graphics.circle("fill", x - 58, y, 28)
  Draw.setColor(Draw.palette.violet, 0.8)
  love.graphics.circle("fill", x + 54, y, 34)
  Draw.setColor(Draw.palette.text)
  love.graphics.setFont(ctx.fonts.small)
  love.graphics.printf("SHADER", x - 88, y - 9, 176, "center")
end

local function drawAdapterScene(scene, ctx, target)
  Draw.clear(ctx.width, ctx.height)
  Draw.header(ctx, target)
  Draw.panel(84, 146, 628, 334)

  local id = target.id
  if id == "shake" or id == "feedbacks" or id == "love2d" then
    ctx.fx:push()
    drawWorldActor(ctx, 402, 300, id == "feedbacks" and "STACK" or "SHIP")
    Draw.setColor(ctx.secondary, 0.8)
    love.graphics.rectangle("line", 194, 214, 408, 194, 8, 8)
    ctx.fx:pop()
    drawParticles(ctx)
  elseif id == "flash" then
    drawWorldActor(ctx, 402, 300, "HIT")
  elseif id == "sound" then
    Draw.wave(160, 238, 430, 96, ctx.sound.level, ctx.primary)
    Draw.progressBar(174, 374, 176, 18, ctx.sound.volume, ctx.primary, "volume", ctx.fonts.small)
    Draw.progressBar(390, 374, 176, 18, (ctx.sound.pitch - 0.7) / 0.8, ctx.secondary, "pitch", ctx.fonts.small)
    Draw.setColor(Draw.palette.panel2)
    love.graphics.rectangle("fill", 224, 314, 360, 10, 5, 5)
    Draw.spark(404 + ctx.sound.pan * 168, 319, 11, ctx.secondary, 1)
    Draw.centerLabel("pan", 300, 332, 210, Draw.palette.muted, ctx.fonts.small)
  elseif id == "haptics" then
    Draw.progressBar(190, 236, 420, 34, ctx.haptic.left, ctx.primary, "left motor", ctx.fonts.small)
    Draw.progressBar(190, 338, 420, 34, ctx.haptic.right, ctx.secondary, "right motor", ctx.fonts.small)
  elseif id == "particles" then
    drawWorldActor(ctx, 402, 300, "BURST")
    drawParticles(ctx)
  elseif id == "shader" then
    local amount = ctx.fx.shaderEntries.glow and (ctx.fx.shaderEntries.glow.values.amount or 0) or 0
    Draw.setColor(ctx.secondary, 0.1 + amount * 0.28)
    love.graphics.circle("fill", 402, 276, 76 + amount * 42)
    if ctx.shader then
      ctx.fx:pushShader("glow")
    end
    drawShaderPlate(ctx, 402, 276, amount)
    if ctx.shader then
      ctx.fx:popShader()
    end
    Draw.progressBar(222, 390, 360, 16, amount, ctx.secondary, "uniform amount", ctx.fonts.small)
  elseif id == "post-processing" then
    local bloom = ctx.fx.post.effects.bloom.target.values.intensity or 0
    local chromatic = ctx.fx.post.effects.chromatic.target.values.force or 0
    Draw.setColor(Draw.palette.pink, chromatic * 0.36)
    love.graphics.rectangle("fill", 188 - chromatic * 10, 228, 396, 178, 8, 8)
    Draw.setColor(Draw.palette.cyan, chromatic * 0.36)
    love.graphics.rectangle("fill", 188 + chromatic * 10, 228, 396, 178, 8, 8)
    Draw.setColor(ctx.secondary, 0.12 + bloom * 0.24)
    love.graphics.circle("fill", 402, 300, 90 + bloom * 48)
    drawWorldActor(ctx, 402, 300, "POST")
  end

  drawLogs(ctx, 730, 158, 212)
  ctx.fx:drawOverlay()
end

local function makeG3dModel(ctx)
  return {
    translation = { 0, 0, 0 },
    rotation = { 0, 0, 0 },
    scale = { 1, 1, 1 },
    setTranslation = function(self, x, y, z)
      self.translation = { x, y, z }
    end,
    setRotation = function(self, x, y, z)
      self.rotation = { x, y, z }
    end,
    setScale = function(self, x, y, z)
      self.scale = { x, y, z }
    end,
  }
end

local function setupThree(scene, ctx, target)
  resetCommon(ctx, target)
  ctx.three = {
    model = makeG3dModel(ctx),
    camera = {
      fov = 60,
    },
    orbit = 0,
    uniform = feel.target({ values = { glow = 0, tint = 0 } }),
  }

  if target.id == "g3d" then
    ctx.three.camera.lookAt = function(x, y, z, tx, ty, tz)
      ctx.three.camera.eye = { x, y, z }
      ctx.three.camera.center = { tx, ty, tz }
    end
    local feelG3d = require("feel.g3d")
    ctx.g3dfx = feelG3d.new({ camera = ctx.three.camera })
    ctx.g3dTarget = ctx.g3dfx:model("ship", ctx.three.model, {
      values = { x = 0, y = 0, z = 0, scale = 1, rz = 0 },
    })
    ctx.g3dfx:camera({
      mode = "lookAt",
      fov = 60,
      values = { x = 0, y = -7, z = 4, tx = 0, ty = 0, tz = 0 },
    })
  end

  local function trigger()
    if target.id == "g3d" then
      play(ctx, {
        {
          kind = "parallel",
          steps = {
            { kind = "emit", event = "g3d.camera.shake", payload = { amount = 0.12, duration = 0.18, frequency = 34 } },
            { kind = "emit", event = "g3d.camera.fov", payload = { amount = 4, duration = 0.07, returnDuration = 0.22 } },
            { kind = "emit", event = "g3d.model.scalePunch", payload = { name = "ship", amount = 0.24, duration = 0.07, returnDuration = 0.24 } },
            { kind = "emit", event = "g3d.model.rotationShake", payload = { name = "ship", amount = 0.14, duration = 0.18 } },
          },
        },
      }, nil, "three.g3d", ctx.g3dfx:handlers({
        emit = function(event)
          if event.kind and event.kind:match("^g3d%.") then
            pushLog(ctx, event.kind)
          end
        end,
      }))
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
      }, ctx.targetValues, "three.menori")
      pushLog(ctx, "menori.node.scalePunch")
      pushLog(ctx, "menori.uniform.pulse")
      pushLog(ctx, "menori.animation.speed")
    end
  end

  ctx.actions = {
    action(0.32, trigger),
    action(1.62, trigger),
  }
end

local function drawThreeScene(scene, ctx, target)
  Draw.clear(ctx.width, ctx.height)
  Draw.header(ctx, target)
  Draw.panel(86, 146, 626, 334)
  drawLogs(ctx, 730, 158, 212)

  local scale = ctx.targetValues.values.scale
  local rot = ctx.targetValues.values.orbit or 0
  local glow = ctx.targetValues.values.glow
  if target.id == "g3d" then
    local model = ctx.three.model
    scale = model.scale[1] or 1
    rot = model.rotation[3] or 0
    glow = math.max(0, (scale - 1) * 3)
  end

  Draw.setColor(ctx.primary, 0.12 + glow * 0.22)
  love.graphics.circle("fill", 402, 292, 128 + glow * 40)
  Draw.isoBox(402, 292, 160, 116, 38, ctx.primary, scale, rot)
  Draw.isoBox(264, 340, 84, 72, 22, ctx.secondary, 0.86, -0.08)
  Draw.isoBox(548, 346, 92, 76, 22, Draw.palette.green, 0.82, 0.07)

  Draw.setColor(Draw.palette.line)
  love.graphics.line(402, 292, 402 + math.sin(ctx.time * 1.8) * 108, 192)
  Draw.centerLabel(target.id == "g3d" and "model + camera targets" or "node + uniform + animation", 184, 420, 432, Draw.palette.muted, ctx.fonts.body)
end

function Scenes.create(target, ctx)
  local scene = {}
  if target.scene == "easing" then
    setupEasing(scene, ctx, target)
    scene.draw = drawEasingScene
  elseif target.scene == "flow" then
    setupFlow(scene, ctx, target)
    scene.draw = drawFlowScene
  elseif target.scene == "adapter" then
    setupAdapter(scene, ctx, target)
    scene.draw = drawAdapterScene
  elseif target.scene == "three" then
    setupThree(scene, ctx, target)
    scene.draw = drawThreeScene
  else
    setupButton(scene, ctx, target)
    scene.draw = drawButtonScene
  end

  scene.update = function(_, updateCtx, _, dt)
    updateCommon(updateCtx, dt)
  end

  return scene
end

return Scenes
