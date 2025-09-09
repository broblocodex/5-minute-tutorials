# 5‑Minute Tutorial: Animated NPC

Start simple: play a standing idle animation on an NPC. Then upgrade to random walking with smooth rotation/grounding. Finally, add jump support with a jump animation.

## What you're building
- Step 0: Idle-only NPC (verify rig + animations play)
- Step 1: Random walker between Parts under `workspace.Waypoints` (with smooth rotate + ground snap)
- Step 2: Walker that hops where paths require a jump (with optional jump animation)
- Step 3: Optional tracing overlay to visualize waypoints/routes for debugging

## What's in here
- [script.lua](./script.lua) — Idle-only (standing/idle animation)
- [steps/](./steps) — upgrades
  - `01-random-walker.lua` — Walk (no jumps)
  - `02-walker-with-jump.lua` — Walk + Jump
  - `03-visualize-waypoints.lua` — Visual tracer for waypoints/routes (debugging aid)
- [wiki.md](./wiki.md) — the Roblox APIs that matter here
- [use-cases.md](./use-cases.md) — ideas to drop into your game

## Before you start
- Put your NPC Model in the workspace
  - It must have `PrimaryPart` set
  - It must have `AnimationController` → `Animator`
- Optional (recommended): Upload/own two animations — a looping Walk and a looping Idle. Replace `WALK_ANIM_ID` and `IDLE_ANIM_ID` in the scripts.

Animation setup is out of scope here — use your favorite rig. If you need help, find a short setup tutorial on our channel and subscribe: https://www.youtube.com/@broblocodex

## Get it working (2–4 minutes)
Step 1 — Idle test (script.lua)
1) Insert a Script into your NPC model, paste `script.lua`.
2) Replace `IDLE_ANIM_ID` with your asset id (optional; uses placeholder otherwise).
3) Play. NPC should stand and loop the idle.

Step 2 — Walking (steps/01-random-walker.lua)
1) Create a Folder named `Waypoints` in `workspace`.
2) Add a few Parts inside it (spread them around).
3) **Important waypoint setup**: For each waypoint Part:
   - Set `Anchored = true` (prevents them from falling)
   - Set `CanCollide = false` (NPCs can walk through them)
4) Replace the Script with `steps/01-random-walker.lua`.
5) Replace `WALK_ANIM_ID`/`IDLE_ANIM_ID` as needed. Play to see wandering.

Step 3 — Jumping (steps/02-walker-with-jump.lua)
1) Use `02-walker-with-jump.lua`.
2) Optionally set `JUMP_ANIM_ID`.
3) Ensure your paths require jumps (gaps/steps); the NPC will hop when near jump waypoints.

Step 4 — Tracing (debug visualization)
1) Open `steps/03-visualize-waypoints.lua` and copy the entire `renderPathWaypoints` function.
2) Paste it into your current script (after the `hop` function, before the `follow` function).
3) Inside the `follow` function, add this line right after the `jumpUntil = 0` line:
   ```lua
   renderPathWaypoints(character, waypoints, goalPos)
   ```
4) This renders neon spheres and beams showing the pathfinding waypoints and routes.
5) Use this to tune speed/turn/stop distance or verify jump spots.
6) Remove the function and its call when you're done debugging.

## Upgrade path
- Start with `script.lua` (idle)
- Add walking via `steps/01-random-walker.lua`
- Add jumping via `steps/02-walker-with-jump.lua`
- Optional: add tracing by copying the visualization function into your current script

Keep the numbers small and iterate: speed, turn rate, stop distance, idle ranges.
