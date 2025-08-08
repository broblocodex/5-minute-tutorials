## Spinning Platform — study links

Keep it short. Use this when you want to go deeper after the tutorial.

- TweenService (create tweens): https://create.roblox.com/docs/reference/engine/classes/TweenService
- TweenInfo (timing, easing, repeats): https://create.roblox.com/docs/reference/engine/datatypes/TweenInfo
- CFrame.Angles (rotate by radians): https://create.roblox.com/docs/reference/engine/datatypes/CFrame
- EasingStyle and EasingDirection: https://create.roblox.com/docs/reference/engine/enums
- BasePart (Anchored, CFrame): https://create.roblox.com/docs/reference/engine/classes/BasePart

Mini patterns you’ll reuse:
- Infinite spin: TweenInfo.new(time, Linear, InOut, -1)
- Rotate relative to current: part.CFrame * CFrame.Angles(...)
- Live edit: part:SetAttribute() + GetAttributeChangedSignal()