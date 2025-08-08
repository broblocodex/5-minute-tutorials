## Coin Collector – Study Notes
Core APIs
- BasePart.Touched
- Players:GetPlayerFromCharacter
- Humanoid detection (FindFirstChildOfClass("Humanoid"))
- TweenService + TweenInfo for shrink/fade
- RunService.Heartbeat for smooth spin
- Sound:Play for feedback

Patterns
- Debounce by disabling CanTouch while collecting.
- Award via leaderstats IntValue “Coins”.
- RemoteEvent "CoinCollected" (extended) to drive UI/VFX.
- Attributes for tuning: CoinValue, RotateRPS, CollectTime, AutoRespawn, RespawnTime.

Edge cases
- Player touches multiple coins quickly: disable CanTouch per coin.
- Removing while tweening: guard with Part existence checks.
- Respawn logic: restore Size/Transparency exactly; reset collecting flag.

Minimal snippet (award)
```
local stats = player:FindFirstChild("leaderstats")
local v = part:GetAttribute("CoinValue") or 1
if stats then
	local coins = stats:FindFirstChild("Coins")
	if coins then coins.Value += v end
end
```