## Tutorial 7 – Coin Collector
Make coins that spin, play a sound, and disappear when collected. Award points through leaderstats.

Files
- script.lua — simple coin (spin + collect + destroy)
- steps/ — incremental checkpoints aligned to use-cases (01 → 02)
- wiki.md — short study links
- use-cases.md — four quick ideas

Try it (simple)
1) Insert a Cylinder or MeshPart and name it “Coin” (any color).
2) Add a Script inside and paste `script.lua`.
3) Optional: add a Sound named “CollectSound” under the Part.
4) Optional: create leaderstats with an IntValue named “Coins” to see scoring.
5) Play and touch the coin.

Then explore (steps)
- Walk through `steps/` in order:
  - 01 attributes → 02 remoteevent

Which step for which use-case?
- Level Gate → Step 01 (use `CoinValue`; read leaderstats)
- Combo Collector → Step 02 (listen to `CoinCollected` to run a combo timer)
- Treasure Trails → Step 01 (increase `CoinValue` for branches)
- Race Lines → Step 01 or 02 (tune `CoinValue`; optional UI feedback via event)

Notes
- Uses RunService.Heartbeat for smooth spin.
- Uses TweenService for shrink/fade.
- Disables CanTouch during collect to prevent double triggers.