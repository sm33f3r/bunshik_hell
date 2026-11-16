# Bunshik Hell Project Log 003

**Sessions:** 16–17 November 2026 (Asia/Seoul)
**Modes:** CHAT, then DEV
**Status labels:** ✅ decided · 🟡 suggested · ❓ open · 🔍 verify · ⚖️ needs a professional
**Previous log:** `bunshik-hell_log-002.md`
**Repo path for this file:** `documentation/logs/`

---

## 1. Documents

| Document | Status |
|---|---|
| `bunshik-hell-dev-decisions-v0.1.md` | **New.** In the repo (`documentation/production/`). Partly overtaken (§4). |
| `bunshik-hell-systems-spec-v0.1.md` | **New.** In the repo (`documentation/production/`). Partly overtaken (§4). |
| `bunshik-hell-episodes-and-maps-v0.1.md` | In the Project only. ❓ **Not in the repo yet.** |
| `bunshik-hell_log-001.md`, `bunshik-hell_log-002.md` | In the repo (`documentation/logs/`). Log 001 was renamed from `bunshik-hell-phase-1-project-log-001.md`. |
| Bible Part 1, Demo Master Roadmap, First Ideas | Moved to `documentation/design/` and `documentation/roadmaps/`. Records. |
| `sdk-master-roadmap.md` | Appeared in the Project during this session (from an SDK session). Not read here. |

---

## 2. Decisions made this session

### 2.1 Platforms, tools, licences (in Dev Decisions v0.1)

| # | Decision | Status |
|---|---|---|
| 1 | Platform priority: **Windows and Linux downloads** from NHMH's site → web build (maybe, skipped if too hard) → Android → iOS and macOS. | ✅ |
| 2 | **Forward+** renderer, for the best desktop look. Web and Android need their own renderer and visual pass later. | ✅ |
| 3 | **Jolt physics** (Godot's default for new projects since 4.6). | ✅ |
| 4 | **Separate private repo for art** (`.blend` sources, Git LFS). Only exported `.glb` files go in the public repo. | ✅ / ❓ name |
| 5 | **Assets All Rights Reserved** for now; planned move to **CC BY-SA 4.0** once the game or at least one episode is done. ⚖️ | ✅ |
| 6 | **`.tres` for our own content** (enemies, items, skills, reaction table); **JSON for outside or on-chain data** (saves, player-made store items). Never load `.tres` from outside the game. | ✅ |
| 7 | **Off-chain until Episode 1 is completely finished**, but prepared from the start (`ChainBridge`). | ✅ |
| 8 | Players choose **"play on-chain"** (connect a Sui wallet) or **"play off-chain"** (DDEOK, clothing and item NFTs stay virtual). The same in HHT and Noraebang Night. | ✅ |
| 9 | README copyright line: "© 2026 니가 한국어 못해 (NHMH)". ⚖️ Who the legal holder is. | ✅ / ⚖️ |
| 10 | README description rewritten (3D, irreverent tone). | ✅ |

### 2.2 Gameplay (after Systems Spec v0.1)

| # | Decision | Status |
|---|---|---|
| 1 | **Stomp is a starting skill.** | ✅ |
| 2 | **Start with 7 hearts, 3 sauce** (0 나트륨 🟡). | ✅ |
| 3 | **Health items never heal on touch.** Every pickup goes into the inventory; healing only through the heal button. | ✅ |
| 4 | **찜기:** used by pressing **W / stick up**. Full heal and checkpoint, like the save spots in Ori and the Blind Forest. **Rare**, placed where they feel like a **reward after a hard stretch**. | ✅ |
| 5 | **Respawn at the last 찜기 used.** | ✅ (built and tested) |
| 6 | **Inventory:** items can be dropped. When it's full, nothing can be picked up; a popup asks: "Your <inventory_item> is full. Do you want to <use it now> or <drop it>?" | ✅ |
| 7 | **The inventory is itself an item**: something a little 떡 could plausibly carry or use for storage. A small one is found very early; better ones are bought from merchants with DDEOK. Container types ❓. | ✅ |
| 8 | **Skipping the tutorial still gives the roll.** | ✅ |
| 9 | **The 떡 has eyes and a mouth** at his head end. No ears, no nose. (Settles Bible §18.) | ✅ |
| 10 | **The 떡 needs to be longer.** Settled during character design in Blender or Grease Pencil. | ✅ |
| 11 | Base resolution **1920×1080 (16:9)**, letterboxed (`keep`). | ✅ |
| 12 | Hearts stored as **half-heart units** (7 hearts = 14). | ✅ |
| 13 | **Testing rule:** run the slow `-- --physics` suite before any commit that touches movement or combat. | ✅ |

---

## 3. Repo and machines

| # | Item | Status |
|---|---|---|
| 1 | Windows checkout failed on `BUNSHIK_HELL_FIRST_IDEAS.md ` (trailing space). Fixed by renaming on the laptop. | ✅ closed |
| 2 | Docs reorganized into `design/`, `roadmaps/`, `logs/`, `production/`. | ✅ |
| 3 | **PC clone:** `C:\Users\smeefer\nhmh\bunshik-hell`. Repo-local git identity `sm33f3r`; remote `https://sm33f3r@github.com/sm33f3r/bunshik_hell.git`; pushes work. | ✅ |
| 4 | **Laptop clone:** `~/nhmh/bunshik-hell`. ❓ Needs `git pull` before use. Its git identity is still global (log 001). | ❓ |
| 5 | **Godot on the PC:** `C:\Users\smeefer\nhmh\tools\godot\Godot_v4.7.2-stable_win64_console.exe` (not on PATH). Laptop: `godot` 4.7.2 on PATH. | ✅ |
| 6 | Claude Code ran Tasks 1a–1c **on the PC**, although the 1a prompt named the laptop. | ✅ (fact) |
| 7 | Log 001/002 items now closed: Godot project pushed; renderer set explicitly; AGPL-3.0 `LICENSE` added; docs moved; trailing space fixed. | ✅ |

**Commits:** docs reorganization (laptop) · Task 1a · Task 1b (`a7a0d2d`) · Task 1c (`95fdcba`).

---

## 4. Where the new docs are already out of date

| Doc | Says | Now |
|---|---|---|
| Systems Spec v0.1 §3.1 | Stomp 🟡 starting or learned | Starting ✅ |
| Systems Spec v0.1 §5 #1 | Starting values ❓ | 7 hearts, 3 sauce ✅ |
| Systems Spec v0.1 §6.2 #3 | Pickups heal on touch when hurt 🟡 | Never heal on touch ✅ |
| Systems Spec v0.1 §6.2 #4 | Inventory ❓ | §2.2 #6–7 |
| Systems Spec v0.1 §10 #4 | Skipping the tutorial ❓ | Roll still granted ✅ |
| Dev Decisions v0.1 §6, Systems Spec §4 | Inventory on View / Touchpad | Built on **Back = Create** on the DualSense. ❓ Keep or move to the touchpad |
| Dev Decisions v0.1 §3.2 | `CLAUDE.md` rules | Written as planned; checkpoint added to saves (optional keys, `save_version` 1) |

A v0.2 of each spec picks these up when it's next needed.

---

## 5. What was built

### Task 1a: project setup
- `project.godot`: name "Bunshik Hell", `rendering/renderer/rendering_method="forward_plus"`, `physics/3d/physics_engine="Jolt Physics"`, 1920×1080, stretch `canvas_items` / `keep`. Keys checked against the 4.7.2 class reference (`--doctool`). Godot's existing `rendering_device/driver.windows="d3d12"` kept.
- Folders from Dev Decisions §3.2 (with `.gitkeep`).
- Input map for every action, keyboard + mouse + joypad.
- Autoloads: `GameState` (half-heart hearts 14/14, sauce 3/7, 나트륨 0/7, skills, inventory placeholder, `to_dict`/`from_dict`), `SaveSystem` (JSON, `save_version` 1, refuses newer versions, never crashes on bad files), `Settings` (heal default, on-chain refused while `ON_CHAIN_AVAILABLE` is false), `ChainBridge` (off-chain stub).
- Headless test runner; `LICENSE` (official AGPL-3.0 text, downloaded); `CLAUDE.md`; README licence section; `.gitignore` additions.
- 20 tests passed.

### Task 1b: the 떡 gray-box test room
- **The 떡:** `CharacterBody3D` locked to the X/Y plane (axis lock plus a clamp in code). Visual: a reddish cylinder on its side with two eyes and a mouth on the camera-facing side; flips with direction; squash/stretch/lean squiggle on the visual only. Collision is a capsule on its side.
- **Moves:** squiggle (speed follows input), variable jump, coyote time, buffering, drop-through, landing damage, stomp, roll, slam (radius hit). Skill locks respected.
- **Data:** `MovementTuning` (`movement_tuning.tres`), `ReactionTable` (`reaction_table.tres`), `EnemyDef` with soft and tall-rigid dummies.
- **Damage:** 1 heart per side hit, 1 s invulnerability with flash, knockback; death and respawn in under 1 s.
- **찜기 placeholder**, test room (main scene), side camera, debug HUD, debug skill keys.
- Fixes from 1a: no healing at 0 hearts; the runner's failure path proven (`-- --fixtures-only` exits 1).
- A bug found by scripted play and fixed: right after a bounce, the next frame counted as a side hit.
- 62 tests passed.

**Starting tuning values:** max_speed 5.5 · acceleration 45 · friction 55 · gravity 30 · fall_gravity_scale 1.4 · jump_velocity 11.5 · short_hop_cut 0.45 · coyote 0.10 · buffer 0.12 · stomp_speed 24 · roll_speed 12 · roll_duration 0.35 · slam_speed 32 · slam_radius 2.2 · bounce_velocity 8.5 · i_frames 1.0 · knockback 6/5 · respawn_delay 1.0. Full jump ≈ 2.3 m.

### Task 1c: playtest fixes
- Debug keys moved to the **number row** (1 unlock roll and slam, 2 relock, 3 respawn dummies, 4 take a heart), matched by physical key position. F-keys removed (the user's keyboard sends them to the monitor).
- Move deadzone **0.5 → 0.2**.
- **Physics interpolation** on (`physics/common/physics_interpolation`); the camera follows the interpolated position; respawn resets interpolation.
- Respawn at the last 찜기 was **already correct**; now covered by tests in both orders.
- Scripted physics checks rebuilt as **41 real tests** in `game/tests/physics/`, behind `-- --physics` (79 s); `-- --only=<text>` filter added.
- Totals: **62 fast tests (0.3 s) + 41 physics tests**, all passing; failing fixture exits 1.

---

## 6. Deviations from the prompts

| Task | Deviation |
|---|---|
| 1a | Run on the Windows PC instead of the laptop. |
| 1b | One-way platforms built by hand (Godot 3D has none). Capsule collision instead of a cylinder. Extra tuning fields. Checkpoint stored in saves. Scenes and `.tres` generated by throwaway scripts outside the repo (not kept). |
| 1c | Physics tests reset the real `GameState` autoload (the room depends on it). The physics suite is behind a flag (over 30 s). A half stick push gives about 3/8 speed, not 1/2 (Godot rescales past the deadzone). Physics tests teleport between scenarios; walking is covered only for the wall and the pit edge. |

---

## 7. Playtest results (user, PC, keyboard and DualSense)

| Check | Result |
|---|---|
| Squiggle | ✅ "Already good." The 떡 should be longer (Blender). |
| Jump, short hop | ✅ |
| Drop-through, stomp | ✅ |
| Side hit, flash, knockback | ✅ |
| Roll and slam (after unlocking with 1) | ✅ "Fantastic." |
| Respawn at the last 찜기 | ✅ |
| Face | ✅ Eyes and mouth facing the camera; look good |
| DualSense | ✅ Works, including a light push |
| Camera | ✅ Smooth |
| Overall | ✅ **"It's already fun."** |

**DualSense layout as built:** left stick move · ✕ jump · stick down in the air stomp · ○ roll / slam in the air · stick up 찜기 · Options pause · □ sauce, △ special, L2 heal, R1/L1 sauce type, right stick aim, Create inventory (mapped, no function yet).

---

## 8. Open items

1. ❓ `bunshik-hell-episodes-and-maps-v0.1.md` into `documentation/production/`; this log into `documentation/logs/`.
2. ❓ Laptop: `git pull`; global vs repo-local git identity.
3. ❓ Inventory button on the DualSense: Create (built) or touchpad (spec).
4. ❓ Art repo name; 🔍 GitHub LFS limits.
5. ❓ Inventory container types (brainstorm).
6. ❓ SDK milestone order (desktop vs web first) and Bunshik Hell's first on-chain features.
7. ⚖️ Copyright holder in the README; asset licence switch; AI music copyright.
8. Carried from log 002: the woman's identity, episode exits and order, missing third maps, Episode 1 final boss and other map bosses, 감칠맛, sauce costs, real-place facts 🔍, Suno terms 🔍.

---

## 9. Next

The 떡 prototype phase is complete. Next, the documents needed before Map 1 (log 002 §10):
1. **Episode 1 roadmap** (frozen once written)
2. **Episode 1 enemy roster v0.1**
3. **Map 1 spec v0.1** (lunch 분식집: prologue, the woman, the tutorial, roll unlock, placement, 찜기, the Mutant 라볶이, exit to Map 2)
