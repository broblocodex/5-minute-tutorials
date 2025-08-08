# Roblox Wiki Resources - The Speed Boost Strip

This document provides links to official Roblox documentation for all the APIs and concepts used in the Speed Boost Strip example.
## Speed Boost Strip – Study Notes
Tiny mechanic: on touch raise Humanoid.WalkSpeed for a duration, then restore.

Key APIs
- Humanoid.WalkSpeed (default 16)
- BasePart.Touched hit.Parent / FindFirstChildOfClass("Humanoid")
- Players:GetPlayerFromCharacter(model)
- Attributes on the Part: BoostSpeed, BoostDuration, Cooldown
- RemoteEvent SpeedBoost (extended script fires: player, speed, duration)

Patterns
- Per‑player cooldown: store lastTrigger[userId] = tick(); compare.
- Safe restore: only write WalkSpeed if Humanoid still exists.
- Extend boost: refresh end timestamp instead of stacking speed.
- Live tuning: AttributeChanged signal updates current boosted speeds.

Edge Cases
- Character respawn mid‑boost: original speed lost? Store original per boost.
- Multiple pads: each manages its own Attribute set; boosts overwrite (expected). Consider highest pad speed only if you need stacking rules.
- Player leaves: restore before cleanup.

Hooks You Can Use
Attributes: LastUserId, LastBoostAt for UI / analytics.
RemoteEvent: SpeedBoost → client can show burst FX, screen flash, timer bar.

Ideas to Extend
- Directional impulse (apply AssemblyLinearVelocity forward).
- Progressive catch‑up: raise BoostSpeed dynamically if player is behind.
- Team colored pads: set BoostSpeed per team.

Minimal Reference Snippet (core restore logic)
```
local original = hum.WalkSpeed
hum.WalkSpeed = boostSpeed
task.delay(duration, function()
	if hum.Parent then hum.WalkSpeed = original end
end)
```

That’s all you need. Everything else (cooldowns, UI, sounds) layers on top.