# Real-World ideas for Patrol / Possess / Follow NPCs

---

## 1) Escort Quest
- Use `steps/03-follow-the-leader.server.lua` + `.client.lua`.
- Trigger `SetMode` → `"Follow"` when the player accepts the quest.
- Adjust `FOLLOW_OFFSET` so the NPC trails just behind the hero.

Bonus: Display quest chatter on `ModeBroadcast` events so everyone knows the escort is active.

---

## 2) Possessable Training Dummy
- Keep `steps/02-possession-swap` scripts.
- Spawn a few NPCs in a combat arena; add `Highlight.FillColor` tweaks so each dummy glows a different color.
- Let players practice movement combos in a safe space before entering PvP.

---

## 3) Squad Command in Co-op Missions
- Use full Step 04 scripts.
- Share one `NPCControl` folder so every squad member can issue `Patrol` / `Follow` / `Possess` commands.
- Add custom `ModeBroadcast` listeners on the client to play voice lines or show mission status when the mode changes.

---

## 4) Cinematic Cutscenes
- Use possession to swap camera control into an NPC mid-cutscene.
- Combine with `ModeBroadcast` to start timeline animations or screen effects when the director toggles between Patrol/Follow.
- Restore the player’s character by firing `ReleasePossess` at the end of the sequence.

---

Remix these patterns: the same remotes can drive security guards, companion bots, or quick debug puppets in Studio.
