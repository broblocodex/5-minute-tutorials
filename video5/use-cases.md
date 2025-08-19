# Real-World ideas for Random Walker NPC

You’ve got a wandering NPC. Now make it part of your world.

---

## 1) Patrol Guide
- Build a `Waypoints` folder in a tour loop (POIs around your map)
- Use `steps/01-random-walker.lua`

Tip: Duplicate the NPC and offset waypoints slightly so they don’t bunch up.

---

## 2) Climber
- Use `steps/02-walker-with-jump.lua`
- Create elevated waypoints (stairs, ledges) and enable jump-capable paths
- Mark special climbable parts (CollectionService tags) for extra behavior on reach

---

## 3) Event Crowd Filler
- Spawn 5–10 walkers with different rigs and clothes
- Stagger idle ranges so the movement looks organic
- Disable collisions on accessories to reduce bumping

---

## 4) Path Debugger (Waypoint Visualizer)
- Use `steps/03-visualize-waypoints.lua`, or copy the `renderPathWaypoints` function into your walker script
- After computing a path, call `renderPathWaypoints(character, waypoints, goalPos)` to draw neon spheres and optional beams
- Pass overrides for quick tuning: `{ connectBeams = false, size = Vector3.new(0.25,0.25,0.25) }`
- Clear when idling by calling it with an empty list: `renderPathWaypoints(character, {})`

Tip: Gate it to Studio-only with `if game:GetService("RunService"):IsStudio() then ... end` so players don’t see debug markers.

---

Steal these patterns and remix. The core idea is the same: believable background motion that makes your map feel alive.
