package.path = "./?.lua;./?/init.lua;" .. package.path

local feel = require("feel")
local Sprite = require("feel.sprite")
local Anim8 = require("feel.sprite.anim8")

describe("feel.sprite", function()
  before_each(function()
    feel.clear()
  end)

  after_each(function()
    feel.clear()
  end)

  it("creates targets with renderer-independent effect values", function()
    local target = Sprite.target({ values = { glow = 0.25 } })
    assert.are.equal(0, target.values.offsetX)
    assert.are.equal(1, target.values.scaleX)
    assert.are.equal(1, target.values.opacity)
    assert.are.equal(0.25, target.values.glow)
  end)

  it("composes additive offsets and multiplicative transforms", function()
    local target = Sprite.target({
      values = {
        offsetX = 4,
        offsetY = -2,
        rotation = 0.1,
        scaleX = 1.2,
        scaleY = 0.8,
        opacity = 0.5,
      },
    })

    local pose = Sprite.pose(target, {
      x = 10,
      y = 20,
      rotation = 0.2,
      scaleX = -2,
      scaleY = 3,
      opacity = 0.8,
    })

    assert.are.equal(14, pose.x)
    assert.are.equal(18, pose.y)
    assert.are.near(0.3, pose.rotation, 0.000001)
    assert.are.equal(-2.4, pose.scaleX)
    assert.are.near(2.4, pose.scaleY, 0.000001)
    assert.are.equal(0.4, pose.opacity)
  end)

  it("passes a composed pose to arbitrary draw callbacks", function()
    local target = Sprite.target({ values = { offsetX = 3 } })
    local seen
    local result = Sprite.draw(target, { x = 7 }, function(pose, receivedTarget)
      seen = { pose.x, receivedTarget }
      return "drawn"
    end)

    assert.are.same({ 10, target }, seen)
    assert.are.equal("drawn", result)
  end)

  it("plays reusable sprite effects through the feel clock", function()
    local target = Sprite.target()
    local run = Sprite.play(target, "hitLight", { x = -6, duration = 0.1 })

    assert.is_truthy(run)
    assert.are.equal(-6, target.values.offsetX)
    assert.is_true(target.values.flash > 0)
    feel.update(0.1)
    assert.are.equal(0, target.values.offsetX)
    assert.are.equal(0, target.values.flash)
  end)

  it("exposes built-in effects and rejects unknown names", function()
    local names = Sprite.list()
    assert.are.equal("blink", names[1])
    for _, name in ipairs(names) do
      local valid, err = feel.validate(Sprite.sequence(name))
      assert.is_true(valid, err)
    end
    assert.is_false(Sprite.play(Sprite.target(), "missing"))
  end)

  it("resets active effects to the neutral pose", function()
    local target = Sprite.target()
    Sprite.play(target, "despawn")
    Sprite.reset(target)

    assert.are.equal(1, target.values.scaleX)
    assert.are.equal(1, target.values.opacity)
    assert.is_false(feel.isPlaying(target))
  end)

  it("draws anim8-compatible animations without requiring anim8", function()
    local previousLove = _G.love
    local calls = {}
    _G.love = {
      graphics = {
        push = function(mode)
          calls[#calls + 1] = { "push", mode }
        end,
        setColor = function(...)
          calls[#calls + 1] = { "color", ... }
        end,
        pop = function()
          calls[#calls + 1] = { "pop" }
        end,
      },
    }
    local animation = {
      draw = function(_, ...)
        calls[#calls + 1] = { "draw", ... }
      end,
    }
    local target = Sprite.target({ values = { offsetX = 2, scaleX = 1.5, opacity = 0.5 } })

    local ok = Anim8.draw(animation, "image", target, { x = 10, y = 20, scaleX = -1, originX = 8, originY = 9 })
    _G.love = previousLove

    assert.is_true(ok)
    assert.are.same({ "push", "all" }, calls[1])
    assert.are.same({ "color", 1, 1, 1, 0.5 }, calls[2])
    assert.are.same({ "draw", "image", 12, 20, 0, -1.5, 1, 8, 9, 0, 0 }, calls[3])
    assert.are.same({ "pop" }, calls[4])
  end)
end)
