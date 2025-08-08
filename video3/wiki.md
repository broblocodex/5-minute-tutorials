# Teleporter — study links

Short and useful. These are the exact pieces this tutorial uses.

## Core pieces

- BasePart.Touched — detect when a character steps on the portal
- Players:GetPlayerFromCharacter — map character to player
- HumanoidRootPart — move the character safely
- CFrame and Vector3 — position, orientation, and small offsets

## Minimal patterns

- Safe teleport: check Humanoid + HumanoidRootPart; set CFrame
- Per‑player cooldown: a map of UserId -> last time
- Keep orientation: new CFrame with old rotation
- Hooks: write Attributes; Fire a RemoteEvent for client VFX

## Study links

- Players: https://create.roblox.com/docs/reference/engine/classes/Players
- BasePart.Touched: https://create.roblox.com/docs/reference/engine/classes/BasePart#Touched
- Humanoid: https://create.roblox.com/docs/reference/engine/classes/Humanoid
- CFrame: https://create.roblox.com/docs/reference/engine/datatypes/CFrame
- Vector3: https://create.roblox.com/docs/reference/engine/datatypes/Vector3
- Attributes: https://create.roblox.com/docs/scripting/elements/attributes
- RemoteEvent: https://create.roblox.com/docs/reference/engine/classes/RemoteEvent
