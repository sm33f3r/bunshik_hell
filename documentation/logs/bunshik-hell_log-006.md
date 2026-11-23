# Bunshik Hell — Project Log 006

*Build session log · 22–24 November 2026 · Modes: CHAT → DEV*
*Repo path: `documentation/logs/`*
*Previous log: `bunshik-hell_log-005.md`*

> ✅ decided · 🟡 suggested · ❓ open · 🔍 verify · ⚖️ needs a professional
> Every gameplay number is 🟡 until playtested.

---

## 1. Where we are

Map 1 (the lunch 분식집) is playable in gray box from the prologue through the tutorial and the whole dining room (tables and floor lane), with a real 찜기 that heals once and auto-saves.

**Next: Task 3c, split into three tasks (✅ split proposed, user to confirm at start):**

| Task | Contents |
|---|---|
| **3c-i** | The first 라면: the pour-water special (cup or bottle filled at the 정수기), swell → kill, sauce flick unlocked on first defeat, sauce absorb. |
| **3c-ii** | The kitchen: 군만두 and 김말이튀김, the fryer that keeps spawning them, the heavy-object special (뚝배기 etc.: kills 튀김, pins 라면). |
| **3c-iii** | The pre-boss 찜기, the 치즈라볶이 arena (gray box, ready for the fight in 3d), the map exit. |

Then **3d:** the 치즈라볶이 fight (Boss Sheet v0.1 §3).

**Test baseline after 3b-iii:** fast **455 / 0**, full physics **665 / 0**.

---

## 2. Working rules with NHMH (keep following these)

1. **Fewer words, more building.** Short replies. Build THE GAME (real Map 1), not test-room work.
2. **Questions:** numbered, **max 4** at a time; say if more are coming.
3. **Never change her Korean lines** or anything not asked for. Suggestions only when asked.
4. **DEV loop:** plan → one Claude Code prompt in one code block (never tells the agent to git add/commit/push) → review the report and `git status --short -uall` → commit block.
5. **Commit blocks:** run `--import` first; `git add` every file by name, including every new `.uid`; `git status` check (no `??` left); `git commit -m "..."`; `git push origin main`.
   **No `Co-Authored-By` / `Claude-Session` trailer lines in commit messages, ever.** (They were pushed once by mistake on 3a-oil; NHMH had them removed with `git commit --amend` + `git push --force-with-lease`.)
6. Every prompt asks for: tests that ship with the task, real-input physics tests (not direct function calls), both suites run, totals vs baseline, deviations, untested items, playtest steps.
7. **Soft-lock rule:** nothing the player needs to progress may be permanently used up. Required elements are `required_for_progress` and respawn; the progress-graph validator must pass for every section.

## 3. Environment

- Godot **4.7.2 stable**, Forward+, Jolt, 2.5D (CharacterBody3D on a plane), 1920×1080 keep.
- **PC (Windows PowerShell):** repo `C:\Users\smeefer\nhmh\bunshik-hell`; Godot `& 'C:\Users\smeefer\nhmh\tools\godot\Godot_v4.7.2-stable_win64_console.exe'`.
- **Laptop (CachyOS, fish):** `~/nhmh/bunshik-hell`; `godot` on PATH.
- Fast tests: `<godot> --headless --path game -s res://tests/test_runner.gd` · full: add `-- --physics` (~11 min) · filter: `--only=<name>` · `--fixtures-only` must exit 1.
- Play: editor (`<godot> --path game -e`), F5. Close the editor during `git pull` and while the agent works.
- **Debug keys:** 8 = finish the prologue · 9 = debug HUD · 0 = load the save (debug builds).
- Save file: `user://saves/slot_1.json`.

---

## 4. Built this session

| Task | What | Tests after | Status |
|---|---|---|---|
| 3a-polish | Prologue reaction lines pool; 만두 respawn (2 at a time); Settings → Controls page; icon HUD | 273 / 419 | 🔍 pushed (later commits on top suggest yes) |
| 3a-oil | Every 3rd 만두 killed **by Ddeok Dude** drops 참기름; per-type counter in GameState, survives death, resets on new game, not saved | 278 / 425 | ✅ pushed (message amended, trailers removed) |
| 3b-i | Map layout as data (`maps/layout/*`, `data/maps/ep01/map01_layout.tres`); one-time tutorial prompt (✕ 튜토리얼 하기 / ○ 건너뛰기); tutorial beats a–e; 단무지 wheel (`bounce_boost`, roll → knock_over); roll + slam granted (source "tutorial", also on skip); data checkpoints with sauce/나트륨 snapshot; action glyphs; new-skill toast | 323 / 490 | ✅ pushed |
| 3b-ii | Dining room: ongoing tables, napkin box → windowsill hops (sills hold pickups; one required sill hop), chairs, floor lane (falls do no damage), 김밥 slice train (`spill`, `break_line`), table chopsticks (customers' hands: grab, easy wiggle, take 만두), gum (stick; wiggle / 3 enemy hits / ~10 s fallback; jump over avoids), giant feet (shadow, 1 heart, flatten-stun, crush enemies); wheel-2 respawn | 393 / 576 | ✅ pushed |
| 3b-ii-fix | Tutorial exit now fades into dining_room_start like skip; bounce no longer cut by releasing jump; table/chair legs moved behind the lane + `lane_rules.gd` validator; 김밥 slices 1 hp (stomp kills); falling chopsticks and spoons on the floor lane only (shadow 0.6 s, ½ heart while falling, land as harmless solid props, cap 4/zone) | 417 / 612 | ✅ pushed (🔍 confirm) |
| 3b-ii-fix2 | Tutorial soft-lock fixed: `required_for_progress` + `usable_when_flat` on spawn entries; wheel 1 respawns upright after 4 s; second route (napkin box `tut_box`); `progress_graph.gd` soft-lock validator for all sections; runner fails on GDScript runtime errors; forearm prologue test made deterministic (seeded RNG) | 429 / 632 | 🔍 commit block given; playtest of both routes not reported |
| 3b-iii | Real 찜기 (refactored `items/steamer.gd`): `JjigiDef` (`heals_once`, `saves`; test room uses `debug_unlimited`), `JjigiPlacement` ids in layout; trigger = W (look_up) in the zone; one full heal + auto-save + steam off + HUD disk icon; respawn = most recent of 찜기 / checkpoint; SaveSystem stores skills, inventory, containers, hearts, sauce, 나트륨, off-chain `ddeok` int (new), map, respawn point, used 찜기 ids, checkpoints, story flags; temp-file write with `.bak` fallback; `load_for_play()` / `continue_game()`; `map_catalog.gd`; 김밥 `roll_break_grace_s` 1.0 | 455 / 665 | 🔍 commit block given; not yet confirmed pushed or playtested |

Map 1 placement now: the dining-room mid checkpoint is replaced by 찜기 `map01_dining_mid` (r_t8). Tutorial-start and dining_room_start stay data checkpoints.

---

## 5. Decisions this session (✅)

1. Tutorial and Map 1 are the same map; skip jumps ahead to dining_room_start; finishing the tutorial lands at the same spot.
2. Falling off a table in the dining room: no damage, land on the floor lane (harder route), climb back via chairs.
3. Floor lane hazards: gum (wiggle escape, enemy hits free him, fallback timer; jump over avoids) and giant feet that smoosh. Feet look needs a FRONTEND pass.
4. Chopsticks: on tables = customers' hands (grab, wiggle). On the floor = chopsticks **and spoons** dropped from above; they hurt while falling and stay on the ground. On tables, dropped items don't exist.
5. A roll knocks a 단무지 flat (it lies still); it doesn't kill it.
6. 찜기: one full heal + auto-save, then nothing more. Saves will later load from the main menu. 1–2 per map; Map 1 = dining room middle + before the boss arena.
7. Save stores the keys in §4 (3b-iii); not the kill counter.
8. Respawn at the most recent 찜기 or checkpoint.
9. Dining room is ongoing tables with occasional windowsills reached from napkin boxes.

## 6. Deviations (from docs, prompts or roadmap)

| Item | Planned | Built |
|---|---|---|
| Roadmap Phase 3 (all systems in the test room first) | Finish Phase 3 before Map 1 | Building Map 1 directly; systems added as needed (already noted in log 005) |
| 단무지 flat platform | Bridges a gap | Wall-adjacent rise (a flat wheel can't bridge a gap at believable size) |
| 단무지 downhill speed-up | Roster | Deferred (no slopes yet) |
| 김밥 uncut charging roll | Roster | Deferred |
| 김밥 landing | spill | Slice survives and leaves a slippery patch |
| Gum after escape | weaker patch or consumed | Consumed for 3 s (`rearm_s`) |
| Sills | shortcuts | Pickups only; one required sill hop |
| Spawning | — | All section enemies spawn at once (not on approach) |
| Wiggle | reuse prologue code | Standalone `systems/wiggle.gd`, same alternation rule |
| Falling items | — | Only hurt below their start height; landed prop non-solid while overlapping him; zones pause beyond 30 m |
| Stools in prologue | — | Allowed as low foreground layer (top ≥ 4 m below him) |
| 찜기 | solid prop | Non-solid, stands in the lane; he respawns 1.6 m to its right |
| DDEOK | — | Plain off-chain int added to GameState |
| `save_version` | — | Stays 1 (all keys additive) |

## 7. Known issues and risks

- 🔍 `rename_absolute` overwrite on Windows unverified; `.bak` fallback exists. Quit-and-relaunch load (key 0) not yet playtested.
- 🔍 DualSense untested for: W-equivalent 찜기 trigger, Options→pause, touchpad inventory, tutorial glyphs.
- Exit leak lines "22 ObjectDB instances leaked / 3 resources still in use" come from autoloads at exit (present since 3a-polish). Not fixed.
- A data checkpoint placed before an already-used 찜기 would overwrite the respawn point. Avoid in map specs, or fix when it matters.
- `roll_break_grace_s` 1.0 may feel like free invincibility; tune in playtest.
- Gray-box visuals only. FRONTEND later: giant feet, realistic hand/mouth, 라면 as a chopstick-lifted clump of noodles, 만두 sizes, falling items.
- ⚠️ Native-speaker review of her lines (esp. "젠장아!") and "여기 치즈 추가요!".

## 8. Playtests still owed by NHMH

1. 3b-ii-fix2: roll wheel 1 first; wait ~4 s; finish via both routes; land at the dining-room start.
2. 3b-iii: use the 찜기 hurt (full hearts, steam off, disk icon); second use does nothing; die → respawn there; quit, relaunch, key 0 → lands at the used 찜기; roll through 김밥 without instant damage.
3. Older unchecked items from log 005 (container pickup, heal order, coat after death, □ drop, DualSense).

---

## 9. Plan for 3c (🟡, confirm at the start of the next session)

Read first: Enemy Roster v0.1 §2, §3, §5 (라면, 군만두/김말이튀김); Boss Sheet v0.1 §3.1 (arena); log 005 for what 2a/2c built.

**Existing pieces to reuse (🔍 the agent must check what exists before adding):** test-room `noodle_dummy` (creep), fried dummies s/m/l with `deteriorate` (3 steps × hits_per_stage), `usable_object`, `water_sheet`, `env_special_def` (env specials cost 나트륨), thrown pots (counted as Ddeok kills in 3a-oil), `unlocks_skill_on_first_defeat` (first 라면 → sauce flick), sauce flick / absorb, drop system (라면 drops a larger 나트륨 amount).

### 3c-i — the first 라면
- New section after the dining-room end wall (or the end of the dining room).
- A 정수기 where he fills a cup/bottle (pour-water special, costs 나트륨 ❓).
- The first 라면 (★★★): creeps, lashes at medium range (1 heart), contact 1 heart; landing/stomp → hurt_player; roll/slam/sauce → absorb; water → swell → collapse → kill; death drops 나트륨 (larger).
- First defeat unlocks the sauce flick (toast). Flick is not usable before.
- The section must teach "you can't fight this head-on": attacks fail visibly; water is offered nearby.
- Soft-lock: water source must never run out (`required_for_progress` or infinite refills).

### 3c-ii — the kitchen
- 군만두 (small, hops fast) and 김말이튀김 (medium, large; slides and lunges). landing → bounce_off + deteriorate; stomp/roll/slam/sauce → deteriorate; heavy object → kill; boiling water → kill 🟡. Size sets durability.
- A fryer that keeps spawning them (cap and interval in data).
- Heavy-object special introduced here: 뚝배기 / pot / steel bowl dropped from above: kills 튀김; pins a later 라면 (bigger object, longer pin; pinned 라면 only hurts if he goes near).
- A later 라면 or two (★★), now beatable with water or pinned.

### 3c-iii — pre-boss
- Pre-boss 찜기 (second Map 1 찜기).
- The 치즈라볶이 arena in gray box: the big pan on a gas burner, room for the boss, heavy object reachable near the burner (needed for the cooling rule in 3d).
- Map exit after the arena (to the street / Map 2 placeholder), locked until the boss is beaten.

### Candidate questions for the start of 3c-i (max 4 at a time)
1. ❓ Where is the 정수기: at the end of the dining room or at the counter by the kitchen door?
2. ❓ 나트륨 cost per water pour (roster says ❓; suggest 1).
3. ❓ Does the first 라면 block the path (must be beaten to proceed) or can it be avoided?
4. ❓ Should the 3b-ii dining-room end wall become the 라면 room entrance, or is there a transition (the counter, a doorway)?

Later (3c-ii/iii): fryer destroyable or not; how the heavy object is reached (shelf, knock it off with a roll); exit form (door to the street; the "food-waste bin" episode-exit idea is for later episodes).

## 10. Carried open items

- Systems Spec v0.2 (new reactions `spill`, `break_line`, `bounce_boost`, `swell`, `pin`; stick; respawn/required rules; 찜기 rules) — not written yet.
- Map 1 spec v0.1 was skipped (Phase 1 steps 3–7 skipped, log 005). Layout lives in `map01_layout.tres`.
- Double jump, talking, merchant, main-menu save/load UI, rebinding — later.
- Log 005 §9 open items still apply.

## 11. Docs

- No production docs changed or superseded this session.
- This log: `documentation/logs/bunshik-hell_log-006.md`.
