# Real-World examples

Time to steal some ideas. You've got a pad that launches players — now let's turn it into features that make games memorable.

**Important:** Each snippet goes in its own Script. Don't try to mash them together — that way lies confusion and bugs.

---

## 1) Spawn area fun zone

**The idea:** Put jump pads around your spawn area to give players something fun to do while waiting for games to start or friends to join.

**Why it works:** Creates a lively, energetic atmosphere. Players naturally gravitate toward bouncing around, and it makes your lobby feel alive and welcoming.

**Setup:**
1. Use Step 01 (`steps/01-cooldown.lua`) - prevents the multi-launch spam issue
2. Place 3-5 pads around benches, waiting areas, or open spaces
3. Keep `LAUNCH_FORCE` moderate (35-45) - fun but not overwhelming
4. Space them out so players don't accidentally chain-bounce

**More ideas:** Different colored pads for different launch heights.

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

---

Here's the thing: jump pads work best when players don't expect them. Tuck one around a corner, hide it after a long climb, or put it right where someone's about to give up on a tricky jump.
