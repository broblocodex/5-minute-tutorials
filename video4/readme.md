# 5‑Minute Tutorial: Spinning Platform

You know that satisfying feeling when something in a game just *smoothly rotates forever*? That's what we're building here. A platform that spins continuously around any axis you choose.

It sounds basic, but this is actually the foundation for tons of game mechanics. Rotating obstacles, showcase pedestals, spinning traps, windmills — they all start with "make this thing rotate smoothly and controllably."

## What you're actually building
A Part that spins forever around any axis (X, Y, or Z). We start with the bare minimum (literally 25 lines), then add the good stuff: clickable speed presets, live attribute controls, network events for client effects.

Think of it as your "Hello World" for smooth mechanical movement.

## What's in here
- [script.lua](./script.lua) — the dead simple version
- [steps/](./steps) — each step adds one new concept (01→02)
- [wiki.md](./wiki.md) — the Roblox docs that actually matter
- [use-cases.md](./use-cases.md) — real examples you can steal

## Get it working (2 minutes)
1. Drop a Part in your workspace (name it Spinner)
2. Stick a Script inside it
3. Copy-paste the code from `script.lua`
4. Hit Play, watch it spin

## What to do next
**Start with real examples** — check out [use-cases.md](./use-cases.md) to see this basic spinner turned into actual game features: escalating obby challenges, team rivalry mechanics, showcase pedestals, warning systems.

**Follow the upgrades** — as you build those examples, you'll need enhanced versions of the basic script. The [steps/](./steps) folder shows you how:

- **Step 01**: Clickable speed presets + attribute controls
- **Step 02**: Network events for client visual effects

You'll use this pattern everywhere: obbies, showcases, mechanical puzzles, and any time you need something to rotate smoothly and reliably.