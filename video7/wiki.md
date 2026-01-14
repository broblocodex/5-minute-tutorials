# Key APIs for Destructible Crate

What you'll actually use:

## Services
- `AssetService` — create EditableMesh/EditableImage from existing assets
- `Debris` — auto-cleanup for spawned chunks and effects

## Objects
- `EditableMesh` — runtime-modifiable mesh with vertex access
- `EditableImage` — runtime-modifiable texture for drawing cracks
- `MeshPart` — the crate geometry; hosts EditableMesh
- `SurfaceAppearance` — applies EditableImage as a texture layer
- `BillboardGui` — world-space UI used for the crate health bar
- `LinearVelocity` / `VectorForce` — impulse for flying chunks

## EditableMesh Methods
- `GetVertices()` — returns list of vertex IDs
- `GetPosition(vertexId)` — get vertex position in local space
- `SetPosition(vertexId, position)` — move a vertex
- `GetVertexNormal(vertexId)` — get vertex normal for inward denting
- `GetTriangles()` — list of triangle face IDs
- `GetTriangleVertices(triangleId)` — get 3 vertex IDs for a face

## EditableImage Methods
- `DrawCircle(center, radius, color, transparency)` — stamp a filled circle
- `DrawImage(position, image, combineType)` — composite another image
- `WritePixels(position, size, pixels)` — direct pixel manipulation
- `Resize(size)` — change texture resolution

## Collision Detection
- `BasePart.Touched` — event fires on physics contact
- `workspace:Raycast()` — precise hit point from projectile trajectory
- `RaycastResult.Position` — world-space hit location
- `RaycastResult.Normal` — surface normal at hit point

## UV Mapping (for crack placement)
- Convert world hit point to local crate space
- Project onto face to get UV coordinates
- Scale UVs to EditableImage pixel coordinates

## Enums
- `Enum.CombineType` — how EditableImage blends (Overwrite, AlphaBlend, Add, Multiply)

## Docs
- EditableMesh: https://create.roblox.com/docs/reference/engine/classes/EditableMesh
- EditableImage: https://create.roblox.com/docs/reference/engine/classes/EditableImage
- AssetService: https://create.roblox.com/docs/reference/engine/classes/AssetService
- Raycasting: https://create.roblox.com/docs/mechanics/raycasting
- SurfaceAppearance: https://create.roblox.com/docs/reference/engine/classes/SurfaceAppearance

## Tips
- EditableMesh requires you to own the source mesh asset.
- Keep crate vertex count low (8–64) for readable, performant deformation.
- Cache vertex positions at start; recalculate only changed verts.
- Clamp max dent depth to prevent mesh inversion/z-fighting.
- Use falloff curves (linear, smooth, exponential) for natural-looking dents.
- EditableImage resolution affects crack sharpness — 256×256 is a good start.
