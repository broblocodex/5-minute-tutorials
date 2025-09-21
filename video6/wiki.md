# Key APIs for Animated Melee Combos

What you'll actually touch while wiring the melee system.

## Services
- `ContextActionService` — binds the kick/attack input so you can swap keys later
- `RunService.Heartbeat` — per-frame polling while the hitbox window is active
- `ReplicatedStorage` — holds the `RemoteEvent` shared by client and server scripts
- `Players` — access `LocalPlayer` and listen for character spawns
- `HttpService` — `GenerateGUID` keeps every swing id unique (anti double-hit)
- `Debris` — clean up transient sounds on the server after they finish

## Objects & Components
- `Animator` / `Animation` / `AnimationTrack` — load your uploaded moves and listen for markers
- `AnimationTrack:GetMarkerReachedSignal` — fires exactly when the marker keyframe plays
- `BasePart` + `Weld` — create an invisible box welded to a limb for overlap checks
- `OverlapParams` + `workspace:GetPartBoundsInBox` — lightweight hit detection around the limb
- `RemoteEvent` — forward validated hit candidates from the client to the server
- `Humanoid` — call `TakeDamage` when the server approves a strike
- `Sound` — spawn impact audio on contact (server) or wind-up whooshes (client)
- `BasePart:ApplyImpulse` — adds instant knockback force on the target's root part

## Networking Patterns
- Clients only report potential hits with swing ids and target references
- Server double-checks range, health, cooldowns, and duplicate hits before applying damage
- Keep the RemoteEvent in `ReplicatedStorage` so both sides can `WaitForChild` it

## Useful Docs
- ContextActionService: https://create.roblox.com/docs/reference/engine/classes/ContextActionService
- AnimationTrack:GetMarkerReachedSignal: https://create.roblox.com/docs/reference/engine/classes/AnimationTrack#GetMarkerReachedSignal
- workspace:GetPartBoundsInBox: https://create.roblox.com/docs/reference/engine/classes/Workspace#GetPartBoundsInBox
- RemoteEvent: https://create.roblox.com/docs/reference/engine/classes/RemoteEvent
- Humanoid:TakeDamage: https://create.roblox.com/docs/reference/engine/classes/Humanoid#TakeDamage
- BasePart:ApplyImpulse: https://create.roblox.com/docs/reference/engine/classes/BasePart#ApplyImpulse
- Sound: https://create.roblox.com/docs/reference/engine/classes/Sound

## Tuning Tips
- Shorten `CONTACT_WINDOW` if hits feel too forgiving; lengthen to help latency
- Raise `MAX_DISTANCE` a little for taller rigs or bigger weapons
- Use separate swing/impact sound ids so the same RemoteEvent data can play both
- Knockback feels better with a small upward component so enemies leave the ground briefly
- Cooldowns should be shorter than animation length so inputs feel responsive, but not zero
