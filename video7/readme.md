# 5‑Minute Tutorial: Destructible Crate

Want a breakable prop that *feels real*? Build a sealed crate that reacts to hits, swaps damage textures, dents with EditableMesh, tracks integrity, then shatters into flying chunks.

## What you're actually building
A MeshPart “Crate” that takes hits and ramps up damage feedback until it breaks (textures → dents → health bar → destruction).

## What's in here
- [script.lua](./script.lua) — the dead simple version (hit + shake + impact SFX)
- [steps/](./steps) — upgrades (01→04)
- [wiki.md](./wiki.md) — the Roblox APIs that matter here
- [use-cases.md](./use-cases.md) — ideas you can steal

## Get it working (2 minutes)
1. Put a MeshPart named `Crate` in `workspace` (low‑poly is best).
2. Add a Script inside it and paste [script.lua](./script.lua).
3. Set `IMPACT_SOUND_ID` to your sound (`rbxassetid://...`).
4. Hit Play and click the crate.

If you hear the impact sound + see the shake, you're good.

## What to do next
**Start with real examples** — check out [use-cases.md](./use-cases.md) for ways to turn this into actual mechanics (breakable cover, mining nodes, loot piñatas, etc.).

**Follow the upgrades** — each step adds one concept:
- **Step 01**: Texture damage stages (SurfaceAppearance skin cycling)
   - Script: [steps/01-texture-modification.lua](./steps/01-texture-modification.lua)
   - Setup: add `ReplicatedStorage/CrateSkins` with `SurfaceAppearance` objects (ex: `Skin1`, `Skin2`, `Skin3`)
- **Step 02**: Real dents with EditableMesh (client-side)
   - Server: [steps/02-mesh-deformation.lua](./steps/02-mesh-deformation.lua)
   - Client: [steps/02-mesh-deformation-client.lua](./steps/02-mesh-deformation-client.lua) → `StarterPlayer > StarterPlayerScripts`
   - Note: you must own the mesh asset to use EditableMesh
- **Step 03**: Integrity + health bar UI + escalating crack strength
   - Script: [steps/03-damage-system.lua](./steps/03-damage-system.lua)
   - Keep the Step 02 client script
- **Step 04**: Break + destruction (procedural physics chunks)
   - Script: [steps/04-break-and-loot.lua](./steps/04-break-and-loot.lua)
   - Keep the Step 02 client script, set `BREAK_SOUND_ID`

EditableMesh manipulation must run client-side; server scripts handle hits/damage and fire events to clients for visuals.
