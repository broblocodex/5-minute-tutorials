# 5‑Minute Tutorial: Chameleon Block

You know that feeling when you press a button and something *actually happens*? That's what we're building here. Touch this block, watch it change color. Touch again — boom, different color. 

It's stupidly simple, but here's the thing: this little interaction is the foundation for 90% of game mechanics you'll ever build. Secret doors, boost pads, claim systems — they all start with "player touches thing, thing reacts."

## What you're actually building
A Part that cycles through colors when players touch it. We start with the bare minimum (literally 20 lines), then add the good stuff: debouncing touch spam, storing data, networking between scripts.

Think of it as your "Hello World" for game mechanics.

## What's in here
- [script.lua](./script.lua) — the dead simple version
- [steps/](./steps) — each step adds one new concept (01→04)
- [wiki.md](./wiki.md) — the Roblox docs that actually matter
- [use-cases.md](./use-cases.md) — real examples you can steal

## Get it working (2 minutes)
1. Drop a Part in your workspace (name it ColorBlock)
2. Stick a Script inside it
3. Copy-paste the code from `script.lua`
4. Hit Play, touch the block

## What to do next
**Start with real examples** — check out [use-cases.md](./use-cases.md) to see this basic block turned into actual game features: secret doors, boost pads, ownership systems, synchronized lighting.

**Follow the upgrades** — as you build those examples, you'll need enhanced versions of the basic script. The [steps/](./steps) folder shows you how:

- **Step 01**: Stop touch spam (debounce)
- **Step 02**: Remember state (attributes) 
- **Step 03**: Track who touched it last
- **Step 04**: Tell other scripts what happened

Each use-case tells you which step to use.

## Dive deeper
The [wiki.md](./wiki.md) has the Roblox docs you'll actually use. The [use-cases.md](./use-cases.md) shows you how to build real features with this pattern.

Copy the code. Break it. Fix it. That's how you learn.
