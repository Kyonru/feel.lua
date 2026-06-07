# feel.lua + Menori Demo

Small LOVE project showing `feel.menori` with [rozenmad/Menori](https://github.com/rozenmad/Menori).

Run it from the repository root:

```sh
love examples/menori
```

Controls:

- `Space` / left click: play node, camera, animation, uniform, screen, and post feedback.
- `O`: switch the satellite animation action between tight and wide orbit.
- `F`: boost the satellite animation speed, then ease it back.
- `S`: seek the animation controller to a random time.
- `A`: pause/resume the animation controller.
- `U`: pulse material uniforms without changing node transforms.
- HUD `SLOW` button / `1`: toggle slow motion.
- HUD `PAUSE` button / `2`: toggle paused gameplay time.
- `P`: play a post-processing focus pass with grade and vignette.
- `C`: clear post-processing and screen overlays.
- `R`: reset animated targets.
- `Esc`: quit.

The demo keeps Menori ownership intact: meshes are generated with Menori shapes, nodes render through `scene:render_nodes`, and `feel.menori` only applies animated target values to Menori nodes, the perspective camera, an animation-controller-like object, and material uniforms. `feel.love` wraps the Menori render pass in `fx:drawPost(...)`, so post effects affect the 3D scene while the HUD stays crisp.
