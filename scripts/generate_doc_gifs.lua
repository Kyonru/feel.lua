package.path = "./?.lua;./?/init.lua;" .. package.path

local Manifest = require("scripts.doc_gifs.manifest")
local Markdown = require("scripts.doc_gifs.markdown")

local WIDTH = tonumber(os.getenv("WIDTH")) or 960
local HEIGHT = tonumber(os.getenv("HEIGHT")) or 540
local FPS = tonumber(os.getenv("FPS")) or 18
local TEMP_ROOT = os.getenv("DOC_GIFS_TMP") or "/tmp/feel-doc-gifs"
local ASSET_DIR = "docs/assets/feature-gifs"

local function shellQuote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function readFile(path)
  local file = io.open(path, "rb")
  if not file then
    return nil
  end
  local contents = file:read("*a")
  file:close()
  return contents
end

local function fileExists(path)
  local file = io.open(path, "rb")
  if file then
    file:close()
    return true
  end
  return false
end

local function run(command)
  local ok, reason, code = os.execute(command)
  if ok == true or ok == 0 then
    return true
  end
  if type(ok) == "number" then
    return ok == 0
  end
  return false, reason or "exit", code
end

local function mustRun(command)
  local ok, reason, code = run(command)
  if not ok then
    error(string.format("command failed (%s %s): %s", tostring(reason), tostring(code), command))
  end
end

local function commandOutput(command)
  local handle = io.popen(command)
  if not handle then
    return nil
  end
  local output = handle:read("*a")
  handle:close()
  output = output and output:gsub("%s+$", "")
  if output == "" then
    return nil
  end
  return output
end

local function resolveLove()
  local env = os.getenv("LOVE_BIN")
  if env and env ~= "" then
    return env
  end
  local love = commandOutput("command -v love 2>/dev/null")
  if love then
    return love
  end
  local macLove = "/Applications/love.app/Contents/MacOS/love"
  if fileExists(macLove) then
    return macLove
  end
  return nil
end

local function resolveFfmpeg()
  local env = os.getenv("FFMPEG_BIN")
  if env and env ~= "" then
    return env
  end
  return commandOutput("command -v ffmpeg 2>/dev/null")
end

local function mkdir(path)
  mustRun("mkdir -p " .. shellQuote(path))
end

local function removeDir(path)
  if path:sub(1, #TEMP_ROOT) ~= TEMP_ROOT then
    error("refusing to remove non-temp path: " .. path)
  end
  mustRun("rm -rf " .. shellQuote(path))
end

local function byteEqual(left, right)
  local leftBytes = readFile(left)
  local rightBytes = readFile(right)
  return leftBytes ~= nil and rightBytes ~= nil and leftBytes == rightBytes
end

local function targetFrameDir(target)
  return TEMP_ROOT .. "/" .. target.id .. "/frames"
end

local function captureTarget(loveBin, target)
  local frameDir = targetFrameDir(target)
  removeDir(TEMP_ROOT .. "/" .. target.id)
  mkdir(frameDir)

  local command = table.concat({
    shellQuote(loveBin),
    shellQuote("scripts/doc_gifs/capture_app"),
    "--target", shellQuote(target.id),
    "--frame-dir", shellQuote(frameDir),
    "--width", tostring(WIDTH),
    "--height", tostring(HEIGHT),
    "--fps", tostring(FPS),
    "--duration", tostring(target.duration),
  }, " ")

  mustRun(command)
  return frameDir
end

local function encodeGif(ffmpegBin, target, frameDir)
  mkdir(ASSET_DIR)
  local pattern = frameDir .. "/%04d.png"
  local palette = frameDir .. "/palette.png"
  local outPath = ASSET_DIR .. "/" .. target.id .. ".gif"
  local tmpPath = outPath .. ".tmp.gif"

  mustRun(table.concat({
    shellQuote(ffmpegBin),
    "-y",
    "-hide_banner",
    "-loglevel", "error",
    "-framerate", tostring(FPS),
    "-start_number", "1",
    "-i", shellQuote(pattern),
    "-vf", shellQuote("palettegen=stats_mode=full"),
    "-map_metadata", "-1",
    "-bitexact",
    shellQuote(palette),
  }, " "))

  mustRun(table.concat({
    shellQuote(ffmpegBin),
    "-y",
    "-hide_banner",
    "-loglevel", "error",
    "-framerate", tostring(FPS),
    "-start_number", "1",
    "-i", shellQuote(pattern),
    "-i", shellQuote(palette),
    "-lavfi", shellQuote("paletteuse=dither=bayer:bayer_scale=1"),
    "-loop", "0",
    "-map_metadata", "-1",
    "-bitexact",
    shellQuote(tmpPath),
  }, " "))

  if byteEqual(outPath, tmpPath) then
    os.remove(tmpPath)
    print("[docs-gifs] " .. target.id .. " unchanged")
    return false
  end

  os.rename(tmpPath, outPath)
  print("[docs-gifs] " .. target.id .. " updated")
  return true
end

local function selectedTargets()
  local ok, err = Manifest.validate()
  if not ok then
    error(err)
  end

  local feature = os.getenv("FEATURE")
  if feature and feature ~= "" then
    local target = Manifest.by_id(feature)
    if not target then
      error("unknown FEATURE '" .. feature .. "'")
    end
    return { target }
  end
  return Manifest.targets()
end

local function main()
  local loveBin = resolveLove()
  if not loveBin then
    error("LOVE2D executable not found; set LOVE_BIN=/path/to/love")
  end
  local ffmpegBin = resolveFfmpeg()
  if not ffmpegBin then
    error("FFmpeg executable not found; set FFMPEG_BIN=/path/to/ffmpeg")
  end

  mkdir(TEMP_ROOT)
  mkdir(ASSET_DIR)

  local changed = false
  for _, target in ipairs(selectedTargets()) do
    print("[docs-gifs] capturing " .. target.id)
    local frameDir = captureTarget(loveBin, target)
    changed = encodeGif(ffmpegBin, target, frameDir) or changed
    if os.getenv("KEEP_FRAMES") ~= "1" then
      removeDir(TEMP_ROOT .. "/" .. target.id)
    else
      print("[docs-gifs] kept frames in " .. frameDir)
    end
  end

  local docsChanged, docsErr = Markdown.updateDocs(Manifest.targets(), {
    log = function(message)
      print("[docs-gifs] " .. message)
    end,
  })
  if docsChanged == nil then
    error(docsErr)
  end
  changed = docsChanged or changed

  if changed then
    print("[docs-gifs] done")
  else
    print("[docs-gifs] all outputs unchanged")
  end
end

main()
