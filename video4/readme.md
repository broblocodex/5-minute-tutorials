# Spinning Platform — 5‑minute tutorial

A Part that spins smoothly forever. Perfect for obbies, pedestals, gears, or rides.

## Files in this tutorial

- [script.lua](script.lua) — simple, copy‑paste spinner
- [steps/](steps) — incremental checkpoints aligned to use-cases (01 → 02)
- [wiki.md](wiki.md) — tiny study links you’ll actually use
- [use-cases.md](use-cases.md) — 4 quick ideas to plug into your game

## Try it

1) Make a Part in Workspace (the thing to spin).
2) Insert a Script inside the Part and paste `script.lua`.
3) Hit Play — your Part spins.

## Then explore

- Walk through `steps/` in order:
  - 01 attributes-presets → 02 remoteevent

## Which step for which use-case?
- Obby timing gate → Step 01 (update SpeedSec)
- Team advantage switch → Step 01 (flip Direction)
- Camera-friendly display pedestal → Step 01 (attributes), optionally Step 02 for client VFX
- Danger blade → Step 02 (SpinChanged listener on client)

Use this for obstacles, showcases, windmills, and puzzle mechanics.