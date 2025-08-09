# Coin Collector — 4 use-cases

Short and focused. Each idea lists which step to use.

Note
- Each idea should live in its own Script (or LocalScript where called out). Don’t mix snippets. Put the Script on the coin or the controller Part as your setup implies, and declare top-of-snippet variables so references resolve.

1) Level Gate
- Use: Step 01 (attributes). Open a door when leaderstats.Coins >= N. Optionally raise `CoinValue` for rare coins.

2) Combo Collector
- Use: Step 02 (remoteevent). Start a short combo timer on `CoinCollected`; collecting again before it ends increases a multiplier.

3) Treasure Trails
- Use: Step 01 (attributes). Place coins as breadcrumbs; increase `CoinValue` on harder branches to reward exploration.

4) Race Lines
- Use: Step 01 or 02. Tune `CoinValue` and spacing; optionally listen to `CoinCollected` for UI feedback.