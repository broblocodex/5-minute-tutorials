# Real-World examples

Time to steal some ideas. You've got an animated melee combo system — now let's turn it into features that make games memorable.

**Important:** Each snippet goes in its own Script. Don't try to mash them together — that way lies confusion and bugs.

---

## 1) Contact Moment

**The idea:** Create a rhythm-based combat system where players must time their attacks perfectly to hit targets.

**Why it's cool:** Adds skill and timing to combat instead of button mashing. Players feel more engaged when precise timing is rewarded, and it creates satisfying "perfect hit" moments.

**Setup:**
  1. Import `steps/01-contact-moment.lua` into `StarterPlayerScripts`.
  2. Edit the animation in the Animation Editor and add a marker named `Hit` on the impact frame.
  3. Set `CONFIG.CONTACT_WINDOW` to match your beat timing window (e.g., `0.1` for strict rhythm, `0.25` for generous timing).
  4. Toggle `CONFIG.HITBOX_OFFSET` so the welded hitbox lines up with the limb that matches the beat.
  5. Add animated impact effects like flying "BAM!" text or explosion clouds that spawn at hit locations using BillboardGui or ParticleEmitter for comic book-style feedback.

---

## 2) Real Damage

**The idea:** Create a platform-based fighting game where players try to knock each other off elevated arenas.

**Why it's cool:** Adds real stakes to combat without permanent elimination. Players can get back in the action quickly, but successful hits have immediate visual impact when opponents go flying.

**Setup:**
  1. Place the client script from `steps/02-real-damage.lua` into `StarterPlayerScripts` and the server portion into `ServerScriptService`.
  2. Insert a `RemoteEvent` named `MeleeStrike` in `ReplicatedStorage` to bridge client strikes to the server validator.
  3. Adjust `SERVER_CONFIG.BASE_DAMAGE` and `SERVER_CONFIG.KNOCKBACK_FORCE` so a single kick can launch opponents off platforms without instantly eliminating them.
  4. Populate your arena with parts that drop into the void so players feel the impact when they fall.

---

## 3) Combo Variety

**The idea:** Adapt the combo system for mobile players who can't easily press keyboard keys repeatedly.

**Why it's cool:** Mobile players often get left out of fast-paced combat systems. A single touch button that cycles through combo moves keeps them competitive with PC players.

**Setup:**
  1. Load `steps/03-combo-variety.lua` into `StarterPlayerScripts` and keep the accompanying server script from Step 02 in `ServerScriptService`.
  2. Fill in additional animation ids for `MOVES.LeftKick` and `MOVES.Punch` with assets that look distinct at phone scale.
  3. Change `CONFIG.INPUT_SOURCE` to `Enum.KeyCode.ButtonX` or bind a custom GUI button to call `beginCombo()` for touch devices.
  4. Tweak `CONFIG.COMBO_RESET` so the chain does not drop if mobile latency causes a short delay between inputs.

---

## 4) Polished Fighter

**The idea:** Create a skill-based 1v1 fighting system with cooldowns, audio feedback, and visual effects that prevent button mashing.

**Why it's cool:** Cooldowns force players to think strategically about when to attack. Sound effects and screen shake make hits feel impactful and satisfying, while preventing spam creates skill-based gameplay.

**Setup:**
  1. Combine the Step 04 client script with the Step 02 server validator so all damage still flows through the secure RemoteEvent.
  2. Configure `CONFIG.COOLDOWN_SECONDS` and `CONFIG.STAMINA_COST` to prevent spam and encourage spacing.
  3. Attach your own `SoundId` and `ParticleEmitter` assets to the `impactEffect` helper for satisfying audiovisual feedback.
  4. Enable camera shake by leaving `CONFIG.CAMERA_SHAKE` true so opponents clearly see when a heavy hit lands.
  5. Add animated impact effects like flying "BAM!" text or explosion clouds that spawn at hit locations using BillboardGui or ParticleEmitter for comic book-style feedback.
