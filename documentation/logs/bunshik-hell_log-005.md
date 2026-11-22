# Bunshik Hell Project Log 005

**Sessions:** 17–21 November 2026 (Asia/Seoul)
**Modes:** CHAT (enemies, bosses), then DEV (Tasks 2a–2c-fix)
**Status labels:** ✅ decided · 🟡 suggested · ❓ open · 🔍 verify · ⚖️ needs a professional
**Previous log:** `bunshik-hell_log-004.md`
**Repo path for this file:** `documentation/logs/`

> **New session? Start here.** Read this log, then the documents in §1. The next step is in §10.

---

## 1. Documents

| Document | Repo path | Status |
|---|---|---|
| `bunshik-hell-episode-1-enemy-roster-v0.1.md` | `documentation/production/` | **New.** Roadmap Phase 1, step 1. Partly overtaken (§7). |
| `bunshik-hell-episode-1-boss-sheet-v0.1.md` | `documentation/production/` | **New.** Roadmap Phase 1, step 2. |
| `bunshik-hell-episode-1-master-roadmap.md` | `documentation/roadmaps/` | Frozen. Departed from (§8). |
| `bunshik-hell-systems-spec-v0.1.md` | `documentation/production/` | Overtaken in many places (§7). v0.2 still to write. |
| `bunshik-hell-dev-decisions-v0.1.md` | `documentation/production/` | Overtaken in places (§7). |
| `bunshik-hell-episodes-and-maps-v0.1.md` | `documentation/production/` | Overtaken in places (§7). |
| `bunshik-hell_log-004.md` | `documentation/logs/` | Previous log. |

❓ **Repo state:** confirm the docs commit (logs 003–004, roadmap, Episodes and Maps v0.1, roster v0.1, boss sheet v0.1) went through. `git status` during Tasks 2a–2c never showed the documentation folder, so they are either committed or were never copied in.

---

## 2. Working rules agreed this session

| # | Rule | Status |
|---|---|---|
| 1 | **Questions are numbered, no more than 4 at a time**, and the reply says whether more are coming. | ✅ |
| 2 | **Build the actual game now** and improve it from there, rather than more test-room work and more documents first (§8, §10). | ✅ |
| 3 | **Play the game from the Godot editor with F5.** Close the editor before `git pull` and while Claude Code works. | ✅ |

---

## 3. Design decisions (CHAT)

### 3.1 Enemies (full detail in Enemy Roster v0.1)

| # | Decision | Status |
|---|---|---|
| 1 | **The first 라면 beaten unlocks the sauce flick** (in Map 1). 라면 absorbs sauce; it's beaten with **water** (swells and collapses) or **pinned** by a heavy object (longer with a bigger object). Swelling on its own (B) is kept in reserve. | ✅ |
| 2 | **Skills come from wherever NHMH decides**, not only bosses and friends. | ✅ |
| 3 | **No 어묵 enemy in Episode 1** (introduced in a later 포장마차 map). **단무지 teaches the roll.** | ✅ |
| 4 | **튀김 near the end of Map 1: 군만두 (small) and 김말이튀김 (medium, large).** More 만두 types come with later restaurants. | ✅ |
| 5 | **Environment specials appear later in Map 1, at most 2 types: pour water (introduced at the first 라면) and heavy object (introduced at the 튀김).** | ✅ |
| 6 | **Enemies sometimes drop** sauce, 나트륨, health items or DDEOK, only what the real food would have. | ✅ |
| 7 | **Enemies repeat across maps** where they fit the location. | ✅ |
| 8 | **Metal chopsticks can grab Ddeok Dude**; wiggling free is easy. | ✅ |
| 9 | Later 라면 are ★★ (the first is ★★★). | 🟡 |
| 10 | **번데기**, not 뻔데기. Fixed in code or roster v0.2 if the name ever appears in the game. | ✅ |
| 11 | **The 라면 enemy looks like a clump of noodles bunched together, as if lifted with chopsticks to eat — not a bowl of 라면.** (For FRONTEND.) | ✅ |

### 3.2 The prologue (for the Map 1 spec; full list in Enemy Roster v0.1 §8)

| # | Decision | Status |
|---|---|---|
| 1 | Cutscene: glimpses of the shop → her table → her cup. **"오~~~ 맛있겠다~~~~~"** while she stabs Ddeok Dude and brings him slowly to her mouth. Her full face and body aren't shown. | ✅ |
| 2 | **Wiggle off the pick by mashing left and right**, or she chews him up: game over, restart at the 맛있겠다 moment. | ✅ |
| 3 | Then only her hand and the pick, stabbing from above, at **a single counter table by the window**. | ✅ |
| 4 | **Small stabs ½ heart. A big stab takes 1 heart and lifts him on the pick** (wiggle off again). | ✅ |
| 5 | **Survive 30 stabs.** The count doesn't restart after a hit; **being eaten restarts everything from 맛있겠다.** The number may change. | ✅ |
| 6 | **The stabbing is varied and unpredictable**, with her lines rising in anger. She sometimes stabs a 만두 instead, which slows her briefly. Dodging the 30th opens the exit. | ✅ |
| 7 | **Her lines exactly as NHMH wrote them; not to be changed without NHMH's say.** ⚠️ Native-speaker review. | ✅ |

### 3.3 Bosses (full detail in Boss Sheet v0.1)

| # | Decision | Status |
|---|---|---|
| 1 | **Map 1: 치즈라볶이.** At 50% health, **치즈 추가**: harder attacks and some health back. 어묵 sheets are part of its body. | ✅ |
| 2 | **Map 2: 쥐포 on the 연탄 brazier.** | ✅ |
| 3 | **Map 3: 미역국 Kelp Leviathan.** | ✅ |
| 4 | **World final boss: 꽁당보리밥, the 혼분식 Titan** (working name), chosen for 혼분식's historical importance to 분식 culture. | ✅ |
| 5 | **The final boss is never a food or any recognizable real thing**: an imaginary monster mutated from many things. | ✅ |
| 6 | **No dream world.** The final fight happens in a real place (Phase 8). | ✅ |

### 3.4 Ddeok Dude

| # | Decision | Status |
|---|---|---|
| 1 | **His name is Ddeok Dude** (no longer a working nickname). | ✅ |
| 2 | **He is a 쌀떡.** | ✅ |

### 3.5 Systems (decided during the DEV tasks)

| # | Decision | Status |
|---|---|---|
| 1 | Flick: straight horizontal shot in the facing direction, ~8 m, 1 sauce, 0.3 s cooldown (data). | ✅ / 🟡 values |
| 2 | Refills: pool +1 per 0.5 s up to 7; drip +1. | ✅ / 🟡 values |
| 3 | **참기름 is not carried.** It **heals ½ heart instantly on touch**, dripping from **real, solid objects** every 10–30 s (varies per source) and found smudged on things. If the object makes sense to stand on, Ddeok Dude can stand on it. | ✅ |
| 4 | **조청 and 꿀 are separate items, 1 heart each.** 콩고물: 1 heart + a coat that blocks the next hit's damage. **No 2-heart item** for now. | ✅ / ❓ 2-heart item |
| 5 | **Starter container: 3 slots, no stacking** (may change). | ✅ |
| 6 | The game **pauses** while the inventory is open. | ✅ |
| 7 | UI in English for now, translation-ready; **a language setting later.** Korean labels render correctly. | ✅ |
| 8 | **DualSense menus: ✕ confirms, ○ closes.** Inventory on the **touchpad**. | ✅ |
| 9 | Special costs **1 나트륨**; a usable object **highlights** when Ddeok Dude is next to or on it. | ✅ / 🟡 value |
| 10 | Drops: **25%** per entry, **guaranteed after 4 dry kills** per enemy type. | 🟡 |
| 11 | Heal order ties: plain items before 콩고물, then oldest first. | 🟡 |
| 12 | The coat survives death and respawn. | 🟡 (not yet playtested) |

---

## 4. What was built

All work on the PC (Windows) except Task 2b (laptop, CachyOS, fish). Godot 4.7.2.

| Task | Built | Tests (fast / full physics run) | Commit |
|---|---|---|---|
| **2a** | Sauce resource (3/7), the **flick** (skill-locked), pool and drip refills, sauce types as data (one: gochujang), reaction-table cells holding a **list** of reactions, `deteriorate` (3 steps × hits_per_stage), `jam`, `absorb` flash; **first-defeat skill unlock** (`unlocks_skill_on_first_defeat`). Dummies: 라면, 튀김 ×3, tube. | 91 / 150 | "Task 2a: …" ✅ |
| **2b** | Health items as data (콩고물, 조청, 꿀), the **starter container** (3), pickup → inventory (none without a container), the **full popup**, heal button (lowest first; Settings default), **coat**, inventory screen (pauses), **inventory on the touchpad** (`JOY_BUTTON_TOUCHPAD` = 20), `drop_item` action (G, X/□), **참기름** drops, puddles and smudges, `item_catalog` (save ids can't become file paths). | 123 / 196 | "Task 2b (WIP, partial playtest): …" ✅ (from the laptop) |
| **2c** | 나트륨 pickups, **pour water** and **heavy object** specials (highlight, single-use, nearest wins), `swell` and `pin`, water and heavy_object columns, **creeping 라면**, **enemy drops** (seeded RNG, bad-luck protection), **standable 참기름 objects** (bottle, shelf; non-standable oil brush), menu-press gate (`GameplayInput`), `ui_accept`/`ui_cancel` on the controller. | 162 / 264 | "Task 2c: …" ✅ |
| **2c-fix** | **✕ confirms, ○ closes**; 4th 나트륨 pickup. | 162 / 264 | "Task 2c-fix: …" (❓ confirm pushed) |

The failing-fixture check (`-- --fixtures-only`) still exits 1 (checked after 2a).

---

## 5. Deviations in the builds

| Task | Deviation |
|---|---|
| 2a | Deteriorate takes **3** steps × hits_per_stage (3 / 6 / 9 hits), not 4 ×: the prompt contradicted itself; 3 is correct. |
| 2a | New content on a new floor left of the start. Key 2 also clears defeat records. Tube fires only within 12 m. Cycling sauce types needs the flick. save_version stays 1 (additive keys). |
| 2b | Extra `drop_item` action (G, X/□). `pickup_color` on ContainerDef. Unknown save item ids kept but inert. Key 2 clears the coat. The coat persists through death. Chain-popup guard. Key 3 hides/restores pickups. Inventory UI polls input in `_process`. Esc closes the inventory. |
| 2c | `GameplayInput` gate blocks gameplay presses for 2 physics ticks after a menu closes (`Input.action_release` doesn't clear "just pressed" in 4.7.2). `ui_accept`/`ui_cancel` overridden rather than new actions. The pinned 라면 stands by the table leg, not under the tabletop. Floor extended to x = −102. `standable` is an export on the placed node, not a .tres field. Extra data fields (EnvSpecialDef, EnemyDef). Water sheet hits each enemy once; guaranteed drop uses the highest-chance entry; drop streak not saved; HUD reads "Sodium (나트륨)". |
| 2c-fix | Cancel tests also check that the closing ○ doesn't roll. |

---

## 6. Playtest results

| Check | Result |
|---|---|
| 2a flick, refills, 튀김 stages, 라면 slurp, tube jam | ❓ Feel not reported |
| 2b full inventory popup · Tab opens inventory · 참기름 falls and heals · Korean labels | ✅ |
| 2b container pickup · heal order · coat (and coat after death) · □ drop not firing a flick | ❓ Not yet checked |
| 2c heavy object kills 튀김 · water swells 라면 and **unlocks the flick without a debug key** · pin then soak · standable oil objects · drops | ✅ |
| 2c dim highlight with 0 나트륨 | ❓ Probably passes |
| 2c DualSense: closing a menu doesn't jump, roll or flick | ✅ |
| 2c-fix DualSense ✕ confirm / ○ close | ❓ 30-second check suggested before commit |

---

## 7. Where earlier docs are now out of date

| Doc | Says | Now |
|---|---|---|
| Systems Spec v0.1 §3.1 | Sauce flick 🟡 Map 2; skills only from bosses and friends | Map 1, first 라면; skills from wherever NHMH decides |
| Systems Spec v0.1 §6.1 | 참기름 a carried item; 조청 or 꿀 2 hearts | 참기름 instant heal from objects; 조청 and 꿀 separate, 1 heart each |
| Systems Spec v0.1 §8 | Reaction list; one reaction per cell | Adds `deteriorate`, `jam`, `swell`, `pin`; cells hold lists; water and heavy_object columns |
| Systems Spec v0.1 §3.1, log 003 | Stomp, starting values, inventory etc. | Log 003 §4 list still stands |
| Dev Decisions v0.1 §6 | Inventory View/Touchpad | Built on the touchpad |
| Episodes and Maps v0.1 | "Mutant 라볶이"; 라면 can't be fought; other bosses ❓ | 치즈라볶이; 라면 beatable; 쥐포, 미역국, the 혼분식 Titan |
| Enemy Roster v0.1 | 라면 "rising out of its bowl"; 뻔데기 | A clump of noodles as if lifted by chopsticks; 번데기 |
| Log 002 §4 | "Ddeok Dude" working nickname | His name |

Systems Spec v0.2 picks these up when it's next needed.

---

## 8. Departures from the Episode 1 Master Roadmap

| Roadmap | Plan | Now |
|---|---|---|
| Phase 1 gate | Steps 3–7 (characters, skill sources, containers, Map 1 spec, Systems Spec v0.2) before building | **Skipped for now.** NHMH's call: build the game and improve it from there. The Map 1 layout is settled in the build prompts instead of a separate spec. |
| Phase 3 | All core systems in the test room before Map 1 | Steps 1–4 done (sauce, health items, inventory, 나트륨 and specials). Double jump, talking, merchant, final HUD, pause/settings/rebinding, save at 찜기 and continue: **deferred** until Map 1 needs them. |
| Phase 4 | Map 1 after Phase 3 | **Starting now** (§10). |

---

## 9. Open items

**New**
1. ❓ Confirm the docs commit and the 2c-fix push (§1, §4).
2. ❓ A 2-heart item, if any.
3. ❓ The 치즈라볶이's reward; the final boss's place and the ending's staging (Phase 8).
4. 🔍 김말이튀김 at 김밥천국-style shops; a water pitcher on tables; 뻔데기/번데기 at school gates; 요구르트 and 미역국 in 급식; 어묵 in 라볶이.
5. ⚠️ Native-speaker review: the prologue lines; 여기 치즈 추가요!
6. ⚖️ The Titan's campaign-jingle parody must be original.
7. 🟡 Every gameplay number (playtests).

**Carried from log 004**
8. ❓ Does Episode 1 launch with on-chain on, or get it in an update?
9. ❓ DDEOK website domain: ddeok.org or ddeok.xyz.
10. ❓ Laptop git identity (global vs repo-local).
11. ❓ Art repo name; 🔍 GitHub LFS limits.
12. ❓ SDK milestone order and Bunshik Hell's first on-chain features.
13. ⚖️ README copyright holder; asset licence switch; AI music copyright.
14. From log 002: the woman's identity; episode exits and order; missing third maps; 감칠맛; real-place facts 🔍; Suno terms 🔍.

---

## 10. Next

**Build Map 1 for real, starting with the prologue** (MODE: DEV): the opening cutscene, the wiggle off the pick, and the 30 unpredictable stabs at the window counter table, with her lines as written. Then the long Map 1 itself (tutorial, dining room, the first 라면, the kitchen and 튀김, a 찜기, the 치즈라볶이 arena, the exit), using the systems from Tasks 2a–2c and the real Map 1 enemies.
