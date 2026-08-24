# BUNSHIK HELL DEMO — Master Roadmap (Revised)

**Target:** Bunshik Hell 0.1 — one polished 분식집 level, the confirmed enemy roster, and the Mutant 라볶이 boss.
**Engine:** Godot 4.x / GDScript
**Platform:** Linux desktop first, itch.io demo release
**Canonical source:** `BUNSHIK_HELL_GAME_DESIGN_BIBLE` (Part 1: Core Identity & Protagonist). If this roadmap and the Bible conflict, the Bible wins. Update both when decisions change.

**Guiding principles:**
- Make the smallest version that proves Bunshik Hell is fun. Then make it bigger.
- Food obeys food logic. No generic "enemy + HP bar + damage."
- The 떡 is a small, strange, limbless piece of food surviving a world it doesn't understand.
- North-star test for every feature: *Does this feel like something only Bunshik Hell would do?*

Each phase ends with a **Gate** — a question that must be answered "yes" before moving on.

---

## Phase 1 — Foundation & Setup

*Goal: a clean launchpad. No game code yet.*

### Steps

1. **Adopt the Bible's core-identity paragraph as the official pitch** (Bible §20). Store it in `documentation/`.
2. **Write the 0.1 scope document.**
   One 분식집 level, the confirmed enemy roster (만두, 뻔데기, 어묵, 라면, lit cigarettes, small 튀김 + one fryer), one boss (Mutant 라볶이). Explicitly out of scope: additional worlds, the winter world / 붕어빵 boss, save system, controller/touch support, multiple playable characters.
3. **Resolve the minimum set of "open" Bible items needed to start building** (Bible §18):
   - Sauce aiming/controls (flick + spin)
   - Roll controls
   - Bounce rules
   - Health / damage / invulnerability model
   These are working decisions for 0.1 — revisable later, but written down now.
4. **Install Godot 4.x** on the Linux development machine.
5. **Create the Git repository** with the agreed folder structure (`assets/`, `characters/`, `enemies/`, `bosses/`, `levels/`, `scripts/`, `ui/`, `audio/`, `documentation/`). Commit the Bible and this roadmap into `documentation/`.
6. **Define placeholder-art rules.**
   Prototype = geometry and flat colors. *Exception:* the 떡's deformation locomotion cannot be represented by a static rectangle — plan for a simple deformable placeholder (a soft-body-looking blob or a squash/stretch-capable sprite) from the start.

### Definition of Done

- Scope document and working-decisions document written
- Godot project opens and runs an empty scene
- Repo initialized with Bible + roadmap committed

### Gate

> Is the scope small enough that one person can realistically finish it, and are the locomotion/combat decisions concrete enough to start building?

---

## Phase 2 — The 떡: Locomotion & Combat

*Goal: the 떡 exists, moves like a 떡, and its three combat categories work.*

This phase is larger than a normal "player controller" phase because the deformation-based locomotion **is** the character. It is a physics/animation design problem, not a parameter-tuning problem.

### Steps

1. **Deformation locomotion prototype.**
   Lurch-back → compress → squiggle-forward movement (Bible §6). No walk cycle, no limbs. Iterate until the movement itself is expressive and satisfying to watch and control. Expect several throwaway prototypes (skeleton/bone deformation, vertex/mesh deformation, or frame-based squash-and-stretch — test cheapest first).
2. **Jump.** Bend-back → compress → launch, elastic elongation in air, SQUASH on landing (Bible §7). Variable height, coyote time, jump buffering.
3. **Emotional posture system (minimal version).**
   The upper "head-like" section leans, recoils, and hesitates (Bible §8). For 0.1: at least *curious lean*, *startled recoil*, and *nervous idle*. This is core identity, not polish — but keep it minimal.
4. **Body combat.**
   - **Roll attack:** compress-and-launch roll (kills 어묵, damages 튀김)
   - **Bounce/jump attack:** squashes soft enemies (만두, 뻔데기), bounces off 튀김, hurts the 떡 on cigarettes
5. **Sauce combat.**
   - **Sauce flick:** targeted attack
   - **Sauce spin:** area attack around the body
   - Sauce is not universal damage — build it so per-enemy reactions are data, not hardcoded
6. **Environmental interaction foundation.**
   Push objects, knock objects over, trigger falling objects (pots/pans/spatulas), throw small objects (toothpicks) if in scope. Falling heavy objects one-shot 튀김.
7. **Damage, health, death & restart.** Per the Phase 1 working decisions. I-frames, readable hit feedback, restart-to-playing in under 2 seconds.
8. **Camera + test room.** A graybox room with platforms, one pushable object, one droppable object, and dummy targets for each attack type.
9. **Game-feel tuning pass.** The movement alone should be fun — and should feel like food, not like a hidden humanoid.

### Definition of Done

- The 떡 moves, jumps, rolls, bounces, flicks/spins sauce, interacts with objects, takes damage, dies, restarts
- All reaction rules driven by a per-enemy/material data table (the start of the food-physics matrix)
- Tunable values exposed as editable parameters

### Gate

> Does the 떡 feel like a piece of food that learned to move — and is it fun to control even in an empty gray room?

---

## Phase 3 — The Food Ecosystem & Level 1

*Goal: the confirmed enemy roster, the food-physics matrix, and a complete graybox 분식집 level.*

### Steps

1. **Build the enemy framework around the food-physics matrix.**
   Each enemy = material + physical properties + behavior. The matrix (attack type × enemy → reaction) lives in one data source so new foods slot in without rewrites.
2. **Implement the confirmed roster one at a time**, each individually fun before the next begins:
   - **만두** — basic squashable enemy
   - **뻔데기** — small, squashable, appears in groups; grotesque presentation
   - **어묵** — tall; killed by roll attack
   - **Lit cigarettes** — look environmental at first; sauce extinguishes, jumping hurts
   - **튀김 (small, 1–2 forms)** — progressive deterioration (fresh → broken → crumbling → soggy), bounce-off platforms, one-shot by heavy objects and boiling water
   - **라면** — avoidance encounter; absorbs sauce; conventional combat must fail
3. **The fryer.** A 튀김 spawner, not a hazard — the player realizes the fryer itself is the enemy source. One fryer set-piece in Level 1.
4. **Hazards.** 꼬치/toothpick spikes, hot surfaces, boiling water (which also kills 튀김 — teach this), at least one falling-object opportunity.
5. **Graybox Level 1 — the 분식집.**
   Structure the level as a discovery curve:
   - **Intro:** movement and jumping in a deceptively cute 분식집
   - **Experimentation:** first enemies + first "what happens if I sauce this?" moments (cigarette teach)
   - **Ecosystem:** the fryer set-piece — spawner + boiling water + falling objects combine
   - **The 라면 encounter:** the level's "I'm not supposed to fight this" horror beat
   - **Descent:** tone shifts darker on the approach to the boss door
6. **Environmental storytelling pass (graybox level).** Even with placeholder art, plan where the cute→strange→disturbing progression happens, and where the player understands the horror before the 떡 does.
7. **Enemy & hazard placement + difficulty pass.** Every death readable and fair.
8. **Checkpoints.** Level start, mid-level, pre-boss.

### Definition of Done

- Full level playable start to finish with placeholder art
- Every roster enemy behaves per the food-physics matrix
- At least three discoverable ecosystem interactions (e.g., sauce/cigarette, roll/어묵, boiling water/튀김)
- The 라면 encounter reliably produces avoidance, not combat

### Gate

> Do playtesters experiment ("can I sauce this? can I roll through this?") — and does the 라면 encounter make them think "I'm not supposed to fight this"?

---

## Phase 4 — The Mutant 라볶이 Boss

*Goal: a learnable, retry-inducing first boss that pays off the level's food logic.*

### Design premise

라볶이 = 떡 + 라면 fused. The boss is a **corrupted mirror of the protagonist**, merged with the one enemy the player learned they cannot fight. The horror escalation of Level 1 pays off here.

### Steps

1. **Boss design doc on paper first.** Phases, attacks, telegraphs, and — critically — **how each phase uses established food logic.** Example direction (to refine in session):
   - **Phase A:** 떡-like body attacks — grotesque mirrored versions of the player's own roll/bounce
   - **Phase B:** 라면 noodle attacks — whips, grabs, sauce absorption (the player's sauce visibly fails, echoing the 라면 lesson)
   - **Phase C:** Desperation — the arena's kitchen environment becomes the weapon, and the player must use environmental combat (the level's real lesson) to win
2. **Telegraph rules.** Every attack has a distinct wind-up. No invisible or instant damage.
3. **Boss framework.** Phase state machine, thresholds, attack scheduler — built to be reused by future bosses (붕어빵 later).
4. **Prototype with placeholder art.** Tune until hard but learnable; the win condition should require at least one ecosystem insight, not raw damage grinding.
5. **Retry loop playtest.** Death → retry instant. Track attempts-to-victory for fresh players.
6. **Arena design.** The 분식집 kitchen: fryer, boiling pot, hanging utensils — readable, and mechanically relevant to Phase C.
7. **Rough final art & animation.** Grotesque-but-funny; strong silhouette; the 라볶이 should be recognizably a wrong version of the 떡.

### Definition of Done

- Fight completable and tuned; victory requires using food logic, not just dodging and attacking
- All attacks telegraphed
- Boss has rough final art with expressive, theatrical animation (entrance included — Pillar 3)

### Gate

> After dying, does the player immediately want to retry — and does beating the boss feel like understanding the food world, not just out-dodging it?

---

## Phase 5 — Polish & Demo Release

*Goal: ship Bunshik Hell 0.1 on itch.io.*

### Steps

1. **Final art pass — player first.** The 떡's deformation, sauce drip, and emotional postures carry the whole game; budget most art time here. Then enemies (silhouette and readability over frame count), then environment (sell the cute→disturbing shift).
2. **UI & HUD.** Minimal, readable, tonally consistent (per Phase 1 health decisions).
3. **Full loop.** Title screen → Level → Boss → Victory → Credits/Restart.
4. **Audio.** SFX for locomotion squishes, sauce, squashes, deaths; unsettling ambient layer for the tone shift; one level track and one boss track (original, or clearly-marked placeholder).
5. **Settings essentials.** Volume, fullscreen, key rebinding if practical.
6. **Bug & performance pass.** Crashes and progression blockers first.
7. **External playtesting.** People who have never seen the game. Watch for: Do they experiment? Do they laugh *and* wince? Do they read the 라면 lesson? Where do they get stuck?
8. **Build & package.** Linux first; Windows and Web if practical.
9. **itch.io page.** Screenshots, GIF of the 떡's locomotion (its strongest hook), GIF of the boss, the pitch paragraph.
10. **Ship Bunshik Hell 0.1.** Feedback channel in place.

### Definition of Done

- Full loop playable with no blockers
- Demo published on itch.io with feedback channel

### Gate

> Does someone who has never heard of the project play the level and want to fight the 라볶이 again — and do they describe the game as *weird* in a way they liked?

---

## After the Demo

**If the gate passes:** begin the 0.5 → 1.0 roadmap — more worlds (including the winter world and the 붕어빵 boss), expanded enemy roster and food-physics matrix, later Bible parts (story, world structure, music), save system, controller support, and the Steam/Android path.

**If it doesn't:** study the feedback, find the repeated problems, and fix the core before expanding. Do not scale a game that isn't fun yet.

**Maintenance rule:** whenever a design decision is made or changed in session, update the Game Design Bible first, then this roadmap. The two documents must never drift apart.
