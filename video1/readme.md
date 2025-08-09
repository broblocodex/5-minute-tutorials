# Chameleon Block — 5‑minute tutorial

Touch it. It swaps color. Touch again. New color. Quick feedback, clear cause → effect.

## What you’ll build
- A Part that cycles through a palette when a player touches or clicks it.
- Starts simple. Then you try variations (sound, debounce, remote, gating).

## Files in this tutorial
- [script.lua](./script.lua) — the simplest version (start here)
- [steps/](./steps) — incremental checkpoints aligned to use-cases (01 → 04)
- [wiki.md](./wiki.md) — hand‑picked Roblox docs links
- [use-cases.md](./use-cases.md) — 4 quick ideas to apply it

## Try it (2 minutes)
1. Insert a Part.
2. Put a Script inside.
3. Paste `script.lua`.
4. Play and touch/click.

## Then explore (3 minutes)
- Walk through `steps/` in order:
    - 01 debounce → 02 attributes → 03 last-user-id → 04 remoteevent

## Which step for which use-case?
- Secret portal → Step 02 (ColorIndex)
- Time‑trial boost pad → Step 03 (LastUserId)
- Lamp color sync → Step 04 (RemoteEvent)
- Claimable nameplate lamp → Step 04 (RemoteEvent + LastUserId)

## Learn more
- Links live in `wiki.md`.
- See examples in `use-cases.md`.

Copy. Run. Tweak.