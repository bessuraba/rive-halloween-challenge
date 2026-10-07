# The Lurker: handoff for "Human Touch" polish

A shadow creature with a pale grin and glowing eyes, standing in moonlit fog.
Built entirely in RML, Luau and WGSL. Everything below was checked with
`rive . --verify`, `rive inspect . --json` (problems: none) and `--screenshot`.

## What's in the project

| File | What it is |
|---|---|
| `scene.rml` | Artboard `Lurker` (500x500): character, moon, backdrop, state machine, `Idle` and `Scare` animations, `Lurker` view model |
| `fogfx.wgsl` | Fragment shader: domain-warped fbm ground fog and ghost wisps. Takes `time` and `scare` uniforms |
| `fog.luau` | Layout script: runs `fogfx.wgsl` into a GPU canvas and draws it across the artboard |

## How it behaves

- **Idle** (240 frames, loops): the Lurker floats, the head sways, the arms
  drift, the eyes blink twice, the eye glow pulses and the foreground fog drifts.
- **Hover** the creature: listeners set the view model `hover` to `true`, which
  fires the state machine into **Scare** (40 frames, loops). The eyes go huge,
  the pupils shrink, the mouth gapes, the arms fling up, the head shakes and the
  creature lunges. The WGSL fog also turns sickly green and churns faster,
  because `hover` is bound into the script's `scared` input.
- Pointer **exit** returns to Idle with a 300 ms blend.

## Verified

- `rive . --verify`: 0 errors, 0 warnings. `rive inspect`: no problems.
- Screenshots at rest, on hover and after hover ends. The fog colour changing on
  hover proves the pointer, view model, script input and shader uniform chain.

## Known limits (deliberate)

- **No `Feather` effects.** The headless renderer has no interlock support, so
  feather did not render in screenshots. Glows are radial gradients instead,
  which render everywhere.
- Fog was only checked at `@1x`. `--screenshot` cannot catch a wrong device
  scale, so look at it in the live window on a HiDPI display.
- Audio is not wired up. A creak or a sting on Scare would help a lot.

## Ideas for the Human Touch pass in the Rive Editor

1. **Character design.** Redraw the head and cloak with hand-tuned vector
   nodes: a more unsettling silhouette, uneven eyes, a lopsided grin.
2. **Animation feel.** Hand-tune the easing on the Scare pop-in, add anticipation
   (a quick recoil before the lunge), and add overshoot and settle.
3. **Timing and personality.** Offset the eyes' blink timing, add an eyes-follow
   -the-pointer look, and add a rare random "twitch" in Idle.
4. **Sound and polish.** Add an `AudioEvent` sting on Scare, and a vignette.
5. **Check the shader in context.** Tweak `fogfx.wgsl` colours and density to
   taste; the `calm` and `angry` vec3 constants are the quickest knobs.

## Getting it into the Editor

Both need `rive login` (opens a browser; the session persists):

```bash
rive login
rive push rive-halloween      # sends it to your Rive workspace as a new file
```

Or run `rive rive-halloween` for the live previewer while you iterate.
`rive push` uploads to your account, so it was not run for you.
