# 5‑Minute Tutorial: Destructible Crate

Break feedback that scales: start with a health-aware crate, layer in texture wear, deform the mesh, and finish with a loot or FX payoff. You’ll ship with a flexible config that lets designers mix and match texture swaps, mesh swaps, or both.

## What you're building
- Step 1: A crate that tracks health and reacts to hits (script.lua)
- Step 2: Texture/SurfaceAppearance swaps driven by damage thresholds (steps/02)
- Step 3: Mesh swaps so the silhouette dents and collapses (steps/03)
- Step 4: Reward or effect spawn on full break (steps/04)
- Designer toggles baked into the final script so you can choose texture, mesh, or hybrid visuals per instance

## What's in here
- [script.lua](./script.lua) — baseline health + damage handling with config flags for visuals/reward
- [steps/](./steps) — incremental upgrades
  - `01-damage-ready-crate.lua` — takes damage, updates health, fires events
  - `02-add-wear-textures.lua` — adds texture/surface appearance swaps on thresholds
  - `03-swap-damaged-meshes.lua` — swaps mesh variants alongside textures
  - `04-reward-on-destroy.lua` — spawns loot/FX and cleans up on zero health
- [wiki.md](./wiki.md) — Roblox services/components that power destructible props
- [use-cases.md](./use-cases.md) — where destructible crates shine in games

## Before you start
- Place a MeshPart crate (or a Model with `PrimaryPart`) in the workspace
- Import 2–3 texture or `SurfaceAppearance` variants (clean, cracked, broken)
- Import 2–3 MeshPart variants that share pivot + size (pristine, dented, smashed)
- Optional: add a `ParticleEmitter`, `Sound`, or loot Model to the crate for the reward moment
- Decide whether crates reset (respawn/regen) or stay broken so you can wire reset logic later

## Get it working (2–4 minutes)
Step 1 — Health + damage (script.lua)
1) Insert a Script into your crate MeshPart/Model and paste `script.lua`.
2) Set `CONFIG.MAX_HEALTH` and `CONFIG.DAMAGE_PER_HIT` to match your weapon.
3) Trigger `script:FindFirstChild("Damage")` (BindableEvent) or call `TakeDamage` from your weapon/projectile.
4) Playtest and watch the Output: health prints and `CrateDamaged` events fire on hit.
5) Confirm the crate anchors/unanchors correctly so physics stay stable when hits land.

Step 2 — Texture wear (steps/02-add-wear-textures.lua)
1) Swap in `steps/02-add-wear-textures.lua`.
2) Populate `CONFIG.TEXTURE_STAGES` with your `SurfaceAppearance` or texture asset ids.
3) Adjust thresholds (values between 0 and 1) so scratches and cracks appear when you expect.
4) Playtest and confirm the crate swaps clean → cracked → broken textures as health falls.

Step 3 — Mesh damage (steps/03-swap-damaged-meshes.lua)
1) Use `steps/03-swap-damaged-meshes.lua`.
2) Fill `CONFIG.MESH_STAGES` with mesh asset ids (same order as texture stages).
3) Make sure each mesh keeps identical pivot/size so physics don’t pop when swapping.
4) Playtest and check that the silhouette dents, collapses, or breaks at the right thresholds.

Step 4 — Reward moment (steps/04-reward-on-destroy.lua)
1) Use `steps/04-reward-on-destroy.lua`.
2) Drop a loot Model or FX folder under the script and set `CONFIG.REWARD_TEMPLATE` / `CONFIG.BREAK_EFFECT`.
3) Customize `spawnReward` to drop loot, emit particles, or both.
4) Test a full break: reward spawns, FX play, and the crate removes itself after the delay.

## Designer choice toggles
- `USE_TEXTURE_SWAPS` — cheaper, ideal for many crates or mobile targets
- `USE_MESH_SWAPS` — heavier but dramatic; reserve for hero props
- `RESET_MODE` — choose between automatic regen, manual reset via event, or permanent destruction

Mix and match: leave textures on for background crates, enable mesh swaps for the single hero crate in the center of your arena.
