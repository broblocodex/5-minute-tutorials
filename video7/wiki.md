# Key APIs for Patrol / Possess / Follow NPCs

## Services
- `PathfindingService` — compute navigation routes between waypoints and dynamic targets.
- `Players` — track controllers, set camera subjects, handle player removal.
- `ReplicatedStorage` — shared container for `RemoteEvent` objects.
- `RunService` — client render loop for streaming movement input.

## Objects
- `Humanoid` — drives movement, provides `Running` signal, handles `Move` and `Jump` requests.
- `Model` — container for the NPC rig and highlight.
- `RemoteEvent` — bidirectional client/server communication for requests, inputs, and broadcasts.
- `Highlight` — simple color overlay to show current mode.
- `ParticleEmitter` — optional sparkles on mode change.
- `Sound` — audible feedback for mode transitions.
- `Attachment` — anchor point for particles.

## Enums
- `Enum.PathWaypointAction.Jump` — instructs the NPC to jump mid-path.
- `Enum.HighlightDepthMode.Occluded` — hide highlight when the NPC is behind walls.
- `Enum.KeyCode` — keyboard input mapping for possession and follow commands.

## Doc links
- PathfindingService: https://create.roblox.com/docs/reference/engine/classes/PathfindingService
- RemoteEvent: https://create.roblox.com/docs/reference/engine/classes/RemoteEvent
- Humanoid: https://create.roblox.com/docs/reference/engine/classes/Humanoid
- Highlight: https://create.roblox.com/docs/reference/engine/classes/Highlight
- ParticleEmitter: https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter
- Sound: https://create.roblox.com/docs/reference/engine/classes/Sound

## Tips
- Give each NPC a unique `PrimaryPart` (HumanoidRootPart) for consistent `SetNetworkOwner` calls.
- Replicate remotes from `ReplicatedStorage` so both server and clients can reference them by name.
- Remember that possession is optional: if no one is controlling the NPC, it automatically returns to patrol.
- Broadcast mode changes to every client so UI can stay in sync even when someone else issued the command.
