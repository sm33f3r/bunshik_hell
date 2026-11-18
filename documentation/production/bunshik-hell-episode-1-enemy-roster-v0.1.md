# Bunshik Hell — Episode 1 Enemy Roster

*Production doc v0.1 · 18 November 2026 · Mode: CHAT*
*Repo path: `documentation/production/`*

> Production document. Changes are made by issuing a new version (v0.2…); this file stays unchanged.
> What is actually built, and every deviation, goes in the project logs.
> ✅ decided · 🟡 suggested · ❓ open · 🔍 verify · ⚖️ needs a professional
>
> **Every number, behaviour and look in the entries is 🟡** unless marked ✅. Final values come from gray-box playtests.

**Episode 1 Master Roadmap:** Phase 1, step 1.
**Reads with:** `bunshik-hell_log-004.md` (log 005 records this session), `bunshik-hell-systems-spec-v0.1.md` §7–8, `bunshik-hell-episodes-and-maps-v0.1.md`, Bible Part 1 §9–17.

---

## 1. Rules for this roster

| # | Rule | Status |
|---|---|---|
| 1 | Every hit goes through the food-reaction table (attack × material → reaction). Nothing is hardcoded. | ✅ (Systems Spec §8) |
| 2 | **Skills come from wherever NHMH decides.** Bosses and friends, and this time the first defeat of a new enemy type (the first 라면). | ✅ |
| 3 | **Enemies sometimes drop** sauce, 나트륨, health items or DDEOK, **only when the real food would have them.** Drops challenge without over-rewarding; rates are tuned in playtests. | ✅ rule / 🟡 rates |
| 4 | **Enemies repeat across maps** where they fit the location. Some appear in one map only. Placement is settled in each map spec. | ✅ |
| 5 | **Environment specials appear later in Map 1**, each introduced to beat a specific enemy type. **At most 2 types in Map 1.** | ✅ |
| 6 | Hazards are in the roster because they need rows in the reaction table. The woman is not: she is a scripted set piece (Map 1 spec, Characters v0.1). | ✅ |
| 7 | Episode 1 has **no 어묵** (it arrives with a later 포장마차 map) and **no alcohol or cigarette enemies.** | ✅ |
| 8 | Real brands are never named (tube candy stays generic). | ✅ |

### 1.1 Drop balance ideas (🟡)

- Harder kills drop more often.
- A little bad-luck protection: a guaranteed drop after several kills with nothing.
- A drop the 떡 can't carry fades after a few seconds.

---

## 2. What the 떡 can do, map by map

| Point in Episode 1 | Abilities | Status |
|---|---|---|
| Start (prologue) | Move, jump, plain landing, stomp | ✅ |
| Late in the Map 1 tutorial | + **Roll**, slam (skipping the tutorial still grants the roll) | ✅ |
| First 라면 (Map 1) | + Environment special 1: **pour water** | ✅ |
| First 라면 beaten (Map 1) | + **Sauce flick** | ✅ |
| 튀김 in the kitchen (Map 1) | + Environment special 2: **drop a heavy object** | ✅ |
| Map 2 | An unlock here? ❓ (Phase 1, step 4) | ❓ |
| Map 3 | + **Double jump** | ✅ Episode 1 / 🟡 map |

---

## 3. Environment specials in Map 1

| Special | Source | Used on | Effect | Status |
|---|---|---|---|---|
| **Pour water** | A cup or plastic water bottle filled at the shop's self-serve 정수기 🟡 | 라면 | It swells (불어), slows and collapses → kill | ✅ |
| **Drop a heavy object** | 뚝배기, a pot, a steel bowl 🟡 | 튀김 → kill. 라면 → **pinned**: the bigger the object, the longer the pin. A pinned 라면 only hurts the 떡 if he goes near it. | ✅ |

Both cost 나트륨 (cost ❓, set in playtests).

---

## 4. Reactions the roster needs (for Systems Spec v0.2)

Systems Spec v0.1 §8.1 doesn't define these yet. ✅ They go into v0.2.

| Reaction | Meaning | Used by |
|---|---|---|
| `spill` | The enemy spills, leaving a slippery patch | 김밥 slices (landing) |
| `break_line` | A line of enemies scatters into single pieces | 김밥 slices (roll) |
| `bounce_boost` | 🟡 bounce_off that also launches the 떡 higher (a springboard) | 단무지 (landing, stomp) |
| `swell` | 🟡 Water makes it swell, slow down and collapse | 라면 (pour water) |
| `pin` | 🟡 Held in place for a time that depends on the object's size | 라면 (heavy object) |
| *break free* | Not a reaction: the 떡 escapes a `stick` by rolling | 쫀드기, 나물 반찬 |

---

## 5. Map 1 — lunch 분식집 (김밥천국-style)

**Story order (🟡, settled in the Map 1 spec):** prologue (the woman; 만두 cameo) → tutorial (만두, then 단무지 and the roll) → dining room (만두, 단무지, 김밥 slices, chopsticks) → **first 라면** (water, then the flick) → kitchen (군만두, 김말이튀김, the fryer, the heavy object) → 찜기 → **Mutant 라볶이** (Boss Sheet v0.1).

### 만두 (찐만두) · ★ · soft

| Field | Entry |
|---|---|
| Look | Steamed dumpling. Its pleats are a mouth that opens to show the filling. |
| First seen | The prologue: the woman stabs one and eats it. |
| Moves | Waddles along tabletops and turns at edges. Hops short when the 떡 is close. |
| Attacks | Contact, 1 heart. |
| Player has | Move, jump, landing, stomp |
| Beaten by | stomp → kill · landing → kill (weak) · roll → damage · slam → kill · sauce → damage · heavy object → kill |
| Death | Bursts. The filling spills and stays on the table. |
| Drops | Sometimes a small sauce drip (its dipping 간장) |
| Teaches | Soft food can be jumped on. |

### 단무지 wheel · ★ · crunchy disc

| Field | Entry |
|---|---|
| Look | A thick yellow pickled-radish slice rolling on its edge, glistening with brine. |
| Moves | Rolls along tables and floors and bounces off walls. Speeds up downhill. |
| Attacks | Contact, 1 heart. |
| Player has | + roll |
| Beaten by | landing / stomp → bounce_off (a springboard) · roll → knock_over (falls flat and becomes a platform) · slam → damage · sauce → absorb · heavy object → damage |
| Death | Snaps in half and leaks yellow brine. |
| Drops | Sometimes 나트륨 (pickled, salty) |
| Teaches | **The roll** ✅. One sits at the end of the tutorial, and one early in the main map for players who skipped it. |

### 김밥 slices · ★★ · segmented

| Field | Entry |
|---|---|
| Look | A line of slices marching like a train, led by the uncut end piece (꼬다리). Each slice's cross-section is a face made of fillings. |
| Moves | The train runs along the table edge. An uncut roll charges in a straight line. |
| Attacks | Contact, 1 heart. Charging roll: 1 heart and knockback. |
| Player has | Move, jump, landing, stomp, roll, slam |
| Beaten by | landing → spill · stomp → damage · roll → break_line (slices scatter and can be picked off one by one) · slam → kill · sauce → damage · heavy object → kill |
| Death | Falls apart: 시금치, 계란, 햄 and a 단무지 strip scatter. |
| Drops | Sometimes a 참기름 drop (김밥 is brushed with sesame oil) |
| Teaches | Groups and patterns. The roll as a crowd-breaker. |

### 라면 · ★★★ first one, ★★ later (🟡) · noodle

| Field | Entry |
|---|---|
| Look | A writhing tangle of noodles rising out of its bowl, steaming. |
| Moves | Creeps slowly. Lashes out with noodle strands at medium range. |
| Attacks | Lash, 1 heart. Touching it, 1 heart. |
| Player has | Everything above + **pour water** (introduced here) |
| Beaten by | landing / stomp → hurt_player · roll / slam → absorb · **sauce → absorb** ✅ (it slurps the sauce up) · **pour water → swell → kill** ✅ · **heavy object → pin** ✅ (later 라면, once the heavy object is known) |
| Reserve | 🟡 B: it swells on its own over time. Kept only if playtests need it. |
| Death | Swollen and soggy, it slumps into a mushy heap. |
| Drops | 나트륨 (the 스프), a larger amount |
| Reward | **First 라면 beaten → sauce flick unlocked** ✅ |
| Teaches | Not everything can be fought head-on. Use the room. Noodles soak up sauce, which sets up the 라볶이. |

### 군만두 (small) · ★ · fried
### 김말이튀김 (medium, large) · ★★ · fried

| Field | Entry |
|---|---|
| Look | Golden and crackling. 김말이 slithers like a crisp eel, glass noodles poking out of the cut end. |
| Where | The kitchen, near the end of Map 1 ✅. **A fryer keeps spawning them** (Bible §15). |
| Moves | 군만두 hops quickly. 김말이 slides and lunges. |
| Attacks | Contact, 1 heart. |
| Player has | Everything, including the flick, + **heavy object** (introduced here) ✅ |
| Beaten by | landing → bounce_off + deteriorate (a short-lived platform) · stomp / roll / slam / sauce → deteriorate (fresh → broken → crumbling → soggy) · **heavy object → kill** · **boiling water → kill** (the kitchen's 라면 water 🟡). Size sets durability: small < medium < large. |
| Death | Crumbles into soggy batter. |
| Drops | Sometimes a sauce drip, or nothing |
| Teaches | Food logic: the stomp that killed 만두 bounces off 군만두. Fryers are where enemies come from. |

More 만두 types come with later restaurant types. ✅

### HAZARD: other customers' metal chopsticks · ★

| Field | Entry |
|---|---|
| Look | Flat Korean stainless-steel chopsticks coming down from off-screen. They contrast with the woman's wooden pick. |
| Moves | A shadow telegraph, then a pinch or stab from above. **They can grab the 떡; wiggling free is easy** ✅. They also pick up enemies. |
| Attacks | ½ heart. |
| Beaten by | Can't be destroyed. Dodge them, or let them take a 만두 away for you. |
| Teaches | The prologue's stabbing in small form. The world above the table is dangerous. |

---

## 6. Map 2 — school gate and 문방구

**Player has:** everything from Map 1. Placement and order are left to the Map 2 spec.

### 뻔데기 swarm · ★ · soft

Standard spelling **번데기**; 뻔데기 is the street pronunciation and is kept as the working name.

| Field | Entry |
|---|---|
| Look | Silkworm pupae spilling out of a paper cup, crawling in clumps. |
| Moves | The swarm surges along the ground and up walls. |
| Attacks | Contact, ½ heart per pupa. |
| Beaten by | stomp / landing → kill · slam → kill (an area hit, the answer to a swarm) · roll / sauce → damage · heavy object → kill |
| Death | Pops with brown juice. |
| Drops | Sometimes 나트륨 (salty broth) |
| Teaches | The slam against crowds. |

### 떡꼬치 · ★★ · skewered

| Field | Entry |
|---|---|
| Look | Fellow 떡 stuck on a stick, glazed red. The first other 떡 he meets. |
| Moves | Spins on its skewer like a top. Jabs with the pointed end. |
| Attacks | Jab or spin, 1 heart. |
| Beaten by | landing / stomp → hurt_player (the point) · roll → knock_over · slam → damage · sauce → damage (aimed at the base) · heavy object → kill |
| Death | The 떡 slide off the stick, an echo of his own escape from the pick. |
| Drops | Sometimes DDEOK |
| Teaches | Which end is dangerous. |

### 쫀드기 whip · ★★ · chewy

| Field | Entry |
|---|---|
| Look | Long chewy strips hanging from the 문방구's display clips. Grilled ones curl. |
| Moves | Hangs and whips down. Grilled ones snap like springs. |
| Attacks | Whip, 1 heart. Touching it → stick (slows the 떡). |
| Beaten by | landing / stomp → stick · roll → break free · slam / sauce / heavy object → damage |
| Death | Tears in two and goes limp. |
| Drops | Nothing |
| Teaches | Getting stuck, and breaking free. |

### Tube candy · ★★ · tube

| Field | Entry |
|---|---|
| Look | A straw-shaped candy tube. Generic, no brand. |
| Moves | Stands upright and turns to aim. Fires candy pellets. |
| Attacks | Pellet, ½ heart. |
| Beaten by | landing → bounce_off · stomp → damage · roll → knock_over · slam / heavy object → kill · **sauce → jam** ✅ (clogs its mouth: no more pellets) |
| Death | Cracks and spills sugar. |
| Drops | Nothing |
| Teaches | Sauce does more than damage. |

### HAZARD: spilled 슬러시 · ★

| Field | Entry |
|---|---|
| Look | Bright puddles spreading from a tipped slushie machine. |
| Effect | Slippery. The cold makes the 떡 go hard, like stale 떡: ½ heart every few seconds while he stays in it. |
| Teaches | The ground itself can hurt. |

---

## 7. Map 3 — school cafeteria (급식실)

**Player has:** everything + **double jump** (unlocked here).

### 흰 우유 carton · ★★ · liquid-filled

| Field | Entry |
|---|---|
| Look | A 200 ml school milk carton, its spout open like a mouth. |
| Moves | Squeezes itself and shoots milk geysers upward. |
| Attacks | Geyser, 1 heart and a throw. A geyser can also launch the 떡 up to a ledge. |
| Beaten by | landing / stomp / slam / heavy object → burst · roll → push · sauce → damage |
| Death | Bursts, leaving a slippery white flood. |
| Drops | Nothing |
| Teaches | An enemy's attack can be used as a lift. |

### 깍두기 dice · ★★ · hard cube

| Field | Entry |
|---|---|
| Look | Red radish cubes tumbling like dice down trays and steps. |
| Moves | Tumbles in bursts and stacks into walls. |
| Attacks | Contact, 1 heart. |
| Beaten by | landing / stomp → bounce_off · roll / slam → push (into the 잔반통) · sauce → absorb · heavy object → damage |
| Death | Splits, leaking red brine. |
| Drops | Sometimes 나트륨 |
| Teaches | Push enemies into hazards. |

### 나물 반찬 tangle · ★★ · tangle

| Field | Entry |
|---|---|
| Look | A heap of seasoned greens moving as one knotted mass. |
| Moves | Creeps along serving trays and reaches out with strands. |
| Attacks | Touching it → stick, plus ½ heart. |
| Beaten by | landing / stomp → stick · roll → break free · slam / heavy object → damage · **sauce → deteriorate** ✅ (it wilts) |
| Death | Wilts flat into a puddle. |
| Drops | Sometimes a 참기름 drop (나물 is dressed with sesame oil) |
| Teaches | Sauce wears some enemies down over time. |

### 요구르트 rocket · ★ · rocket

| Field | Entry |
|---|---|
| Look | A small yogurt-drink bottle. The foil lid is its nose cone. |
| Moves | Shakes, then launches in an arc. Lands empty and staggers. |
| Attacks | Hit in flight, 1 heart. |
| Beaten by | landing → hurt_player (while armed) · stomp → kill (once empty) · roll → damage · slam / sauce / heavy object → kill |
| Death | Crumples like a can. |
| Drops | Nothing |
| Teaches | Wait for the danger to pass, then strike. |

### HAZARD: serving ladle · ★★

| Field | Entry |
|---|---|
| Look | A giant steel ladle swinging down from the serving line. |
| Moves | Scoops and grabs the 떡 (a harder wiggle than the chopsticks), then dumps him somewhere worse. |
| Attacks | 1 heart. |

### HAZARD: 잔반통 pit · ★★★

| Field | Entry |
|---|---|
| Look | The food-waste bin: rotting, churning. |
| Effect | Falling in is death (back to the last 찜기). Wide gaps across it need the double jump. |
| Note | Fits the "thrown in a food-waste bin" idea for episode exits. |

---

## 8. Handed to the Map 1 spec: the prologue

Decided this session and recorded here so nothing is lost. The Map 1 spec v0.1 is where it is designed in full.

| # | Decision | Status |
|---|---|---|
| 1 | The opening cutscene shows glimpses of the shop, then moves to the woman's table, to her dish or cup. Her full face and body don't need to be shown. | ✅ |
| 2 | She says "오~~~ 맛있겠다~~~~~" while stabbing the 떡 and moving him slowly to her mouth. The player must wiggle him off the pick quickly (**mashing left and right**), or she chews him up: game over, and a restart on the pick at the 맛있겠다 moment. | ✅ |
| 3 | Once he's free, only her hand and the pick are seen, stabbing from above. **Where:** a single counter table at the window, typical of these shops. | ✅ |
| 4 | **Damage:** small stabs ½ heart. A big stab takes 1 heart and lifts him on the pick; he must wiggle off again. | ✅ |
| 5 | **30 stabs** to survive. The count doesn't restart after a hit; he just has to survive all 30 (the number may change). **If he's eaten, everything restarts from 맛있겠다.** | ✅ |
| 6 | She sometimes stabs a 만두 instead, with eating sounds, which slows her for a moment. | ✅ |
| 7 | The stabbing is **varied and unpredictable**, not mechanical: random lengths, random bursts of quick stabs, and so on. Every stab is still telegraphed. 🟡 Patterns (single big stab, burst, hover-then-strike, fake-out, slow drag, 만두 break) chosen at random, with her anger raising the odds of the harder ones. | ✅ / 🟡 patterns |
| 8 | Dodging the 30th stab opens the exit. | ✅ |

**Her lines, exactly as written by NHMH** (not to be changed without NHMH's say; ⚠️ native-speaker review):

```
오~~~ 맛있겠다~~~~~
아이구 소스 너무 많아
이 떡볶이 왜 이렇게 미끄럽지?
야! 왜 그래!!
야 씨발 배고파!
아 그래                     (after stabbing a 만두)
씨~~~~~~발 년아!            (as the exit opens)
```

---

## 9. Facts checked

| Fact | Result |
|---|---|
| 김밥천국-style shops serve fried 만두 | ✅ A 김밥천국 menu lists 군만두 and a 스페셜떡볶이 with 군만두; a similar chain serves 만두튀김 |
| 김말이튀김 at these shops | 🟡 Sold mainly at 분식집, usually fried from frozen; not found on a 김밥천국 menu. 🔍 |
| Self-serve water | ✅ A 김밥집 owner's review: customers use the 정수기 themselves. A pitcher on the table 🔍 |
| 라면 and 라볶이 on the menu | ✅ Many 라면 variants and 라볶이 |
| 문방구 at school gates with snacks at the door; 분식집 beside them | ✅ |
| 떡꼬치 as a remembered school-gate snack | ✅ |
| School milk programme; 200 ml white-milk cartons | ✅ |
| 뻔데기 sold at school gates | 🔍 |
| 요구르트 as a 급식 dessert | 🔍 |
| Straw-style tube candy at 문방구 | 🔍 (stays generic) |

**Sources:** a 김밥천국 menu (polle.com, 공덕점); 얌샘김밥 menu (autoreserve.com); thewiki.kr 김말이; rentre.kr water-purifier review; 경인일보 레트로K articles on school-gate 문방구 and 분식집; Esquire Korea on 문방구 bars; 경상남도 학교우유급식사업 guidelines; foodspring.co.kr (200 ml carton).

---

## 10. Deviations from earlier docs (for log 005)

| Doc | Said | Now |
|---|---|---|
| Episodes and Maps v0.1 §2; log 002 §5 #7 | 라면 is a regular enemy **you can't fight** (🚫) | Beaten with water or pinned. The first one gives the flick. |
| Systems Spec v0.1 §3 | Skills only from bosses and friends | Skills come from wherever NHMH decides (this time the first 라면) |
| Systems Spec v0.1 §3.1; log 002 §7.1 | Sauce flick 🟡 Map 2 | Map 1, from the first 라면 |
| Systems Spec v0.1 §8.2 | 어묵 and 튀김 rows (Bible) | No 어묵 in Episode 1. 튀김 = 군만두 and 김말이튀김 in Map 1's kitchen. |
| Systems Spec v0.1 §8.1 | Reactions list | Adds `spill`, `break_line`, 🟡 `bounce_boost`, `swell`, `pin` |
| Log 002 §6 | 라면 🚫 · chopsticks: stab only | 라면 ★★★ / ★★ · chopsticks can grab (easy wiggle) |

---

## 11. Open

1. ❓ Does Map 2 get an unlock now that the flick is in Map 1? (Phase 1, step 4)
2. ❓ Which enemies come back in later maps (each map spec).
3. ❓ Drop rates; 나트륨 cost per environment special; every 🟡 value (playtests).
4. 🔍 김말이튀김 at 김밥천국-style shops; a water pitcher on tables; 뻔데기 at school gates; 요구르트 in 급식; tube candy.
5. ⚠️ Native-speaker review of the prologue lines.

## 12. Next

Episode 1 Master Roadmap, Phase 1, step 2: **Episode 1 Boss Sheet v0.1** (the Mutant 라볶이 in detail; the Map 2, Map 3 and world final bosses as concepts).
