# Speed Boost Strip — 5‑minute tutorial

A Part that gives temporary WalkSpeed boost, then restores normal speed.

## Files in this tutorial

- [script.lua](script.lua) — simple, copy‑paste booster
- [steps/](steps) — incremental checkpoints aligned to use-cases (01 → 02)
- [wiki.md](wiki.md) — tiny study links
- [use-cases.md](use-cases.md) — 4 quick ideas

## Try it

1) Make a flat Part (the boost strip).
2) Insert Script and paste `script.lua`.
3) Walk over it — you speed up, then revert.

## Then explore

- Walk through `steps/` in order:
  - 01 attributes-cooldown → 02 remoteevent

## Which step for which use-case?
- Racing catch‑up → Step 01 (adjust attributes dynamically)
- Risk lane → Step 01 (short cooldown)
- Combo chain → Step 02 (listen to `SpeedBoost` to drive combo UI)
- Boost meter UI → Step 02 (use event to render duration bar)

Use for racing catch‑ups, parkour bursts, and timed puzzles.