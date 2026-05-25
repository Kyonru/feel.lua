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
