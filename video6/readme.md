# 5‑Minute Tutorial: Animated Melee Combo

Turn your avatar into a fighter. Start with a single kick that plays on key press. Then gate the hit using animation markers, hook it to server-side damage, branch into a three-move combo, and finish with cooldowns, impact audio, and knockback.

## What you're building
- Step 1: **First Move** — trigger one uploaded kick animation from a LocalScript
- Step 2: **Contact Moment** — only register hits on the animation's "Hit" marker window
- Step 3: **Real Damage** — validate hits on the server and subtract health
- Step 4: **Combo Variety** — rotate through right kick, left kick, and punch animations
- Step 5: **Polished Fighter** — add cooldowns, hit sounds, and knockback for feedback

## What's in here
- [script.lua](./script.lua) — Step 1 (First Move) LocalScript for a single kick
- [steps/02-contact-moment.lua](./steps/02-contact-moment.lua) — add timing and a local hitbox
- [steps/03-real-damage.lua](./steps/03-real-damage.lua) — client + server scripts for real damage
- [steps/04-combo-variety.lua](./steps/04-combo-variety.lua) — multi-move combo system
- [steps/05-polished-fighter.lua](./steps/05-polished-fighter.lua) — cooldowns, knockback, and SFX polish
- [wiki.md](./wiki.md) — the Roblox APIs you'll lean on here
- [use-cases.md](./use-cases.md) — ideas to drop this melee kit into your game

## Before you start
- Upload at least one kick animation (`rbxassetid://...`) and note the id
- Optional for later steps: upload matching left-kick and punch animations with a marker named `Hit`
- Decide where to place scripts:
  - LocalScripts go into `StarterPlayerScripts`
  - Server scripts go into `ServerScriptService`
- (Step 2+) The rig should expose parts named `RightFoot`, `LeftFoot`, and `RightHand` (R15 default)

## Get it working (5 minutes)
1. Insert a LocalScript under `StarterPlayerScripts` and paste `script.lua`
2. Replace `KICK_ANIM_ID` with your animation id
3. Press **F** in Play mode — your character should fire the kick animation

## Upgrade path
- **Step 01**: add a welded hitbox and limit hits to the `Hit` marker window
- **Step 01 → 02**: introduce a RemoteEvent so the server owns damage
- **Step 02 → 03**: define multiple moves (right/left kick + punch) with shared networking
- **Step 03 → 04**: layer in cooldowns, knockback impulses, and sound effects

Keep tweaking animation speed, contact windows, and knockback strength until it feels right for your game.
