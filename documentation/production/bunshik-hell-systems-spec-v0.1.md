# Bunshik Hell — Systems Spec

*Production doc v0.1 · 16 November 2026*
*Repo path: `documentation/production/`*

> Production document. Changes are made by issuing a new version (v0.2…); this file stays unchanged.
> What is actually built, and every deviation, goes in the project logs.
> ✅ decided · 🟡 suggested · ❓ open · 🔍 verify
>
> **Numbers marked 🟡 are prototype starting values only.** Final values come from playtesting.

Reads with: `bunshik-hell_log-002.md`, `bunshik-hell-dev-decisions-v0.1.md`, `bunshik-hell-episodes-and-maps-v0.1.md`, and the Bible (Part 1) as a design record.

---

## 1. The 떡

| # | Rule | Status |
|---|---|---|
| 1 | One single limbless 떡, sauce dripping off his body. He never moves like a humanoid with the limbs removed. | ✅ |
| 2 | Curious, nervous, shy, persistent. He doesn't understand the world; the player often understands the horror first. | ✅ |
| 3 | 3D model seen from the side, locked to one plane (2.5D). | ✅ |

---

## 2. Movement

| # | Rule | Status |
|---|---|---|
| 1 | **Squiggle locomotion**, like the worm in the original *Worms*: lurch back, compress, squiggle forward, pull the body along. The whole body undulates with the direction of travel. | ✅ |
| 2 | Squiggle speed follows input: a light push is a slow squiggle, a full push the full squiggle. | ✅ |
| 3 | **Jump:** bend back → compress → snap straight → launch. Stretched in the air, **SQUASH** on landing, quick recovery. | ✅ |
| 4 | Variable jump height (release early for a short hop). Coyote time and jump buffering. | 🟡 |
| 5 | **Double jump** (skill, §3): press Jump again in the air. | ✅ |
| 6 | **Drop through** thin platforms: S / stick down on the ground. | ✅ |
| 7 | **Look up / look down** (W / S): the camera pans a little; W also talks and enters. | ✅ |
| 8 | **Posture acting** with the upper body. Minimum set for Episode 1: curious lean, startled recoil, nervous idle. | 🟡 |
| 9 | All movement values (speed, acceleration, gravity, jump force, coyote and buffer windows) are editable parameters, not hardcoded. | ✅ |

---

## 3. Skills

| # | Rule | Status |
|---|---|---|
| 1 | **Skills are earned through play** from **boss rewards** and **friend characters**. They are not found lying around. | ✅ |
| 2 | Locked skills are never shown or taught early (including in the tutorial). | ✅ |

### 3.1 Unlock order (Episode 1)

| When | Skill | Status |
|---|---|---|
| Start | Move, jump, **plain landing** damage | ✅ |
| Start | **Stomp** | 🟡 (❓ starting skill or learned) |
| Late in the tutorial (Map 1) | **Roll** | ✅ |
| With the roll | **Slam** (roll in the air) | 🟡 |
| Map 2 | **Sauce flick**, basic, no aiming | ✅ skill / 🟡 map |
| Map 3 | **Double jump** | ✅ Episode 1 / 🟡 map |
| Later episodes | **Sauce spin**, **sniper shot**, aiming, more sauce types | ✅ exist / ❓ when |

---

## 4. Controls

Controls v0.1 as approved in log 002; action names and the full table in Dev Decisions v0.1 §6.

| Action | Keyboard + mouse | Controller |
|---|---|---|
| Move | A / D | Left stick |
| Look up · talk · enter | W | Stick up |
| Look down · drop through | S | Stick down |
| Jump · double jump | Space | A / ✕ |
| Stomp | S in the air | Down in the air |
| Roll · slam (in the air) | Left Shift | B / ○ |
| Sauce attack | Left mouse | X / □ |
| Cycle sauce type | Q, mouse wheel | RB / R1 (LB / L1 back) |
| Aim (later) | Mouse | Right stick |
| Environment special | Right mouse | Y / △ |
| Instant heal | R | LT / L2 |
| Inventory · pause | Tab · Esc | View · Menu |

All rebindable. The layout grows as weapons are added. ✅

---

## 5. Resources

| Resource | Cap | Gained from | Spent on | Status |
|---|---|---|---|---|
| **Hearts** | 7 | Health items, 찜기 steam (§6) | Damage taken | ✅ |
| **Sauce** | 7 | **Large:** sauce pools, dipping dishes. **Small:** drips scavenged off floors and walls | Sauce attacks | ✅ |
| **나트륨** | 7 | Found at random | Environment special attacks | ✅ |
| **감칠맛** | ❓ | ❓ | ❓ Possibly charm or persuasion | ❓ |

| # | Rule | Status |
|---|---|---|
| 1 | ❓ Does the 떡 **start** with the full 7, or start lower and grow to 7 through upgrades? 🟡 Start with 7 hearts and 3 sauce; the sauce bar fills as he finds sauce. | ❓ |
| 2 | Hearts work in **halves** (the 참기름 drop heals ½). | ✅ |
| 3 | **Sauce costs and damage per attack type** are set after building and playtesting. Prototype placeholders: flick 1, sniper 2, spin 3. | ✅ rule / 🟡 values |
| 4 | Sauce attacks share **one button**; another button cycles the type. | ✅ |
| 5 | 나트륨 cost per environment special. | ❓ playtest |

---

## 6. Health and damage taken

| # | Rule | Status |
|---|---|---|
| 1 | A hurt 떡 goes **hard and cracked**, like stale 떡. Healing makes him **soft again**. The hearts can show it, from soft to hard. | ✅ |
| 2 | Damage per hit: 🟡 1 heart from enemies and bosses, ½ heart from minor hazards. | 🟡 |
| 3 | After a hit, a short **invulnerability window** (🟡 about 1 second) with a visible flash. | 🟡 |
| 4 | Death sends him back to the **last 찜기 checkpoint**. Restart is fast (🟡 under 2 seconds), with no long death animation. | 🟡 |

### 6.1 Health items

| Item | Heals | Where | Status |
|---|---|---|---|
| **참기름 drop** | ½ heart | Common, on tables | ✅ |
| **콩고물** | 1 heart, plus a coat that blocks one hit | Uncommon | ✅ |
| **조청 or 꿀** | 2 hearts | Rare | ✅ |
| **찜기 steam** | Full heal, and a **checkpoint** | Fixed spots | ✅ |

### 6.2 Instant heal

| # | Rule | Status |
|---|---|---|
| 1 | Instant heal (R / LT) uses the **lowest healing item** in the inventory first, then moves up. | ✅ |
| 2 | A **setting** lets the player choose a different default item. | ✅ |
| 3 | ❓ When does a pickup go into the inventory instead of healing on touch? 🟡 Pickups heal on touch when he's hurt, and go into the inventory when hearts are full. | ❓ |
| 4 | ❓ Inventory size and how many of each item he can carry. | ❓ |

---

## 7. Attacks

| Attack | Input | What it does | Status |
|---|---|---|---|
| **Plain landing** | Landing on an enemy | A little damage to soft enemies; kills weak soft ones early in an episode | ✅ |
| **Stomp** | S / down in the air | Quick single-target kill on soft enemies (만두, 뻔데기) | ✅ |
| **Roll** | Shift / B on the ground | Knocks over tall, rigid foods (어묵); damages some others | ✅ |
| **Slam** | Shift / B in the air | Heavier drop: breaks objects (cracked floors, tray stacks) and hits the area where he lands | ✅ |
| **Sauce flick** | Sauce attack | Targeted shot; basic, no aiming at first | ✅ |
| **Sauce sniper** | Sauce attack (type) | Long-range shot (later) | ✅ exists |
| **Sauce spin** | Sauce attack (type) | Sprays everything around him (later) | ✅ exists |
| **Environment special** | Right mouse / Y | Spends 나트륨 to use the environment: knock, drop or throw objects, trigger hazards | ✅ |

**Rule:** sauce is not universal damage. Every attack's result comes from the food-reaction table (§8). ✅

---

## 8. Food-reaction table

Every hit is looked up as **attack × material → reaction**. Enemies differ by material, not by hardcoded rules. ✅ Stored as one `.tres` Resource (Dev Decisions §4). ✅

### 8.1 Reactions

`damage` · `kill` · `bounce_off` · `hurt_player` · `absorb` (no effect) · `knock_over` · `extinguish` · `burst` · `deteriorate` (one stage: fresh → broken → crumbling → soggy) · `stick` (slows the 떡) · `jam` (disables a ranged attack) · `push`

### 8.2 Materials and reactions (🟡 Episode 1 starting table)

| Material | Example | Landing | Stomp | Roll | Slam | Sauce | Heavy object |
|---|---|---|---|---|---|---|---|
| soft | 만두, 뻔데기 | damage (kill if weak) | kill | damage | kill | damage | kill |
| segmented | 김밥 slices | spill (slippery rice) | damage | breaks the line | kill | damage | kill |
| crunchy disc | 단무지 | bounce_off | bounce_off | knock_over (flat = platform) | damage | absorb | damage |
| noodle | 라면 | hurt_player | hurt_player | absorb | absorb | **absorb** | absorb |
| skewered | 떡꼬치 | hurt_player (the point) | hurt_player | knock_over | damage | damage (at the base) | kill |
| chewy | 쫀드기 | stick | stick | breaks free | damage | damage | damage |
| tube | tube candy | bounce_off | damage | knock_over | kill | **jam** | kill |
| liquid-filled | 흰 우유 carton | burst | burst | push | burst | damage | burst |
| hard cube | 깍두기 | bounce_off | bounce_off | push | push | absorb | damage |
| tangle | 나물 반찬 | stick | stick | breaks free | damage | **deteriorate** | damage |
| rocket | 요구르트 | hurt_player (while armed) | kill (when empty) | damage | kill | damage | kill |
| tall rigid | 어묵 (Bible) | bounce_off | damage | **knock_over (kill)** | kill | damage | kill |
| fried | 튀김 (Bible) | bounce_off + deteriorate | deteriorate | deteriorate | deteriorate | deteriorate | kill |
| lit | lit cigarette (Bible; not in Episode 1) | hurt_player | hurt_player | hurt_player | hurt_player | **extinguish** | kill |

Bold entries are fixed rules from the Bible or the accepted enemy list ✅. Everything else is 🟡 and gets tuned in playtests. Boiling water kills 튀김 ✅; fryers spawn 튀김 ✅.

---

## 9. Checkpoints and maps

| # | Rule | Status |
|---|---|---|
| 1 | **찜기 steam** = checkpoint + full heal. | ✅ |
| 2 | 🟡 At least one 찜기 before every map boss. | 🟡 |
| 3 | Each episode: up to 3 maps, a map boss on each, one world final boss. | ✅ |

---

## 10. Tutorial

| # | Rule | Status |
|---|---|---|
| 1 | **Optional**, and part of **Map 1**. | ✅ |
| 2 | A guided exercise showing the controls and the attacks **already available**. | ✅ |
| 3 | The **roll** is gained late in the tutorial. | ✅ |
| 4 | ❓ A player who skips the tutorial must still get the roll. 🟡 Skipping grants it automatically. | ❓ |

---

## 11. Settings

Key rebinding · instant-heal default item · audio · display · **play on-chain / play off-chain** (off-chain only until Episode 1 is finished). ✅

---

## 12. Save data (JSON)

Saved: unlocked skills · hearts, sauce, 나트륨 · inventory · last 찜기 checkpoint · current episode and map · defeated bosses. Settings are saved separately. Compact, versioned (`save_version`), stable IDs so items can map to NFTs later. ✅ (Dev Decisions §4, §7)

---

## 13. Open

1. ❓ Stomp: starting skill or learned?
2. ❓ Starting hearts, sauce and 나트륨, versus the cap of 7.
3. ❓ When pickups go into the inventory; inventory size.
4. ❓ Skipping the tutorial and the roll.
5. ❓ When the sauce spin, sniper shot and aiming arrive.
6. ❓ 감칠맛.
7. 🟡 All damage, i-frame, restart and sauce-cost values until playtesting.

## 14. Next

The first DEV task: project setup and the **떡 gray-box test room** (move, jump, landing, stomp, roll and slam, dummy enemies for the soft and tall-rigid materials).
