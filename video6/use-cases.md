# Speed Boost Strip — 4 use-cases

Short and focused. Each idea lists which step to use.

Note
- Each idea should live in its own Script (or LocalScript where called out). Don’t mix snippets. Put the Script where your setup expects it, and declare top-of-snippet variables so references resolve.

1) Racing Catch‑Up (rubber‑banding)
- Use: Step 01 (attributes-cooldown). If player is last place, temporarily raise `BoostSpeed` on pads.
- Client UI can show “SLINGSHOT”.

2) Risk Lane (choice and timing)
- Use: Step 01 (attributes-cooldown). Narrow lane with pads over a fall; shorten `Cooldown` so timing matters.

3) Combo Chain (style points)
- Use: Step 02 (remoteevent). When `SpeedBoost` fires, client starts a combo timer; chaining before it ends adds points.

4) Boost Meter UI (feedback)
- Use: Step 02 (remoteevent). Client listens to `SpeedBoost` and renders a shrinking duration bar; refresh on new boosts.