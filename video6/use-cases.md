# Use Cases for the Animated Melee Combo Kit

Drop these scripts in, tune the numbers, and you've got a combat loop in minutes.

---

## Step 1 — First Move
- **Lobby Kick Emote**
  1. Copy `video6/script.lua` into `StarterPlayerScripts` as a LocalScript.
  2. Replace `CONFIG.KICK_ANIM_ID` with your uploaded kick animation asset id.
  3. Swap `CONFIG.INPUT_KEY` to something social-friendly (for example `Enum.KeyCode.E`) so players can trigger it while waiting in the lobby.
  4. Optionally bump `CONFIG.PLAYBACK_SPEED` for a snappier feel if the lobby energy is high.
- **Scripted Cutscene Strike**
  1. Drop the script into a `LocalScript` that runs during your cutscene controller.
  2. Call the exposed `bind()` helper after the camera pans to the hero to let the player throw one dramatic kick.
  3. Disable ContextActionService binding afterwards with `ContextActionService:UnbindAction(CONFIG.INPUT_ACTION)` so normal controls return.

---

## Step 2 — Contact Moment
- **Hit-the-Beat Minigame**
  1. Import `video6/steps/02-contact-moment.lua` into `StarterPlayerScripts`.
  2. Edit the animation in the Animation Editor and add a marker named `Hit` on the impact frame.
  3. Set `CONFIG.CONTACT_WINDOW` to match your beat timing window (e.g., `0.1` for strict rhythm, `0.25` for generous timing).
  4. Toggle `CONFIG.HITBOX_OFFSET` so the welded hitbox lines up with the limb that matches the beat.
- **Target Dummy Trainer**
  1. Use the same script and duplicate a dummy NPC with a Humanoid in your map.
  2. Anchor the dummy in place and position it inside the hitbox path to visualize when the contact window is active.
  3. Watch the output window for `[Melee] Contact window active → would hit ...` logs to fine-tune the marker placement.

---

## Step 3 — Real Damage
- **Knock-Off Arena**
  1. Place the client script from `video6/steps/03-real-damage.lua` into `StarterPlayerScripts` and the server portion into `ServerScriptService`.
  2. Insert a `RemoteEvent` named `MeleeStrike` in `ReplicatedStorage` to bridge client strikes to the server validator.
  3. Adjust `SERVER_CONFIG.BASE_DAMAGE` and `SERVER_CONFIG.KNOCKBACK_FORCE` so a single kick can launch opponents off platforms without instantly eliminating them.
  4. Populate your arena with parts that drop into the void so players feel the impact when they fall.
- **Breakable Props**
  1. Tag destructible crates or doors with `CollectionService` tags referenced in the server script's `BREAKABLE_TAGS` list.
  2. In the server script, customize `applyDamage` to call your prop shatter modules when the Humanoid takes damage.
  3. Use the existing limb validation logic to reject hits that come from outside the configured hitbox radius, preventing griefing exploits.

---

## Step 4 — Combo Variety
- **Mobile-Friendly Combo Button**
  1. Load `video6/steps/04-combo-variety.lua` into `StarterPlayerScripts` and keep the accompanying server script from Step 03 in `ServerScriptService`.
  2. Fill in additional animation ids for `MOVES.LeftKick` and `MOVES.Punch` with assets that look distinct at phone scale.
  3. Change `CONFIG.INPUT_SOURCE` to `Enum.KeyCode.ButtonX` or bind a custom GUI button to call `beginCombo()` for touch devices.
  4. Tweak `CONFIG.COMBO_RESET` so the chain does not drop if mobile latency causes a short delay between inputs.
- **Boss Phase Switcher**
  1. During a boss encounter, update the shared `MOVES` table at runtime (e.g., swap `MOVES.Roundhouse.finisher` with a new animation when health < 50%).
  2. Use the script's `setMoveOverrides` helper to inject new damage values or hitbox sizes mid-fight.
  3. Broadcast the current combo state to spectators by listening to the `comboStateChanged` signal exposed near the bottom of the script.

---

## Step 5 — Polished Fighter
- **Competitive PvP Duel**
  1. Combine the Step 05 client script with the Step 03 server validator so all damage still flows through the secure RemoteEvent.
  2. Configure `CONFIG.COOLDOWN_SECONDS` and `CONFIG.STAMINA_COST` to prevent spam and encourage spacing.
  3. Attach your own `SoundId` and `ParticleEmitter` assets to the `impactEffect` helper for satisfying audiovisual feedback.
  4. Enable camera shake by leaving `CONFIG.CAMERA_SHAKE` true so opponents clearly see when a heavy hit lands.
- **Co-op Dungeon Brawler**
  1. Leave cooldowns moderate but increase `SERVER_CONFIG.STAGGER_DURATION` so enemies briefly pause after being hit.
  2. Hook into the provided `onDamageApplied` callback to drop loot, award combo points, or trigger door unlock logic when the team clears a wave.
  3. Adjust `CONFIG.KNOCKBACK_VECTOR` per enemy type to send lighter mobs flying while heavy bosses simply flinch.

---

## Expansion Ideas
- **Weapon Swap System**
  1. Create accessory-specific hitboxes and call `setHitboxProfile("Sword")` before each swing to swap sizes and offsets.
  2. Store profile data in `ReplicatedStorage` so both the client and server agree on the active weapon stats.
- **Combo Finisher Rewards**
  1. Listen to the exposed `onComboFinished` event and award a RemoteEvent-driven ultimate ability when players land the full chain.
  2. Increase the `SERVER_CONFIG.FINISHER_DAMAGE` or trigger a cinematic camera shot when that event fires.
- **Stat-Driven Cooldowns**
  1. Tie `CONFIG.COOLDOWN_SECONDS` to player data by reading a leaderstat or profile module each time `beginCombo()` is called.
  2. Mirror the same calculation on the server validator to keep cooldown logic authoritative.
