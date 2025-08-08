# Disappearing Bridge — 5‑minute tutorial

A Part that vanishes when stepped on, then comes back after a delay.

## Files in this tutorial

- [script.lua](script.lua) — simple, copy‑paste bridge
- [script.extended.lua](script.extended.lua) — attributes, RemoteEvent, sounds
- [wiki.md](wiki.md) — tiny study links
- [use-cases.md](use-cases.md) — 4 quick ideas

## Try it

1) Make a thin Part (a bridge tile).
2) Insert a Script inside it and paste `script.lua`.
3) Walk on it — it fades out, disables collision, then respawns.

## Then explore

- Swap to `script.extended.lua` for Attributes and a `BridgeState` RemoteEvent.
- Tune timing live via Attributes: DisappearDelay, RespawnDelay, FadeTime.
- Add optional Sounds named `WarnSound` and `RespawnSound` under the Part.

Use this for obbies, chase scenes, and timed puzzle paths.