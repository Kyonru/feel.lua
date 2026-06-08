local Manifest = {}

local targets = {
  {
    id = "getting-started",
    title = "Getting Started",
    docs = { "docs/getting-started.md" },
    inline_docs = { "docs/getting-started.md" },
    duration = 2.8,
    scene = "button",
    alt = "Animated GIF showing a Feel.lua button press sequence with glow and sparks.",
    subtitle = "A target, a sequence, and one emitted burst.",
    primary = { 0.1, 0.82, 1, 1 },
    secondary = { 1, 0.72, 0.18, 1 },
  },
  {
    id = "animate",
    title = "Animate",
    docs = { "docs/sequence-steps.md" },
    duration = 2.6,
    scene = "button",
    alt = "Animated GIF showing Feel.lua animate steps moving and scaling a card.",
    subtitle = "Tween numeric target values with easing.",
    primary = { 0.32, 1, 0.52, 1 },
    secondary = { 0.1, 0.82, 1, 1 },
  },
  {
    id = "easing",
    title = "Easing",
    docs = { "docs/sequence-steps.md" },
    duration = 2.8,
    scene = "easing",
    alt = "Animated GIF comparing linear, quadout, sineinout, backout, elasticout, and bounceout easing motion.",
    subtitle = "Different ease names change the same tween.",
    primary = { 1, 0.72, 0.18, 1 },
    secondary = { 0.62, 0.38, 1, 1 },
  },
  {
    id = "sequence",
    title = "Sequence",
    docs = { "docs/sequence-steps.md" },
    inline_docs = { "docs/sequence-steps.md" },
    duration = 3.0,
    scene = "flow",
    alt = "Animated GIF showing Feel.lua steps running one after another.",
    subtitle = "Steps wait for the previous motion to finish.",
    primary = { 0.1, 0.82, 1, 1 },
    secondary = { 1, 0.18, 0.46, 1 },
  },
  {
    id = "parallel",
    title = "Parallel",
    docs = { "docs/sequence-steps.md" },
    duration = 2.8,
    scene = "flow",
    alt = "Animated GIF showing parallel Feel.lua branches animating together.",
    subtitle = "Branches advance together, then rejoin.",
    primary = { 0.62, 0.38, 1, 1 },
    secondary = { 0.32, 1, 0.52, 1 },
  },
  {
    id = "repeat",
    title = "Repeat",
    docs = { "docs/sequence-steps.md" },
    duration = 2.8,
    scene = "flow",
    alt = "Animated GIF showing a repeated Feel.lua step ticking three times.",
    subtitle = "One child step can pulse several times.",
    primary = { 1, 0.72, 0.18, 1 },
    secondary = { 0.1, 0.82, 1, 1 },
  },
  {
    id = "random",
    title = "Random",
    docs = { "docs/sequence-steps.md" },
    duration = 2.8,
    scene = "flow",
    alt = "Animated GIF showing a deterministic random branch choosing one weighted result.",
    subtitle = "Weighted options pick one child sequence.",
    primary = { 1, 0.18, 0.46, 1 },
    secondary = { 1, 0.72, 0.18, 1 },
  },
  {
    id = "callbacks",
    title = "Callbacks",
    docs = { "docs/sequence-steps.md", "docs/api.md" },
    duration = 2.8,
    scene = "flow",
    alt = "Animated GIF showing emit, audio, callback, and log events landing in an event stream.",
    subtitle = "Side effects stay host-owned.",
    primary = { 0.32, 1, 0.52, 1 },
    secondary = { 0.62, 0.38, 1, 1 },
  },
  {
    id = "pulse",
    title = "Pulse",
    docs = { "docs/core-runner.md" },
    duration = 2.6,
    scene = "button",
    alt = "Animated GIF showing a target pulse with scale and glow feedback.",
    subtitle = "A tiny scale punch can make UI state read clearly.",
    primary = { 0.62, 0.38, 1, 1 },
    secondary = { 0.1, 0.82, 1, 1 },
  },
  {
    id = "shake",
    title = "Shake",
    docs = { "docs/love-adapter.md" },
    inline_docs = { "docs/love-adapter.md" },
    duration = 2.8,
    scene = "adapter",
    alt = "Animated GIF showing Feel.lua camera shake applied to a small game scene.",
    subtitle = "Camera shake moves the world, not the HUD.",
    primary = { 1, 0.72, 0.18, 1 },
    secondary = { 0.1, 0.82, 1, 1 },
  },
  {
    id = "flash",
    title = "Flash",
    docs = { "docs/love-adapter.md" },
    duration = 2.6,
    scene = "adapter",
    alt = "Animated GIF showing a screen flash overlay after an impact.",
    subtitle = "Screen overlays are drawn after the scene.",
    primary = { 1, 0.18, 0.46, 1 },
    secondary = { 1, 0.72, 0.18, 1 },
  },
  {
    id = "sound",
    title = "Sound",
    docs = { "docs/love-adapter.md" },
    duration = 2.8,
    scene = "adapter",
    alt = "Animated GIF showing sound volume, pitch, and pan feedback meters.",
    subtitle = "Audio events can still be visualized as timing cues.",
    primary = { 0.32, 1, 0.52, 1 },
    secondary = { 1, 0.72, 0.18, 1 },
  },
  {
    id = "haptics",
    title = "Haptics",
    docs = { "docs/love-adapter.md" },
    duration = 2.8,
    scene = "adapter",
    alt = "Animated GIF showing left and right haptic rumble meters driven by feedback.",
    subtitle = "Rumble strength is a timed feedback signal.",
    primary = { 0.62, 0.38, 1, 1 },
    secondary = { 0.32, 1, 0.52, 1 },
  },
  {
    id = "particles",
    title = "Particles",
    docs = { "docs/love-adapter.md" },
    duration = 2.8,
    scene = "adapter",
    alt = "Animated GIF showing particle bursts emitted from a Feel.lua event.",
    subtitle = "Recipe events can spawn app-owned particles.",
    primary = { 0.1, 0.82, 1, 1 },
    secondary = { 1, 0.72, 0.18, 1 },
  },
  {
    id = "shader",
    title = "Shader",
    docs = { "docs/love-adapter.md" },
    duration = 2.8,
    scene = "adapter",
    alt = "Animated GIF showing a shader uniform pulse around an actor.",
    subtitle = "Shader uniforms can be sent or tweened.",
    primary = { 0.62, 0.38, 1, 1 },
    secondary = { 1, 0.18, 0.46, 1 },
  },
  {
    id = "post-processing",
    title = "Post Processing",
    docs = { "docs/post-processing.md" },
    inline_docs = { "docs/post-processing.md" },
    duration = 2.8,
    scene = "adapter",
    alt = "Animated GIF showing bloom and chromatic post-processing feedback on a scene.",
    subtitle = "Canvas effects run after the world is captured.",
    primary = { 1, 0.72, 0.18, 1 },
    secondary = { 0.62, 0.38, 1, 1 },
  },
  {
    id = "feedbacks",
    title = "Feedbacks",
    docs = { "docs/feedbacks.md" },
    inline_docs = { "docs/feedbacks.md" },
    duration = 3.0,
    scene = "adapter",
    alt = "Animated GIF showing one named feedback stack triggering camera, flash, post, and model cues.",
    subtitle = "A named stack can route many adapter events.",
    primary = { 1, 0.18, 0.46, 1 },
    secondary = { 0.1, 0.82, 1, 1 },
  },
  {
    id = "love2d",
    title = "LOVE2D",
    docs = { "docs/love-examples.md" },
    inline_docs = { "docs/love-examples.md" },
    duration = 3.0,
    scene = "adapter",
    alt = "Animated GIF showing Feel.lua driving a compact LOVE2D mini-scene.",
    subtitle = "A real game loop calls feel.update and draws the result.",
    primary = { 0.1, 0.82, 1, 1 },
    secondary = { 0.32, 1, 0.52, 1 },
  },
  {
    id = "g3d",
    title = "g3d",
    docs = { "docs/g3d.md" },
    inline_docs = { "docs/g3d.md" },
    duration = 3.0,
    scene = "three",
    alt = "Animated GIF showing Feel.lua g3d helper-style model and camera feedback in a 3D scene.",
    subtitle = "Model and camera targets can be punched, shaken, and reset.",
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
    alt = "Animated GIF showing Feel.lua Menori helper-style node, camera, animation, and uniform feedback.",
    subtitle = "Nodes, cameras, animation speed, and uniforms can share one feedback stack.",
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
