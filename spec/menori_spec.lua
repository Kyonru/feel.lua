package.path = "./?.lua;./?/init.lua;" .. package.path

local feel = require("feel")
local feelFeedbacks = require("feel.feedbacks")
local feelMenori = require("feel.menori")

describe("feel.menori", function()
  local calls

  local function vec3(x, y, z)
    return {
      x = x or 0,
      y = y or 0,
      z = z or 0,
      set = function(self, nx, ny, nz)
        self.x = nx or 0
        self.y = ny or 0
        self.z = nz or 0
        return self
      end,
    }
  end

  local function vec4(x, y, z, w)
    return {
      x = x or 0,
      y = y or 0,
      z = z or 0,
      w = w or 0,
    }
  end

  local function menori()
    return {
      ml = {
        vec3 = vec3,
        vec4 = vec4,
        quat = {
          from_euler_angles = function(yaw, pitch, roll)
            return { kind = "euler", yaw = yaw, pitch = pitch, roll = roll }
          end,
          from_direction = function(forward, up)
            return { kind = "direction", forward = forward, up = up }
          end,
        },
      },
    }
  end

  local function node(name)
    return {
      name = name,
      position = vec3(0, 0, 0),
      set_position = function(self, x, y, z)
        self.position:set(x, y, z)
        calls[#calls + 1] = { "set_position", name, x, y, z }
      end,
      set_rotation = function(self, q)
        self.rotation = q
        calls[#calls + 1] = { "set_rotation", name, q }
      end,
      set_scale = function(self, x, y, z)
        self.scale = { x = x, y = y, z = z }
        calls[#calls + 1] = { "set_scale", name, x, y, z }
      end,
    }
  end

  local function projection()
    return {
      perspective_RH_NO = function(self, fov, aspect, near, far)
        self.last = { fov, aspect, near, far }
        calls[#calls + 1] = { "projection", fov, aspect, near, far }
        return self
      end,
      clone = function(self)
        return {
          source = self,
          inverse = function(clone)
            clone.inversed = true
            calls[#calls + 1] = { "projection_inverse" }
            return clone
          end,
        }
      end,
    }
  end

  local function camera()
    return {
      eye = vec3(0, 0, 0),
      center = vec3(0, 0, 1),
      up = vec3(0, 1, 0),
      m_projection = projection(),
      update_view_matrix = function(self)
        self.updated = (self.updated or 0) + 1
        calls[#calls + 1] = { "update_view_matrix", self.eye.x, self.eye.y, self.eye.z, self.center.x, self.center.y, self.center.z }
      end,
    }
  end

  local function environment(cam)
    return {
      camera = cam,
      vectors = {},
      set_vector = function(self, name, value)
        self.vectors[name] = value
        calls[#calls + 1] = { "set_vector", name, value.x, value.y, value.z }
      end,
    }
  end

  before_each(function()
    feel.clear()
    calls = {}
  end)

  after_each(function()
    feel.clear()
  end)

  it("applies node target position rotation and scale through Menori node methods", function()
    local fx = feelMenori.new(menori())
    local shipNode = node("ship")
    local target = fx:node("ship", shipNode, {
      values = { x = 1, y = 2, z = 3, rx = 0.1, ry = 0.2, rz = 0.3, scale = 2 },
    })

    calls = {}
    target.values.offsetX = 0.5
    target.values.shakeZ = -0.25
    target.values.rotationOffsetY = 0.4
    target.values.fxScaleZ = 1.5
    fx:update()

    assert.are.same({ "set_position", "ship", 1.5, 2, 2.75 }, calls[1])
    assert.are.equal("euler", calls[2][3].kind)
    assert.is_true(math.abs(calls[2][3].yaw - 0.3) < 0.000001)
    assert.is_true(math.abs(calls[2][3].pitch - 0.6) < 0.000001)
    assert.is_true(math.abs(calls[2][3].roll - 0.1) < 0.000001)
    assert.are.same({ "set_scale", "ship", 2, 2, 3 }, calls[3])
  end)

  it("handles node lookAt visibility and feedback events", function()
    local fx = feelMenori.new(menori())
    local shipNode = node("ship")
    local target = fx:node("ship", shipNode, {
      values = { x = 0, y = 0, z = 0 },
    })

    calls = {}
    fx:emit({ kind = "menori.node.lookAt", payload = { name = "ship", x = 0, y = 1, z = 0 } })
    assert.are.equal("direction", shipNode.rotation.kind)
    assert.are.equal(1, shipNode.rotation.forward.y)

    fx:emit({ kind = "menori.node.visible", payload = { name = "ship", visible = false } })
    assert.is_false(shipNode.render_flag)

    fx:emit({
      kind = "menori.node.scalePunch",
      payload = { name = "ship", amount = 0.5, duration = 0.01, returnDuration = 0.1 },
    })
    feel.update(0.01)
    fx:update()

    assert.are.equal(1.5, target.values.fxScale)
    assert.are.same({ "set_scale", "ship", 1.5, 1.5, 1.5 }, calls[#calls])
  end)

  it("applies lookAt cameras projection updates and environment view position uniforms", function()
    local cam = camera()
    local env = environment(cam)
    local fx = feelMenori.new(menori(), { environment = env })
    local target = fx:camera({
      mode = "lookAt",
      fov = 70,
      aspect = 2,
      near = 0.5,
      far = 900,
      values = { x = 1, y = 2, z = 3, tx = 4, ty = 5, tz = 6 },
    })

    assert.are.same({ 70, 2, 0.5, 900 }, cam.m_projection.last)
    assert.is_true(cam.m_inv_projection.inversed)
    assert.are.equal(1, cam.eye.x)
    assert.are.equal(2, cam.eye.y)
    assert.are.equal(3, cam.eye.z)
    assert.are.equal(cam.eye, env.vectors.view_position)

    calls = {}
    target.values.shakeX = 0.25
    target.values.heightKick = 0.5
    target.values.targetOffsetZ = -1
    fx:update()

    assert.are.same({ "update_view_matrix", 1.25, 2.5, 3, 4, 5, 5 }, calls[1])
    assert.are.same({ "set_vector", "view_position", 1.25, 2.5, 3 }, calls[2])
  end)

  it("supports orbit camera targets and camera feedback pulses", function()
    local cam = camera()
    local fx = feelMenori.new(menori(), { camera = cam })
    local target = fx:camera({
      mode = "orbit",
      values = { tx = 1, ty = 2, tz = 3, distance = 2, yaw = math.pi / 2, pitch = 0 },
    })

    assert.is_true(math.abs(cam.eye.x - 3) < 0.000001)
    assert.are.equal(2, cam.eye.y)
    assert.is_true(math.abs(cam.eye.z - 3) < 0.000001)

    fx:emit({ kind = "menori.camera.distance", payload = { amount = 1, duration = 0 } })
    fx:update()

    assert.are.equal(1, target.values.distanceKick)
    assert.is_true(math.abs(cam.eye.x - 4) < 0.000001)
  end)

  it("updates glTF animation controllers with actions speed and seeking", function()
    local animations = {
      accumulator = 0,
      set_action = function(self, index)
        self.actionIndex = index
        calls[#calls + 1] = { "set_action", index }
      end,
      set_action_by_name = function(self, name)
        self.actionName = name
        calls[#calls + 1] = { "set_action_by_name", name }
      end,
      update = function(self, dt)
        self.accumulator = self.accumulator + dt
        calls[#calls + 1] = { "update_animation", dt }
      end,
    }

    local fx = feelMenori.new(menori())
    local target = fx:animation("hero", animations, { actionIndex = 2 })
    fx:update(0.5)
    target.values.speed = 2
    fx:update(0.25)

    fx:emit({ kind = "menori.animation.action", payload = { name = "hero", action = "run" } })
    fx:emit({ kind = "menori.animation.seek", payload = { name = "hero", time = 1.25 } })
    fx:emit({ kind = "menori.animation.pause", payload = { name = "hero" } })
    fx:update(1)

    assert.are.same({ "set_action", 2 }, calls[1])
    assert.are.same({ "update_animation", 0.5 }, calls[2])
    assert.are.same({ "update_animation", 0.5 }, calls[3])
    assert.are.same({ "set_action_by_name", "run" }, calls[4])
    assert.are.same({ "update_animation", 0 }, calls[5])
    assert.are.equal(0, target.values.playing)
    assert.are.equal(1.25, animations.accumulator)
  end)

  it("can drive animation time directly from a target value", function()
    local animations = {
      accumulator = 0,
      update = function(self, dt)
        calls[#calls + 1] = { "update_animation", self.accumulator, dt }
      end,
    }

    local fx = feelMenori.new(menori())
    local target = fx:animation("cutscene", animations, {
      driveTime = true,
      values = { time = 1.5 },
    })

    calls = {}
    target.values.time = 2.25
    fx:update(0.5)

    assert.are.equal(2.25, animations.accumulator)
    assert.are.same({ "update_animation", 2.25, 0 }, calls[1])
  end)

  it("binds and animates UniformList values", function()
    local uniform = {
      set = function(_, name, value)
        calls[#calls + 1] = { "set", name, value }
      end,
      set_color = function(_, name, r, g, b, a)
        calls[#calls + 1] = { "set_color", name, r, g, b, a }
      end,
      set_vector = function(_, name, value)
        calls[#calls + 1] = { "set_vector", name, value.x, value.y, value.z, value.w }
      end,
    }

    local fx = feelMenori.new(menori())
    local color = fx:uniform("ship.color", uniform, "baseColor", {
      type = "color",
      values = { r = 0.8, g = 0.9, b = 1, a = 1 },
    })
    fx:uniform("wind", uniform, "windDirection", {
      type = "vector",
      values = { x = 1, y = 0, z = 0 },
    })
    fx:uniform("material.color", uniform, "baseColor", {
      keys = { "r", "g", "b", "a" },
      values = { r = 0.2, g = 0.4, b = 0.8, a = 1 },
    })

    assert.are.same({ "set_color", "baseColor", 0.8, 0.9, 1, 1 }, calls[1])
    assert.are.same({ "set_vector", "windDirection", 1, 0, 0, nil }, calls[2])
    assert.are.equal("set", calls[3][1])
    assert.are.equal("baseColor", calls[3][2])
    assert.are.same({ 0.2, 0.4, 0.8, 1 }, calls[3][3])

    fx:emit({
      kind = "menori.uniform.pulse",
      payload = { name = "ship.color", values = { r = 1, g = 0.2, b = 0.1 }, duration = 0 },
    })
    fx:update()

    assert.are.equal(1, color.values.r)
    assert.are.same({ "set_color", "baseColor", 1, 0.2, 0.1, 1 }, calls[#calls - 2])
  end)

  it("clears named and all bindings", function()
    local fx = feelMenori.new(menori(), { camera = camera() })

    fx:node("ship", node("ship"))
    fx:animation("hero", { update = function() end })
    fx:uniform("color", { set = function() end }, "baseColor")
    fx:camera()

    assert.is_not_nil(fx:get("ship"))
    assert.is_true(fx:clear("ship"))
    assert.is_nil(fx:get("ship"))
    assert.is_false(fx:clear("missing"))
    assert.is_true(fx:clear())
    assert.is_nil(fx:get("hero"))
    assert.is_nil(fx:get("color"))
    assert.is_nil(fx.cameraEntry)
  end)

  it("routes feedback manifests through the Menori adapter", function()
    local routed = {}
    local Feedbacks = feelFeedbacks.new({
      menori = {
        emit = function(_, event)
          routed[#routed + 1] = event.kind
        end,
      },
      emit = function(event)
        routed[#routed + 1] = "user:" .. event.kind
      end,
    })

    Feedbacks.play({
      { kind = "menori.camera.shake", amount = 0.2 },
    })

    assert.are.same({ "menori.camera.shake", "user:menori.camera.shake" }, routed)
  end)
end)
