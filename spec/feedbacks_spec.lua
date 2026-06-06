package.path = "./?.lua;./?/init.lua;" .. package.path

local feel = require("feel")
local feelFeedbacks = require("feel.feedbacks")

describe("feel.feedbacks", function()
  before_each(function()
    feel.clear()
    math.randomseed(1234)
  end)

  after_each(function()
    feel.clear()
  end)

  it("defines manifests and plays compiled sequences through feel.play", function()
    local events = {}
    local target = feel.target({ values = { scale = 1 } })
    local Feedbacks = feelFeedbacks.new({
      emit = function(event)
        events[#events + 1] = event
      end,
    })

    Feedbacks.define("button.hit", {
      { kind = "screen.flash", amount = 0.2, duration = 0.05 },
      { kind = "animate", to = { scale = 1.25 }, duration = 0.1 },
    })

    Feedbacks.play("button.hit", nil, { target = target, restart = true, key = "button.hit" })
    feel.update(0.1)

    assert.are.equal(1.25, target.values.scale)
    assert.are.equal("screen.flash", events[1].kind)
    assert.are.equal(0.2, events[1].payload.amount)
  end)

  it("resolves context paths functions and scalar ranges without randomizing color arrays", function()
    local seen
    local Feedbacks = feelFeedbacks.new({
      emit = function(event)
        seen = event
      end,
    })

    Feedbacks.define("spark", {
      {
        kind = "particle.emit",
        name = "$name",
        x = "$position.x",
        y = function(ctx)
          return ctx.position.y + 2
        end,
        speed = { 10, 20 },
        color = { 1, 0.5, 0.25, 1 },
      },
    })

    Feedbacks.play("spark", {
      name = "hit",
      position = { x = 3, y = 4 },
    })

    assert.are.equal("particle.emit", seen.kind)
    assert.are.equal("hit", seen.payload.name)
    assert.are.equal(3, seen.payload.x)
    assert.are.equal(6, seen.payload.y)
    assert.is_true(seen.payload.speed >= 10 and seen.payload.speed <= 20)
    assert.are.same({ 1, 0.5, 0.25, 1 }, seen.payload.color)
  end)

  it("routes adapter shorthand events to love g3d and user emit handlers", function()
    local calls = {}
    local loveAdapter = {
      emit = function(_, event)
        calls[#calls + 1] = "love:" .. event.kind
      end,
    }
    local g3dAdapter = {
      emit = function(_, event)
        calls[#calls + 1] = "g3d:" .. event.kind
      end,
    }
    local Feedbacks = feelFeedbacks.new({
      love = loveAdapter,
      g3d = g3dAdapter,
      emit = function(event)
        calls[#calls + 1] = "user:" .. event.kind
      end,
    })

    Feedbacks.play({
      { kind = "screen.flash", amount = 0.3 },
      { kind = "post.tween", effect = "bloom", values = { intensity = 1 }, duration = 0.1 },
      { kind = "sound.play", cue = "hit", pitch = { 0.9, 1.1 } },
      { kind = "custom.feedback", value = 2 },
    })

    assert.are.same({
      "love:screen.flash",
      "g3d:screen.flash",
      "user:screen.flash",
      "love:post.tween",
      "g3d:post.tween",
      "user:post.tween",
      "love:sound.play",
      "g3d:sound.play",
      "user:sound.play",
      "love:custom.feedback",
      "g3d:custom.feedback",
      "user:custom.feedback",
    }, calls)
  end)

  it("routes core audio steps to love and user audio handlers", function()
    local calls = {}
    local loveAdapter = {
      audio = function(_, event)
        calls[#calls + 1] = "love:" .. event.cue
      end,
    }
    local Feedbacks = feelFeedbacks.new({
      love = loveAdapter,
      audio = function(event)
        calls[#calls + 1] = "user:" .. event.cue
      end,
    })

    Feedbacks.play({
      { kind = "audio", cue = "hit" },
    }, nil, {
      audio = function(event)
        calls[#calls + 1] = "opts:" .. event.cue
      end,
    })

    assert.are.same({ "love:hit", "user:hit", "opts:hit" }, calls)
  end)

  it("updates explicit time scale feedback", function()
    local Feedbacks = feelFeedbacks.new()

    Feedbacks.play({
      { kind = "time.freeze", duration = 0.05 },
    })
    assert.are.equal(0, Feedbacks.timeScale())
    feel.update(0.05)
    assert.are.equal(1, Feedbacks.timeScale())

    Feedbacks.timeTarget().values.scale = 0.35
    Feedbacks.play({
      { kind = "time.freeze", duration = 0.05 },
    })
    assert.are.equal(0, Feedbacks.timeScale())
    feel.update(0.05)
    assert.are.equal(0.35, Feedbacks.timeScale())

    Feedbacks.play({
      { kind = "time.restore", duration = 0 },
    })
    assert.are.equal(1, Feedbacks.timeScale())

    Feedbacks.play({
      { kind = "time.slow", scale = 0.4, duration = 0.05 },
    })
    assert.are.equal(0.4, Feedbacks.timeScale())
    feel.update(0.05)
    assert.are.equal(1, Feedbacks.timeScale())

    Feedbacks.timeTarget().values.scale = 0.2
    Feedbacks.play({
      { kind = "time.restore", duration = 0 },
    })
    assert.are.equal(1, Feedbacks.timeScale())
  end)
end)
