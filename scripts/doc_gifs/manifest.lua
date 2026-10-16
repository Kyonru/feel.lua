local Manifest = {}

local targets = {
  {
    id = "motion-basics",
    title = "Motion Basics",
    docs = { "docs/getting-started.md", "docs/core-runner.md", "docs/sequence-steps.md" },
    inline_docs = { "docs/getting-started.md", "docs/core-runner.md" },
    duration = 2.8,
    scene = "motion",
    alt = "Animated GIF showing a heart pulse built from numeric animation, easing, and a short reusable recipe.",
    subtitle = "Animate values, shape the easing, compose the pulse",
    primary = { 1, 0.18, 0.46, 1 },
    secondary = { 1, 0.72, 0.18, 1 },
  },
  {
    id = "combo-recipe",
    title = "Combo Recipe",
    docs = { "docs/sequence-steps.md", "docs/recipes.md" },
    inline_docs = { "docs/sequence-steps.md" },
    duration = 3.0,
    scene = "combo",
    alt = "Animated GIF showing a three-hit platformer combo composed with sequence, repeat, random, and parallel steps.",
    subtitle = "Sequence a combo; repeat hits; vary and layer each impact",
    primary = { 0.1, 0.82, 1, 1 },
    secondary = { 1, 0.18, 0.46, 1 },
  },
  {
    id = "host-integration",
    title = "Host Integration",
    docs = { "docs/sequence-steps.md", "docs/api.md" },
    inline_docs = { "docs/api.md" },
    duration = 2.8,
    scene = "host",
    alt = "Animated GIF mapping recipe emit, audio, callback, and log steps to host-owned results.",
    subtitle = "Recipe steps dispatch into host-owned handlers",
    primary = { 0.32, 1, 0.52, 1 },
    secondary = { 0.62, 0.38, 1, 1 },
  },
  {
    id = "impact-feedback",
    title = "Impact Feedback",
    docs = { "docs/love-adapter.md", "docs/feedbacks.md", "docs/post-processing.md" },
    inline_docs = { "docs/love-adapter.md", "docs/feedbacks.md", "docs/post-processing.md" },
    duration = 3.0,
    scene = "adapter",
    alt = "Animated GIF showing one impact recipe combining camera shake, flash, particles, sound, and post-processing.",
    subtitle = "One impact recipe layers five synchronized feedback channels",
    primary = { 1, 0.18, 0.46, 1 },
    secondary = { 0.1, 0.82, 1, 1 },
  },
  {
    id = "haptics",
    title = "Haptics",
    docs = { "docs/haptics.md", "docs/love-adapter.md" },
    inline_docs = { "docs/haptics.md" },
    duration = 2.8,
    scene = "adapter",
    alt = "Animated GIF showing asymmetric haptic motor strength on a game controller.",
    subtitle = "Each grip shows its motor's timed intensity",
    primary = { 0.62, 0.38, 1, 1 },
    secondary = { 0.32, 1, 0.52, 1 },
  },
  {
    id = "sprite",
    title = "Sprite / Anim8",
    docs = { "docs/sprite.md" },
    inline_docs = { "docs/sprite.md" },
    duration = 2.8,
    scene = "sprite",
    alt = "Animated GIF showing renderer-independent sprite recoil, squash, flash, and an optional Anim8 draw path.",
    subtitle = "Compose a pose; draw it with plain LOVE or Anim8",
    primary = { 1, 0.72, 0.18, 1 },
    secondary = { 0.62, 0.38, 1, 1 },
  },
  {
    id = "g3d",
    title = "g3d",
    docs = { "docs/g3d.md" },
    inline_docs = { "docs/g3d.md" },
    duration = 3.0,
    scene = "three",
    alt = "Animated GIF showing one projected cube responding to g3d camera field of view, camera shake, model scale, and 3D rotation feedback.",
    subtitle = "One cube makes camera FOV and 3D model feedback clear",
    primary = { 0.1, 0.82, 1, 1 },
    secondary = { 1, 0.72, 0.18, 1 },
  },
  {
    id = "menori",
    title = "Menori",
    docs = { "docs/menori.md" },
    inline_docs = { "docs/menori.md" },
    duration = 3.0,
    scene = "three",
    alt = "Animated GIF showing a projected cube rotating through a Menori camera orbit while its node scale and material tint react.",
    subtitle = "Camera orbit reveals the cube's changing 3D faces",
    primary = { 0.62, 0.38, 1, 1 },
    secondary = { 0.32, 1, 0.52, 1 },
  },
}

local function copyList(list)
  local result = {}
  for index, value in ipairs(list or {}) do
    result[index] = value
  end
  return result
end

function Manifest.targets()
  return copyList(targets)
end

function Manifest.by_id(id)
  for _, target in ipairs(targets) do
    if target.id == id then
      return target
    end
  end
  return nil
end

function Manifest.validate(list)
  list = list or targets
  local seen = {}
  for index, target in ipairs(list) do
    if type(target.id) ~= "string" or not target.id:match("^[%w][%w%-]*$") then
      return false, string.format("target %d has invalid id", index)
    end
    if seen[target.id] then
      return false, "duplicate manifest id '" .. target.id .. "'"
    end
    seen[target.id] = true
    if type(target.title) ~= "string" or target.title == "" then
      return false, "target '" .. target.id .. "' requires title"
    end
    if type(target.alt) ~= "string" or target.alt == "" then
      return false, "target '" .. target.id .. "' requires alt"
    end
    if type(target.duration) ~= "number" or target.duration <= 0 then
      return false, "target '" .. target.id .. "' requires positive duration"
    end
    if type(target.docs) ~= "table" or #target.docs == 0 then
      return false, "target '" .. target.id .. "' requires docs"
    end
  end
  return true
end

return Manifest
