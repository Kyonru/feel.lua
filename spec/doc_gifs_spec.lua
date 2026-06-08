package.path = "./?.lua;./?/init.lua;" .. package.path

local Manifest = require("scripts.doc_gifs.manifest")
local Markdown = require("scripts.doc_gifs.markdown")

describe("doc GIF manifest", function()
  it("validates the shipped manifest", function()
    local ok, err = Manifest.validate(Manifest.targets())
    assert.is_true(ok)
    assert.is_nil(err)
  end)

  it("rejects duplicate manifest IDs", function()
    local ok, err = Manifest.validate({
      { id = "shake", title = "Shake", alt = "Shake preview", duration = 1, docs = { "docs/a.md" } },
      { id = "shake", title = "Shake Again", alt = "Shake preview", duration = 1, docs = { "docs/b.md" } },
    })

    assert.is_false(ok)
    assert.is_truthy(err:match("duplicate manifest id"))
  end)
end)

describe("doc GIF Markdown updater", function()
  local target = {
    id = "shake",
    title = "Shake",
    alt = "Animated GIF showing camera shake.",
  }

  it("inserts missing managed feature blocks after the top-level heading", function()
    local input = table.concat({
      "---",
      "icon: lucide/gamepad-2",
      "---",
      "",
      "# LOVE Adapter",
      "",
      "Existing body.",
      "",
    }, "\n")

    local updated = assert(Markdown.upsertFeatureBlock(input, target, "docs/love-adapter.md"))

    assert.is_truthy(updated:match("# LOVE Adapter\n\n<!%-%- feel:feature%-gif shake %-%->"))
    assert.is_truthy(updated:match("Existing body%."))
    assert.is_truthy(updated:match("^%-%-%-\nicon: lucide/gamepad%-2\n%-%-%-"))
  end)

  it("replaces existing managed feature blocks idempotently", function()
    local input = table.concat({
      "# LOVE Adapter",
      "",
      "<!-- feel:feature-gif shake -->",
      "old",
      "<!-- /feel:feature-gif shake -->",
      "",
      "Body.",
      "",
    }, "\n")

    local once = assert(Markdown.upsertFeatureBlock(input, target, "docs/love-adapter.md"))
    local twice = assert(Markdown.upsertFeatureBlock(once, target, "docs/love-adapter.md"))

    assert.are.equal(once, twice)
    assert.is_truthy(once:match("!%[Animated GIF showing camera shake%.%]%(assets/feature%-gifs/shake%.gif%)"))
    assert.is_truthy(once:match("Body%."))
  end)

  it("leaves already-current feature Markdown unchanged", function()
    local block = Markdown.renderFeatureBlock(target, "docs/love-adapter.md")
    local input = "# LOVE Adapter\n\n" .. block .. "\n\nBody.\n"

    local updated = assert(Markdown.upsertFeatureBlock(input, target, "docs/love-adapter.md"))

    assert.are.equal(input, updated)
  end)

  it("inserts and replaces the managed gallery block", function()
    local targets = {
      target,
      { id = "flash", title = "Flash", alt = "Animated GIF showing a flash." },
    }
    local input = "# feel.lua Docs\n\nIntro.\n"

    local once = assert(Markdown.upsertGalleryBlock(input, targets, "docs/index.md"))
    local twice = assert(Markdown.upsertGalleryBlock(once, targets, "docs/index.md"))

    assert.are.equal(once, twice)
    assert.is_truthy(once:match("## Feature GIFs"))
    assert.is_truthy(once:match("assets/feature%-gifs/shake%.gif"))
    assert.is_truthy(once:match("assets/feature%-gifs/flash%.gif"))
    assert.is_truthy(once:match("Intro%.\n\n<!%-%- feel:feature%-gif%-gallery %-%->"))
    assert.is_truthy(once:match("<!%-%- /feel:feature%-gif%-gallery %-%->\n$"))
  end)

  it("moves existing managed gallery blocks to the end of the overview", function()
    local block = Markdown.renderGalleryBlock({ target }, "docs/index.md")
    local input = "# feel.lua Docs\n\n" .. block .. "\n\nIntro.\n"

    local updated = assert(Markdown.upsertGalleryBlock(input, { target }, "docs/index.md"))

    assert.is_truthy(updated:match("# feel%.lua Docs\n\nIntro%.\n\n<!%-%- feel:feature%-gif%-gallery %-%->"))
    assert.is_truthy(updated:match("<!%-%- /feel:feature%-gif%-gallery %-%->\n$"))
  end)

  it("rejects duplicate managed feature blocks", function()
    local input = table.concat({
      "# A",
      "",
      "<!-- feel:feature-gif shake -->",
      "one",
      "<!-- /feel:feature-gif shake -->",
      "",
      "<!-- feel:feature-gif shake -->",
      "two",
      "<!-- /feel:feature-gif shake -->",
    }, "\n")

    local updated, err = Markdown.upsertFeatureBlock(input, target, "docs/love-adapter.md")

    assert.is_nil(updated)
    assert.is_truthy(err:match("duplicate managed Markdown block"))
  end)

  it("rejects unterminated managed feature blocks", function()
    local input = "# A\n\n<!-- feel:feature-gif shake -->\nmissing close\n"

    local updated, err = Markdown.upsertFeatureBlock(input, target, "docs/love-adapter.md")

    assert.is_nil(updated)
    assert.is_truthy(err:match("unterminated managed Markdown block"))
  end)

  it("rejects duplicate managed gallery blocks", function()
    local input = table.concat({
      "# A",
      "",
      "<!-- feel:feature-gif-gallery -->",
      "one",
      "<!-- /feel:feature-gif-gallery -->",
      "",
      "<!-- feel:feature-gif-gallery -->",
      "two",
      "<!-- /feel:feature-gif-gallery -->",
    }, "\n")

    local updated, err = Markdown.upsertGalleryBlock(input, { target }, "docs/index.md")

    assert.is_nil(updated)
    assert.is_truthy(err:match("duplicate managed Markdown block"))
  end)

  it("computes relative asset paths for flat and nested docs pages", function()
    assert.are.equal(
      "assets/feature-gifs/shake.gif",
      Markdown.relativeAssetPath("docs/love-adapter.md", "docs/assets/feature-gifs/shake.gif")
    )
    assert.are.equal(
      "../assets/feature-gifs/shake.gif",
      Markdown.relativeAssetPath("docs/guides/love-adapter.md", "docs/assets/feature-gifs/shake.gif")
    )
  end)
end)
