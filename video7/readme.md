# 5‑Minute Tutorial: Destructible Crate

Build a sealed crate that reacts to hits, deforms visually, tracks damage, and breaks into flying pieces. This lesson covers SurfaceAppearance texture swapping and EditableMesh for real vertex deformation.

## What you're building
- Step 0: Sealed crate with hit detection + impact SFX (smoke test)
- Step 1: Texture modification — cycle through pre-made SurfaceAppearance skins
- Step 2: Real deformation — dent the mesh using EditableMesh vertex manipulation
- Step 3: Damage system — integrity value drives crack density + dent depth, health bar UI
- Step 4: Break + destruction — crate shatters into procedural chunks with physics

## What's in here
- [script.lua](./script.lua) — Sealed crate (hit detection + SFX only)
- [steps/](./steps) — upgrades
  - `01-texture-modification.lua` — SurfaceAppearance texture cycling
   - `02-mesh-deformation.lua` + `02-mesh-deformation-client.lua` — EditableMesh vertex denting (client script is reused for Steps 2–4)
   - `03-damage-system.lua` — Integrity-driven visuals with health bar
   - `04-break-and-loot.lua` — Final break with procedural chunks (no loot system)
- [wiki.md](./wiki.md) — the Roblox APIs that matter here
- [use-cases.md](./use-cases.md) — ideas to drop into your game

## Before you start

### Required Assets
1. **MeshPart for the crate**
   - Must be a low-poly mesh (8–100 vertices recommended)
   - **You must own the mesh** to use EditableMesh (Steps 2-4)
   - Simple cube or box shape works best for learning
   
2. **SurfaceAppearance textures** (for Steps 1-4)
   - Create a folder named `CrateSkins` in `ReplicatedStorage`
   - Add 3+ `SurfaceAppearance` objects named `Skin1`, `Skin2`, `Skin3`, etc.
   - Each should have different `ColorMap` textures to show damage progression

3. **Sound assets** (optional but recommended)
   - **Impact sound** — Used in all steps (Step 0-4) for hit feedback
     - Examples: wood thunk, metal clang, rock impact
     - Config: `IMPACT_SOUND_ID`
   - **Break sound** — Only needed for Step 4 (final destruction)
     - Examples: wood splinter, glass shatter, crate crunch
     - Config: `BREAK_SOUND_ID`
   - Upload sounds to Roblox and use their `rbxassetid://` URLs in the CONFIG

### Client Scripts Setup
Steps 2-4 require a client LocalScript in `StarterPlayer > StarterPlayerScripts`:
- **Step 2-4:** Add `02-mesh-deformation-client.lua` and keep it for all subsequent steps
  - This single script handles all client-side mesh deformation
  - Do not replace or remove it when advancing to Steps 3-4

**Note:** EditableMesh manipulation **must** run client-side. The server scripts handle game logic and fire RemoteEvents to clients for visual effects.

## Get it working (4–6 minutes)

### Step 0 — Hit Detection (script.lua)
1. Insert a MeshPart named `Crate` into `workspace`.
2. Add a Script inside it, paste [script.lua](./script.lua).
3. Replace `IMPACT_SOUND_ID` with your sound asset ID.
4. Play. Click the crate; you should hear impact sounds and see shake animation.

### Step 1 — Texture Cycling (steps/01-texture-modification.lua)
1. **Precondition:** Create `ReplicatedStorage/CrateSkins` folder with `SurfaceAppearance` objects.
2. Replace the Script with [steps/01-texture-modification.lua](./steps/01-texture-modification.lua).
3. Update `CONFIG.SKIN_NAMES` to match your SurfaceAppearance names.
4. Play and click. The crate cycles through skins on each hit.

### Step 2 — Mesh Deformation (steps/02-mesh-deformation.lua)
1. **Preconditions:**
   - Your MeshPart uses a mesh you own (required for EditableMesh)
   - Add [steps/02-mesh-deformation-client.lua](./steps/02-mesh-deformation-client.lua) to `StarterPlayer > StarterPlayerScripts`
2. Replace the crate Script with [steps/02-mesh-deformation.lua](./steps/02-mesh-deformation.lua).
3. Play and click. The surface dents inward at random points.
4. Tune `CRACK_STRENGTH` in the client script (default 1.2).

### Step 3 — Damage System (steps/03-damage-system.lua)
1. **Preconditions:**
   - Keep the client script from Step 2 (do not remove or replace it)
2. Replace the crate Script with [steps/03-damage-system.lua](./steps/03-damage-system.lua).
3. Set `CONFIG.MAX_HITS = 3` (or higher) for difficulty.
4. Play and click. Health bar appears, changes color (green → yellow → red), cracks intensify.
5. Health bar auto-hides after 3 seconds, reappears on next hit.

### Step 4 — Break + Destruction (steps/04-break-and-loot.lua)
1. **Preconditions:**
   - Keep the client script from Step 2 (do not remove or replace it)
   - Replace `BREAK_SOUND_ID` in CONFIG with your break sound asset
2. Replace the crate Script with [steps/04-break-and-loot.lua](./steps/04-break-and-loot.lua).
3. Adjust `CONFIG.CHUNK_COUNT`, `CHUNK_COLOR`, and `CHUNK_IMPULSE` for your aesthetic.
4. Play and break the crate. Procedural chunks spawn and scatter with physics.

## Upgrade path
1. Start with `script.lua` (hit detection + shake + sound)
2. Add texture swapping via `01-texture-modification.lua`
3. Add mesh dents via `02-mesh-deformation.lua` + client
4. Add damage tracking + health bar via `03-damage-system.lua` + client
5. Complete with destruction/chunks via `04-break-and-loot.lua` + client

Keep the mesh simple and iterate: crack strength, chunk count, health bar timing.
