# Bunshik Hell — Episode 1 Boss Sheet

*Production doc v0.1 · 18 November 2026 · Mode: CHAT*
*Repo path: `documentation/production/`*

> Production document. Changes are made by issuing a new version (v0.2…); this file stays unchanged.
> What is actually built, and every deviation, goes in the project logs.
> ✅ decided · 🟡 suggested · ❓ open · 🔍 verify · ⚖️ needs a professional
>
> **Every attack, number, telegraph and look is 🟡** unless marked ✅. Final values come from gray-box playtests.

**Episode 1 Master Roadmap:** Phase 1, step 2. The 치즈라볶이 is in detail; the other three are at concept level and get full specs in their own phases (6, 7 and 8).
**Reads with:** `bunshik-hell-episode-1-enemy-roster-v0.1.md`, `bunshik-hell-systems-spec-v0.1.md` §7–9, `bunshik-hell-episodes-and-maps-v0.1.md` §1, Bible Part 1.

---

## 1. Rules

| # | Rule | Status |
|---|---|---|
| 1 | **Map bosses are recognizable** food (or non-food) monsters. | ✅ (Episodes and Maps §1 #3) |
| 2 | **The world final boss is not a food or any recognizable real-life thing.** It is an imaginary monster mutated from many different things: gigantic, absurd, difficult, original. It can grow out of food culture and history, but it must be unrecognizable as any one thing. | ✅ |
| 3 | **Every attack is telegraphed.** | ✅ (roadmap) |
| 4 | **Every boss is beaten with food logic**: what the maps before it taught, not raw damage. | ✅ (roadmap) |
| 5 | At least one 찜기 before every map boss. | 🟡 (Systems Spec §9) |
| 6 | **Ddeok Dude is a 쌀떡.** | ✅ |
| 7 | **No dream world.** The final fight happens in a real place. Where it is and how Ddeok Dude gets there is decided in Phase 8. | ✅ / ❓ place |

---

## 2. Episode 1 bosses

| Map | Boss | Detail | Status |
|---|---|---|---|
| 1 · lunch 분식집 | **치즈라볶이** | Full (§3) | ✅ |
| 2 · school gate and 문방구 | **쥐포 on the 연탄 brazier** | Concept (§4) | ✅ boss / 🟡 design |
| 3 · school cafeteria | **미역국 Kelp Leviathan** | Concept (§5) | ✅ boss / 🟡 design |
| World final | **꽁당보리밥, the 혼분식 Titan** (working name) | Concept (§6) | ✅ theme / 🟡 design |

**Not chosen, kept for later episodes:** the 떡꼬치 Skewer (a market or street-cart map), the 식판 Mimic, 현무암 치킨, the 멸치볶음 Hive, the 콩자반 Barrage, the curry flood, and the 도시락 Tower (F1).

---

## 3. Map 1 — 치즈라볶이 (detailed)

### 3.1 Arena and body

| Field | Entry |
|---|---|
| Arena | The kitchen's big pan on a gas burner, at the end of Map 1. A 찜기 just before it. |
| Body | A heaving pan of red 라볶이. Noodle tentacles; **어묵 sheets** folded through it like gills and flaps ✅; a boiled-egg eye that rolls to track Ddeok Dude; 대파 spines; rows of **captive 떡 for teeth**, his own kind stuck inside it. |
| Ddeok Dude has | Everything from Map 1: move, jump, landing, stomp, roll, slam, the sauce flick, pour water, heavy object. |
| Health | Units set in the gray box. **Phase 2 starts at 50%** ✅. |

### 3.2 Phase 1 (100% → 50%): 라볶이

| Attack | Telegraph | Effect |
|---|---|---|
| **Noodle lash** | The noodles coil back; a puff of steam | 1 heart |
| **Boil-over** | Bubbles rise; the surface swells | A sauce wave across the floor; jump over it |
| **떡 spit** | Its sides bulge | Captive 떡 shot out as projectiles (1 heart). They land and stay as stepping stones. |
| **Egg stare** | The egg eye locks on and glows | A body slam on that spot (1 heart and knockback) |
| **어묵 flap** | The 어묵 sheets stiffen and fan out | A gust that pushes Ddeok Dude toward the pan's edge |

**Food logic: everything Map 1 taught**

| Action | Result |
|---|---|
| Sauce on the noodles | **absorb** (the 라면's lesson) |
| Sauce on the egg eye | damage |
| Pour water | The noodles swell (불어), slow down and go limp for a while |
| Heavy object | Pins one noodle tentacle |
| Roll or slam into the 떡 teeth | Knocks 떡 loose. **Its main damage source.** |
| Over time | It keeps cooking: the sauce on the floor reduces (졸아들다) and gets stickier, slowing Ddeok Dude. The fight gets harder the longer it lasts. |

### 3.3 At 50%: 치즈 추가 ✅

| Field | Entry |
|---|---|
| Trigger | 50% health ✅ |
| Event | A shower of cheese pours over it, and it repowers ✅ |
| Health back | ✅ some health back from the cheese / 🟡 to about 65% |
| Voice | 🟡 An unseen customer shouts **여기 치즈 추가요!** (NHMH's call on the line; standard spacing is 치즈 추가) |

### 3.4 Phase 2: 치즈라볶이

Harder attacks ✅. Every Phase 1 attack stays, and gets faster.

| Attack | Telegraph | Effect |
|---|---|---|
| **Cheese grab** | Strands stretch toward Ddeok Dude | `stick`, then he's pulled toward the pan. Wiggle free (left-right mash, as in the prologue). |
| **Cheese curtain** | Drips hang from above | Sticky walls that split the arena |
| **Cheese blanket** | A shadow and dripping | A molten sheet drops over one zone (1 heart and `stick`) |
| **Blister pop** | The cheese bubbles up | Splashes in a ring (½ heart each) |

**The cooling rule (the counter to its healing, 🟡)**

| Step | What happens |
|---|---|
| 1 | Melted cheese cools: it slows down, hardens and turns brittle. |
| 2 | Brittle cheese **cracks** under roll and slam: the 떡 teeth show again. |
| 3 | To soften and heal, it drags itself back over the burner. |
| 4 | A **heavy object dropped onto the burner** blocks it, and the heat is gone for good. |

### 3.5 Defeat

The cheese sets solid and splits open. The trapped 떡 spill out across the kitchen floor. A burnt-cheese crust is left on the bottom of the pan. Then the exit to Map 2.

**Reward:** ❓ (Phase 1, step 4: skill sources).

---

## 4. Map 2 — 쥐포 on the 연탄 brazier (concept)

| Field | Entry |
|---|---|
| Body | A giant flattened filefish on a wire grill over a 구공탄. Its squashed fish face still shows in the dried flesh. |
| Heat stages | Flat and slapping → curling into a rolling tube → edges charred black and brittle (a slam breaks pieces off). |
| Hazards | Flame jets fire in rhythm through the coal's holes. |
| Food logic | Water on the coal → a burst of steam that cools it for a while. |
| 연탄가스 phase | The fumes warp the screen and make Ddeok Dude dizzy (controls drift). |

---

## 5. Map 3 — 미역국 Kelp Leviathan (concept)

| Field | Entry |
|---|---|
| Body | A cauldron of 미역국 rising as a mass of dark, slippery kelp. |
| Core rule | **Every splash makes it swell.** The pour-water special that beat the 라면 makes it bigger and stronger. |
| Twist | **Too much water turns 미역 to mush.** Push it past its limit and it goes limp and collapses. In the middle phase it's at its most dangerous: a risk-and-reward fight. |
| Attacks | Strands that tangle (`stick`). Swelling coils that need the **double jump**. |

---

## 6. World final boss — 꽁당보리밥, the 혼분식 Titan (concept)

**Origin (✅ theme):** the state's 혼분식 campaign of the 1950s–80s. Lunchboxes were inspected for 30% barley, rice 떡 was once banned, and flour from food aid was pushed onto the nation's tables. 분식 culture itself grew out of it. The Titan is **the thing that gave birth to the world of Bunshik Hell**, and it hunts the one thing it forbade: Ddeok Dude is a 쌀떡.

**What it is (🟡):** not a food, not a person, not any real object. A mutation of grain, spoon, tin, flour, loudspeaker, stick and appetite, fused into one living thing.

### 6.1 Body

| Part | Description |
|---|---|
| Skin | An endless hide of **barley grains, each split open into a wet eye**. They blink in waves that roll across the body like wind over a field. |
| Gills | Between the grains, **thousands of tiny tin hinges** open and shut, breathing with a sound like a classroom of lunchboxes snapping closed. |
| Limbs | Long jointed arms ending in **clusters of spoons fused bowl to bowl**, digging like mole claws. Some of the spoons are tongues; they taste the ground for rice. |
| Core | A **pillar of flour that never settles**. It inhales (pulling Ddeok Dude toward it) and exhales (choking dust storms). Deep inside, a stamped **"30%"** flickers like a heartbeat. This is its weak point. |
| Voice | **Loudspeaker throats grown out of its back like coral**, singing an **original** campaign jingle off-key, slowed down, then reversed. Never the real song's lyrics or melody. |
| Spine | A ridge of **몽둥이** that fan out like plates and slam down. |
| Blood | Raw, stretchy dough. Its wounds **bud chimeras**: mutated mixtures of every enemy in the episode (a 만두 with 라면 hair and 김말이 fingers; a 단무지 wheel with 밀떡 teeth; a 군만두 with milk-carton gills). |
| Senses | It smells rice. It always knows roughly where Ddeok Dude is. |

### 6.2 Phases (🟡)

**Phase 1 · The Inspection**
- The ground is layered: barley on top, white rice hidden underneath.
- The spoon claws dig through it, hunting him. **He hides by burrowing under the barley** while a claw passes (avoidance, Bible §11).
- **A 30% meter:** whenever too much white rice is exposed (by his movement or by its digging), the 몽둥이 spine slams down on that area.
- **How to hurt it:** a digging arm's eye-grains are exposed. Stomp them, flick them, slam them.

**Phase 2 · The Campaign**
- The loudspeaker coral sings, and **its rhythm is the telegraph**: attacks land on the beat.
- Flocks of eye-grains peel off its body and swarm.
- On "no-rice days", rice patches on the floor suddenly turn to flour (a callback to the Wednesday and Saturday rice bans).
- **How to hurt it:** sauce **jams** the loudspeaker throats (the tube candy's lesson). Each throat silenced weakens it.

**Phase 3 · The Flour**
- The body collapses into the flour pillar. Its wounds spawn chimeras.
- Inhaling pulls Ddeok Dude in; exhaling blinds the screen with dust.
- **Food logic:** pour water → its flour body turns to **heavy, sticky dough** that slows it down and sticks it in place. Roll and slam break off dough chunks. A heavy object pins a chunk.
- With enough dough broken away, the flickering "30%" heart is exposed.

**Every map's lesson is used:** avoidance (the 라면), hiding and patience (the 요구르트), jam (the tube candy), water (the 라면, turned around by the 미역국), slam (the 번데기), cracking what's brittle (the 쥐포, the cheese).

### 6.3 After the fight

**The ending ✅:** after the final boss, the pick stabs Ddeok Dude and the woman swallows him. Cliffhanger into Episode 2.
**❓ Phase 8:** where the Titan's arena is, and how the woman and her pick reach that moment.

---

## 7. Facts checked

| Fact | Result |
|---|---|
| School 혼식 검사: lunchboxes checked for ≥ 30% barley | ✅ National Archives of Korea; 한국교육신문 (2006); 브라보마이라이프 (2017): teachers with 몽둥이; continued in the 1980s |
| Children hid white rice under barley; teachers dug with spoons | ✅ 한국교육신문 (2006); 뉴스토마토 (2018) |
| 1951 cabinet resolution banning rice-based 떡, 제과 and 엿 | ✅ National Archives of Korea |
| 혼분식 campaign song in schools, mid-1960s–70s | ✅ National Archives of Korea (the real song is never reproduced) |
| Seoul banned rice dishes in restaurants on Wednesdays and Saturdays (1969) | ✅ Seoul Metropolitan Archives |
| Food-aid wheat flour and 분식 promotion | ✅ National Archives of Korea |
| 연탄 = 구공탄; 9 holes, later 19, 22 and 25 | ✅ 서울신문 (2017); thewiki.kr |
| 연탄가스 deaths peaked in the mid-to-late 1970s; called "살인가스" | ✅ 연합뉴스 (2025); 뉴스토마토 |
| 쥐포 grilled on a 연탄 brazier beside a school-gate shop | ✅ brunch memoir |
| Dried 미역 expands a lot in water; soaked too long, it goes mushy | ✅ Maangchi; wikitree (2025); 10000recipe |
| 미역국 as a regular 급식 dish | 🔍 not confirmed |
| 오뎅라면 on a 김밥천국 menu; 어묵 in 라볶이 | ✅ menu (공덕점) / 🔍 어묵 in 라볶이 is common practice, not checked |

---

## 8. Deviations (for log 005)

| Doc | Said | Now |
|---|---|---|
| Episodes and Maps v0.1; Roadmap | "Mutant 라볶이" | **치즈라볶이**, with a 치즈 추가 phase at 50% |
| Enemy Roster v0.1 §1 #7 | No 어묵 in Episode 1 | No 어묵 **enemy**; 어묵 sheets are part of the 치즈라볶이's body |
| Episodes and Maps v0.1 §3 | Map 2 and 3 bosses, world final boss ❓ | 쥐포 · 미역국 · the 혼분식 Titan |
| Enemy Roster v0.1 | 뻔데기 | **번데기** (fixed in code or roster v0.2 if the name appears in the game) |
| Log 002 §4 | "Ddeok Dude" working nickname | **Ddeok Dude** is his name; he is a **쌀떡** |

---

## 9. Open

1. ❓ The 치즈라볶이's reward (Phase 1, step 4).
2. ❓ The final boss arena and how the ending is staged (Phase 8).
3. 🟡 All health, damage, timing and healing values (gray-box playtests).
4. 🔍 미역국 in 급식; 어묵 in 김밥천국-style 라볶이.
5. ⚖️ The campaign-jingle parody: original words and melody only. A check before release that nothing resembles the real song.
6. ⚠️ Native-speaker review: 여기 치즈 추가요!

## 10. Sources

National Archives of Korea (theme.archives.go.kr: 혼식과 분식으로 밥상을 바꿔라; 미곡자급정책; 혼분식 이행실태) · Seoul Metropolitan Archives (불량식품 단속과 혼분식 장려) · 한국교육신문 "보릿고개 벌써 잊었나요?" (2006) · 뉴스토마토 "도시락 변천사" (2018) · 브라보마이라이프 "혼식에는 몽둥이와 당뇨가 최고" (2017) · 서울신문 "[그때의 사회면] 연탄가스 중독" (2017) · 연합뉴스 "[팩트체크] 석탄의 시대" (2025) · thewiki.kr 연탄, 도시락 · Maangchi "mareun miyeok" · wikitree on soaking 미역 · polle.com 김밥천국 공덕점 menu.
