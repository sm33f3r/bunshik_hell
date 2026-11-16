# Bunshik Hell Project Log 002

**Sessions:** 11–16 November 2026 (Asia/Seoul)
**Mode:** CHAT (planning). No code was written.
**Status labels:** ✅ decided · 🟡 suggested · ❓ open · 🔍 verify · ⚖️ needs a professional
**Previous log:** `bunshik-hell-phase-1-project-log-001.md`
**Repo path for this file:** `documentation/logs/`

---

## 1. Documents

| Document | Status |
|---|---|
| `bunshik-hell-phase-1-project-log-001.md` | Previous log. Its §8 open items are carried into §11 below. |
| `bunshik-hell-episodes-and-maps-v0.1.md` | **New this session.** Production doc. Partly overtaken by later decisions (§9). |
| `BUNSHIK_HELL_GAME_DESIGN_BIBLE_PART_1.md` | Record. `BUNSHIK_HELL_GAME_DESIGN_BIBLE.md` in the Project is an identical copy. |
| `Bunshik_Hell_Game_Development_Plan.md` | Record. `Bunshik_Hell_Game_Development_Plan (1).md` is an identical copy. |
| `Bunshik_Hell_Demo_Master_Roadmap.md` | Frozen. To be followed by a new Episode 1 roadmap (§10). |

---

## 2. Document policy

| # | Decision | Status |
|---|---|---|
| 1 | Older documents are records of what was brainstormed and planned. Newer plans win when they conflict. | ✅ |
| 2 | Logs and roadmaps are never edited. The project only moves forward. | ✅ |
| 3 | Story and much of the design are decided one step at a time, often after building begins. | ✅ |

---

## 3. Identity, platform and release

| # | Decision | Status |
|---|---|---|
| 1 | **3D game seen from the side**, played like a platformer (2.5D). Replaces the Bible's and the roadmap's 2D. | ✅ |
| 2 | Art made with **Blender, Blender Grease Pencil** and other tools. | ✅ |
| 3 | Released independently under **NHMH (니가 한국어 못해)**, on NHMH's own website (from an earlier NHMH funding session). | ✅ |
| 4 | Korean title **분식헬** (from the DDEOK whitepaper style sheet). | ✅ |
| 5 | Released in **episodes**, ongoing until NHMH decides to finish. | ✅ |
| 6 | The **only non-educational NHMH series**: a game for fun and for messing with people's heads. | ✅ |
| 7 | On **Sui with DDEOK rewards**, like the other NHMH games. | ✅ |
| 8 | Background music made in **Suno Pro**. Suno's help centre (edited 7 Jan 2026) says songs made on a paid plan belong to the user, with commercial use kept after cancelling. 🔍 Recheck the full terms before release. ⚖️ Copyright status of AI music. | ✅ |
| 9 | Renderer: 🟡 **Forward+** suggested for 3D lighting. The project was created without choosing; check `game/project.godot` 🔍. | ❓ |
| 10 | 🔍 Grease Pencil strokes probably don't export to Godot through glTF and would need baking or rendering. | 🔍 |
| 11 | The Worms-style squiggle is built in 3D (🟡 Blender shape keys or bones), replacing log 001's frame-based sprite plan. | 🟡 |

---

## 4. Story and structure

| # | Decision | Status |
|---|---|---|
| 1 | The 떡 (working nickname "Ddeok Dude") **has no mission**. He moves onward and survives. | ✅ |
| 2 | **Opening:** the 떡 is speared on a **wooden pick** from a cup of 떡볶이 and slides off just before a woman puts him in her mouth. She is the first enemy or obstacle, stabbing at him again and again. Probably an indoor 분식집. | ✅ |
| 3 | **The woman's identity is undecided.** She may be a crossover character. | ❓ |
| 4 | **Episode 1 ends** after its final boss: the pick stabs the 떡 and the woman swallows him. | ✅ |
| 5 | **Episode 2, Inside the Woman**, follows: her stomach, then the toilet race. How fast the player gets him out decides where he lands next (noraebang, 포차, 노가리포차, the 회식 toilet, or the sewer to a 종로3가 포장마차). | ✅ concept / ❓ branching |
| 6 | **Each episode has its own exit** (toilet, vomited onto a street, thrown in a food-waste bin…). | ✅ concept |
| 7 | **The date is a mystery** and doesn't follow logical rules, so crossover characters can be any age. | ✅ |
| 8 | **Crossover characters** from Noraebang Night and Hangul Hiking Trip appear alongside original characters. Who, where and when is decided in session. | ✅ |
| 9 | **Realism serves the satire.** Food, cuisine and settings are true to life. | ✅ |
| 10 | Satire targets usually go **unnamed**. Parody names are decided later, if needed. ⚖️ Defamation and trademark check for any satirical name of a real business. | ✅ |
| 11 | Order of brainstorming: locations → enemies → bosses → friends → merchants. | ✅ |

---

## 5. Worlds, episodes and maps

Full list in `bunshik-hell-episodes-and-maps-v0.1.md`. Summary:

| # | Decision | Status |
|---|---|---|
| 1 | **One world is one episode**, with its own theme. | ✅ |
| 2 | **No more than 3 maps per episode.** | ✅ |
| 3 | **Map bosses** are recognizable food (or non-food) monsters. **World final bosses** are gigantic, absurd, difficult, original monsters that grow out of food culture but are unrecognizable. | ✅ |
| 4 | **Episode 1, "Yummy! Bunshik for Lunch"** (working title): daytime school-kid 분식, lunchtime. Maps: a 김밥천국-style lunch 분식집 ✅, school-gate street and 문방구 🟡, school cafeteria ✅. | ✅ |
| 5 | **Episode 1 has no alcohol or cigarette enemies.** | ✅ |
| 6 | **The Mutant 라볶이 is the 분식집 map boss.** | ✅ |
| 7 | **No 라면 boss.** 라면 stays a regular enemy you can't fight. | ✅ |
| 8 | **Cut:** the 분식지옥 world. **Kept:** everything else from the old plan (Fryer Hell, Sundae Kingdom, the old bosses). The 분식집 Owner is ❓. | ✅ |
| 9 | Winter in Seoul holds the **군고구마 cart (giant 고구마 boss)** and the **붕어빵 cart**, as separate maps. | ✅ |
| 10 | **New maps:** dessert cafe, bakery cafe, 한강 picnic, 전기통닭 truck, 노가리포차, 전주 가맥 with 황태구이, 피순대, a 곱창·막창·대창·염통·생간 포차, a school cafeteria. Busan oyster 포장마차 ✅. | ✅ |
| 11 | The dessert cafe goes to a **new episode satirizing typical Seoul dates**. | ✅ |
| 12 | **Busan comes later.** | ✅ |
| 13 | All episode names other than Episode 1's are placeholders. | ✅ |

---

## 6. Episode 1 enemies (accepted as the starting draft)

Accepted as listed; changes come later. ★ easy · ★★ medium · ★★★ hard · 🚫 escape only.

| Map | Enemies and hazards |
|---|---|
| Lunch 분식집 | 만두 ★ · 김밥 slices (train line, uncut roll charges) ★★ · 단무지 wheels ★ · 라면 🚫 · hazard: other customers' metal chopsticks |
| School gate and 문방구 | 뻔데기 swarm ★ · 떡꼬치 (skewered 떡, spinning and jabbing) ★★ · 쫀드기 whips ★★ · tube candy firing pellets ★★ · hazard: spilled 슬러시 |
| School cafeteria | 흰 우유 carton (milk geysers) ★★ · 깍두기 dice ★★ · 나물 반찬 tangle ★★ · 요구르트 rocket ★ · hazards: serving ladle, 잔반통 pit ★★★ |

---

## 7. Abilities, controls and combat

### 7.1 Skills

| # | Decision | Status |
|---|---|---|
| 1 | **Skills are earned through play.** He starts with move, **jump** and **bounce**. | ✅ |
| 2 | Skills come from **boss rewards and friend characters** (not found lying around). | ✅ |
| 3 | **Roll** is gained late in the tutorial. | ✅ |
| 4 | **Double jump** is learned later in Episode 1 (🟡 Map 3). | ✅ / 🟡 map |
| 5 | **Sauce flick** is learned, basic and without aiming at first (🟡 Map 2). | ✅ / 🟡 map |
| 6 | Several sauce attack types: flick, long-range sniper shot, spin, more later. The spin is learned later (🟡 a later episode). | ✅ |

### 7.2 Controls v0.1 (approved)

| Action | Keyboard + mouse | Controller (Xbox / PlayStation) |
|---|---|---|
| Move | A / D | Left stick |
| Look up · talk · enter | W | Stick up |
| Look down · drop through | S | Stick down |
| Jump · double jump | Space | A / ✕ |
| **Stomp** (S or down in the air) | S in the air | Stick down in the air |
| Roll | Left Shift | B / ○ |
| **Slam** (roll in the air) | Shift in the air | B / ○ in the air |
| Sauce attack | Left mouse | X / □ |
| Cycle sauce type | Q, mouse wheel | RB / R1 (LB / L1 back) |
| Aim (later skills) | Mouse | Right stick |
| Environment special (나트륨) | Right mouse | Y / △ |
| Instant heal | R | LT / L2 |
| Inventory | Tab | View / Touchpad |
| Pause | Esc | Menu / Options |

All keys can be rebound, and the layout grows as weapons are added. ✅

### 7.3 Combat rules

| # | Decision | Status |
|---|---|---|
| 1 | **Plain landing** does a little damage to soft enemies, enough to kill weak soft ones early in an episode. | ✅ |
| 2 | **Stomp:** a quick single-target kill. Kills 만두 and 뻔데기. | ✅ |
| 3 | **Slam:** a heavier drop that breaks things (cracked floors, tray stacks) and hits the area around where he lands. | ✅ |
| 4 | **Sauce attacks share one button**; another button cycles the type. Each type costs a different amount of sauce and does different damage. | ✅ |
| 5 | Sauce costs and damage are set **after building and playtesting**. | ✅ |
| 6 | **Environment special attacks** spend **나트륨**. | ✅ |

---

## 8. Resources, health and the tutorial

| # | Decision | Status |
|---|---|---|
| 1 | **Hearts, sauce and 나트륨 all cap at 7.** | ✅ |
| 2 | **나트륨** is a collectible found at random. | ✅ |
| 3 | **감칠맛** may be a separate resource for charm or persuasion. | ❓ |
| 4 | **Sauce refills:** sauce pools and dipping dishes (large), drips scavenged off floors and walls (small). | ✅ |
| 5 | A hurt 떡 goes **hard and cracked**, like stale 떡; healing makes him soft again. The hearts can show this. | ✅ |
| 6 | **Health items:** 참기름 drop (½ heart) · 조청 or 꿀 (2 hearts, rare) · 콩고물 (1 heart plus a coat that blocks one hit) · **찜기 steam** (full heal and a checkpoint). | ✅ |
| 7 | **Instant heal** uses the **lowest healing item** in the inventory first, then moves up. A setting lets the player choose a different default. | ✅ |
| 8 | **The tutorial is optional and part of Map 1.** It guides the player through an exercise with the controls and attacks, covering only abilities already available. | ✅ |

---

## 9. Deviations

| Source | Said | Now |
|---|---|---|
| Demo Master Roadmap | 2D; a 0.1 demo of one level and one boss on itch.io | 3D side view; Episode 1 with 3 maps, a tutorial and a final boss, released on NHMH's site |
| Demo Master Roadmap | Mutant 라볶이 as the demo boss | Map boss of the 분식집 |
| Demo Master Roadmap Phase 2 | Frame-based squash-and-stretch prototype | 3D deformation (🟡 shape keys or bones) |
| Bible §1, §20 | 2D action-platformer | 3D side view |
| Bible §18 | Controls, health, special abilities open | Controls v0.1, caps of 7, health items, skill progression decided (§7, §8) |
| Log 001 | Phase 1 working decisions on sauce, roll, bounce and health deferred to Phase 2 prototyping | Some now decided on paper; tuning still happens in playtests |
| Episodes and Maps v0.1 §3 | Mutant 라볶이 map ❓ | 분식집 ✅ |
| Episodes and Maps v0.1 §6 | Butts and caps "rare or absent" in Episode 1 | Absent ✅ |
| Episodes and Maps v0.1 §3 | Tutorial not mentioned | Optional tutorial inside Map 1 ✅ |

---

## 10. Documents to write before building (approved order)

**Before any code**
1. ✅ This log.
2. **Dev decisions v0.1**: repo layout (content folders inside `game/`), renderer, enemies as data, AGPL `LICENSE`, DDEOK and Sui deferred to a shared addon.
3. **Systems spec v0.1**: movement, skills and unlock order, controls, resources and caps, refills, health items and instant heal, damage rules, the food-physics reaction table.

Then the **떡 prototype in a gray test room** (move, jump, bounce, stomp, roll).

**Before Map 1**
4. **Episode 1 roadmap** (frozen once written). ✅ approved
5. **Episode 1 enemy roster v0.1**
6. **Map 1 spec v0.1** (lunch 분식집): prologue, the woman, the tutorial, roll unlock, placement, 찜기 checkpoints, the Mutant 라볶이, the exit to Map 2.

**Later:** style brief (before the art pass), friends, merchants, music briefs, 감칠맛.

---

## 11. Open items

**Carried from log 001 (status not confirmed this session)**
1. 🔍 Was the `game/` (Godot project) commit pushed?
2. 🔍 Renderer setting in `game/project.godot`.
3. 🔍 Does a LICENSE file exist on GitHub? Add **AGPL-3.0** and the README note on assets.
4. ❓ Move existing docs into `documentation/roadmaps/`, `design/`, `production/`, `logs/`.
5. ❓ Rename `BUNSHIK_HELL_FIRST_IDEAS.md ` (trailing space).
6. ❓ Global versus repo-local git identity on the laptop.
7. ⚖️ Lawyer review: AGPL code / asset rights split, contributor rights, crypto payments and tax.

**New**
8. ❓ The woman's identity.
9. ❓ How episode exits branch once episodes release separately.
10. ❓ Episode order after Episode 2; episode names.
11. ❓ Missing third maps (dating, market, Jeonju, Winter in Seoul, Fryer Hell, Sundae Kingdom); the two Busan maps beside the oyster 포장마차.
12. ❓ Episode 1 final boss, the other Episode 1 map bosses, and the 분식집 Owner.
13. ❓ 감칠맛's role.
14. ❓ Sauce attack costs and damage (after playtests).
15. 🔍 Real-place facts: 노가리포차 (을지로), 종로3가 포장마차, 전주 가맥 and 황태구이, 피순대, 전기통닭 trucks, Busan's fish market and 씨앗호떡; Korean school lunch (급식) habits.
16. 🔍 Suno terms recheck before release; ⚖️ AI music copyright.

---

## 12. Next

**Dev decisions v0.1** (doc 2 of §10), then the systems spec.
