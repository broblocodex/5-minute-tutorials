# 5‑Minute Tutorial: Instant Teleporter

Remember Pac-Man? Those tunnels that zap you from one side of the screen to the other? That's exactly what we're building. Step on a portal, instantly appear somewhere else.

Here's the thing: teleporters solve so many game design problems. Need to connect distant areas? Portal. Want to create puzzle mechanics? Portal with conditions. Building a hub world? Portals everywhere. This one pattern unlocks tons of possibilities.

## What you're actually building
A Part that instantly moves players to another Part when touched. We start with basic teleportation, then add cooldowns and access controls.

Think of it as cutting holes in space — but safer and with fewer physics violations.

## What's in here
- [script.lua](./script.lua) — the dead simple version (start here)
- [steps/](./steps) — each step adds one new concept (01→03)
- [wiki.md](./wiki.md) — the Roblox docs that actually matter
- [use-cases.md](./use-cases.md) — real examples you can steal

## Get it working (2 minutes)
1. Drop two Parts in your workspace (these are your portals)
2. In each portal, add an ObjectValue named "Target"
3. Set each Target to point to the other portal
4. Drop a Script in each portal and paste `script.lua`
5. Hit Play, step on either portal

If you teleport between them, you've got it working. If you get stuck in the floor, adjust the height offset.

## What to do next
**Start with real examples** — check out [use-cases.md](./use-cases.md) to see this basic teleporter turned into actual game features: fast-travel hubs, key-locked portals, rotating puzzle doors.

**Follow the upgrades** — as you build those examples, you'll need enhanced versions of the basic script. The [steps/](./steps) folder shows you how:

- **Step 01**: Lock behind requirements (gated access)  
- **Step 02**: Add arrival effects (client events)

All the pieces you need to build teleportation that feels polished and professional.
