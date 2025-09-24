# 5‑Minute Tutorial: Patrol • Possess • Command NPCs

Import a custom Meshy NPC, make it patrol on its own, let players possess it with a click, then flip it into a loyal follower with UI buttons. Each step is self-contained, so you can stop at autonomous patrol or keep going until you have a polished squad command system.

## What you're building
- **Step 00** (`script.lua`): Attach Roblox's default idle/walk loops to your imported R15 humanoid.
- **Step 01** (`steps/01-walking-patrol.lua`): NPC patrols between waypoint Parts using `PathfindingService`.
- **Step 02** (`steps/02-possession-swap.server.lua` + `.client.lua`): Click to possess, WASD to drive, release to resume patrol.
- **Step 03** (`steps/03-follow-the-leader.server.lua` + `.client.lua`): Command NPCs to follow you or go back to patrol.
- **Step 04** (`steps/04-polished-control.server.lua` + `.client.lua`): UI buttons + keybinds, mode highlights, and SFX/VFX cues.

## What's in here
- [script.lua](./script.lua) — baseline animation harness to prove your rig works.
- [steps/](./steps) — server/client upgrades for each feature.
  - `01-walking-patrol.lua` — autonomous patrol loop.
  - `02-possession-swap.server.lua` / `.client.lua` — request/release control remotes and input handler.
  - `03-follow-the-leader.server.lua` / `.client.lua` — adds follow mode command.
  - `04-polished-control.server.lua` / `.client.lua` — UI + broadcast polish.
- [wiki.md](./wiki.md) — APIs you’ll touch (PathfindingService, RemoteEvent, Highlight, etc.).
- [use-cases.md](./use-cases.md) — drop-in ideas for real projects.

## Before you start
- Import your NPC as an **R15 Model** with a `Humanoid` and `HumanoidRootPart`.
- Duplicate Roblox's **default Animate** script into your NPC (or replace animation IDs in the scripts).
- Create a folder called **`PatrolWaypoints`** in `workspace` and drop a few anchored, non-colliding Parts inside.
- Create a **Folder** named `NPCControl` inside `ReplicatedStorage` with these `RemoteEvent` children:
  - `RequestPossess`
  - `ReleasePossess`
  - `MoveInput`
  - `CameraSwap`
  - (Step 03+) `SetMode`
  - (Step 04) `ModeBroadcast`

## Get it working (3–6 minutes)
### Step 0 — Rig smoke test (`script.lua`)
1. Insert a Script into your NPC model, paste `script.lua`.
2. Hit Play. NPC should idle. WalkSpeed > 16? It’ll swap to the default run animation automatically.

### Step 1 — Patrol route (`steps/01-walking-patrol.lua`)
1. Replace the Script with `01-walking-patrol.lua`.
2. Confirm `workspace.PatrolWaypoints` exists with Parts positioned along your desired patrol.
3. Play. NPC should path to each Part, pausing briefly between legs.

### Step 2 — Possession swap
1. Server: drop `steps/02-possession-swap.server.lua` into the NPC.
2. Client: drop `steps/02-possession-swap.client.lua` into `StarterPlayerScripts`.
3. Play in Studio. Click the NPC to possess, use WASD/Space, press **Q** to release. NPC returns to patrol when released.

### Step 3 — Follow command
1. Swap both scripts for the Step 03 versions.
2. In playtest, press **F** while pointing at the NPC to make it follow you. Press **E** to send it back to patrol.

### Step 4 — Polished control & UI
1. Swap both scripts for the Step 04 versions.
2. Play. Hover the NPC to reveal the toolbar. Buttons or keys **1/2/3** trigger Possess, Follow, Patrol.
3. Watch for highlight colors, sparkles, and audio cues on mode changes. Swap `MODE_SOUND_ID` / particle texture to fit your game.

### Tips
- Duplicate the NPC to create whole patrol teams — every copy listens to the same remotes.
- Update `FOLLOW_OFFSET` or `FOLLOW_DISTANCE` in the server scripts to tweak formation spacing.
- For click-to-possess with proximity prompts, fire the same `RequestPossess` remote from your prompt’s callback.
