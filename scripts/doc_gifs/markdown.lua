local Markdown = {}

local ASSET_ROOT = "docs/assets/feature-gifs"

local function readFile(path)
  local file = assert(io.open(path, "rb"))
  local contents = file:read("*a")
  file:close()
  return contents
end

local function writeFile(path, contents)
  local file = assert(io.open(path, "wb"))
  file:write(contents)
  file:close()
end

local function splitPath(path)
  local parts = {}
  for part in tostring(path):gmatch("[^/]+") do
    if part ~= "." and part ~= "" then
      parts[#parts + 1] = part
    end
  end
  return parts
end

local function dirname(path)
  local parts = splitPath(path)
  parts[#parts] = nil
  return parts
end

local function assetPathFor(target)
  return ASSET_ROOT .. "/" .. target.id .. ".gif"
end

function Markdown.relativeAssetPath(docPath, assetPath)
  local from = dirname(docPath)
  local to = splitPath(assetPath)
  local index = 1
  while from[index] and to[index] and from[index] == to[index] do
    index = index + 1
  end

  local result = {}
  for _ = index, #from do
    result[#result + 1] = ".."
  end
  for i = index, #to do
    result[#result + 1] = to[i]
  end
  if #result == 0 then
    return "."
  end
  return table.concat(result, "/")
end

local function featureMarkers(id)
  return "<!-- feel:feature-gif " .. id .. " -->",
    "<!-- /feel:feature-gif " .. id .. " -->"
end

local function galleryMarkers()
  return "<!-- feel:feature-gif-gallery -->",
    "<!-- /feel:feature-gif-gallery -->"
end

local function countPlain(text, needle)
  local count = 0
  local pos = 1
  while true do
    local startPos, endPos = text:find(needle, pos, true)
    if not startPos then
      break
    end
    count = count + 1
    pos = endPos + 1
  end
  return count
end

local function findTopLevelHeadingEnd(text)
  local searchStart = 1
  if text:sub(1, 4) == "---\n" then
    local frontMatterEnd = text:find("\n---\n", 5, true)
    if frontMatterEnd then
      searchStart = frontMatterEnd + 5
    end
  end

  local headingStart, headingEnd = text:find("\n?# [^\n]*\n?", searchStart)
  if headingStart then
    local matched = text:sub(headingStart, headingEnd)
    if matched:sub(1, 1) == "\n" then
      return headingStart, headingEnd
    end
    return 1, headingEnd
  end
  return nil, nil
end

local function insertAfterHeading(text, block)
  local _, headingEnd = findTopLevelHeadingEnd(text)
  if not headingEnd then
    return block .. "\n\n" .. text
  end

  local before = text:sub(1, headingEnd):gsub("%s*$", "")
  local after = text:sub(headingEnd + 1):gsub("^%s*", "")
  if after == "" then
    return before .. "\n\n" .. block .. "\n"
  end
  return before .. "\n\n" .. block .. "\n\n" .. after
end

local function appendBlock(text, block)
  local base = text:gsub("%s*$", "")
  if base == "" then
    return block .. "\n"
  end
  return base .. "\n\n" .. block .. "\n"
end

local function joinWithoutBlock(before, after)
  before = before:gsub("%s*$", "")
  after = after:gsub("^%s*", "")
  if before ~= "" and after ~= "" then
    return before .. "\n\n" .. after
  end
  if before ~= "" then
    return before
  end
  return after
end

local function replaceOrInsert(text, openMarker, closeMarker, block, opts)
  opts = opts or {}
  local openCount = countPlain(text, openMarker)
  local closeCount = countPlain(text, closeMarker)

  if openCount > 1 or closeCount > 1 then
    return nil, "duplicate managed Markdown block '" .. openMarker .. "'"
  end
  if openCount == 0 and closeCount > 0 then
    return nil, "closing managed Markdown block without opener '" .. closeMarker .. "'"
  end
  if openCount > 0 and closeCount == 0 then
    return nil, "unterminated managed Markdown block '" .. openMarker .. "'"
  end

  if openCount == 1 then
    local openStart = assert(text:find(openMarker, 1, true))
    local closeStart, closeEnd = text:find(closeMarker, openStart + #openMarker, true)
    if not closeStart then
      return nil, "unterminated managed Markdown block '" .. openMarker .. "'"
    end
    local before = text:sub(1, openStart - 1)
    local after = text:sub(closeEnd + 1)
    if opts.position == "end" then
      return appendBlock(joinWithoutBlock(before, after), block)
    end
    before = before:gsub("%s*$", "")
    after = after:gsub("^%s*", "")
    if before ~= "" and after ~= "" then
      return before .. "\n\n" .. block .. "\n\n" .. after
    elseif before ~= "" then
      return before .. "\n\n" .. block .. "\n"
    elseif after ~= "" then
      return block .. "\n\n" .. after
    end
    return block .. "\n"
  end

  if opts.position == "end" then
    return appendBlock(text, block)
  end
  return insertAfterHeading(text, block)
end

function Markdown.renderFeatureBlock(target, docPath)
  local openMarker, closeMarker = featureMarkers(target.id)
  local path = Markdown.relativeAssetPath(docPath, assetPathFor(target))
  return table.concat({
    openMarker,
    "![" .. target.alt .. "](" .. path .. ")",
    closeMarker,
  }, "\n")
end

function Markdown.renderGalleryBlock(targets, docPath)
  local openMarker, closeMarker = galleryMarkers()
  local lines = {
    openMarker,
    "## Feature GIFs",
    "",
    "| Feature | Preview |",
    "| --- | --- |",
  }
  for _, target in ipairs(targets) do
    local path = Markdown.relativeAssetPath(docPath, assetPathFor(target))
    lines[#lines + 1] = "| " .. target.title .. " | ![" .. target.alt .. "](" .. path .. ") |"
  end
  lines[#lines + 1] = closeMarker
  return table.concat(lines, "\n")
end

function Markdown.upsertFeatureBlock(text, target, docPath)
  local openMarker, closeMarker = featureMarkers(target.id)
  return replaceOrInsert(text, openMarker, closeMarker, Markdown.renderFeatureBlock(target, docPath))
end

function Markdown.upsertGalleryBlock(text, targets, docPath)
  local openMarker, closeMarker = galleryMarkers()
  return replaceOrInsert(text, openMarker, closeMarker, Markdown.renderGalleryBlock(targets, docPath), {
    position = "end",
  })
end

local function writeIfChanged(path, contents, log)
  local current = readFile(path)
  if current == contents then
    if log then
      log(path .. " unchanged")
    end
    return false
  end
  writeFile(path, contents)
  if log then
    log(path .. " updated")
  end
  return true
end

function Markdown.updateDocs(targets, opts)
  opts = opts or {}
  local changed = false
  local docsByPath = {}

  local ok, err = require("scripts.doc_gifs.manifest").validate(targets)
  if not ok then
    return nil, err
  end

  local indexPath = opts.index_path or "docs/index.md"
  docsByPath[indexPath] = readFile(indexPath)
  local updatedIndex, indexErr = Markdown.upsertGalleryBlock(docsByPath[indexPath], targets, indexPath)
  if not updatedIndex then
    return nil, indexErr
  end
  docsByPath[indexPath] = updatedIndex

  for _, target in ipairs(targets) do
    for _, docPath in ipairs(target.inline_docs or {}) do
      docsByPath[docPath] = docsByPath[docPath] or readFile(docPath)
      local updated, updateErr = Markdown.upsertFeatureBlock(docsByPath[docPath], target, docPath)
      if not updated then
        return nil, updateErr
      end
      docsByPath[docPath] = updated
    end
  end

  for path, contents in pairs(docsByPath) do
    if writeIfChanged(path, contents, opts.log) then
      changed = true
    end
  end

  return changed
end

return Markdown
