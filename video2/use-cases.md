# Real-World examples

Time to steal some ideas. You've got a pad that launches players — now let's turn it into features that make games memorable.

**Important:** Each snippet goes in its own Script. Don't try to mash them together — that way lies confusion and bugs.

---

## 1) Spawn area chaos control

**The idea:** Put jump pads in your spawn area for fun, but use cooldown to prevent new players from getting launched 5 times in one step and rage-quitting.

**Why cooldown matters:** Without it, stepping on the pad triggers from legs, arms, torso separately - players get launched way too high and it feels broken instead of fun.

**Setup:**
1. Use Step 01 (`steps/01-cooldown.lua`) - this is essential here
2. Place pads around spawn benches or waiting areas
3. Set `LAUNCH_FORCE` gentle (25-35) and `COOLDOWN` to 0.8s
4. Players get one smooth launch per step, not a chaotic multi-bounce

**Test it:** Try the basic script first - you'll see players getting launched multiple times per step. Then switch to Step 01 and feel the difference.

---

## 2) Directional launcher

**The idea:** Launch players in the direction they're facing instead of just straight up. Feels much more natural for movement and parkour.

**Why it's better:** When players run toward a jump pad, they expect to keep moving forward, not just bounce up and down in place.

**Setup:**
1. Use Step 02 (`steps/02-forward-mode.lua`)
2. Players get launched forward (where they're looking) + upward
3. Great for parkour courses where momentum matters
4. The 70% upward / 100% forward ratio feels natural

**Key insight:** Uses the player's `root.CFrame.LookVector` (where they're facing) instead of just launching straight up.

**More ideas:** Perfect for race tracks or speed-running courses where players want to maintain momentum while getting height boosts.

---

## 3) Surface cannon

**The idea:** Launch players perpendicular to the pad's surface. Place pads on walls, ceilings, or angled surfaces to shoot players in any direction.

**Why it's brilliant:** The launch direction is based on the pad's surface normal - place it on a wall and players shoot away from the wall, place it angled and they launch at that exact angle.

**Setup:**
1. Use Step 03 (`steps/03-directional-launcher.lua`) 
2. Place/rotate the pad surface to face the direction you want players launched
3. The pad's green color shows it's directional
4. Adjust `FORWARD_RATIO` and `UP_RATIO` for different trajectories

**Perfect for:** 
- Wall-mounted launchers that shoot players across rooms
- Angled pads that launch players up and over obstacles  
- Ceiling-mounted pads for dramatic downward launches

---

Here's the thing: jump pads work best when players don't expect them. Tuck one around a corner, hide it after a long climb, or put it right where someone's about to give up on a tricky jump. That surprise "WHOOSH!" moment? That's what keeps people playing.
