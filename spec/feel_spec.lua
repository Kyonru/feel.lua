package.path = "./?.lua;./?/init.lua;" .. package.path

local feel = require("feel")

describe("feel.lua", function()
  before_each(function()
    feel.clear()
  end)

  it("defines, gets, plays, and clears named sequences", function()
    local events = {}

    local sequence = feel.define("test.ping", {
      { kind = "emit", event = "ping" },
    })

    assert.are.equal(sequence, feel.get("test.ping"))
    feel.play("test.ping", nil, {
      emit = function(event)
        events[#events + 1] = event.kind
      end,
    })

    assert.are.same({ "ping" }, events)
    feel.clear()
    assert.is_nil(feel.get("test.ping"))
    assert.is_nil(feel.play("test.ping"))
  end)

  it("validates named and inline sequences", function()
    feel.define("valid.pulse", {
      { kind = "animate", to = { scale = 1.2 }, duration = 0.1 },
      { kind = "audio", cue = "pulse" },
    })

    local ok, err = feel.validate("valid.pulse")

    assert.is_true(ok)
    assert.is_nil(err)
    assert.is_true(feel.validate({
      { kind = "emit", event = "spark" },
      { kind = "parallel", steps = {
        { { kind = "wait", duration = 0.01 } },
        { { kind = "audio", cue = "spark" } },
      } },
    }))
  end)

  it("reports useful validation errors for bad sequences", function()
    local cases = {
      {
        sequence = { kind = "wobble" },
        message = "unknown kind",
      },
      {
        sequence = { kind = "animate", to = { scale = "big" } },
        message = "to.scale: must be a number",
      },
      {
        sequence = { kind = "parallel", steps = { left = { kind = "wait" } } },
        message = "parallel step requires a non-empty array",
      },
      {
        sequence = { kind = "random", options = {} },
        message = "random step requires a non-empty options array",
      },
      {
        sequence = { kind = "audio" },
        message = "audio step requires cue",
      },
      {
        sequence = "missing.sequence",
        message = "unknown sequence 'missing.sequence'",
      },
    }

    for _, case in ipairs(cases) do
      local ok, err = feel.validate(case.sequence)

      assert.is_false(ok)
      assert.is_truthy(string.find(err, case.message, 1, true))
    end
  end)

  it("plays inline animation sequences through flux", function()
    local target = feel.target({ label = "Launch" })
    local dirty = 0

    feel.play({
      { kind = "animate", to = { x = 10, scale = 1.2 }, duration = 0.1 },
    }, target, {
      markDirty = function()
        dirty = dirty + 1
      end,
    })

    feel.update(0.1)

    assert.are.equal(10, target.values.x)
    assert.are.equal(1.2, target.values.scale)
    assert.is_true(dirty > 0)
  end)

  it("supports bounce easing through flux", function()
    local target = feel.target()

    assert.is_not_nil(feel.flux.easing.bouncein)
    assert.is_not_nil(feel.flux.easing.bounceout)
    assert.is_not_nil(feel.flux.easing.bounceinout)

    feel.play({
      { kind = "animate", to = { y = 10 }, duration = 0.1, ease = "bounceout" },
    }, target)
    feel.update(0.1)

    assert.are.equal(10, target.values.y)
  end)

  it("passes emit, audio, and callback context", function()
    local target = feel.target({ label = "Launch" })
    local calls = {}

    feel.play({
      { kind = "emit", event = "spark", payload = { count = 3 } },
      { kind = "audio", cue = "ui-pop" },
      {
        kind = "callback",
        callback = function(ctx)
          calls[#calls + 1] = "callback:" .. ctx.trigger .. ":" .. ctx.target.label
        end,
      },
    }, target, {
      trigger = "activate",
      emit = function(event)
        calls[#calls + 1] = "emit:" .. event.kind .. ":" .. event.payload.count
      end,
      audio = function(event)
        calls[#calls + 1] = "audio:" .. event.kind .. ":" .. event.cue
      end,
    })

    assert.are.same({
      "emit:spark:3",
      "audio:feedback:ui-pop",
      "callback:activate:Launch",
    }, calls)
  end)

  it("runs sequenced steps after animation completion", function()
    local target = feel.target()
    local events = {}

    feel.play({
      { kind = "animate", to = { y = 4 }, duration = 0.1 },
      { kind = "emit", event = "done" },
    }, target, {
      emit = function(event)
        events[#events + 1] = event.kind
      end,
    })

    assert.are.same({}, events)
    feel.update(0.1)
    assert.are.same({ "done" }, events)
  end)

  it("clear stops active tweens and target state changes", function()
    local target = feel.target()

    feel.play({
      { kind = "animate", to = { x = 10 }, duration = 1 },
    }, target)

    feel.clear()
    feel.update(1)

    assert.are.equal(0, target.values.x)
  end)

  it("wait delays the next step until updated past its duration", function()
    local events = {}

    feel.play({
      { kind = "emit", event = "before" },
      { kind = "wait", duration = 0.2 },
      { kind = "emit", event = "after" },
    }, nil, {
      emit = function(event)
        events[#events + 1] = event.kind
      end,
    })

    assert.are.same({ "before" }, events)
    feel.update(0.1)
    assert.are.same({ "before" }, events)
    feel.update(0.1)
    assert.are.same({ "before", "after" }, events)
  end)

  it("parallel waits for all child branches before continuing", function()
    local events = {}
    local target = feel.target()

    feel.play({
      {
        kind = "parallel",
        steps = {
          { kind = "wait", duration = 0.2 },
          {
            { kind = "animate", to = { x = 4 }, duration = 0.1 },
            { kind = "emit", event = "animated" },
          },
        },
      },
      { kind = "emit", event = "done" },
    }, target, {
      emit = function(event)
        events[#events + 1] = event.kind
      end,
    })

    feel.update(0.1)
    assert.are.same({ "animated" }, events)
    feel.update(0.1)
    assert.are.same({ "animated", "done" }, events)
  end)

  it("repeat runs a child sequence the requested number of times", function()
    local events = {}

    feel.play({
      {
        kind = "repeat",
        count = 3,
        step = { kind = "emit", event = "tick" },
      },
      { kind = "emit", event = "done" },
    }, nil, {
      emit = function(event)
        events[#events + 1] = event.kind
      end,
    })

    assert.are.same({ "tick", "tick", "tick", "done" }, events)
  end)

  it("random selects one weighted option", function()
    local originalRandom = math.random
    local events = {}
    math.random = function()
      return 0.95
    end

    feel.play({
      {
        kind = "random",
        options = {
          { weight = 3, step = { kind = "emit", event = "small" } },
          { weight = 1, step = { kind = "emit", event = "big" } },
        },
      },
    }, nil, {
      emit = function(event)
        events[#events + 1] = event.kind
      end,
    })

    math.random = originalRandom
    assert.are.same({ "big" }, events)
  end)

  it("play runs named nested sequences and preserves context", function()
    local target = feel.target({ label = "Launch" })
    local calls = {}

    feel.define("nested.spark", {
      {
        kind = "callback",
        callback = function(ctx)
          calls[#calls + 1] = ctx.trigger .. ":" .. ctx.target.label
        end,
      },
    })

    feel.play({
      { kind = "play", name = "nested.spark" },
      { kind = "emit", event = "done" },
    }, target, {
      trigger = "activate",
      emit = function(event)
        calls[#calls + 1] = event.kind
      end,
    })

    assert.are.same({ "activate:Launch", "done" }, calls)
  end)

  it("log calls opts.log before continuing", function()
    local calls = {}

    feel.play({
      { kind = "log", message = "hello" },
      { kind = "emit", event = "done" },
    }, nil, {
      log = function(message)
        calls[#calls + 1] = "log:" .. message
      end,
      emit = function(event)
        calls[#calls + 1] = event.kind
      end,
    })

    assert.are.same({ "log:hello", "done" }, calls)
  end)

  it("clear cancels active waits and nested sequence runners", function()
    local events = {}

    feel.play({
      {
        kind = "parallel",
        steps = {
          {
            kind = "repeat",
            forever = true,
            steps = {
              { kind = "wait", duration = 0.1 },
              { kind = "emit", event = "loop" },
            },
          },
          {
            { kind = "wait", duration = 0.3 },
            { kind = "emit", event = "late" },
          },
        },
      },
      { kind = "emit", event = "done" },
    }, nil, {
      emit = function(event)
        events[#events + 1] = event.kind
      end,
    })

    feel.update(0.1)
    assert.are.same({ "loop" }, events)
    feel.clear()
    feel.update(1)
    assert.are.same({ "loop" }, events)
  end)

  it("clear target cancels runners waiting on that target", function()
    local target = feel.target()
    local events = {}

    feel.play({
      { kind = "animate", to = { x = 10 }, duration = 0.1 },
      { kind = "emit", event = "done" },
    }, target, {
      emit = function(event)
        events[#events + 1] = event.kind
      end,
    })

    feel.clear(target)
    feel.update(0.1)

    assert.are.equal(0, target.values.x)
    assert.are.same({}, events)
  end)

  it("restart cancels the previous run for the same target and key", function()
    local target = feel.target()
    local events = {}

    feel.play({
      { kind = "animate", to = { x = 10 }, duration = 0.2 },
      { kind = "emit", event = "old" },
    }, target, {
      restart = true,
      key = "impact",
      emit = function(event)
        events[#events + 1] = event.kind
      end,
    })
    feel.update(0.1)

    feel.play({
      { kind = "animate", to = { x = 1 }, duration = 0.1 },
      { kind = "emit", event = "new" },
    }, target, {
      restart = true,
      key = "impact",
      emit = function(event)
        events[#events + 1] = event.kind
      end,
    })

    feel.update(0.1)
    feel.update(1)

    assert.are.equal(1, target.values.x)
    assert.are.same({ "new" }, events)
  end)

  it("applies custom numeric fields from animate `from` on restart", function()
    local target = feel.target({ values = { glow = 0 } })

    local sequence = {
      { kind = "animate", from = { glow = 1 }, to = { glow = 0 }, duration = 0.2 },
    }

    feel.play(sequence, target, { restart = true, key = "flash" })
    assert.are.equal(1, target.values.glow)
    feel.update(0.2)
    assert.are.equal(0, target.values.glow)

    feel.play(sequence, target, { restart = true, key = "flash" })
    assert.are.equal(1, target.values.glow)
    feel.update(0.1)
    assert.is_true(target.values.glow > 0 and target.values.glow < 1)
  end)

  it("reports active runner snapshots", function()
    local target = feel.target()

    feel.define("debug.wait", {
      { kind = "wait", duration = 1 },
      { kind = "emit", event = "done" },
    })

    feel.play("debug.wait", target, { restart = true, key = "debug" })
    feel.update(0.25)

    local active = feel.active()
    assert.are.equal(1, #active)
    assert.are.equal(target, active[1].target)
    assert.are.equal("debug.wait", active[1].source)
    assert.are.equal("debug", active[1].key)
    assert.are.equal(1, active[1].index)
    assert.are.equal(2, active[1].count)
    assert.are.equal(0.25, active[1].elapsed)
    assert.is_true(active[1].waiting)
    assert.are.equal(0.75, active[1].remaining)

    active[1].index = 99
    assert.are.equal(1, feel.active()[1].index)
  end)

  it("reports whether a target/key slot is playing", function()
    local target = feel.target()

    feel.play({
      { kind = "wait", duration = 0.1 },
    }, target, { restart = true, key = "pulse" })

    assert.is_true(feel.isPlaying(target))
    assert.is_true(feel.isPlaying(target, "pulse"))
    assert.is_false(feel.isPlaying(target, "other"))

    feel.update(0.1)

    assert.is_false(feel.isPlaying(target, "pulse"))
  end)

  it("restart slots are scoped by target", function()
    local one = feel.target()
    local two = feel.target()
    local events = {}

    local sequence = {
      { kind = "wait", duration = 0.1 },
      {
        kind = "callback",
        callback = function(ctx)
          events[#events + 1] = ctx.target.label
        end,
      },
    }
    one.label = "one"
    two.label = "two"

    feel.play(sequence, one, { restart = true, key = "pulse" })
    feel.play(sequence, two, { restart = true, key = "pulse" })
    feel.play({
      {
        kind = "callback",
        callback = function(ctx)
          events[#events + 1] = ctx.target.label .. ":new"
        end,
      },
    }, one, { restart = true, key = "pulse" })
    feel.update(0.1)

    assert.are.same({ "one:new", "two" }, events)
  end)

  it("named sequences restart without an explicit key", function()
    local events = {}

    feel.define("restart.named", {
      { kind = "wait", duration = 0.1 },
      { kind = "emit", event = "done" },
    })

    feel.play("restart.named", nil, {
      restart = true,
      emit = function(event)
        events[#events + 1] = event.kind
      end,
    })
    feel.play("restart.named", nil, {
      restart = true,
      emit = function(event)
        events[#events + 1] = event.kind
      end,
    })
    feel.update(0.1)

    assert.are.same({ "done" }, events)
  end)

  it("restart options do not leak into child sequence runners", function()
    local events = {}
    local child = {
      { kind = "wait", duration = 0.1 },
      { kind = "emit", event = "child" },
    }

    feel.play({
      {
        kind = "parallel",
        steps = {
          child,
          child,
        },
      },
    }, nil, {
      restart = true,
      key = "parent",
      emit = function(event)
        events[#events + 1] = event.kind
      end,
    })
    feel.update(0.1)

    assert.are.same({ "child", "child" }, events)
  end)

  it("channel subscribes emits and unsubscribes feedback intents", function()
    local channel = feel.channel()
    local calls = {}

    local unsubscribe = channel:on("ship.shoot", function(event)
      calls[#calls + 1] = event.payload.weapon
    end)

    assert.are.equal(1, channel:emit("ship.shoot", { payload = { weapon = "laser" } }))
    unsubscribe()
    assert.are.equal(0, channel:emit("ship.shoot", { payload = { weapon = "beam" } }))
    assert.are.same({ "laser" }, calls)
  end)

  it("channel emits against a snapshot when listeners change during dispatch", function()
    local channel = feel.channel()
    local calls = {}
    local unsubscribeSecond

    channel:on("hit", function()
      calls[#calls + 1] = "first"
      unsubscribeSecond()
    end)
    unsubscribeSecond = channel:on("hit", function()
      calls[#calls + 1] = "second"
    end)

    assert.are.equal(2, channel:emit("hit"))
    assert.are.equal(1, channel:emit("hit"))
    assert.are.same({ "first", "second", "first" }, calls)
  end)

  it("channel map plays sequences with default and event options", function()
    local channel = feel.channel()
    local target = feel.target()
    local events = {}

    feel.define("mapped.pulse", {
      { kind = "animate", to = { x = 8 }, duration = 0.1 },
      { kind = "emit", event = "done" },
    })

    channel:map("pulse", "mapped.pulse", {
      target = target,
      opts = {
        restart = true,
        key = "default",
        emit = function(event)
          events[#events + 1] = event.kind
        end,
      },
    })

    channel:emit("pulse", { opts = { key = "override" } })
    feel.update(0.1)

    assert.are.equal(8, target.values.x)
    assert.are.same({ "done" }, events)
  end)

  it("channel clears one intent or all intents", function()
    local channel = feel.channel()
    local calls = {}

    channel:on("a", function()
      calls[#calls + 1] = "a"
    end)
    channel:on("b", function()
      calls[#calls + 1] = "b"
    end)

    channel:clear("a")
    assert.are.equal(0, channel:emit("a"))
    assert.are.equal(1, channel:emit("b"))
    channel:clear()
    assert.are.equal(0, channel:emit("b"))
    assert.are.same({ "b" }, calls)
  end)

  it("loads from an arbitrary package prefix", function()
    local nestedPrefix = "lib.random.folder.feel"
    local loaders = package.searchers or package.loaders

    for name in pairs(package.loaded) do
      if name == nestedPrefix or name:sub(1, #nestedPrefix + 1) == nestedPrefix .. "." then
        package.loaded[name] = nil
      end
    end

    local function nestedSearcher(name)
      if name ~= nestedPrefix and name:sub(1, #nestedPrefix + 1) ~= nestedPrefix .. "." then
        return nil
      end

      local suffix = name == nestedPrefix and "init" or name:sub(#nestedPrefix + 2)
      local path = "feel/" .. suffix:gsub("%.", "/") .. ".lua"
      local loader, err = loadfile(path)
      if loader then
        return loader
      end
      return err
    end

    table.insert(loaders, 1, nestedSearcher)
    local ok, nested = pcall(require, nestedPrefix)
    table.remove(loaders, 1)

    assert.is_true(ok)
    assert.are.equal("function", type(nested.play))
    assert.are.equal("table", type(package.loaded[nestedPrefix .. ".vendor.flux"]))
  end)

  describe("per-run control", function()
    it("pauses one run while others keep advancing, then resumes to completion", function()
      local a = feel.target()
      local b = feel.target()

      local ctx = feel.play({ { kind = "animate", to = { x = 10 }, duration = 0.1 } }, a)
      feel.play({ { kind = "animate", to = { x = 10 }, duration = 0.1 } }, b)

      feel.update(0.05)
      local frozen = a.values.x
      assert.is_true(frozen > 0 and frozen < 10)

      ctx:pause()
      assert.is_true(ctx:isPaused())

      feel.update(0.05)
      assert.are.equal(frozen, a.values.x) -- paused run is frozen
      assert.are.equal(10, b.values.x) -- other run completed

      ctx:resume()
      assert.is_false(ctx:isPaused())
      feel.update(0.1)
      assert.are.equal(10, a.values.x)
    end)

    it("freezes a waiting step while paused", function()
      local fired = {}
      local ctx = feel.play({
        { kind = "wait", duration = 0.1 },
        { kind = "emit", event = "go" },
      }, nil, {
        emit = function(event)
          fired[#fired + 1] = event.kind
        end,
      })

      ctx:pause()
      feel.update(0.2)
      assert.are.same({}, fired) -- wait does not count down while paused

      ctx:resume()
      feel.update(0.1)
      assert.are.same({ "go" }, fired)
    end)

    it("stops a run mid-flight, freezing values and skipping later steps", function()
      local target = feel.target()
      local fired = {}
      local ctx = feel.play({
        { kind = "animate", to = { x = 10 }, duration = 0.1 },
        { kind = "emit", event = "after" },
      }, target, {
        emit = function(event)
          fired[#fired + 1] = event.kind
        end,
      })

      feel.update(0.05)
      local frozen = target.values.x
      ctx:stop()
      assert.is_false(ctx:isPlaying())

      feel.update(0.2)
      assert.are.equal(frozen, target.values.x)
      assert.are.same({}, fired)
    end)

    it("pausing a parent freezes its parallel subtree", function()
      local target = feel.target()
      local ctx = feel.play({
        {
          kind = "parallel",
          steps = {
            { { kind = "animate", to = { x = 10 }, duration = 0.1 } },
            { { kind = "animate", to = { y = 10 }, duration = 0.1 } },
          },
        },
      }, target)

      feel.update(0.05)
      local fx, fy = target.values.x, target.values.y
      ctx:pause()

      feel.update(0.1)
      assert.are.equal(fx, target.values.x)
      assert.are.equal(fy, target.values.y)

      ctx:resume()
      feel.update(0.1)
      assert.are.equal(10, target.values.x)
      assert.are.equal(10, target.values.y)
    end)

    it("treats free functions and methods identically, and tolerates nil", function()
      assert.has_no.errors(function()
        feel.stop(nil)
        feel.pause(nil)
        feel.resume(nil)
      end)

      local target = feel.target()
      local ctx = feel.play({ { kind = "animate", to = { x = 10 }, duration = 0.1 } }, target)
      feel.update(0.05)
      feel.pause(ctx) -- free-function form
      local frozen = target.values.x
      feel.update(0.1)
      assert.are.equal(frozen, target.values.x)
      feel.resume(ctx)
      feel.update(0.1)
      assert.are.equal(10, target.values.x)
    end)
  end)

  describe("global pause and time scale", function()
    it("pauseAll freezes every run until resumeAll", function()
      local target = feel.target()
      feel.play({ { kind = "animate", to = { x = 10 }, duration = 0.1 } }, target)

      feel.update(0.05)
      local frozen = target.values.x
      feel.pauseAll()
      assert.is_true(feel.isPausedAll())

      feel.update(0.2)
      assert.are.equal(frozen, target.values.x)

      feel.resumeAll()
      assert.is_false(feel.isPausedAll())
      feel.update(0.1)
      assert.are.equal(10, target.values.x)
    end)

    it("setTimeScale slows tweens and waits uniformly", function()
      local target = feel.target()
      local fired = {}
      assert.are.equal(0.5, feel.setTimeScale(0.5))

      feel.play({ { kind = "animate", to = { x = 10 }, duration = 0.1 } }, target)
      feel.play({
        { kind = "wait", duration = 0.1 },
        { kind = "emit", event = "go" },
      }, nil, {
        emit = function(event)
          fired[#fired + 1] = event.kind
        end,
      })

      feel.update(0.1) -- effective 0.05
      assert.is_true(target.values.x > 0 and target.values.x < 10)
      assert.are.same({}, fired)

      feel.update(0.1) -- effective 0.05 more -> reaches 0.1 of scaled time
      assert.are.equal(10, target.values.x)
      assert.are.same({ "go" }, fired)
    end)

    it("clamps negative time scale to zero", function()
      assert.are.equal(0, feel.setTimeScale(-2))
    end)

    it("feel.clear resets global pause and time scale", function()
      feel.pauseAll()
      feel.setTimeScale(0.25)
      feel.clear()
      assert.is_false(feel.isPausedAll())
      assert.are.equal(1, feel.timeScale())
    end)
  end)

  describe("run-level signals", function()
    it("fires onComplete once when a run finishes", function()
      local target = feel.target()
      local completed = 0
      local ctx = feel.play({ { kind = "animate", to = { x = 10 }, duration = 0.1 } }, target)
      ctx:onComplete(function()
        completed = completed + 1
      end)

      assert.are.equal(0, completed)
      feel.update(0.1)
      assert.are.equal(1, completed)
      feel.update(0.1)
      assert.are.equal(1, completed) -- no double fire
    end)

    it("fires onStop on stop but not on completion", function()
      local target = feel.target()
      local stops, completes = 0, 0
      local ctx = feel.play({ { kind = "animate", to = { x = 10 }, duration = 0.1 } }, target)
      ctx:onStop(function()
        stops = stops + 1
      end)
      ctx:onComplete(function()
        completes = completes + 1
      end)

      feel.update(0.05)
      ctx:stop()
      assert.are.equal(1, stops)
      assert.are.equal(0, completes)
    end)

    it("invokes late onComplete immediately but not late onStop after completion", function()
      local completed, stopped = false, false
      local ctx = feel.play({ { kind = "emit", event = "x" } }, nil, {
        emit = function() end,
      })

      -- An emit-only sequence completes synchronously during play.
      assert.is_false(ctx:isPlaying())
      assert.are.equal(ctx, ctx:onComplete(function()
        completed = true
      end))
      ctx:onStop(function()
        stopped = true
      end)

      assert.is_true(completed)
      assert.is_false(stopped)
    end)
  end)

  describe("field aliases", function()
    it("accepts alias fields identically to canonical names", function()
      -- duration <- time, on both animate and wait
      local target = feel.target()
      feel.play({ { kind = "animate", to = { x = 10 }, time = 0.1 } }, target)
      feel.update(0.1)
      assert.are.equal(10, target.values.x)

      local fired = {}
      feel.play({
        { kind = "wait", time = 0.1 },
        { kind = "emit", event = "go" },
      }, nil, {
        emit = function(event)
          fired[#fired + 1] = event.kind
        end,
      })
      feel.update(0.05)
      assert.are.same({}, fired)
      feel.update(0.05)
      assert.are.same({ "go" }, fired)

      -- count <- times, callback <- fn
      local count = 0
      feel.play({
        {
          kind = "repeat",
          times = 3,
          sequence = {
            {
              kind = "callback",
              fn = function()
                count = count + 1
              end,
            },
          },
        },
      })
      assert.are.equal(3, count)

      -- weight <- chance
      local picked
      feel.play({
        { kind = "random", options = { { chance = 1, sequence = { { kind = "emit", event = "hit" } } } } },
      }, nil, {
        emit = function(event)
          picked = event.kind
        end,
      })
      assert.are.equal("hit", picked)

      -- message <- text
      local logged
      feel.play({ { kind = "log", text = "hello" } }, nil, {
        log = function(message)
          logged = message
        end,
      })
      assert.are.equal("hello", logged)
    end)

    it("warns once per alias under strictAliases and stays silent otherwise", function()
      local messages = {}
      local realPrint = print
      _G.print = function(message)
        messages[#messages + 1] = message
      end

      -- silent by default
      feel.play({ { kind = "callback", fn = function() end } })
      assert.are.equal(0, #messages)

      feel.strictAliases(true)
      feel.play({ { kind = "callback", fn = function() end } })
      feel.play({ { kind = "callback", fn = function() end } })
      feel.strictAliases(false)
      _G.print = realPrint

      local fnWarnings = 0
      for _, message in ipairs(messages) do
        if type(message) == "string" and message:find("'fn'", 1, true) then
          fnWarnings = fnWarnings + 1
        end
      end
      assert.are.equal(1, fnWarnings) -- deduped on the second use
    end)
  end)
end)
