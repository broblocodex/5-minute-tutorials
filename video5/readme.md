# Disappearing Bridge — 5‑minute tutorial

A Part that vanishes when stepped on, then comes back after a delay.

## Files in this tutorial

- [script.lua](script.lua) — simple, copy‑paste bridge
- [steps/](steps) — incremental checkpoints aligned to use-cases (01 → 02)
- [wiki.md](wiki.md) — tiny study links
- [use-cases.md](use-cases.md) — 4 quick ideas

## Try it

1) Make a thin Part (a bridge tile).
2) Insert a Script inside it and paste `script.lua`.
3) Walk on it — it fades out, disables collision, then respawns.

## Then explore

- Walk through `steps/` in order:
  - 01 attributes → 02 remoteevent

## Which step for which use-case?
- Obby difficulty ramp → Step 01 (lower DisappearDelay progressively)
- Team path routing → Step 01 (set RespawnDelay per team)
- Warning UI countdown → Step 02 (listen for "warn")
- Chase scene effects → Step 02 (hook "vanish"/"respawn" for VFX)

Use this for obbies, chase scenes, and timed puzzle paths.