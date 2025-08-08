# Use Cases - The Coin Collector in Game Development
## Coin Collector – 4 Quick Use Cases

1) Level Gate
Put a Door that opens when Coins >= N. Client listens to CoinCollected to animate a progress bar.

2) Combo Collector
Start a short combo timer on CoinCollected; collecting the next coin before it ends increases a multiplier. Reset on miss.

3) Treasure Trails
Place coins as breadcrumbs to guide players. Increase CoinValue for harder branches to reward exploration.

4) Race Lines
Two racing lines: safe vs coin-rich risky path. Use CoinValue and spacing to tune difficulty and reward.

Hook references
- Attributes: CoinValue, RotateRPS, CollectTime, AutoRespawn, RespawnTime.
- RemoteEvent: CoinCollected (player, value).