# Teleporter Portal — 5‑minute tutorial

A portal Part that moves players to another Part instantly.

## Files in this tutorial

- [script.lua](script.lua) — simple, copy‑paste teleporter
- [script.extended.lua](script.extended.lua) — cooldown, orientation, sound, RemoteEvent, attributes
- [wiki.md](wiki.md) — tiny study links you’ll actually use
- [use-cases.md](use-cases.md) — 4 quick ideas to plug into your game

## Try it

1) Make two Parts anywhere in Workspace (your two portals).
2) In each portal Part, insert an ObjectValue named Target and set it to the other Part.
3) Insert a Script inside each portal Part and paste `script.lua`.
4) Play. Step on a portal to jump to its Target.

## Then explore

- Swap to `script.extended.lua` to get per‑player cooldown, optional sound, and clean hooks.
- Set PRESERVE_ORIENTATION to keep the player’s facing when arriving.
- Gate access with a Player attribute (for keys/quests).
- Add a RemoteEvent named "Teleported" under the portal for client VFX.

Great for hubs, fast travel, puzzle rooms, and secret doors.