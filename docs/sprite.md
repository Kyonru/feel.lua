---
icon: lucide/person-standing
---

# Sprite Effects

`feel.sprite` adds reusable 2D sprite reactions without owning a renderer, spritesheet, or
animation clock. It produces ordinary Feel target values that compose with your existing
position, rotation, scale, tint, and opacity.

```lua
local feel = require("feel")
local Sprite = require("feel.sprite")

local spriteFx = Sprite.target()

function love.update(dt)
  feel.update(dt)
end

function love.draw()
  Sprite.draw(spriteFx, {
    x = player.x,
    y = player.y,
    scaleX = player.facingLeft and -1 or 1,
  }, function(pose)
    love.graphics.push("all")
    love.graphics.setColor(pose.tintR, pose.tintG, pose.tintB, pose.opacity)
    love.graphics.draw(image, pose.x, pose.y, pose.rotation, pose.scaleX, pose.scaleY, ox, oy)
    love.graphics.pop()
  end)
end
```

Offsets and rotation are added to the base pose. Scale, opacity, and tint are multiplied, so
existing sprite flips and fades remain intact. `flash`, `glow`, and `outline` use the strongest
base/effect value and can be sent to your own shader.

## Built-in Effects

Play a semantic effect against the sprite target:

```lua
Sprite.play(spriteFx, "hitLight", { x = -5 })
Sprite.play(spriteFx, "hitHeavy", { x = -12, rotation = -0.08 })
Sprite.play(spriteFx, "land", { squash = 0.22 })
```

Available effects are:

| Effect | Use |
| --- | --- |
| `hitLight` | Brief recoil, squash, and flash |
| `hitHeavy` | Larger two-stage impact with outline |
| `land` | Landing squash and overshoot |
| `recoil` | Directional position/rotation recovery |
| `wobble` | Decaying rotational wobble |
| `blink` | Repeated invulnerability-style opacity blink |
| `spawn` | Scale, fade, and glow in |
| `despawn` | Scale, fade, and glow out |
| `chargePulse` | Scale, glow, and outline pulse |

`Sprite.sequence(name, opts)` returns the ordinary Feel sequence behind an effect when you
want to extend it. `Sprite.list()` returns all registered names, and `Sprite.reset(target)`
cancels active work and restores a neutral pose.

## Allocation-Free Pose Composition

Pass an output table when composing every frame to avoid allocations:

```lua
local pose = {}

function love.draw()
  Sprite.pose(spriteFx, {
    x = player.x,
    y = player.y,
    rotation = player.rotation,
  }, pose)

  drawPlayer(pose)
end
```

The same output table can be passed as the fourth argument to `Sprite.draw`.

## Anim8 Helper

The optional `feel.sprite.anim8` helper adapts the composed pose to Anim8's public `draw`
method. It does not import Anim8, update it, select frames, or inspect its internals.

```lua
local Sprite = require("feel.sprite")
local SpriteAnim8 = require("feel.sprite.anim8")

local spriteFx = Sprite.target()
local pose = {}

function love.update(dt)
  animation:update(dt) -- Anim8 owns frame timing
  feel.update(dt)      -- Feel owns temporary effects
end

function love.draw()
  SpriteAnim8.draw(animation, image, spriteFx, {
    x = player.x,
    y = player.y,
    scaleX = player.facingLeft and -1 or 1,
    originX = frameWidth / 2,
    originY = frameHeight / 2,
    pose = pose,
  })
end
```

The helper applies tint and opacity, invokes `animation:draw`, and restores LOVE's graphics
state. Flash, glow, outline, shaders, animation switching, playback speed, and frame callbacks
remain app-owned.

## Integration Boundary

This division prevents conflicts with Anim8 and other animation libraries:

- Your animation library owns frames, quads, looping, and playback speed.
- Your game owns world position, facing direction, and persistent transforms.
- Feel adds temporary offsets and multipliers at draw time.
- Your renderer decides how flash, glow, outline, and shaders are drawn.

If two Feel effects animate the same value simultaneously, normal Feel stacking rules apply.
Use stable restart keys or build one combined recipe when those effects should replace each
other.
