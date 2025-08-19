# Key APIs for Random Walker NPC

What you’ll actually use:

## Services
- `PathfindingService` — creates a navmesh path between two points
- `RunService.Heartbeat` — frame-based timing for smooth movement

## Objects
- `AnimationController` → `Animator` — play animations on non-Humanoid rigs
- `Animation` — container for uploaded animation assets
- `LinearVelocity` — apply a brief upward force to simulate a hop
- `RaycastParams` / `workspace:Raycast` — find ground height for foot placement

## Enums
- `Enum.PathWaypointAction.Jump` — path tells you a jump is needed here
- `Enum.RaycastFilterType.Exclude` — ignore this NPC when raycasting

## Docs
- PathfindingService: https://create.roblox.com/docs/reference/engine/classes/PathfindingService
- Animator: https://create.roblox.com/docs/reference/engine/classes/Animator
- Animation: https://create.roblox.com/docs/reference/engine/classes/Animation
- LinearVelocity: https://create.roblox.com/docs/reference/engine/classes/LinearVelocity
- Raycasting: https://create.roblox.com/docs/physics/raycasting

## Tips
- Set `PrimaryPart` on the NPC model. All movement uses it as the root.
- Keep `AgentRadius/Height` close to your model’s size for better paths.
- If paths often fail, simplify geometry or add more waypoints.
- Jumps only trigger when the path includes a jump waypoint and you’re close.
