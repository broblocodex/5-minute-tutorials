# Teleporter Portal — 5‑minute tutorial

A portal Part that moves players to another Part instantly.

## Files in this tutorial

- [script.lua](script.lua) — simple, copy‑paste teleporter
- [steps/](steps) — incremental checkpoints aligned to use-cases (01 → 03)
- [wiki.md](wiki.md) — tiny study links you’ll actually use
- [use-cases.md](use-cases.md) — 4 quick ideas to plug into your game

## Try it

1) Make two Parts anywhere in Workspace (your two portals).
2) In each portal Part, insert an ObjectValue named Target and set it to the other Part.
3) Insert a Script inside each portal Part and paste `script.lua`.
4) Play. Step on a portal to jump to its Target.

## Then explore

- Walk through `steps/` in order:
  - 01 cooldown → 02 gated-access → 03 remoteevent

## Which step for which use-case?
- Fast‑travel hub → `script.lua`
- Key‑locked portal → Step 02 (gated-access)
- Puzzle: rotate destinations → `script.lua` + snippet
- Party arrival VFX → Step 03 (remoteevent + client snippet)

Great for hubs, fast travel, puzzle rooms, and secret doors.