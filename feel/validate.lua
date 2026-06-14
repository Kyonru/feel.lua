local M = {}

local STEP_KINDS = {
  animate = true,
  spring = true,
  wait = true,
  pause = true,
  emit = true,
  audio = true,
  callback = true,
  play = true,
  parallel = true,
  ["repeat"] = true,
  random = true,
  log = true,
}

local function fail(path, message)
  return false, path .. ": " .. message
end

local function fieldPath(path, field)
  return path .. "." .. field
end

local function arrayPath(path, index)
  return path .. "[" .. tostring(index) .. "]"
end

local function isSequenceArray(value)
  if type(value) ~= "table" or #value == 0 then
    return false
  end

  for index = 1, #value do
    if value[index] == nil then
      return false
    end
  end

  return true
end

local function childSequence(step)
  return step.sequence or step.steps or step.step or step.feedback or step.name or step[1]
end

local function validateNumberMap(value, path)
  if value == nil then
    return true
  end

  if type(value) ~= "table" then
    return fail(path, "must be a table of numeric fields")
  end

  for key, fieldValue in pairs(value) do
    if type(fieldValue) ~= "number" then
      return fail(fieldPath(path, tostring(key)), "must be a number")
    end
  end

  return true
end

function M.new(normalizeStep, getSequence)
  local validateSequence

  local function validateStep(step, path)
    local normalized = normalizeStep(step)
    if type(normalized) ~= "table" then
      return fail(path, "must be a valid step")
    end

    local kind = normalized.kind or "emit"
    if not STEP_KINDS[kind] then
      return fail(path, "unknown kind '" .. tostring(kind) .. "'")
    end

    if kind == "animate" then
      local ok, err = validateNumberMap(normalized.to, fieldPath(path, "to"))
      if not ok then
        return ok, err
      end
      ok, err = validateNumberMap(normalized.from, fieldPath(path, "from"))
      if not ok then
        return ok, err
      end
      if normalized.duration ~= nil and type(normalized.duration) ~= "number" then
        return fail(fieldPath(path, "duration"), "must be a number")
      end
      if normalized.delay ~= nil and type(normalized.delay) ~= "number" then
        return fail(fieldPath(path, "delay"), "must be a number")
      end
    elseif kind == "spring" then
      local ok, err = validateNumberMap(normalized.to, fieldPath(path, "to"))
      if not ok then
        return ok, err
      end
      ok, err = validateNumberMap(normalized.pull, fieldPath(path, "pull"))
      if not ok then
        return ok, err
      end
      ok, err = validateNumberMap(normalized.from, fieldPath(path, "from"))
      if not ok then
        return ok, err
      end
      if normalized.to == nil and normalized.pull == nil then
        return fail(path, "spring step requires 'to' or 'pull'")
      end
      for _, field in ipairs({ "stiffness", "k", "damping", "d", "settle", "epsilon", "duration" }) do
        if normalized[field] ~= nil and type(normalized[field]) ~= "number" then
          return fail(fieldPath(path, field), "must be a number")
        end
      end
    elseif kind == "wait" or kind == "pause" then
      if normalized.duration ~= nil and type(normalized.duration) ~= "number" then
        return fail(fieldPath(path, "duration"), "must be a number")
      end
      if normalized.time ~= nil and type(normalized.time) ~= "number" then
        return fail(fieldPath(path, "time"), "must be a number")
      end
    elseif kind == "audio" then
      if normalized.cue == nil or normalized.cue == "" then
        return fail(path, "audio step requires cue")
      end
    elseif kind == "callback" then
      local callback = normalized.callback or normalized.fn or normalized[1]
      if type(callback) ~= "function" then
        return fail(path, "callback step requires a function")
      end
    elseif kind == "play" then
      local sequence = childSequence(normalized)
      if sequence == nil or sequence == false then
        return fail(path, "play step requires a sequence")
      end
      return validateSequence(sequence, fieldPath(path, "sequence"))
    elseif kind == "parallel" then
      local children = normalized.steps or normalized.sequences or normalized[1]
      if not isSequenceArray(children) then
        return fail(path, "parallel step requires a non-empty array of steps")
      end
      for index, child in ipairs(children) do
        local ok, err = validateSequence(child, arrayPath(fieldPath(path, "steps"), index))
        if not ok then
          return ok, err
        end
      end
    elseif kind == "repeat" then
      local count = normalized.count or normalized.times
      if count ~= nil and type(count) ~= "number" then
        return fail(fieldPath(path, "count"), "must be a number")
      end
      local sequence = childSequence(normalized)
      if sequence == nil or sequence == false then
        return fail(path, "repeat step requires a sequence")
      end
      return validateSequence(sequence, fieldPath(path, "sequence"))
    elseif kind == "random" then
      local options = normalized.options or normalized[1]
      if not isSequenceArray(options) then
        return fail(path, "random step requires a non-empty options array")
      end
      for index, option in ipairs(options) do
        if type(option) ~= "table" then
          return fail(arrayPath(fieldPath(path, "options"), index), "must be an option table")
        end
        if option.weight ~= nil and type(option.weight) ~= "number" then
          return fail(fieldPath(arrayPath(fieldPath(path, "options"), index), "weight"), "must be a number")
        end
        if option.chance ~= nil and type(option.chance) ~= "number" then
          return fail(fieldPath(arrayPath(fieldPath(path, "options"), index), "chance"), "must be a number")
        end
        local sequence = option.step or option.sequence or option.steps or option[1]
        if sequence == nil or sequence == false then
          return fail(arrayPath(fieldPath(path, "options"), index), "random option requires a sequence")
        end
        local ok, err = validateSequence(sequence, arrayPath(fieldPath(path, "options"), index))
        if not ok then
          return ok, err
        end
      end
    end

    return true
  end

  validateSequence = function(value, path)
    path = path or "sequence"

    if value == nil or value == false then
      return fail(path, "must be a sequence")
    end

    if type(value) == "string" then
      local sequence = getSequence(value)
      if not sequence then
        return fail(path, "unknown sequence '" .. value .. "'")
      end
      return validateSequence(sequence, path)
    end

    if type(value) == "function" or type(value) ~= "table" then
      return validateStep(value, path)
    end

    if value.kind or value.to or value.from or value.duration or value.ease then
      return validateStep(value, path)
    end

    if not isSequenceArray(value) then
      return validateStep(value, path)
    end

    for index, step in ipairs(value) do
      local ok, err = validateStep(step, arrayPath(path, index))
      if not ok then
        return ok, err
      end
    end

    return true
  end

  return validateSequence
end

return M
