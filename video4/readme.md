# Spinning Platform — 5‑minute tutorial

A Part that spins smoothly forever. Perfect for obbies, pedestals, gears, or rides.

## Files in this tutorial

- [script.lua](script.lua) — simple, copy‑paste spinner
- [script.extended.lua](script.extended.lua) — presets, click control, RemoteEvent, attributes
- [wiki.md](wiki.md) — tiny study links you’ll actually use
- [use-cases.md](use-cases.md) — 4 quick ideas to plug into your game

## Try it

1) Make a Part in Workspace (the thing to spin).
2) Insert a Script inside the Part and paste `script.lua`.
3) Hit Play — your Part spins.

## Then explore

- Swap to `script.extended.lua` to get speed presets and click to cycle.
- Change AXIS to X|Y|Z for different rotation feels.
- The extended script auto-creates a RemoteEvent named "SpinChanged" (clients can listen for VFX).
- Attributes are set so other scripts can react (SpeedSec, Axis, Direction).

Use this for obstacles, showcases, windmills, and puzzle mechanics.