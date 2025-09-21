# Key APIs for Destructible Crates

What you’ll touch while building texture + mesh damage with rewards.

## Services
- `TweenService` — punch or wobble the crate when hits land
- `Debris` — auto-clean reward clones, FX, or temporary parts
- `CollectionService` (optional) — tag destructible props for mass updates or quests

## Objects
- `MeshPart` — lets you swap `MeshId`, `TextureID`, and `CollisionFidelity`
- `SurfaceAppearance` — modern PBR texture container; clone/swaps per damage stage
- `BindableEvent` / `BindableFunction` — lightweight messaging between this script and designers’ systems
- `ParticleEmitter` / `Sound` — optional reward FX triggered on destruction
- `Attachment` — anchor particle emitters or sound sources without extra parts

## Enums
- `Enum.CollisionFidelity` — pick collision detail level per mesh variant
- `Enum.EasingStyle` / `Enum.EasingDirection` — drive wobble tweens for hit feedback

## Docs
- MeshPart: https://create.roblox.com/docs/reference/engine/classes/MeshPart
- SurfaceAppearance: https://create.roblox.com/docs/reference/engine/classes/SurfaceAppearance
- TweenService: https://create.roblox.com/docs/reference/engine/classes/TweenService
- Debris: https://create.roblox.com/docs/reference/engine/classes/Debris
- BindableEvent: https://create.roblox.com/docs/reference/engine/classes/BindableEvent
- ParticleEmitter: https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter

## Tips
- Keep mesh variants aligned: identical pivot and size prevents physics pops.
- Group texture maps in a Folder under the script so stages can clone cleanly.
- Drive designer UI with the `CrateDamaged` event — broadcast health updates to HUDs.
- Combine `CollectionService:GetTagged("Destructible")` with `CrateDestroyed` to track break goals.
