package.path = "?.lua;?/init.lua;../../../?.lua;../../../?/init.lua;../../../../?.lua;../../../../?/init.lua;" .. package.path

local Manifest = require("scripts.doc_gifs.manifest")
local Scenes = require("scripts.doc_gifs.scenes")

local function parseArgs(args)
  local opts = {
    width = 960,
    height = 540,
    fps = 18,
    frame_dir = "/tmp/feel-doc-gifs/frames",
  }

  local index = 1
  while args and index <= #args do
    local value = args[index]
    local key, inline = value:match("^%-%-([^=]+)=(.*)$")
    if key then
      opts[key:gsub("-", "_")] = inline
    elseif value:sub(1, 2) == "--" then
      key = value:sub(3):gsub("-", "_")
      opts[key] = args[index + 1]
      index = index + 1
    end
    index = index + 1
  end

  opts.width = tonumber(opts.width) or 960
  opts.height = tonumber(opts.height) or 540
  opts.fps = tonumber(opts.fps) or 18
  opts.duration = tonumber(opts.duration)
  return opts
end

local function shellQuote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function ensureDir(path)
  os.execute("mkdir -p " .. shellQuote(path))
end

local function framePath(dir, frame)
  return string.format("%s/%04d.png", dir, frame)
end

local function writeFrame(canvas, path)
  local imageData = canvas:newImageData()
  local fileData = imageData:encode("png")
  local file = assert(io.open(path, "wb"))
  file:write(fileData:getString())
  file:close()
end

local function newDepthCanvas(width, height)
  local formats = { "depth24", "depth16", "depth32f" }
  for _, format in ipairs(formats) do
    local ok, canvas = pcall(love.graphics.newCanvas, width, height, {
      format = format,
      readable = false,
    })
    if ok and canvas then
      return canvas
    end
  end
  return nil
end

local function setCaptureCanvas(colorCanvas, depthCanvas)
  if depthCanvas then
    local ok = pcall(love.graphics.setCanvas, { colorCanvas, depthstencil = depthCanvas })
    if ok then
      return
    end
  end
  love.graphics.setCanvas(colorCanvas)
end

local function clearCapture()
  local ok = pcall(love.graphics.clear, 0.025, 0.028, 0.04, 1, true, true)
  if not ok then
    love.graphics.clear(0.025, 0.028, 0.04, 1)
  end
end

local function renderFrame(ctx, scene, target, colorCanvas, depthCanvas, frame)
  setCaptureCanvas(colorCanvas, depthCanvas)
  love.graphics.origin()
  love.graphics.setShader()
  clearCapture()
  scene.draw(scene, ctx, target)
  love.graphics.setShader()
  love.graphics.setCanvas()
  writeFrame(colorCanvas, framePath(ctx.frame_dir, frame))
end

local function runActions(ctx)
  for _, item in ipairs(ctx.actions or {}) do
    if not item.done and ctx.time + 0.000001 >= item.at then
      item.done = true
      item.run(ctx)
    end
  end
end

function love.load(args)
  local opts = parseArgs(args or arg)
  local target = Manifest.by_id(opts.target)
  if not target then
    error("unknown doc GIF target '" .. tostring(opts.target) .. "'")
  end

  local ok, err = Manifest.validate()
  if not ok then
    error(err)
  end

  ensureDir(opts.frame_dir)
  love.window.setMode(opts.width, opts.height, {
    resizable = false,
    vsync = 0,
    highdpi = false,
  })

  math.randomseed(1000 + #target.id * 37)
  if love.math and love.math.setRandomSeed then
    love.math.setRandomSeed(2000 + #target.id * 53, 3000 + #target.title * 29)
  end

  local ctx = {
    width = opts.width,
    height = opts.height,
    fps = opts.fps,
    duration = opts.duration or target.duration,
    frame_dir = opts.frame_dir,
    time = 0,
    frame = 1,
    target = target,
    love = love,
    events = {},
    fonts = {
      title = love.graphics.newFont(44),
      body = love.graphics.newFont(22),
      small = love.graphics.newFont(16),
    },
  }

  local scene = Scenes.create(target, ctx)
  local colorCanvas = love.graphics.newCanvas(opts.width, opts.height, {
    format = "rgba8",
    readable = true,
    msaa = 0,
  })
  local depthCanvas = newDepthCanvas(opts.width, opts.height)
  local dt = 1 / opts.fps
  local frameCount = math.max(1, math.floor(ctx.duration * opts.fps + 0.5))

  for frame = 1, frameCount do
    ctx.frame = frame
    ctx.time = (frame - 1) * dt
    runActions(ctx)
    scene.update(scene, ctx, ctx.time, dt)
    renderFrame(ctx, scene, target, colorCanvas, depthCanvas, frame)
  end

  love.event.quit()
end
