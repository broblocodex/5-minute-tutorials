# Real-world ideas for Destructible Crates

You’ve got a crate that bruises, breaks, and pays out. Drop it into your experience.

---

## 1) Loot Shower
- Use `steps/01-damage-ready-crate.lua`
- Tag crates with `CollectionService:AddTag(crate, "DailyCrate")`
- Randomize `CONFIG.REWARD_TEMPLATE` (coins, health, ammo) when the crate resets

Tip: Use `CrateDestroyed` to update a streak UI or battle pass quest.

---

## 2) Shortcut Gate
- Use `steps/02-add-wear-textures.lua`
- Place cracked crates blocking a side tunnel
- On break, lower collision so players dash through; optionally trigger a door animation

Tip: Swap to a low-profile mesh stage so players can visually read the new path.

---

## 3) Wave Defense Objective
- Use `steps/03-swap-damaged-meshes.lua`
- Spawn crates around an objective; enemies smash them to weaken defenses
- Broadcast `CrateDamaged` to defenders so they know which crate needs repairs

Tip: Let players patch up crates by calling `script.Reset:Invoke()` when they spend resources.

---

## 4) Environmental Storytelling
- Keep `USE_TEXTURE_SWAPS = true`, disable mesh swaps
- Drop damaged crates in raid aftermath scenes to show long-term wear
- Flip `RESET_MODE` to `Regen` so they heal between sessions

Tip: Vary texture stage thresholds per crate so the same damage looks different across the map.

---

Smash, reward, repeat. Mix mesh + texture swaps to match how dramatic (or performant) you need the scene to be.
