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
end)
