# Speed Boost Strip — 5‑minute tutorial

A Part that gives temporary WalkSpeed boost, then restores normal speed.

## Files in this tutorial

- [script.lua](script.lua) — simple, copy‑paste booster
- [script.extended.lua](script.extended.lua) — attributes, per‑player cooldown, RemoteEvent
- [wiki.md](wiki.md) — tiny study links
- [use-cases.md](use-cases.md) — 4 quick ideas

## Try it

1) Make a flat Part (the boost strip).
2) Insert Script and paste `script.lua`.
3) Walk over it — you speed up, then revert.

## Then explore

- Swap to `script.extended.lua` for live tweak Attributes: BoostSpeed, BoostDuration, Cooldown.
- RemoteEvent `SpeedBoost` fires (player, boostSpeed, duration) for client VFX/UI.
- Add optional child Sound `BoostSound` for activation.

Use for racing catch‑ups, parkour bursts, and timed puzzles.