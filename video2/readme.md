# 5‑Minute Tutorial: Magic Jump Pad

Ever stepped on a trampoline? That's exactly what we're building, except in Roblox. Touch the pad, get launched into the air. It's physics made fun.

Here's why this matters: jump pads are everywhere in successful games. Obbies, racing games, battle arenas, speed runs — they all use this same core mechanic. Master this pattern, and you've got the foundation for tons of movement systems.

## What you're actually building
A Part that launches players upward (or forward) when touched. We start with basic physics, then add cooldowns and directional control.

Think of it as controlled chaos — predictable enough to be useful, exciting enough to be fun.

## What's in here
- [script.lua](./script.lua) — the dead simple version (start here)
- [steps/](./steps) — each step adds one new concept (01→02)
- [wiki.md](./wiki.md) — the Roblox docs that actually matter
- [use-cases.md](./use-cases.md) — real examples you can steal

## Get it working (2 minutes)
1. Drop a Part in your workspace (name it JumpPad)
2. Stick a Script inside it
3. Copy-paste the code from `script.lua`
4. Hit Play, step on the pad

If you go flying, you've nailed it. If not, check the Output window for errors.

## What to do next
**Start with real examples** — check out [use-cases.md](./use-cases.md) to see this basic pad turned into actual game features: race start gates, anti-spam cooldowns, forward flings, speed combos.

**Follow the upgrades** — as you build those examples, you'll need enhanced versions of the basic script. The [steps/](./steps) folder shows you how:

- **Step 01**: Add per-player cooldown (anti-spam)
- **Step 02**: Launch forward instead of just up

Each use-case tells you which step to use.

## Dive deeper
The [wiki.md](./wiki.md) has the Roblox docs you'll actually use. The [use-cases.md](./use-cases.md) shows you how to build real features with this pattern.

Copy the code. Break it. Fix it. That's how you learn.
