package.path = "./?.lua;./?/init.lua;" .. package.path

local feel = require("feel")
local feelG3d = require("feel.g3d")

describe("feel.g3d", function()
  local calls

  local function model(name)
    return {
      setTranslation = function(_, x, y, z)
        calls[#calls + 1] = { "setTranslation", name, x, y, z }
      end,
      setRotation = function(_, x, y, z)
        calls[#calls + 1] = { "setRotation", name, x, y, z }
      end,
      setScale = function(_, x, y, z)
        calls[#calls + 1] = { "setScale", name, x, y, z }
      end,
      lookAt = function(_, target, up)
        calls[#calls + 1] = { "lookAtModel", name, target, up }
      end,
    }
  end

  local function g3d()
    return {
      camera = {
        lookAt = function(x, y, z, tx, ty, tz)
          calls[#calls + 1] = { "lookAtCamera", x, y, z, tx, ty, tz }
        end,
        lookInDirection = function(x, y, z, direction, pitch)
          calls[#calls + 1] = { "lookInDirection", x, y, z, direction, pitch }
        end,
        resize = function(width, height)
          calls[#calls + 1] = { "resize", width, height }
        end,
      },
    }
  end

  local function g3dWithProjection()
    return {
      camera = {
        fov = math.pi / 2,
        lookAt = function(x, y, z, tx, ty, tz)
          calls[#calls + 1] = { "lookAtCamera", x, y, z, tx, ty, tz }
        end,
        lookInDirection = function(x, y, z, direction, pitch)
          calls[#calls + 1] = { "lookInDirection", x, y, z, direction, pitch }
        end,
        updateProjectionMatrix = function()
          calls[#calls + 1] = { "updateProjectionMatrix" }
        end,
      },
    }
  end

  before_each(function()
    feel.clear()
    calls = {}
  end)

  after_each(function()
    feel.clear()
  end)

  it("applies model target translation rotation and scale", function()
    local fx = feelG3d.new(g3d())
    local target = fx:model("ship", model("ship"), {
      values = { x = 1, y = 2, z = 3, rx = 0.1, ry = 0.2, rz = 0.3, sx = 2, sy = 3, sz = 4 },
    })

    calls = {}
    target.values.x = 5
    target.values.ry = 0.8
    target.values.sz = 9
    fx:update()

    assert.are.same({ "setTranslation", "ship", 5, 2, 3 }, calls[1])
    assert.are.same({ "setRotation", "ship", 0.1, 0.8, 0.3 }, calls[2])
    assert.are.same({ "setScale", "ship", 2, 3, 9 }, calls[3])
  end)

  it("expands scale to uniform model scale", function()
    local fx = feelG3d.new(g3d())
    local target = fx:model("pickup", model("pickup"))

    calls = {}
    target.values.scale = 1.6
    fx:update()

    assert.are.same({ "setScale", "pickup", 1.6, 1.6, 1.6 }, calls[3])
  end)

  it("applies lookAt camera targets", function()
    local fx = feelG3d.new(g3d())
    local target = fx:camera({
      mode = "lookAt",
      values = { x = 1, y = -8, z = 4, tx = 2, ty = 3, tz = 4 },
    })

    calls = {}
    target.values.z = 6
    fx:update()

    assert.are.same({ "lookAtCamera", 1, -8, 6, 2, 3, 4 }, calls[1])
  end)

  it("applies direction camera targets", function()
    local fx = feelG3d.new(g3d())
    local target = fx:camera({
      mode = "direction",
      values = { x = 1, y = 2, z = 3, direction = 0.4, pitch = -0.2 },
    })

    calls = {}
    target.values.direction = 0.9
    fx:update()

    assert.are.same({ "lookInDirection", 1, 2, 3, 0.9, -0.2 }, calls[1])
  end)

  it("applies additive camera feedback values and fov kick", function()
    local world = g3dWithProjection()
    local fx = feelG3d.new(world)
    local target = fx:camera({
      mode = "lookAt",
      values = { x = 1, y = -8, z = 4, tx = 2, ty = 3, tz = 4 },
    })

    target.values.shakeX = 0.25
    target.values.shakeY = -0.5
    target.values.shakeZ = 0.75
    target.values.heightKick = 0.4
    target.values.targetOffsetX = 0.1
    target.values.fovKick = 0.2
    calls = {}
    fx:update()

    assert.are.equal(math.pi / 2 + 0.2, world.camera.fov)
    assert.are.same({ "updateProjectionMatrix" }, calls[1])
    assert.are.same({ "lookAtCamera", 1.25, -8.5, 5.15, 2.1, 3, 4 }, calls[2])
  end)

  it("handles g3d emit events and delegates unknown events", function()
    local fx = feelG3d.new(g3d())
    local seen = {}
    local up = { 0, 0, 1 }

    fx:model("ship", model("ship"))
    calls = {}
    local handlers = fx:handlers({
      emit = function(event)
        seen[#seen + 1] = event.kind
      end,
    })

    handlers.emit({ kind = "g3d.model.lookAt", payload = { name = "ship", x = 1, y = 2, z = 3, up = up } })
    handlers.emit({ kind = "g3d.camera.lookAt", payload = { x = 1, y = 2, z = 3, tx = 4, ty = 5, tz = 6 } })
    handlers.emit({ kind = "g3d.camera.direction", payload = { x = 7, y = 8, z = 9, direction = 0.5, pitch = 0.25 } })
    handlers.emit({ kind = "g3d.camera.resize", payload = { width = 800, height = 450 } })
    handlers.emit({ kind = "g3d.unknown", payload = {} })

    assert.are.same({ "lookAtModel", "ship", { 1, 2, 3 }, up }, calls[1])
    assert.are.same({ "lookAtCamera", 1, 2, 3, 4, 5, 6 }, calls[2])
    assert.are.same({ "lookInDirection", 7, 8, 9, 0.5, 0.25 }, calls[3])
    assert.are.same({ "resize", 800, 450 }, calls[4])
    assert.are.same({
      "g3d.model.lookAt",
      "g3d.camera.lookAt",
      "g3d.camera.direction",
      "g3d.camera.resize",
      "g3d.unknown",
    }, seen)
  end)

  it("handles camera feedback events through the camera target", function()
    local world = g3dWithProjection()
    local fx = feelG3d.new(world)
    local target = fx:camera({
      values = { x = 0, y = -6, z = 3, tx = 0, ty = 0, tz = 0 },
    })

    fx:emit({ kind = "g3d.camera.fov", payload = { amount = 5, duration = 0.01, returnDuration = 0.1 } })
    feel.update(0.01)
    fx:update()

    assert.is_true(math.abs(target.values.fovKick - math.rad(5)) < 0.000001)
    assert.is_true(math.abs(world.camera.fov - (math.pi / 2 + math.rad(5))) < 0.000001)

    fx:emit({ kind = "g3d.camera.reset", payload = { duration = 0 } })
    assert.are.equal(0, target.values.fovKick)
    assert.are.equal(0, target.values.heightKick)
  end)

  it("handles model feedback events through additive target values", function()
    local fx = feelG3d.new(g3d())
    local target = fx:model("ship", model("ship"))

    calls = {}
    fx:emit({
      kind = "g3d.model.scalePunch",
      payload = { name = "ship", amount = 0.5, duration = 0.01, returnDuration = 0.1 },
    })
    feel.update(0.01)
    fx:update()
    assert.are.equal(1.5, target.values.fxScale)
    assert.are.same({ "setScale", "ship", 1.5, 1.5, 1.5 }, calls[3])

    target.values.shakeX = 0.2
    target.values.rotationOffsetZ = 0.3
    fx:emit({ kind = "g3d.model.reset", payload = { name = "ship", duration = 0 } })
    assert.are.equal(1, target.values.fxScale)
    assert.are.equal(0, target.values.shakeX)
    assert.are.equal(0, target.values.rotationOffsetZ)
  end)

  it("clears named and all bindings", function()
    local fx = feelG3d.new(g3d())

    fx:model("ship", model("ship"))
    fx:model("rock", model("rock"))
    fx:camera()

    assert.is_not_nil(fx:get("ship"))
    assert.is_true(fx:clear("ship"))
    assert.is_nil(fx:get("ship"))
    assert.is_false(fx:clear("missing"))
    assert.is_true(fx:clear())
    assert.is_nil(fx:get("rock"))
    assert.is_nil(fx.cameraEntry)
  end)
end)
