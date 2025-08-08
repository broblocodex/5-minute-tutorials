## Tutorial 7 – Coin Collector
Make coins that spin, play a sound, and disappear when collected. Award points through leaderstats.

Files
- script.lua — simple coin (spin + collect + destroy)
- script.extended.lua — attributes + RemoteEvent + optional auto-respawn
- wiki.md — short study links
- use-cases.md — four quick ideas

Try it (simple)
1) Insert a Cylinder or MeshPart and name it “Coin” (any color).
2) Add a Script inside and paste `script.lua`.
3) Optional: add a Sound named “CollectSound” under the Part.
4) Optional: create leaderstats with an IntValue named “Coins” to see scoring.
5) Play and touch the coin.

Then explore (extended)
- Attributes on the Part:
	- CoinValue (number) — how many to award (default 1)
	- RotateRPS (number) — spin speed
	- CollectTime (number) — shrink/fade seconds
	- AutoRespawn (bool) — if true, coin hides then returns
	- RespawnTime (number) — seconds before respawn
	- LastUserId (int), LastCollectedAt (int) — hooks for UI/analytics
- RemoteEvent: CoinCollected (player, value)
	- Clients can listen to show UI, play local VFX, combo meters, etc.

Notes
- Uses RunService.Heartbeat for smooth spin.
- Uses TweenService for shrink/fade.
- Disables CanTouch during collect to prevent double triggers.